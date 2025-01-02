. $PSScriptRoot\..\lib\helper.ps1

$option = $args[0]

function Get-Remote {
    $Python_Mirror = Get-Config | Select-Object -ExpandProperty Python_Mirror

    #ban the progress bar
    $ProgressPreference = "SilentlyContinue"
    $response = Invoke-WebRequest -Uri $Python_Mirror -UseBasicParsing
    $versions = [regex]::Matches($response.Content, '<a href="(\d+\.\d+\.\d+)/"') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -match '^\d+\.\d+\.\d+$' } | Sort-Object -Property { [version]$_ } -Descending

    $groupedVersions = $versions | Group-Object { $_.Split('.')[0] }

    foreach ($group in $groupedVersions) {
        Write-Host "$($group.Name).x:" -ForegroundColor Cyan

        $table = @()
        $row = @()
        $count = 0

        foreach ($version in $group.Group) {
            $row += "| $($version.PadRight(7))"
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
    "--local" {
        Get-Local
    }
    Default {
        Get-Local
    }
}


