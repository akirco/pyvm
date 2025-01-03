Set-StrictMode -Off

$subCommand = $Args[0]

$commandsPath = Join-Path $PSScriptRoot "..\commands"

function command_path {
  param (
    [string]$cmd
  )
  Join-Path $commandsPath "$cmd.ps1"
}

function exec($cmd, $arguments) {
  $cmd_path = command_path $cmd
  & $cmd_path @arguments
}

$commands = [string[]]$(Get-ChildItem $commandsPath).BaseName
function Show-VersionInfo {
  Write-Host "version: 0.1.1" -f DarkBlue
}


switch ($subCommand) {

    ({ $subCommand -in @($null, '-h', '--help', '/?') }) {
    exec 'help'
  }
    ({ $subCommand -in @('-v', '--version') }) {
    Show-VersionInfo
  }

    ({ $subCommand -in ($commands) }) {
    [string[]]$arguments = $Args | Select-Object -Skip 1
    if ($null -ne $arguments -and $arguments[0] -in @('-h', '--help', '/?')) {
      exec 'help' @($subCommand)
    }
    else {
      exec $subCommand $arguments
    }
  }
  default {
    Write-Host "Command '$subCommand' is not recognized. See 'help'." -f darkyellow
    exit 1
  }
}
