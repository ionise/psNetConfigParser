# Example: Export Individual Virtual Server Documentation

# Import the module
Import-Module ./psNetConfigParser -Force

# Parse the FortiADC configuration
Write-Host "Parsing FortiADC configuration..." -ForegroundColor Cyan
$config = ConvertFrom-FortiADCConfig -Path "./configparser/fadc_config.conf"

# Alternatively, parse an F5 Big-IP configuration
Write-Host "Parsing F5 Big-IP configuration..." -ForegroundColor Cyan

$config = ConvertFrom-F5BigIPConfig -Path "./configparser/f5_bigip_config.conf"


# Display summary
Write-Host "`nConfiguration Summary:" -ForegroundColor Green
Write-Host "  Virtual Servers: $($config.VirtualServers.Count)"
Write-Host "  Pools: $($config.Pools.Count)"
Write-Host "  Real Servers: $($config.RealServers.Count)"
Write-Host "  Health Monitors: $($config.HealthMonitors.Count)"
Write-Host "  Certificates: $($config.Certificates.Count)"

# Export individual documentation files
Write-Host "`nExporting individual virtual server documentation..." -ForegroundColor Cyan
$config | Export-VirtualServerDocumentation -OutputDirectory "./vs-docs" -IncludeDiagrams

Write-Host "`nDone! Open ./vs-docs/index.md to start browsing." -ForegroundColor Green
