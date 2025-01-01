. $PSScriptRoot\..\lib\helper.ps1


if ($args.Length -eq 0 -or [string]::IsNullOrWhiteSpace($args[0])) {
  Write-Host "Usage: pyvm uninstall <version>" -ForegroundColor Yellow
  exit 1
}

$version = Test-Version $args[0]

$installed_versions = Get-InstalledPython | ForEach-Object {
  $_.Version
}

$CONFIG = Get-Config

$current_version = Get-CurrentPython | Select-Object -ExpandProperty Version

$current_dir = $CONFIG | Select-Object -ExpandProperty Current_Dir

$version_dir = $CONFIG | Select-Object -ExpandProperty Python_Dir | Join-Path -ChildPath $version



if ($installed_versions -contains $version) {
  Write-Host "Uninstalling Python $version..." -ForegroundColor Cyan

  # Check for running processes
  $pythonExePath = Join-Path $current_dir "python.exe"

  $runningProcesses = Get-Process | Where-Object { $_.Path -eq $pythonExePath } -ErrorAction SilentlyContinue

  if ($runningProcesses) {
    Write-Host "The following processes are using Python $version :" -ForegroundColor Yellow
    $runningProcesses | ForEach-Object { Write-Host "  - $($_.Name) (PID: $($_.Id))" }
    Write-Host "Please close the processes and try again." -ForegroundColor Yellow
    exit 1
  }

  if ($current_version -eq $version) {
    # ask user weather to remove the current version
    Write-Host "Python $version is the current used version." -ForegroundColor Yellow
    $response = Read-Host "Do you want to remove the current version? (y/n)"
    if ($response.ToLower() -eq "y") {
      Remove-Item -Path $current_dir -Recurse -Force -ErrorAction SilentlyContinue
      Remove-Item -Path $version_dir -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
      Write-Host "Uninstall aborted." -ForegroundColor Yellow
      exit 1
    }
  }
  else {
    Remove-Item -Path $version_dir -Recurse -Force -ErrorAction SilentlyContinue
  }


  Write-Host "Python $version uninstalled." -ForegroundColor Green
  exit
}
Write-Host "Python $version is not installed. Type "pyvm list" to see what is installed." -ForegroundColor Yellow


