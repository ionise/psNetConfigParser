# Quick Start Example for psNetConfigParser

# Import the module
Import-Module ./psNetConfigParser -Force

# Parse the FortiADC configuration
Write-Host "Parsing FortiADC configuration..." -ForegroundColor Cyan
$config = ConvertFrom-FortiADCConfig -Path "../configparser/fadc_config.conf"

# Display summary
Write-Host "`nConfiguration Summary:" -ForegroundColor Green
Write-Host "  Virtual Servers: $($config.VirtualServers.Count)"
Write-Host "  Pools: $($config.Pools.Count)"
Write-Host "  Real Servers: $($config.RealServers.Count)"
Write-Host "  Health Monitors: $($config.HealthMonitors.Count)"
Write-Host "  Certificates: $($config.Certificates.Count)"

# Show first virtual server
if ($config.VirtualServers.Count -gt 0) {
    Write-Host "`nFirst Virtual Server:" -ForegroundColor Yellow
    $vs = $config.VirtualServers[0]
    Write-Host "  Name: $($vs.Name)"
    Write-Host "  IP: $($vs.Ip):$($vs.Port)"
    Write-Host "  Status: $($vs.Status)"
    Write-Host "  Type: $($vs.Type)"
    Write-Host "  Pool: $($vs.LoadBalancePoolName)"
    
    if ($vs.LoadBalancePool) {
        Write-Host "  Pool Members: $($vs.LoadBalancePool.Members.Count)"
    }
}

# Generate outputs
Write-Host "`nGenerating outputs..." -ForegroundColor Cyan

# Markdown documentation
Write-Host "  - Markdown documentation (with diagrams)..."
$config | ConvertTo-Markdown -IncludeDiagrams | Out-File "output-documentation.md" -Encoding UTF8
Write-Host "    Saved to: output-documentation.md" -ForegroundColor Gray

# YAML configuration
Write-Host "  - YAML configuration..."
$config | ConvertTo-Yaml | Out-File "output-config.yaml" -Encoding UTF8
Write-Host "    Saved to: output-config.yaml" -ForegroundColor Gray

# Example diagram for first VS
if ($config.VirtualServers.Count -gt 0) {
    Write-Host "  - Mermaid diagram for first VS..."
    $config.VirtualServers[0] | ConvertTo-MermaidDiagram | Out-File "output-diagram.mmd" -Encoding UTF8
    Write-Host "    Saved to: output-diagram.mmd" -ForegroundColor Gray
}

Write-Host "`nDone! Check the output files in the current directory." -ForegroundColor Green
Write-Host "`nTip: To view Mermaid diagrams, paste the content into https://mermaid.live" -ForegroundColor Yellow
