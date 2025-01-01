$subCommand = $args[0]

function Show-MainHelp {
    Write-Host "pyvm - Python Version Manager" -f Blue
    Write-Host ""
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm <command> [<args>]" -f Black
    Write-Host ""
    Write-Host "Commands:" -f Black
    Write-Host "  install    Install a Python version using python-build"
    Write-Host "  list       List all installed and used versions"
    Write-Host "  latest     Print the latest installed or known version with the given prefix"
    Write-Host "  mirror     Set python-build mirror"
    Write-Host "  use        Use a Python version"
    Write-Host "  uninstall  Uninstall a Python version"
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
    Write-Host "  pyvm install latest   # Install the latest version"
}

function Show-ListHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm list [options]" -f Black
    Write-Host ""
    Write-Host "Options:" -f Black
    Write-Host "  --remote     Show installable remote versions"
    Write-Host "  --local      Show installed local versions (default)"
}

function Show-LatestHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm latest <prefix>" -f Black
    Write-Host ""
    Write-Host "Examples:" -f Black
    Write-Host "  pyvm latest 3.9    # Print the latest version with prefix 3.9 (e.g. 3.9.13)"
}

function Show-MirrorHelp {
    Write-Host "Usage:" -f Black
    Write-Host "  pyvm mirror <mirror>" -f Black
    Write-Host ""
    Write-Host "Examples:" -f Black
    Write-Host "  pyvm mirror https://www.example.com/python-build    # Set the mirror to https://www.example.com/python-build"
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
    "latest" { 
        Show-LatestHelp 
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
        Show-UseHelp 
        exit 0
    }
    Default { 
        Show-MainHelp 
        exit 0
    }
}



