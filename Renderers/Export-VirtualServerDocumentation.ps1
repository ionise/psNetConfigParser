function Export-VirtualServerDocumentation {
    <#
    .SYNOPSIS
        Exports individual documentation files for each virtual server with a table of contents.
    
    .DESCRIPTION
        Creates separate Markdown files for each virtual server along with an index page
        that serves as a table of contents. Each virtual server document includes a 
        YAML code block for configuration reproduction.
    
    .PARAMETER Config
        The NetworkConfiguration object to export.
    
    .PARAMETER OutputDirectory
        Directory where the documentation files will be created. Defaults to current directory.
    
    .PARAMETER IncludeDiagrams
        Include Mermaid diagrams in each virtual server document.
    
    .EXAMPLE
        $config | Export-VirtualServerDocumentation -OutputDirectory "./docs"
    
    .EXAMPLE
        Export-VirtualServerDocumentation -Config $config -OutputDirectory "./docs" -IncludeDiagrams
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Config,
        
        [Parameter()]
        [string]$OutputDirectory = ".",
        
        [switch]$IncludeDiagrams
    )
    
    process {
        # Create output directory if it doesn't exist
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        }
        
        # Generate index file
        Write-Verbose "Generating table of contents..."
        $indexPath = Join-Path $OutputDirectory "index.md"
        $indexContent = Generate-IndexPage -Config $Config
        $indexContent | Out-File -FilePath $indexPath -Encoding UTF8
        Write-Host "Created: $indexPath" -ForegroundColor Green
        
        # Generate individual VS documents
        foreach ($vs in $Config.VirtualServers | Sort-Object Name) {
            Write-Verbose "Generating documentation for $($vs.Name)..."
            
            # Sanitize filename
            $filename = $vs.Name -replace '[^\w\-]', '_'
            $filename = "vs_$filename.md"
            $filePath = Join-Path $OutputDirectory $filename
            
            # Generate content
            $content = Generate-VirtualServerPage -VirtualServer $vs -Config $Config -IncludeDiagrams:$IncludeDiagrams
            $content | Out-File -FilePath $filePath -Encoding UTF8
            
            Write-Host "Created: $filePath" -ForegroundColor Gray
        }
        
        Write-Host "`nDocumentation exported successfully to: $OutputDirectory" -ForegroundColor Green
        Write-Host "Open $indexPath to start browsing." -ForegroundColor Yellow
    }
}

# Helper function to get port display (either port number or service name)
function Get-PortDisplay {
    param(
        [int]$Port,
        [string]$ServiceName
    )
    
    if ($ServiceName) {
        return $ServiceName
    }
    if ($Port -gt 0) {
        return $Port.ToString()
    }
    return "0"
}

