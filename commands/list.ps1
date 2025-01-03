. $PSScriptRoot\..\lib\helper.ps1

$option = $args[0]
function Get-Remote {
    param(
        [switch]$Refresh
    )

    $Python_Mirror = Get-Config | Select-Object -ExpandProperty Python_Mirror
    $cache_dir = Get-Config | Select-Object -ExpandProperty Cache_Dir

    if (-not (Test-Path $cache_dir)) {
        New-Item $cache_dir -ItemType Directory -Force | Out-Null
    }

    $cacheFile = Join-Path $cache_dir "versions.json"
    $cacheExpiry = 24 * 14 # 缓存有效期（小时）

    # 如果指定了 Refresh 参数，删除现有缓存
    if ($Refresh -and (Test-Path $cacheFile)) {
        Remove-Item $cacheFile
    }

    # 检查缓存是否存在且有效
    if (Test-Path $cacheFile) {
        $cache = Get-Content $cacheFile | ConvertFrom-Json
        $currentTime = [int][double]::Parse((Get-Date -UFormat %s))
        $cacheAge = ($currentTime - $cache.timestamp) / 3600  # 转换为小时

        if ($cacheAge -lt $cacheExpiry) {
            $versions = $cache.versions
            Write-Host "Using cached versions." -ForegroundColor DarkBlue
        }
    }

    if (-not $versions) {

        Write-Host "Fetching remote versions..." -ForegroundColor DarkBlue

        #ban the progress bar
        $ProgressPreference = "SilentlyContinue"
        $response = Invoke-WebRequest -Uri $Python_Mirror -UseBasicParsing
        $allVersions = [regex]::Matches($response.Content, '<a href="(\d+\.\d+\.\d+)/"') |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -match '^\d+\.\d+\.\d+$' }

        # 过滤掉没有 Windows 安装程序的版本
        $versions = @()
        foreach ($version in $allVersions) {
            $versionUrl = Repair-Url -BaseUrl $Python_Mirror -RelativeUrl "$version/"
            try {
                $versionResponse = Invoke-WebRequest -Uri $versionUrl -UseBasicParsing
                $majorVersion = [version]$version | Select-Object -ExpandProperty Major
                if ($majorVersion -eq 2) {
                    if ($versionResponse.Content -match "python-$version\.amd64\.msi") {
                        $versions += @{
                            version = $version
                            installerType = "msi"
                        }
                    }
                }
                else {
                    if ($versionResponse.Content -match "python-$version-amd64\.exe") {
                        $versions += @{
                            version = $version
                            installerType = "exe"
                        }
                    }
                }
            }
            catch {
                continue
            }
        }

        # 保存到缓存，使用 Unix 时间戳
        $cache = @{
            timestamp = [int][double]::Parse((Get-Date -UFormat %s))
            versions  = $versions
        }
        $cache | ConvertTo-Json | Set-Content $cacheFile
    }

    $groupedVersions = $versions | Sort-Object -Property { [version]$_.version } -Descending |
    Group-Object { $_.version.Split('.')[0] }

    foreach ($group in $groupedVersions) {
        Write-Host "Version $($group.Name).x:" -ForegroundColor Cyan

        $table = @()
        $row = @()
        $count = 0

        foreach ($versionInfo in $group.Group) {
            $row += "| $($versionInfo.version.PadRight(7))"
            $count++

            if ($count -eq 6) {
                $table += , $row
                $row = @()
                $count = 0
            }
        }

        if ($row.Count -gt 0) {
            while ($row.Count -lt 6) {
                $row += "|        "
            }
            $table += , $row
        }

        foreach ($row in $table) {
            $output = ($row -join "") + "|"
            Write-Host $output.TrimEnd()
        }
        Write-Host ""
    }
}

function Get-Local {
    $installed_versions = Get-InstalledPython
    $current_version = Get-CurrentPython | Select-Object -ExpandProperty Version
    if ($installed_versions.Count -eq 0) {
        Write-Host "No Python versions installed." -ForegroundColor Yellow
        return
    }
    Write-Host "Installed versions:" -ForegroundColor Cyan
    foreach ($installs in $installed_versions) {
        if ($installs.Version -eq $current_version) {
            Write-Host "  * $($installs.Version)" -ForegroundColor Green
        }
        else {
            Write-Host "    $($installs.Version)" -ForegroundColor Green
        }
    }
}

switch ($option) {
    "--remote" {
        Get-Remote
    }
    "--remote-refresh" {
        Get-Remote -Refresh
    }
    "--local" {
        Get-Local
    }
    Default {
        Get-Local
    }
}


