. $PSScriptRoot\..\lib\helper.ps1

$subCommand = $args[0]



function Show-MainHelp {
    Write-Host "pyvm - Python Version Manager" -f Blue
    Write-Host ""
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm <command> [<args>]" -f Black
    Write-Host ""
    Write-Host "Commands:" -f Black
    Write-Host "  install    Install the specified python version"
    Write-Host "  list       List the python installations. Type '--remote' to see what versions can be installed"
    Write-Host "  venv       Create a virtual environment using the specified Python version"
    Write-Host "  mirror     Cat or set python installer mirror"
    Write-Host "  use        Set the specified version to be used in global,like 'nvm use'"
    Write-Host "  uninstall  Uninstall the specified python version"
    Write-Host "  help       Print this message or the help of the given subcommand(s)"
    Write-Host ""
    Write-Host "Options:" -f Black
    Write-Host "  -h, --help     Print help"
    Write-Host "  -v, --version  Print version"
}

function Show-InstallHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm install <version>" -f Black
    Write-Host ""
    Write-Host "Examples:" -f Black
    Write-Host "  pyvm install 3.9.0    # Install Python 3.9.0"
}

function Show-ListHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm list [options]" -f Black
    Write-Host ""
    Write-Host "Options:" -f Black
    Write-Host "  --remote     Show installable remote versions"
    Write-Host "  --local      Show installed local versions (default)"
}

function Show-VenvHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm venv <version> [venv_path]" -f Black
    Write-Host ""
    Write-Host "Examples:" -f Black
    Write-Host "  pyvm venv 3.9.3    # Create a virtual environment using Python 3.9.3"
    Write-Host ""
    Write-Host "Tips:" -f Black
    Write-Host "  venv_path, default is $(Get-Config | Select-Object -ExpandProperty Venv_Dir)"
    Write-Host "  this command is a experimental function,will be dropped."
}

function Show-MirrorHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm mirror <mirror>" -f Black
    Write-Host ""
    Write-Host "Examples:" -f Black
    Write-Host "  pyvm mirror https://www.example.com/mirror    # Set the mirror to https://www.example.com/mirror"
}

function Show-UseHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm use <version>" -f Black
    Write-Host ""
    Write-Host "Examples:" -f Black
    Write-Host "  pyvm use 3.9.0    # Use Python 3.9.0"
}

function Show-UninstallHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm uninstall <version>" -f Black
    Write-Host ""
    Write-Host "Examples:" -f Black
    Write-Host "  pyvm uninstall 3.9.0    # Uninstall Python 3.9.0"
}



if ($null -eq $subCommand) {
    Show-MainHelp
    exit 0
}

switch ($subCommand) {
    "install" {
        Show-InstallHelp
        exit 0
    }
    "list" {
        Show-ListHelp
        exit 0
    }
    "venv" {
        Show-VenvHelp
        exit 0
    }
    "mirror" {
        Show-MirrorHelp
        exit 0
    }
    "use" {
        Show-UseHelp
        exit 0
    }
    "uninstall" {
        Show-UninstallHelp
        exit 0
    }
    "help" {
        Show-MainHelp
        exit 0
    }
    Default {
        Show-MainHelp
        exit 0
    }
}



