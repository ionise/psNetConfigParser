function ConvertFrom-YamlToF5BigIPCli {
    <#
    .SYNOPSIS
        Converts a YAML configuration to F5 BigIP tmsh CLI commands.
    
    .DESCRIPTION
        Reads a YAML file (previously generated from ConvertTo-Yaml) and
        generates F5 BigIP tmsh commands that can be applied to recreate
        the configuration.
    
    .PARAMETER Path
        Path to the YAML configuration file.
    
    .PARAMETER YamlText
        YAML configuration as a string.
    
    .PARAMETER Config
        A NetworkConfiguration object directly (bypasses YAML parsing).
    
    .PARAMETER Partition
        The partition name to use in the commands. Defaults to "Common".
    
    .EXAMPLE
        ConvertFrom-YamlToF5BigIPCli -Path "config.yaml"
    
    .EXAMPLE
        $config | ConvertFrom-YamlToF5BigIPCli -Partition "Production"
    
    .EXAMPLE
        # Parse F5 config and generate tmsh commands
        $config = ConvertFrom-F5BigIPConfig -Path "bigip.conf"
        $config | ConvertFrom-YamlToF5BigIPCli | Out-File "rebuild-config.txt"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Config')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path', Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,
        
        [Parameter(Mandatory, ParameterSetName = 'Text', ValueFromPipeline)]
        [string]$YamlText,
        
        [Parameter(Mandatory, ParameterSetName = 'Config', ValueFromPipeline)]
        [object]$Config,
        
        [Parameter()]
        [string]$Partition = "Common"
    )
    
    begin {
        # Helper to format port/service for tmsh commands
        function Format-PortSpec {
            param(
                [int]$Port,
                [string]$ServiceName
            )
            
            if ($ServiceName) {
                return $ServiceName
            }
            elseif ($Port -gt 0) {
                return $Port.ToString()
            }
            else {
                return "any"
            }
        }
        
        # Helper to escape strings for tmsh
        function Format-TmshString {
            param([string]$Value)
            
            if ([string]::IsNullOrEmpty($Value)) {
                return '""'
            }
            
            # If contains spaces or special chars, quote it
            if ($Value -match '[\s\{\}\[\]"'']') {
                return "`"$($Value.Replace('"', '\"'))`""
            }
            
            return $Value
        }
        
        # Helper to format node name from IP
        function Format-NodeName {
            param([string]$Address)
            
            # Replace dots with underscores for node naming
            return "node_$($Address.Replace('.', '_'))"
        }
    }
    
    process {
        $sb = [System.Text.StringBuilder]::new()
        
        # Determine the configuration source
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            # Try to load YAML - requires powershell-yaml module
            if (Get-Module -ListAvailable -Name 'powershell-yaml') {
                Import-Module powershell-yaml
                $YamlText = Get-Content -Path $Path -Raw
                $data = ConvertFrom-Yaml $YamlText
            }
            else {
                Write-Warning "YAML parsing requires powershell-yaml module. Install with: Install-Module powershell-yaml"
                Write-Warning "Alternatively, pass a NetworkConfiguration object directly via pipeline."
                return
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Text') {
            if (Get-Module -ListAvailable -Name 'powershell-yaml') {
                Import-Module powershell-yaml
                $data = ConvertFrom-Yaml $YamlText
            }
            else {
                Write-Warning "YAML parsing requires powershell-yaml module. Install with: Install-Module powershell-yaml"
                return
            }
        }
        else {
            # Direct Config object - most efficient path
            $data = $null
        }
        
        # Header
        $null = $sb.AppendLine("#!/bin/bash")
        $null = $sb.AppendLine("# F5 BigIP tmsh Configuration Script")
        $null = $sb.AppendLine("# Generated at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $null = $sb.AppendLine("# Partition: $Partition")
        $null = $sb.AppendLine("#")
        $null = $sb.AppendLine("# IMPORTANT: Review and test in a non-production environment before applying!")
        $null = $sb.AppendLine()
        
        # If we have a direct Config object, use it
        if ($Config) {
            # =====================
            # Health Monitors
            # =====================
            if ($Config.HealthMonitors.Count -gt 0) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Health Monitors")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($monitor in $Config.HealthMonitors) {
                    $monitorType = switch -Regex ($monitor.Type) {
                        'http'  { 'http' }
                        'https' { 'https' }
                        'tcp'   { 'tcp' }
                        'udp'   { 'udp' }
                        'icmp'  { 'gateway_icmp' }
                        'ping'  { 'gateway_icmp' }
                        default { 'tcp' }
                    }
                    
                    $null = $sb.AppendLine("# Monitor: $($monitor.Name)")
                    $null = $sb.Append("tmsh create ltm monitor $monitorType /$Partition/$($monitor.Name)")
                    
                    if ($monitor.Interval -gt 0) {
                        $null = $sb.Append(" interval $($monitor.Interval)")
                    }
                    
                    if ($monitor.Timeout -gt 0) {
                        $null = $sb.Append(" timeout $($monitor.Timeout)")
                    }
                    
                    if ($monitor.SendString) {
                        $null = $sb.Append(" send $(Format-TmshString $monitor.SendString)")
                    }
                    
                    if ($monitor.ReceiveString) {
                        $null = $sb.Append(" recv $(Format-TmshString $monitor.ReceiveString)")
                    }
                    
                    $null = $sb.AppendLine()
                }
                $null = $sb.AppendLine()
            }
            
            # =====================
            # Nodes (Real Servers)
            # =====================
            if ($Config.RealServers.Count -gt 0) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Nodes (Real Servers)")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($server in $Config.RealServers) {
                    $nodeName = $server.Name
                    
                    $null = $sb.AppendLine("# Node: $nodeName ($($server.Address))")
                    $null = $sb.Append("tmsh create ltm node /$Partition/$nodeName address $($server.Address)")
                    
                    if ($server.Status -eq 'disable' -or $server.Status -eq 'disabled') {
                        $null = $sb.Append(" state user-down")
                    }
                    
                    $null = $sb.AppendLine()
                }
                $null = $sb.AppendLine()
            }
            
            # =====================
            # Pools
            # =====================
            if ($Config.Pools.Count -gt 0) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Pools")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($pool in $Config.Pools) {
                    $null = $sb.AppendLine("# Pool: $($pool.Name)")
                    $null = $sb.Append("tmsh create ltm pool /$Partition/$($pool.Name)")
                    
                    # Load balancing method
                    $lbMethod = switch ($pool.LoadBalanceMethod) {
                        'round-robin'       { 'round-robin' }
                        'least-connections' { 'least-connections-member' }
                        'ratio'             { 'ratio-member' }
                        'fastest'           { 'fastest-node' }
                        'observed'          { 'observed-member' }
                        'predictive'        { 'predictive-member' }
                        default             { 'round-robin' }
                    }
                    $null = $sb.Append(" load-balancing-mode $lbMethod")
                    
                    # Health monitors
                    if ($pool.HealthCheckList -and $pool.HealthCheckList.Count -gt 0) {
                        $monitors = ($pool.HealthCheckList | ForEach-Object { "/$Partition/$_" }) -join ' and '
                        $null = $sb.Append(" monitor `"$monitors`"")
                    }
                    
                    # Members
                    if ($pool.Members -and $pool.Members.Count -gt 0) {
                        $null = $sb.Append(" members add {")
                        
                        foreach ($member in $pool.Members) {
                            $serverName = if ($member.RealServer) { $member.RealServer.Name } else { $member.RealServerName }
                            $portSpec = Format-PortSpec -Port $member.Port -ServiceName $member.ServiceName
                            
                            $null = $sb.Append(" /$Partition/${serverName}:${portSpec}")
                            
                            # Add member properties if needed
                            if ($member.Weight -and $member.Weight -gt 1) {
                                $null = $sb.Append(" { ratio $($member.Weight) }")
                            }
                        }
                        
                        $null = $sb.Append(" }")
                    }
                    
                    $null = $sb.AppendLine()
                }
                $null = $sb.AppendLine()
            }
            
            # =====================
            # SSL Profiles (if certificates exist)
            # =====================
            if ($Config.Certificates.Count -gt 0) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# SSL Profiles")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Note: Certificates must be imported separately before creating profiles")
                $null = $sb.AppendLine()
                
                foreach ($cert in $Config.Certificates) {
                    $null = $sb.AppendLine("# SSL Profile for certificate: $($cert.Name)")
                    $null = $sb.AppendLine("# tmsh create ltm profile client-ssl /$Partition/ssl_$($cert.Name) cert /$Partition/$($cert.Name).crt key /$Partition/$($cert.Name).key")
                }
                $null = $sb.AppendLine()
            }
            
            # =====================
            # Virtual Servers
            # =====================
            if ($Config.VirtualServers.Count -gt 0) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Virtual Servers")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($vs in $Config.VirtualServers) {
                    $portSpec = Format-PortSpec -Port $vs.Port -ServiceName $vs.ServiceName
                    
                    $null = $sb.AppendLine("# Virtual Server: $($vs.Name)")
                    $null = $sb.AppendLine("# Destination: $($vs.Ip):$portSpec")
                    $null = $sb.Append("tmsh create ltm virtual /$Partition/$($vs.Name)")
                    $null = $sb.Append(" destination /$Partition/$($vs.Ip):$portSpec")
                    
                    # IP Protocol
                    if ($vs.Protocol) {
                        $null = $sb.Append(" ip-protocol $($vs.Protocol.ToLower())")
                    }
                    else {
                        $null = $sb.Append(" ip-protocol tcp")
                    }
                    
                    # Pool
                    if ($vs.LoadBalancePoolName) {
                        $null = $sb.Append(" pool /$Partition/$($vs.LoadBalancePoolName)")
                    }
                    
                    # Source Address Translation (SNAT)
                    if ($vs.SourceAddressTranslation -and $vs.SourceAddressTranslation -ne 'none') {
                        $null = $sb.Append(" source-address-translation { type $($vs.SourceAddressTranslation) }")
                    }
                    else {
                        $null = $sb.Append(" source-address-translation { type automap }")
                    }
                    
                    # Profiles
                    $profiles = @()
                    
                    # HTTP profile
                    if ($vs.Type -match 'http|l7' -or $vs.LoadBalanceProfile -match 'http') {
                        $profiles += "/$Partition/http"
                    }
                    
                    # SSL profile
                    if ($vs.ClientSslProfile) {
                        $profiles += "/$Partition/$($vs.ClientSslProfile) { context clientside }"
                    }
                    
                    if ($profiles.Count -gt 0) {
                        $null = $sb.Append(" profiles add { $($profiles -join ' ') }")
                    }
                    
                    # Persistence
                    if ($vs.LoadBalancePersistence -and $vs.LoadBalancePersistence -ne 'none') {
                        $persistProfile = switch -Regex ($vs.LoadBalancePersistence) {
                            'source.?ip|source.?addr' { 'source_addr' }
                            'cookie'                   { 'cookie' }
                            'ssl'                      { 'ssl' }
                            'dest.?addr'               { 'dest_addr' }
                            default                    { $vs.LoadBalancePersistence }
                        }
                        $null = $sb.Append(" persist replace-all-with { /$Partition/$persistProfile }")
                    }
                    
                    # Connection limit
                    if ($vs.ConnectionLimit -gt 0) {
                        $null = $sb.Append(" connection-limit $($vs.ConnectionLimit)")
                    }
                    
                    # Status
                    if ($vs.Status -eq 'disable' -or $vs.Status -eq 'disabled') {
                        $null = $sb.Append(" disabled")
                    }
                    else {
                        $null = $sb.Append(" enabled")
                    }
                    
                    $null = $sb.AppendLine()
                }
            }
            
            # =====================
            # Save Configuration
            # =====================
            $null = $sb.AppendLine()
            $null = $sb.AppendLine("#" + "=" * 70)
            $null = $sb.AppendLine("# Save Configuration")
            $null = $sb.AppendLine("#" + "=" * 70)
            $null = $sb.AppendLine("tmsh save sys config")
        }
        elseif ($data) {
            # YAML-parsed data structure
            $null = $sb.AppendLine("# Configuration from YAML")
            $null = $sb.AppendLine()
            
            # Health Monitors from YAML
            if ($data.health_monitors) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Health Monitors")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($monitor in $data.health_monitors) {
                    $monitorType = switch -Regex ($monitor.type) {
                        'http'  { 'http' }
                        'https' { 'https' }
                        'tcp'   { 'tcp' }
                        'udp'   { 'udp' }
                        'icmp'  { 'gateway_icmp' }
                        default { 'tcp' }
                    }
                    
                    $null = $sb.Append("tmsh create ltm monitor $monitorType /$Partition/$($monitor.name)")
                    
                    if ($monitor.interval) {
                        $null = $sb.Append(" interval $($monitor.interval)")
                    }
                    
                    if ($monitor.timeout) {
                        $null = $sb.Append(" timeout $($monitor.timeout)")
                    }
                    
                    if ($monitor.send_string) {
                        $null = $sb.Append(" send $(Format-TmshString $monitor.send_string)")
                    }
                    
                    $null = $sb.AppendLine()
                }
                $null = $sb.AppendLine()
            }
            
            # Nodes from YAML
            if ($data.real_servers) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Nodes (Real Servers)")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($server in $data.real_servers) {
                    $null = $sb.Append("tmsh create ltm node /$Partition/$($server.name) address $($server.address)")
                    
                    if ($server.status -eq 'disable' -or $server.status -eq 'disabled') {
                        $null = $sb.Append(" state user-down")
                    }
                    
                    $null = $sb.AppendLine()
                }
                $null = $sb.AppendLine()
            }
            
            # Pools from YAML
            if ($data.pools) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Pools")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($pool in $data.pools) {
                    $null = $sb.Append("tmsh create ltm pool /$Partition/$($pool.name) load-balancing-mode round-robin")
                    
                    if ($pool.health_checks) {
                        $monitors = ($pool.health_checks | ForEach-Object { "/$Partition/$_" }) -join ' and '
                        $null = $sb.Append(" monitor `"$monitors`"")
                    }
                    
                    if ($pool.members) {
                        $null = $sb.Append(" members add {")
                        foreach ($member in $pool.members) {
                            $null = $sb.Append(" /$Partition/$($member.real_server):$($member.port)")
                        }
                        $null = $sb.Append(" }")
                    }
                    
                    $null = $sb.AppendLine()
                }
                $null = $sb.AppendLine()
            }
            
            # Virtual Servers from YAML
            if ($data.virtual_servers) {
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine("# Virtual Servers")
                $null = $sb.AppendLine("#" + "=" * 70)
                $null = $sb.AppendLine()
                
                foreach ($vs in $data.virtual_servers) {
                    $null = $sb.Append("tmsh create ltm virtual /$Partition/$($vs.name)")
                    $null = $sb.Append(" destination /$Partition/$($vs.ip):$($vs.port)")
                    $null = $sb.Append(" ip-protocol tcp")
                    
                    if ($vs.pool) {
                        $null = $sb.Append(" pool /$Partition/$($vs.pool)")
                    }
                    
                    $null = $sb.Append(" source-address-translation { type automap }")
                    
                    if ($vs.status -eq 'disable' -or $vs.status -eq 'disabled') {
                        $null = $sb.Append(" disabled")
                    }
                    else {
                        $null = $sb.Append(" enabled")
                    }
                    
                    $null = $sb.AppendLine()
                }
            }
            
            # Save
            $null = $sb.AppendLine()
            $null = $sb.AppendLine("# Save Configuration")
            $null = $sb.AppendLine("tmsh save sys config")
        }
        
        return $sb.ToString()
    }
}
