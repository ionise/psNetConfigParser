function ConvertTo-Yaml {
    <#
    .SYNOPSIS
        Converts a NetworkConfiguration object to YAML format.
    
    .DESCRIPTION
        Generates a clean YAML representation of the parsed configuration
        that can be used for declarative configuration management.
    
    .PARAMETER Config
        The NetworkConfiguration object to convert.
    
    .EXAMPLE
        $config | ConvertTo-Yaml | Out-File "config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Config
    )
    
    process {
        $sb = [System.Text.StringBuilder]::new()
        
        # Metadata
        $null = $sb.AppendLine("---")
        $null = $sb.AppendLine("metadata:")
        $null = $sb.AppendLine("  vendor: $($Config.Metadata['Vendor'])")
        $null = $sb.AppendLine("  parsed_at: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')")
        $null = $sb.AppendLine()
        
        # Virtual Servers
        $null = $sb.AppendLine("virtual_servers:")
        foreach ($vs in $Config.VirtualServers) {
            $null = $sb.AppendLine("  - name: $($vs.Name)")
            $null = $sb.AppendLine("    status: $($vs.Status)")
            $null = $sb.AppendLine("    type: $($vs.Type)")
            $null = $sb.AppendLine("    ip: $($vs.Ip)")
            $null = $sb.AppendLine("    port: $($vs.Port)")
            $null = $sb.AppendLine("    interface: $($vs.Interface)")
            
            if ($vs.LoadBalancePoolName) {
                $null = $sb.AppendLine("    pool: $($vs.LoadBalancePoolName)")
            }
            
            $null = $sb.AppendLine("    load_balance_method: $($vs.LoadBalanceMethod)")
            
            if ($vs.LoadBalancePersistence) {
                $null = $sb.AppendLine("    persistence: $($vs.LoadBalancePersistence)")
            }
            
            if ($vs.LoadBalanceProfile) {
                $null = $sb.AppendLine("    profile: $($vs.LoadBalanceProfile)")
            }
            
            if ($vs.ClientSslProfile) {
                $null = $sb.AppendLine("    ssl_profile: $($vs.ClientSslProfile)")
            }
            
            if ($vs.WafProfile) {
                $null = $sb.AppendLine("    waf_profile: $($vs.WafProfile)")
            }
            
            if ($vs.PublicIp -and $vs.PublicIp -ne '0.0.0.0') {
                $null = $sb.AppendLine("    public_ip: $($vs.PublicIp)")
            }
            
            $null = $sb.AppendLine("    traffic_log: $($vs.TrafficLog.ToString().ToLower())")
            $null = $sb.AppendLine("    connection_limit: $($vs.ConnectionLimit)")
        }
        $null = $sb.AppendLine()
        
        # Pools
        $null = $sb.AppendLine("pools:")
        foreach ($pool in $Config.Pools) {
            $null = $sb.AppendLine("  - name: $($pool.Name)")
            $null = $sb.AppendLine("    type: $($pool.Type)")
            $null = $sb.AppendLine("    health_check_enabled: $($pool.HealthCheckCtrl.ToString().ToLower())")
            $null = $sb.AppendLine("    health_check_action: $($pool.HealthCheckDownAction)")
            
            if ($pool.HealthCheckList) {
                $null = $sb.AppendLine("    health_checks:")
                foreach ($hc in $pool.HealthCheckList) {
                    $null = $sb.AppendLine("      - $hc")
                }
            }
            
            if ($pool.RealServerSslProfile -and $pool.RealServerSslProfile -ne 'NONE') {
                $null = $sb.AppendLine("    ssl_profile: $($pool.RealServerSslProfile)")
            }
            
            $null = $sb.AppendLine("    members:")
            foreach ($member in $pool.Members) {
                $realServerName = if ($member.RealServer) { $member.RealServer.Name } else { $member.RealServerName }
                $null = $sb.AppendLine("      - id: $($member.Id)")
                $null = $sb.AppendLine("        real_server: $realServerName")
                $null = $sb.AppendLine("        port: $($member.Port)")
                $null = $sb.AppendLine("        weight: $($member.Weight)")
                $null = $sb.AppendLine("        status: $($member.Status)")
                $null = $sb.AppendLine("        backup: $($member.Backup.ToString().ToLower())")
            }
        }
        $null = $sb.AppendLine()
        
        # Real Servers
        $null = $sb.AppendLine("real_servers:")
        foreach ($rs in $Config.RealServers) {
            $null = $sb.AppendLine("  - name: $($rs.Name)")
            $null = $sb.AppendLine("    address: $($rs.Address)")
            $null = $sb.AppendLine("    type: $($rs.Type)")
            $null = $sb.AppendLine("    status: $($rs.Status)")
        }
        $null = $sb.AppendLine()
        
        # Health Monitors
        $null = $sb.AppendLine("health_monitors:")
        foreach ($hc in $Config.HealthMonitors) {
            $null = $sb.AppendLine("  - name: $($hc.Name)")
            $null = $sb.AppendLine("    type: $($hc.Type)")
            $null = $sb.AppendLine("    interval: $($hc.Interval)")
            $null = $sb.AppendLine("    timeout: $($hc.Timeout)")
            $null = $sb.AppendLine("    retry: $($hc.Retry)")
            
            if ($hc.Port -gt 0) {
                $null = $sb.AppendLine("    port: $($hc.Port)")
            }
            
            if ($hc.SendString) {
                $null = $sb.AppendLine("    send_string: $($hc.SendString)")
            }
            
            if ($hc.StatusCode -gt 0) {
                $null = $sb.AppendLine("    expected_status: $($hc.StatusCode)")
            }
            
            if ($hc.Hostname) {
                $null = $sb.AppendLine("    hostname: $($hc.Hostname)")
            }
        }
        $null = $sb.AppendLine()
        
        # Certificates (optional, can be excluded for security)
        if ($Config.Certificates.Count -gt 0) {
            $null = $sb.AppendLine("certificates:")
            foreach ($cert in $Config.Certificates) {
                $null = $sb.AppendLine("  - name: $($cert.Name)")
                $null = $sb.AppendLine("    certificate_file: $($cert.CertificateFile)")
                $null = $sb.AppendLine("    private_key_file: $($cert.PrivateKeyFile)")
            }
        }
        
        return $sb.ToString()
    }
}
