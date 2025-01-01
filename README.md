
## Tips

> It's in development, and if you want vscode to recognize the python interpreter, you can run:
> ```
>  scoop shim add python "$(scoop prefix pyvm)\python\current\python.exe"
> ```


## install

```
scoop bucket add aki https://github.com/akirco/aki-apps.git
scoop install aki/pyvm
```

## usage

```
pyvm - Python Version Manager

Usage:
  pyvm <command> [<args>]

Commands:
  install    Install a Python version using python-build
  list       List all installed and used versions
  venv       Create a virtual environment using the specified Python version
  mirror     Set python-build mirror
  use        Use a Python version
  uninstall  Uninstall a Python version
  help       Print this message or the help of the given subcommand(s)

Options:
  -h, --help     Print help
  -v, --version  Print version
```