function Generate-IndexPage {
    param([object]$Config)
    
    # Helper to get port display
    $getPortDisplay = {
        param($Port, $ServiceName)
        if ($ServiceName) { $ServiceName } elseif ($Port -gt 0) { $Port } else { "0" }
    }
    
    $sb = [System.Text.StringBuilder]::new()
    
    # Header
    $null = $sb.AppendLine("# Load Balancer Configuration - Table of Contents")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $null = $sb.AppendLine("**Vendor:** $($Config.Metadata['Vendor'])")
    $null = $sb.AppendLine()
    
    # Summary
    $null = $sb.AppendLine("## Configuration Summary")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("| Resource Type | Count |")
    $null = $sb.AppendLine("|--------------|-------|")
    $null = $sb.AppendLine("| Virtual Servers | $($Config.VirtualServers.Count) |")
    $null = $sb.AppendLine("| Pools | $($Config.Pools.Count) |")
    $null = $sb.AppendLine("| Real Servers | $($Config.RealServers.Count) |")
    $null = $sb.AppendLine("| Health Monitors | $($Config.HealthMonitors.Count) |")
    $null = $sb.AppendLine("| Certificates | $($Config.Certificates.Count) |")
    $null = $sb.AppendLine()
    
    # Virtual Servers list
    $null = $sb.AppendLine("## Virtual Servers")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("Click on a virtual server to view detailed configuration:")
    $null = $sb.AppendLine()
    
    # Group by status
    $enabledVS = $Config.VirtualServers | Where-Object { $_.Status -eq 'enable' } | Sort-Object Name
    $disabledVS = $Config.VirtualServers | Where-Object { $_.Status -eq 'disable' } | Sort-Object Name
    
    if ($enabledVS) {
        $null = $sb.AppendLine("### Enabled Virtual Servers")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("| Virtual Server | IP Address | Port | Type | Pool |")
        $null = $sb.AppendLine("|----------------|------------|------|------|------|")
        
        foreach ($vs in $enabledVS) {
            $filename = $vs.Name -replace '[^\w\-]', '_'
            $filename = "vs_$filename.md"
            $poolName = if ($vs.LoadBalancePoolName) { $vs.LoadBalancePoolName } else { "-" }
            $portDisplay = & $getPortDisplay -Port $vs.Port -ServiceName $vs.ServiceName
            $null = $sb.AppendLine("| [$($vs.Name)]($filename) | ``$($vs.Ip)`` | $portDisplay | $($vs.Type) | $poolName |")
        }
        $null = $sb.AppendLine()
    }
    
    if ($disabledVS) {
        $null = $sb.AppendLine("### Disabled Virtual Servers")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("| Virtual Server | IP Address | Port | Type | Pool |")
        $null = $sb.AppendLine("|----------------|------------|------|------|------|")
        
        foreach ($vs in $disabledVS) {
            $filename = $vs.Name -replace '[^\w\-]', '_'
            $filename = "vs_$filename.md"
            $poolName = if ($vs.LoadBalancePoolName) { $vs.LoadBalancePoolName } else { "-" }
            $portDisplay = & $getPortDisplay -Port $vs.Port -ServiceName $vs.ServiceName
            $null = $sb.AppendLine("| [$($vs.Name)]($filename) | ``$($vs.Ip)`` | $portDisplay | $($vs.Type) | $poolName |")
        }
        $null = $sb.AppendLine()
    }
    
    # Quick reference sections
    $null = $sb.AppendLine("## Quick Reference")
    $null = $sb.AppendLine()
    
    # Health Monitors
    if ($Config.HealthMonitors.Count -gt 0) {
        $null = $sb.AppendLine("### Health Monitors")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("| Name | Type | Interval | Timeout | Port |")
        $null = $sb.AppendLine("|------|------|----------|---------|------|")
        
        foreach ($hc in $Config.HealthMonitors | Sort-Object Name) {
            $null = $sb.AppendLine("| $($hc.Name) | $($hc.Type) | $($hc.Interval)s | $($hc.Timeout)s | $($hc.Port) |")
        }
        $null = $sb.AppendLine()
    }
    
    # Pools summary
    if ($Config.Pools.Count -gt 0) {
        $null = $sb.AppendLine("### Pools")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("| Pool Name | Members | Health Check |")
        $null = $sb.AppendLine("|-----------|---------|--------------|")
        
        foreach ($pool in $Config.Pools | Sort-Object Name) {
            $hcList = if ($pool.HealthCheckList) { $pool.HealthCheckList -join ', ' } else { "-" }
            $null = $sb.AppendLine("| $($pool.Name) | $($pool.Members.Count) | $hcList |")
        }
        $null = $sb.AppendLine()
    }
    
    return $sb.ToString()
}

