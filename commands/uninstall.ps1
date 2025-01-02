. $PSScriptRoot\..\lib\helper.ps1


if ($args.Length -eq 0 -or [string]::IsNullOrWhiteSpace($args[0])) {
  Write-Host "Usage: pyvm uninstall <version>" -ForegroundColor Yellow
  exit 1
}

$version = Test-Version $args[0]

Test-RunningProcesses $version


$installed_versions = Get-InstalledPython | ForEach-Object {
  $_.Version
}

$CONFIG = Get-Config

$version_dir = $CONFIG | Select-Object -ExpandProperty Version_Dir | Join-Path -ChildPath $version

$current_dir = $CONFIG | Select-Object -ExpandProperty Current_Dir


if ($installed_versions -contains $version) {
  Write-Host "Uninstalling Python $version..." -ForegroundColor Cyan
  try {
    $is_currnet = Test-IsUsing $version
    if ($is_currnet) {
      Remove-Item $current_dir -Recurse -Force -ErrorAction Ignore
    }
    Remove-Item -Path $version_dir -Recurse -Force -ErrorAction Ignore
  }
  catch {
    Write-Host "Failed to uninstall Python $version." -ForegroundColor Red
    Write-Host "Please mauanlly remove the directory: $version_dir" -ForegroundColor Yellow
    exit 1
  }
  finally {
    Write-Host "Python $version has been uninstalled." -ForegroundColor Green
  }
}
else {
  Write-Host "Python $version is not installed. Type 'pyvm list' to see what is installed." -ForegroundColor Yellow
}

