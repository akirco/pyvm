. $PSScriptRoot\..\lib\helper.ps1

# Check if the version argument is provided
if ($args.Length -eq 0 -or [string]::IsNullOrWhiteSpace($args[0])) {
  Write-Host "Usage: pyvm venv <version> [venvPath]" -ForegroundColor Yellow
  exit 1
}

$version = Test-Version $args[0]

# Determine the virtual environment path
$venvPath = if ($args.Length -gt 1) { $args[1] } else { Get-Config | Select-Object -ExpandProperty Venv_Dir }

# Verify the Python version
$pythonInfo = Get-Python -PythonPath (Get-Config | Select-Object -ExpandProperty Python_Dir | Join-Path -ChildPath $version)
if (-not $pythonInfo.IsValid) {
  Write-Host "Python $version is not valid or not installed." -ForegroundColor Red
  exit 1
}

# Create the virtual environment
try {
  # hidden virtual environment default prompt
  $env:VIRTUAL_ENV_DISABLE_PROMPT = "1"
  $pythonExe = $pythonInfo.Executable
  $venv_log = Get-Config | Select-Object -ExpandProperty Logs_Dir | Join-Path -ChildPath "venv.log"
  $venv_error_log = Get-Config | Select-Object -ExpandProperty Logs_Dir | Join-Path -ChildPath "venv_error.log"
  New-Item -Path $venv_log -ItemType File -Force | Out-Null
  New-Item -Path $venv_error_log -ItemType File -Force | Out-Null

  Write-Host "Creating virtual environment($version) at $(fname $venvPath)"
  $proc = Start-Process -FilePath $pythonExe -ArgumentList @("-m", "venv", $venvPath) -NoNewWindow -PassThru -Wait -RedirectStandardOutput $venv_log -RedirectStandardError $venv_error_log
  if ($proc.ExitCode -ne 0) {
    throw "Failed to create virtual environment. Exit code: $($proc.ExitCode)"
  }
  # activate the virtual environment
  $activate = Join-Path $venvPath "Scripts\Activate.ps1"
  if (-not (Test-Path $activate)) {
    throw "Virtual environment activation script not found at $activate"
  }
  Write-Host "Activating virtual environment..."
  . $activate
  Write-Host "Completd !" -ForegroundColor Green

  exit 0
}
catch {
  Write-Host "Error creating virtual environment: $_" -ForegroundColor Red
  exit 1
}
