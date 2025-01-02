$mirror_url = $args[0]

if ($null -eq $args[0] -or $args[0] -eq "") {
  $mirror_url = [Environment]::GetEnvironmentVariable("Python_Mirror", "User")
  Write-Host "Current Python Mirror URL: $mirror_url"
}
else {
  if ($mirror_url -match "^(http|https)://.*") {
    $mirror_url | Out-Null

    $ProgressPreference = "SilentlyContinue"
    $reachable = Invoke-WebRequest -Uri $mirror_url -UseBasicParsing -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue

    if ($reachable.StatusCode -eq 200) {
      # Aadd the mirror url to the environment variable
      [Environment]::SetEnvironmentVariable("Python_Mirror", $mirror_url, "User")
      Write-Host "Python Mirror URL set to $mirror_url"
      Write-Host "To use the mirror URL, please restart the terminal"
    }
    else {
      Write-Host "Please check the Python Mirror URL is reachable"
    }
  }
  else {
    Write-Host "Invalid URL format"
    Write-Host "Usage: pyvm mirror <URL>"
    exit
  }
}






