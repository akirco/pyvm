function Repair-Path {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
  )

  try {
    $fullPath = [System.IO.Path]::GetFullPath((New-Object -TypeName System.IO.FileInfo -ArgumentList $Path).FullName)
    return $fullPath
  }
  catch {
    Write-Error "Failed to repair path: $_"
    throw
  }
}


function Repair-Url {
  param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
    [Parameter(Mandatory = $true)]
    [string]$RelativeUrl
  )
  if ($BaseUrl.EndsWith('/')) {
    $BaseUrl = $BaseUrl.TrimEnd('/')
  }
  if ($RelativeUrl.StartsWith('/')) {
    $RelativeUrl = $RelativeUrl.TrimStart('/')
  }
  return "$BaseUrl/$RelativeUrl"
}



function Get-Config {
  $mirror_url = [Environment]::GetEnvironmentVariable("Python_Mirror", "User")
  $gpg_key_id = [Environment]::GetEnvironmentVariable("GPG_Key_ID", "User")
  $Python_Mirror = if ($mirror_url) { $mirror_url } else { "https://www.python.org/ftp/python/" }
  $GPG_Key_ID = if ($gpg_key_id) { $gpg_key_id } else { "FC624643487034E5" } # Default key ID
  $Root_Path = Get-Target -Path $(Repair-Path -Path (Join-Path $PSScriptRoot ".."))
  $CONFIG = @{
    Python_Mirror = $Python_Mirror
    GPG_Key_ID    = $GPG_Key_ID
    Root_Path     = $Root_Path
    Dark_Path     = Repair-Path -Path $(Join-Path $Root_Path "bin\wix\dark.exe")
    Logs_Dir      = Repair-Path -Path $(Join-Path $Root_Path "logs")
    Python_Dir    = Repair-Path -Path $(Join-Path $Root_Path "python")
    Venv_Dir      = Repair-Path -Path $(Join-Path $Root_Path "python\venvs")
    Current_Dir   = Repair-Path -Path $(Join-Path $Root_Path "python\current")
    Cache_Dir     = Repair-Path -Path $(Join-Path $Root_Path "python\caches")
    Version_Dir   = Repair-Path -Path $(Join-Path $Root_Path "python\$version")
    Tmp_Dir       = Repair-Path -Path $(Join-Path $Root_Path "python\tmp")
  }
  return $CONFIG
}

function Get-Target {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path
  )
  $link_type = Get-Item $Path | Select-Object -ExpandProperty LinkType -ErrorAction SilentlyContinue
  if ($link_type -eq "SymbolicLink" -or $link_type -eq "Junction" -or $link_type -eq "HardLink") {
    $target = (Get-Item $Path).LinkTarget
    return $target
  }
  return $Path
}



function fname($path) { split-path $path -leaf }


function movedir($from, $to) {
  $from = $from.trimend('\')
  $to = $to.trimend('\')

  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo.FileName = 'robocopy.exe'
  $proc.StartInfo.Arguments = "`"$from`" `"$to`" /e /move"
  $proc.StartInfo.RedirectStandardOutput = $true
  $proc.StartInfo.RedirectStandardError = $true
  $proc.StartInfo.UseShellExecute = $false
  $proc.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
  [void]$proc.Start()
  $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
  $proc.WaitForExit()

  if ($proc.ExitCode -ge 8) {
    Write-Host $stdoutTask.Result
    throw "Could not find '$(fname $from)'! (error $($proc.ExitCode))"
  }

  # wait for robocopy to terminate its threads
  1..10 | ForEach-Object {
    if (Test-Path $from) {
      Start-Sleep -Milliseconds 100
    }
  }
}

function Expand-DarkArchive {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [String]
    $Path,
    [Parameter(Position = 1)]
    [String]
    $DestinationPath = (Split-Path $Path)
  )

  try {
    if (-not (Test-Path $Path)) {
      throw "Source file not found: $Path"
    }

    if (-not (Test-Path $DestinationPath)) {
      New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }

    $DarkPath = Get-Config | Select-Object -ExpandProperty Dark_Path
    $dark_error_log = Get-Config | Select-Object -ExpandProperty Logs_Dir | Join-Path -ChildPath "dark_error.log"
    $installed_timedate = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
    $install_log = Get-Config | Select-Object -ExpandProperty Logs_Dir | Join-Path -ChildPath $installed_timedate
    New-Item -Path $dark_error_log -ItemType File -Force | Out-Null
    New-Item -Path $install_log -ItemType File -Force | Out-Null
    if (-not (Test-Path $DarkPath)) {
      throw "Dark.exe not found at: $DarkPath"
    }
    $proc = Start-Process -FilePath $DarkPath -ArgumentList @(
      '-nologo',
      '-x',
      "`"$DestinationPath`"",
      "`"$Path`""
    ) -NoNewWindow -PassThru -Wait -RedirectStandardError $dark_error_log -RedirectStandardOutput $install_log

    if ($proc.ExitCode -ne 0) {
      $errorContent = Get-Content $dark_error_log -ErrorAction SilentlyContinue
      throw "Dark.exe failed with exit code $($proc.ExitCode). Error: $errorContent"
    }
    Write-Verbose "Archive extraction completed successfully"
  }
  catch {
    Write-Error "Failed to expand archive: $_"
    throw
  }
  finally {
    Remove-Item $dark_error_log -ErrorAction SilentlyContinue
  }
}

function Expand-MsiArchive {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [String]
    $Path,
    [Parameter(Position = 1)]
    [String]
    $DestinationPath = (Split-Path $Path)
  )
  $DestinationPath = $DestinationPath.TrimEnd('\')

  $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList @(
    '/a',
    $Path,
    '/qn',
    "TARGETDIR=$(Resolve-Path $DestinationPath)"
  ) -NoNewWindow -PassThru -Wait

  if ($proc.ExitCode -ne 0) {
    throw "Failed to extract MSI file. Exit code: $($proc.ExitCode)"
  }
  Remove-Item $(Join-Path $(Resolve-Path $DestinationPath) $(fname $Path)) -Force -ErrorAction Ignore
}
function Add-Path {
  param (
    [Parameter(Mandatory = $true)]
    [string]$pathToAdd,

    [Parameter(Mandatory = $false)]
    [bool]$global = $false
  )

  function CheckPathExists {
    param ([string]$path, [EnvironmentVariableTarget]$target)
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $target)
    return $currentPath.Split(';') -contains $path
  }

  function AddPath {
    param([string]$path, [EnvironmentVariableTarget]$target)

    if (-not (CheckPathExists -path $path -target $target)) {
      $currentPath = [Environment]::GetEnvironmentVariable("Path", $target)
      $newPath = if ($currentPath) { "$currentPath;$path" } else { $path }
      [Environment]::SetEnvironmentVariable("Path", $newPath, $target)
      Write-Host "Path added to $target environment variable."
    }
    else {
      Write-Host "Path already exists in $target environment variable."
    }
  }

  AddPath $pathToAdd ([EnvironmentVariableTarget]::User)

  if ($global) {
    AddPath $pathToAdd ([EnvironmentVariableTarget]::Machine)
  }
}

