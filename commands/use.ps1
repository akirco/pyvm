. $PSScriptRoot\..\lib\helper.ps1


if ($args.Length -eq 0 -or [string]::IsNullOrWhiteSpace($args[0])) {
    Write-Host "Usage: pyvm use <version>" -ForegroundColor Yellow
    exit 1
}

$version = Test-Version $args[0]

$CONFIG = Get-Config

$Used_Version_Dir = $CONFIG | Select-Object -ExpandProperty Version_Dir | Join-Path -ChildPath $version

$pythonInfo = Get-Python $Used_Version_Dir

if (-not $pythonInfo.IsValid -and $null -eq $pythonInfo.Version) {
    Write-Host "Version $version is not installed" -ForegroundColor Red
    exit 1
}


$Current_Dir = $CONFIG | Select-Object -ExpandProperty Current_Dir

New-Item -ItemType Junction -Path $Current_Dir -Value $Used_Version_Dir -Force | Out-Null

Write-Host "Now using Python v$version (64-bit)"

