function ConvertTo-Markdown {
    <#
    .SYNOPSIS
        Converts a NetworkConfiguration object to Markdown documentation.
    
    .DESCRIPTION
        Generates human-readable as-built documentation from parsed configuration,
        including virtual servers, pools, health checks, and optionally Mermaid diagrams.
    
    .PARAMETER Config
        The NetworkConfiguration object to convert.
    
    .PARAMETER IncludeDiagrams
        Include Mermaid diagrams for each virtual server.
    
    .EXAMPLE
        $config | ConvertTo-Markdown
    
    .EXAMPLE
        ConvertTo-Markdown -Config $config -IncludeDiagrams | Out-File "documentation.md"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Config,
        
        [switch]$IncludeDiagrams
    )
    
    process {
        $sb = [System.Text.StringBuilder]::new()
        
        # Title
        $null = $sb.AppendLine("# Load Balancer Configuration Documentation")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $null = $sb.AppendLine("**Vendor:** $($Config.Metadata['Vendor'])")
        $null = $sb.AppendLine()
        
        # Summary
        $null = $sb.AppendLine("## Summary")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("| Resource Type | Count |")
        $null = $sb.AppendLine("|--------------|-------|")
        $null = $sb.AppendLine("| Virtual Servers | $($Config.VirtualServers.Count) |")
        $null = $sb.AppendLine("| Pools | $($Config.Pools.Count) |")
        $null = $sb.AppendLine("| Real Servers | $($Config.RealServers.Count) |")
        $null = $sb.AppendLine("| Health Monitors | $($Config.HealthMonitors.Count) |")
        $null = $sb.AppendLine("| Certificates | $($Config.Certificates.Count) |")
        $null = $sb.AppendLine()
        
        # Virtual Servers
        $null = $sb.AppendLine("## Virtual Servers")
        $null = $sb.AppendLine()
        
        foreach ($vs in $Config.VirtualServers | Sort-Object Name) {
            $null = $sb.AppendLine("### $($vs.Name)")
            $null = $sb.AppendLine()
            
            # Basic info
            $null = $sb.AppendLine("**Listener Configuration:**")
            $null = $sb.AppendLine("- **Status:** $($vs.Status)")
            $null = $sb.AppendLine("- **Type:** $($vs.Type)")
            $null = $sb.AppendLine("- **IP Address:** ``$($vs.Ip)``")
            $null = $sb.AppendLine("- **Port:** $($vs.Port)")
            $null = $sb.AppendLine("- **Interface:** $($vs.Interface)")
            
            if ($vs.PublicIp -and $vs.PublicIp -ne '0.0.0.0') {
                $null = $sb.AppendLine("- **Public IP:** ``$($vs.PublicIp)``")
            }
            
            $null = $sb.AppendLine()
            
            # Load balancing
            $null = $sb.AppendLine("**Load Balancing:**")
            $null = $sb.AppendLine("- **Method:** $($vs.LoadBalanceMethod)")
            $null = $sb.AppendLine("- **Pool:** $($vs.LoadBalancePoolName)")
            
            if ($vs.LoadBalancePersistence) {
                $null = $sb.AppendLine("- **Persistence:** $($vs.LoadBalancePersistence)")
            }
            
            if ($vs.LoadBalanceProfile) {
                $null = $sb.AppendLine("- **Profile:** $($vs.LoadBalanceProfile)")
            }
            
            $null = $sb.AppendLine()
            
            # Security & Advanced
            if ($vs.ClientSslProfile -or $vs.WafProfile -or $vs.DosProfile) {
                $null = $sb.AppendLine("**Security:**")
                if ($vs.ClientSslProfile) {
                    $null = $sb.AppendLine("- **SSL Profile:** $($vs.ClientSslProfile)")
                }
                if ($vs.WafProfile) {
                    $null = $sb.AppendLine("- **WAF Profile:** $($vs.WafProfile)")
                }
                if ($vs.DosProfile) {
                    $null = $sb.AppendLine("- **DoS Profile:** $($vs.DosProfile)")
                }
                $null = $sb.AppendLine()
            }
            
            # Pool details
            if ($vs.LoadBalancePool) {
                $pool = $vs.LoadBalancePool
                $null = $sb.AppendLine("**Backend Pool ($($pool.Name)):**")
                $null = $sb.AppendLine("- **Type:** $($pool.Type)")
                $null = $sb.AppendLine("- **Health Check:** $($pool.HealthCheckCtrl)")
                
                if ($pool.HealthCheckList) {
                    $null = $sb.AppendLine("- **Health Monitors:** $($pool.HealthCheckList -join ', ')")
                }
                
                $null = $sb.AppendLine("- **Members:** $($pool.Members.Count)")
                $null = $sb.AppendLine()
                
                # Pool members table
                $null = $sb.AppendLine("| Member | Address | Port | Weight | Status |")
                $null = $sb.AppendLine("|--------|---------|------|--------|--------|")
                
                foreach ($member in $pool.Members) {
                    $address = if ($member.RealServer) { $member.RealServer.Address } else { $member.RealServerName }
                    $null = $sb.AppendLine("| $($member.Id) | ``$address`` | $($member.Port) | $($member.Weight) | $($member.Status) |")
                }
                
                $null = $sb.AppendLine()
            }
            
            # Mermaid diagram
            if ($IncludeDiagrams) {
                $null = $sb.AppendLine("**Architecture Diagram:**")
                $null = $sb.AppendLine()
                $null = $sb.AppendLine('```mermaid')
                $null = $sb.Append((ConvertTo-MermaidDiagram -VirtualServer $vs))
                $null = $sb.AppendLine('```')
                $null = $sb.AppendLine()
            }
            
            $null = $sb.AppendLine("---")
            $null = $sb.AppendLine()
        }
        
        # Health Monitors
        if ($Config.HealthMonitors.Count -gt 0) {
            $null = $sb.AppendLine("## Health Monitors")
            $null = $sb.AppendLine()
            $null = $sb.AppendLine("| Name | Type | Interval | Timeout | Retry | Port |")
            $null = $sb.AppendLine("|------|------|----------|---------|-------|------|")
            
            foreach ($hc in $Config.HealthMonitors | Sort-Object Name) {
                $null = $sb.AppendLine("| $($hc.Name) | $($hc.Type) | $($hc.Interval)s | $($hc.Timeout)s | $($hc.Retry) | $($hc.Port) |")
            }
            
            $null = $sb.AppendLine()
        }
        
        # Real Servers
        if ($Config.RealServers.Count -gt 0) {
            $null = $sb.AppendLine("## Real Servers")
            $null = $sb.AppendLine()
            $null = $sb.AppendLine("| Name | Address | Type | Status |")
            $null = $sb.AppendLine("|------|---------|------|--------|")
            
            foreach ($rs in $Config.RealServers | Sort-Object Name) {
                $null = $sb.AppendLine("| $($rs.Name) | ``$($rs.Address)`` | $($rs.Type) | $($rs.Status) |")
            }
            
            $null = $sb.AppendLine()
        }
        
        # Certificates
        if ($Config.Certificates.Count -gt 0) {
            $null = $sb.AppendLine("## SSL Certificates")
            $null = $sb.AppendLine()
            $null = $sb.AppendLine("| Name | Certificate File | Private Key File |")
            $null = $sb.AppendLine("|------|------------------|------------------|")
            
            foreach ($cert in $Config.Certificates | Sort-Object Name) {
                $null = $sb.AppendLine("| $($cert.Name) | $($cert.CertificateFile) | $($cert.PrivateKeyFile) |")
            }
            
            $null = $sb.AppendLine()
        }
        
        return $sb.ToString()
    }
}