function Generate-VirtualServerPage {
    param(
        [object]$VirtualServer,
        [object]$Config,
        [switch]$IncludeDiagrams
    )
    
    # Helper to get port display
    $getPortDisplay = {
        param($Port, $ServiceName)
        if ($ServiceName) { $ServiceName } elseif ($Port -gt 0) { $Port } else { "0" }
    }
    
    $sb = [System.Text.StringBuilder]::new()
    
    # Header with breadcrumb
    $null = $sb.AppendLine("# Virtual Server: $($VirtualServer.Name)")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("[← Back to Index](index.md)")
    $null = $sb.AppendLine()
    
    # Status badge
    $statusEmoji = if ($VirtualServer.Status -eq 'enable') { "✅" } else { "⚠️" }
    $null = $sb.AppendLine("**Status:** $statusEmoji $($VirtualServer.Status.ToUpper())")
    $null = $sb.AppendLine()
    
    # Overview
    $null = $sb.AppendLine("## Overview")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("| Property | Value |")
    $null = $sb.AppendLine("|----------|-------|")
    $null = $sb.AppendLine("| **Name** | $($VirtualServer.Name) |")
    $null = $sb.AppendLine("| **Type** | $($VirtualServer.Type) |")
    $null = $sb.AppendLine("| **IP Address** | ``$($VirtualServer.Ip)`` |")
    $portDisplay = & $getPortDisplay -Port $VirtualServer.Port -ServiceName $VirtualServer.ServiceName
    $null = $sb.AppendLine("| **Port** | $portDisplay |")
    $null = $sb.AppendLine("| **Interface** | $($VirtualServer.Interface) |")
    
    if ($VirtualServer.PublicIp -and $VirtualServer.PublicIp -ne '0.0.0.0') {
        $null = $sb.AppendLine("| **Public IP** | ``$($VirtualServer.PublicIp)`` |")
    }
    
    $null = $sb.AppendLine("| **Load Balance Method** | $($VirtualServer.LoadBalanceMethod) |")
    
    if ($VirtualServer.LoadBalancePersistence) {
        $null = $sb.AppendLine("| **Persistence** | $($VirtualServer.LoadBalancePersistence) |")
    }
    
    $null = $sb.AppendLine("| **Traffic Log** | $($VirtualServer.TrafficLog) |")
    $null = $sb.AppendLine("| **Connection Limit** | $($VirtualServer.ConnectionLimit) |")
    $null = $sb.AppendLine()
    
    # Profiles & Security
    $null = $sb.AppendLine("## Profiles & Security")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("| Type | Profile |")
    $null = $sb.AppendLine("|------|---------|")
    
    if ($VirtualServer.LoadBalanceProfile) {
        $null = $sb.AppendLine("| Load Balance Profile | $($VirtualServer.LoadBalanceProfile) |")
    }
    if ($VirtualServer.ClientSslProfile) {
        $null = $sb.AppendLine("| Client SSL Profile | $($VirtualServer.ClientSslProfile) |")
    }
    if ($VirtualServer.WafProfile) {
        $null = $sb.AppendLine("| WAF Profile | $($VirtualServer.WafProfile) |")
    }
    if ($VirtualServer.DosProfile) {
        $null = $sb.AppendLine("| DoS Profile | $($VirtualServer.DosProfile) |")
    }
    if ($VirtualServer.AvProfile) {
        $null = $sb.AppendLine("| AV Profile | $($VirtualServer.AvProfile) |")
    }
    
    if (-not ($VirtualServer.LoadBalanceProfile -or $VirtualServer.ClientSslProfile -or $VirtualServer.WafProfile -or $VirtualServer.DosProfile -or $VirtualServer.AvProfile)) {
        $null = $sb.AppendLine("| - | *No additional profiles configured* |")
    }
    
    $null = $sb.AppendLine()
    
    # Backend Pool
    if ($VirtualServer.LoadBalancePool) {
        $pool = $VirtualServer.LoadBalancePool
        
        $null = $sb.AppendLine("## Backend Pool: $($pool.Name)")
        $null = $sb.AppendLine()
        
        # Pool info
        $null = $sb.AppendLine("**Configuration:**")
        $null = $sb.AppendLine("- Type: $($pool.Type)")
        $null = $sb.AppendLine("- Health Check Enabled: $($pool.HealthCheckCtrl)")
        
        if ($pool.HealthCheckList) {
            $null = $sb.AppendLine("- Health Monitors: $($pool.HealthCheckList -join ', ')")
            $null = $sb.AppendLine("- Health Check Relation: $($pool.HealthCheckRelation)")
        }
        
        if ($pool.RealServerSslProfile -and $pool.RealServerSslProfile -ne 'NONE') {
            $null = $sb.AppendLine("- SSL Profile (to backends): $($pool.RealServerSslProfile)")
        }
        
        $null = $sb.AppendLine()
        
        # Pool members
        $null = $sb.AppendLine("### Pool Members")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("| ID | Server | Address | Port | Weight | Status | Backup |")
        $null = $sb.AppendLine("|----|--------|---------|------|--------|--------|--------|")
        
        foreach ($member in $pool.Members) {
            $serverName = if ($member.RealServer) { $member.RealServer.Name } else { $member.RealServerName }
            $address = if ($member.RealServer) { $member.RealServer.Address } else { "-" }
            $statusIcon = if ($member.Status -eq 'enable') { "✅" } else { "⚠️" }
            $backupIcon = if ($member.Backup) { "🔄" } else { "-" }
            $memberPortDisplay = & $getPortDisplay -Port $member.Port -ServiceName $member.ServiceName
            
            $null = $sb.AppendLine("| $($member.Id) | $serverName | ``$address`` | $memberPortDisplay | $($member.Weight) | $statusIcon $($member.Status) | $backupIcon |")
        }
        
        $null = $sb.AppendLine()
        
        # Health check details
        if ($pool.HealthChecks -and $pool.HealthChecks.Count -gt 0) {
            $null = $sb.AppendLine("### Health Check Details")
            $null = $sb.AppendLine()
            
            foreach ($hc in $pool.HealthChecks) {
                $null = $sb.AppendLine("#### $($hc.Name)")
                $null = $sb.AppendLine()
                $null = $sb.AppendLine("| Property | Value |")
                $null = $sb.AppendLine("|----------|-------|")
                $null = $sb.AppendLine("| Type | $($hc.Type) |")
                $null = $sb.AppendLine("| Interval | $($hc.Interval)s |")
                $null = $sb.AppendLine("| Timeout | $($hc.Timeout)s |")
                $null = $sb.AppendLine("| Retry | $($hc.Retry) |")
                
                if ($hc.Port -gt 0) {
                    $null = $sb.AppendLine("| Port | $($hc.Port) |")
                }
                
                if ($hc.SendString) {
                    $null = $sb.AppendLine("| Send String | ``$($hc.SendString)`` |")
                }
                
                if ($hc.StatusCode -gt 0) {
                    $null = $sb.AppendLine("| Expected Status Code | $($hc.StatusCode) |")
                }
                
                if ($hc.Hostname) {
                    $null = $sb.AppendLine("| Hostname | $($hc.Hostname) |")
                }
                
                $null = $sb.AppendLine()
            }
        }
    }
    else {
        $null = $sb.AppendLine("## Backend Pool")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine("⚠️ **No pool configured for this virtual server**")
        $null = $sb.AppendLine()
    }
    
    # Mermaid Diagram
    if ($IncludeDiagrams) {
        $null = $sb.AppendLine("## Architecture Diagram")
        $null = $sb.AppendLine()
        $null = $sb.AppendLine('```mermaid')
        $null = $sb.Append((ConvertTo-MermaidDiagram -VirtualServer $VirtualServer))
        $null = $sb.AppendLine('```')
        $null = $sb.AppendLine()
    }
    
    # YAML Configuration
    $null = $sb.AppendLine("## YAML Configuration")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("Use this YAML to recreate this virtual server configuration:")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine('```yaml')
    $null = $sb.Append((Convert-VirtualServerToYaml -VirtualServer $VirtualServer -Config $Config))
    $null = $sb.AppendLine('```')
    $null = $sb.AppendLine()
    
    # Footer
    $null = $sb.AppendLine("---")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("[← Back to Index](index.md)")
    
    return $sb.ToString()
}

