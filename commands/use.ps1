. $PSScriptRoot\..\lib\helper.ps1


if ($args.Length -eq 0 -or [string]::IsNullOrWhiteSpace($args[0])) {
    Write-Host "Usage: pyvm use <version>" -ForegroundColor Yellow
    exit 1
}

$version = Test-Version $args[0]

$Used_Version_Dir = Join-Path $PSScriptRoot "..\python" $version

$pythonInfo = Get-Python $Used_Version_Dir

if (-not $pythonInfo.IsValid) {
    Write-Host "Version $version is not installed" -ForegroundColor Red
    exit 1
}


$Current_Version_Dir = Join-Path $PSScriptRoot "..\python\current"

New-Item -ItemType Junction -Path $Current_Version_Dir -Value $Used_Version_Dir -Force | Out-Null

Write-Host "Now using Python v$version (64-bit)"