function Remove-Path {
  param (
    [Parameter(Mandatory = $true)]
    [string]$pathToRemove,

    [Parameter(Mandatory = $false)]
    [bool]$global = $false
  )

  function CheckPathExists {
    param ([string]$path, [EnvironmentVariableTarget]$target)
    $currentPath = [Environment]::GetEnvironmentVariable("Path", $target)
    return $currentPath.Split(';') -contains $path
  }

  function RemovePath {
    param([string]$path, [EnvironmentVariableTarget]$target)

    $currentPath = [Environment]::GetEnvironmentVariable("Path", $target)
    if (CheckPathExists -path $path -target $target) {
      $newPath = ($currentPath.Split(';') | Where-Object { $_ -ne $path }) -join ';'
      [Environment]::SetEnvironmentVariable("Path", $newPath, $target)
      Write-Host "Path removed from $target environment variable."
    }
    else {
      Write-Host "Path not found in $target environment variable."
    }
  }

  RemovePath $pathToRemove ([EnvironmentVariableTarget]::User)

  if ($global) {
    RemovePath $pathToRemove ([EnvironmentVariableTarget]::Machine)
  }
}

function Get-Python {
  param (
    [Parameter(Mandatory = $true)]
    [string]$PythonPath
  )

  try {
    if (Test-Path $PythonPath) {
      $pythonExe = Join-Path $PythonPath "python.exe"
      if (Test-Path $pythonExe) {
        $version = & $pythonExe -c "import sys; print('.'.join(map(str, sys.version_info[:3])))"
        return @{
          Version    = $version
          Path       = $PythonPath
          Executable = $pythonExe
          IsValid    = $true
        }
      }
    }
  }
  catch {
    Write-Host "Error while checking Python version: $_" -ForegroundColor Red
  }

  return @{
    Version    = $null
    Path       = $PythonPath
    Executable = $null
    IsValid    = $false
  }
}

function Get-InstalledPython {
  try {
    $pythonDir = Get-Config | Select-Object -ExpandProperty Python_Dir
    $versions = Get-ChildItem $pythonDir -Directory -ErrorAction Ignore | Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' }
    if (-not $versions) {
      return @()
    }
    $pythonVersions = @()
    foreach ($versionDir in $versions) {
      $pythonInfo = Get-Python -PythonPath $versionDir.FullName
      if ($pythonInfo.IsValid) {
        $pythonVersions += $pythonInfo
      }
    }
    return $pythonVersions
  }
  catch {
    <#Do this if a terminating exception happens#>
    Write-Host "Failed to get installed Python versions: $_" -ForegroundColor Red
  }
}

function Get-CurrentPython {
  $pythonPath = Get-Config | Select-Object -ExpandProperty Current_Dir
  if (-not $pythonPath) {
    return @{
      Version    = $null
      Path       = $null
      Executable = $null
      IsValid    = $false
    }
  }
  return Get-Python -PythonPath $pythonPath
}