function Convert-VirtualServerToYaml {
    param(
        [object]$VirtualServer,
        [object]$Config
    )
    
    # Helper to get port display
    $getPortDisplay = {
        param($Port, $ServiceName)
        if ($ServiceName) { $ServiceName } elseif ($Port -gt 0) { $Port } else { "0" }
    }
    
    $sb = [System.Text.StringBuilder]::new()
    
    # Virtual Server
    $null = $sb.AppendLine("virtual_server:")
    $null = $sb.AppendLine("  name: $($VirtualServer.Name)")
    $null = $sb.AppendLine("  status: $($VirtualServer.Status)")
    $null = $sb.AppendLine("  type: $($VirtualServer.Type)")
    $null = $sb.AppendLine("  ip: $($VirtualServer.Ip)")
    $vsPort = & $getPortDisplay -Port $VirtualServer.Port -ServiceName $VirtualServer.ServiceName
    $null = $sb.AppendLine("  port: $vsPort")
    $null = $sb.AppendLine("  interface: $($VirtualServer.Interface)")
    
    if ($VirtualServer.PublicIp -and $VirtualServer.PublicIp -ne '0.0.0.0') {
        $null = $sb.AppendLine("  public_ip: $($VirtualServer.PublicIp)")
    }
    
    $null = $sb.AppendLine("  load_balance_method: $($VirtualServer.LoadBalanceMethod)")
    
    if ($VirtualServer.LoadBalancePersistence) {
        $null = $sb.AppendLine("  persistence: $($VirtualServer.LoadBalancePersistence)")
    }
    
    if ($VirtualServer.LoadBalancePoolName) {
        $null = $sb.AppendLine("  pool: $($VirtualServer.LoadBalancePoolName)")
    }
    
    if ($VirtualServer.LoadBalanceProfile) {
        $null = $sb.AppendLine("  profile: $($VirtualServer.LoadBalanceProfile)")
    }
    
    if ($VirtualServer.ClientSslProfile) {
        $null = $sb.AppendLine("  ssl_profile: $($VirtualServer.ClientSslProfile)")
    }
    
    if ($VirtualServer.WafProfile) {
        $null = $sb.AppendLine("  waf_profile: $($VirtualServer.WafProfile)")
    }
    
    $null = $sb.AppendLine("  traffic_log: $($VirtualServer.TrafficLog.ToString().ToLower())")
    $null = $sb.AppendLine("  connection_limit: $($VirtualServer.ConnectionLimit)")
    $null = $sb.AppendLine()
    
    # Pool (if exists)
    if ($VirtualServer.LoadBalancePool) {
        $pool = $VirtualServer.LoadBalancePool
        
        $null = $sb.AppendLine("pool:")
        $null = $sb.AppendLine("  name: $($pool.Name)")
        $null = $sb.AppendLine("  type: $($pool.Type)")
        $null = $sb.AppendLine("  health_check_enabled: $($pool.HealthCheckCtrl.ToString().ToLower())")
        
        if ($pool.HealthCheckList) {
            $null = $sb.AppendLine("  health_checks:")
            foreach ($hc in $pool.HealthCheckList) {
                $null = $sb.AppendLine("    - $hc")
            }
        }
        
        if ($pool.RealServerSslProfile -and $pool.RealServerSslProfile -ne 'NONE') {
            $null = $sb.AppendLine("  ssl_profile: $($pool.RealServerSslProfile)")
        }
        
        $null = $sb.AppendLine("  members:")
        foreach ($member in $pool.Members) {
            $realServerName = if ($member.RealServer) { $member.RealServer.Name } else { $member.RealServerName }
            $memberPort = & $getPortDisplay -Port $member.Port -ServiceName $member.ServiceName
            $null = $sb.AppendLine("    - id: $($member.Id)")
            $null = $sb.AppendLine("      real_server: $realServerName")
            $null = $sb.AppendLine("      port: $memberPort")
            $null = $sb.AppendLine("      weight: $($member.Weight)")
            $null = $sb.AppendLine("      status: $($member.Status)")
            $null = $sb.AppendLine("      backup: $($member.Backup.ToString().ToLower())")
        }
        $null = $sb.AppendLine()
        
        # Real servers for this pool
        $null = $sb.AppendLine("real_servers:")
        foreach ($member in $pool.Members | Where-Object { $_.RealServer }) {
            $rs = $member.RealServer
            $null = $sb.AppendLine("  - name: $($rs.Name)")
            $null = $sb.AppendLine("    address: $($rs.Address)")
            $null = $sb.AppendLine("    type: $($rs.Type)")
            $null = $sb.AppendLine("    status: $($rs.Status)")
        }
        $null = $sb.AppendLine()
        
        # Health monitors for this pool
        if ($pool.HealthChecks -and $pool.HealthChecks.Count -gt 0) {
            $null = $sb.AppendLine("health_monitors:")
            foreach ($hc in $pool.HealthChecks) {
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
            }
        }
    }
    
    return $sb.ToString()
}
