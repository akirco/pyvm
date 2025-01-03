. $PSScriptRoot\..\lib\helper.ps1


if ($args.Length -eq 0 -or [string]::IsNullOrWhiteSpace($args[0])) {
    Write-Host "Usage: pyvm install <version>" -ForegroundColor Yellow
    exit 1
}

$version = Test-Version $args[0] -Install

$CONFIG = Get-Config

$installed_dir = $CONFIG | Select-Object -ExpandProperty Version_Dir | Join-Path -ChildPath $version

$caches_dir = $CONFIG | Select-Object -ExpandProperty Cache_Dir

$tmp_dir = $CONFIG | Select-Object -ExpandProperty Tmp_Dir

$download_mirror = $CONFIG | Select-Object -ExpandProperty Python_Mirror


@($caches_dir, $installed_dir, $tmp_dir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}



try {
    $python_installer = Get-InstallerName $version
    $Cached_Version_Path = Join-Path $caches_dir $python_installer
    $X64_Url = Repair-Url $download_mirror "$version/$python_installer"

    if (-not (Test-Path $Cached_Version_Path)) {
        Write-Host "Downloading Python version $version (64-bit)..." -NoNewline
        if (-not (Get-RemoteFile -Url $X64_Url -OutFile $Cached_Version_Path)) {
            throw "Failed to download Python $version"
        }
        Write-Host "ok" -ForegroundColor Green

        Write-Host "Verifying file signature..."
        if (-not (Test-Signature -FilePath $Cached_Version_Path -Version $version -DownloadMirror $download_mirror)) {
            Remove-Item $Cached_Version_Path -ErrorAction SilentlyContinue
            throw "File signature verification failed. The download may be corrupted or tampered with."
        }
    }
    else {
        Write-Host "Loading $(fname $Cached_Version_Path) from cache..."
        Write-Host "Verifying cached file signature..."
        if (-not (Test-Signature -FilePath $Cached_Version_Path -Version $version -DownloadMirror $download_mirror)) {
            Remove-Item $Cached_Version_Path -ErrorAction SilentlyContinue
            throw "Cached file signature verification failed. Please try installing again."
        }
    }

    if (-not (Test-Path $Cached_Version_Path)) {
        throw "Downloaded file not found at $Cached_Version_Path"
    }

    Write-Host "Extracting Python installer..." -NoNewline

    # check installer is .exe or .msi ,use switch
    $ext = (Get-Item $Cached_Version_Path).Extension
    switch ($ext) {
        ".exe" {
            Expand-DarkArchive $Cached_Version_Path $tmp_dir

            @('path.msi', 'pip.msi') | ForEach-Object {
                $msiPath = Join-Path $tmp_dir "AttachedContainer\$_"
                if (Test-Path $msiPath) {
                    Remove-Item $msiPath -Force
                }
            }

            # Write-Host "Installing Python components..."
            $msiFiles = Get-ChildItem (Join-Path $tmp_dir "AttachedContainer\*.msi")

            foreach ($msiFile in $msiFiles) {
                if ($msiFile.BaseName -eq 'appendpath') { continue }
                Expand-MsiArchive $msiFile.FullName $installed_dir
            }
        }
        ".msi" {
            Expand-MsiArchive $Cached_Version_Path $installed_dir
        }
        default {
            throw "Unsupported file extension: $ext"
        }
    }

    Write-Host "ok" -ForegroundColor Green
    Write-Host "Installing pip..." -NoNewline

    Get-Pip $version

    Write-Host "ok" -ForegroundColor Green

    Write-Host "Python $version has been successfully installed." -ForegroundColor Green
    Write-Host "If you want to use this version, type:" -ForegroundColor Green
    Write-Host ""
    Write-Host "  pyvm use $version" -ForegroundColor Green
}
catch {
    Write-Host "`nError during installation: $_" -ForegroundColor Red
    Write-Host "Please type 'pyvm list --remote' to fetch installable versions." -NoNewline

    if (Test-Path $installed_dir) {
        Remove-Item $installed_dir -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit 1
}
finally {
    if (Test-Path $tmp_dir) {
        Remove-Item $tmp_dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