function Get-Pip {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Version
  )

  $pythonInfo = Get-Python -PythonPath (Get-Config | Select-Object -ExpandProperty Python_Dir | Join-Path -ChildPath $Version)
  if (-not $pythonInfo.IsValid) {
    Write-Host "Python $Version is not valid" -ForegroundColor Red
    exit 1
  }
  $pythonExe = $pythonInfo.Executable

  $pip_log = Get-Config | Select-Object -ExpandProperty Logs_Dir | Join-Path -ChildPath "pip.log"
  $pip_warning_log = Get-Config | Select-Object -ExpandProperty Logs_Dir | Join-Path -ChildPath "pip_warning.log"

  New-Item -Path $pip_log -ItemType File -Force | Out-Null
  New-Item -Path $pip_warning_log -ItemType File -Force | Out-Null

  # Redirect standard error to null to suppress warnings
  $proc = Start-Process -FilePath $pythonExe -ArgumentList @("-E", "-s", "-m", "ensurepip", "-U", "--default-pip") -NoNewWindow -PassThru -Wait -RedirectStandardOutput $pip_log -RedirectStandardError $pip_warning_log
  if ($proc.ExitCode -ne 0) {
    throw "Failed to install pip. Exit code: $($proc.ExitCode)"
  }
  # Write-Host "Pip installed successfully" -ForegroundColor Green
}


function Test-Version {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [switch]$Install
  )

  # Check if the version argument is provided
  if (-not $Version -or $Version.Trim() -eq "") {
    Write-Host "Usage: pyvm <command> <version>" -ForegroundColor Yellow
    exit 1
  }

  # Check python version format (x.y.z)
  if (-not $Version -match '^\d+\.\d+\.\d+$') {
    Write-Host "Invalid version format. Please specify a version in the format x.y.z" -ForegroundColor Yellow
    exit 1
  }

  if ($Install) {
    try {
      # Check if the version is installed
      $installed_versions = Get-InstalledPython | ForEach-Object {
        $_.Version
      }

      $has_cached_version = Get-Config | Select-Object -ExpandProperty Cache_Dir -ErrorAction Ignore | Get-ChildItem -Filter "python-$Version-amd64.exe" -ErrorAction Ignore | Where-Object { $_.Name -match "^python-$Version-amd64.exe$" }

      # Check if the version is installed and is valid
      if ($installed_versions -contains $Version -and (Get-InstalledPython | Where-Object { $_.Version -eq $Version }).IsValid) {
        Write-Host "Python $Version is already installed." -ForegroundColor Yellow
        exit 0
      }
      $download_mirror = Get-Config | Select-Object -ExpandProperty Python_Mirror
      if (-not $has_cached_version) {
        $ProgressPreference = 'SilentlyContinue'
        $response = Invoke-WebRequest -Uri $(Repair-Url -BaseUrl $download_mirror -RelativeUrl "/")
        $versions = [regex]::Matches($response.Content, '<a href="(\d+\.\d+\.\d+)/"') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object -Property { [version]$_ } -Descending
        if (-not $versions.Contains($Version)) {
          Write-Host "Version $Version is not available" -ForegroundColor Red
          Write-Host "Type 'pyvm list --remote' to see available versions" -ForegroundColor Green
          exit 1
        }
      }
    }
    catch {
      Write-Host "Failed to fetch remote versions. Error: $_" -ForegroundColor Red
    }
  }

  return $Version.Trim()
}

function Get-RemoteFile {
  param (
    [string]$Url,
    [string]$OutFile
  )

  try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $Url -OutFile $OutFile
    $ProgressPreference = 'Continue'
    return $true
  }
  catch {
    Remove-Item $OutFile -ErrorAction SilentlyContinue
    return $false
  }
}


function Test-Signature {
  param (
    [string]$FilePath,
    [string]$Version,
    [string]$DownloadMirror
  )

  $fileName = fname $FilePath
  $baseUrl = Repair-Url $DownloadMirror $Version
  $ascPath = Join-Path (Split-Path $FilePath) "$fileName.asc"

  # Download signature file
  Write-Host "Downloading signature file..."
  if (-not (Get-RemoteFile -Url "$baseUrl/$fileName.asc" -OutFile $ascPath)) {
    throw "Failed to download signature file"
  }

  try {
    # Import the public key
    $keyId = (Get-Config | Select-Object -ExpandProperty GPG_Key_ID)  # Use configured key ID
    Write-Host "Importing public key..."
    $importResult = & gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys $keyId 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to import public key: $importResult"
    }

    # Verify signature using GPG
    Write-Host "Verifying GPG signature..."
    $result = & gpg --verify $ascPath $FilePath 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "GPG signature verification failed: $result"
    }

    Write-Host "Signature verification successful" -ForegroundColor Green
    return $true
  }
  catch {
    Write-Host "Verification failed: $_" -ForegroundColor Red
    return $false
  }
  finally {
    Remove-Item $ascPath -ErrorAction SilentlyContinue
  }
}