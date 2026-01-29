function ConvertTo-MermaidDiagram {
    <#
    .SYNOPSIS
        Generates a Mermaid diagram for a virtual server.
    
    .DESCRIPTION
        Creates a simple architecture diagram showing the flow from
        virtual server to pool to backend members.
    
    .PARAMETER VirtualServer
        The VirtualServer object to diagram.
    
    .EXAMPLE
        $vs | ConvertTo-MermaidDiagram
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$VirtualServer
    )
    
    process {
        $sb = [System.Text.StringBuilder]::new()
        
        # Start diagram
        $null = $sb.AppendLine("graph LR")
        
        # Client
        $null = $sb.AppendLine("    Client([Client]) -->|$($VirtualServer.Ip):$($VirtualServer.Port)| VS")
        
        # Virtual Server
        $vsLabel = "$($VirtualServer.Name)<br/>$($VirtualServer.Ip):$($VirtualServer.Port)"
        $null = $sb.AppendLine("    VS[$vsLabel]")
        
        # Pool
        if ($VirtualServer.LoadBalancePool) {
            $pool = $VirtualServer.LoadBalancePool
            $poolLabel = "$($pool.Name)<br/>Method: $($VirtualServer.LoadBalanceMethod)"
            $null = $sb.AppendLine("    VS --> Pool")
            $null = $sb.AppendLine("    Pool{$poolLabel}")
            
            # Members
            $memberCount = 0
            foreach ($member in $pool.Members) {
                $memberCount++
                $address = if ($member.RealServer) { $member.RealServer.Address } else { $member.RealServerName }
                $memberLabel = "$address<br/>:$($member.Port)<br/>Weight: $($member.Weight)"
                $memberNode = "Member$memberCount"
                
                $null = $sb.AppendLine("    Pool --> $memberNode")
                $null = $sb.AppendLine("    $memberNode[$memberLabel]")
                
                # Add styling for disabled members
                if ($member.Status -eq 'disable') {
                    $null = $sb.AppendLine("    style $memberNode fill:#ffcccc")
                }
            }
            
            # Add health check indicator
            if ($pool.HealthCheckCtrl -and $pool.HealthCheckList) {
                $null = $sb.AppendLine("    HC((Health Check<br/>$($pool.HealthCheckList -join ', '))) -.-> Pool")
                $null = $sb.AppendLine("    style HC fill:#ccffcc")
            }
        }
        else {
            # No pool configured
            $null = $sb.AppendLine("    VS --> NoPool[No Pool Configured]")
            $null = $sb.AppendLine("    style NoPool fill:#ffcccc")
        }
        
        # Add styling for disabled VS
        if ($VirtualServer.Status -eq 'disable') {
            $null = $sb.AppendLine("    style VS fill:#ffcccc")
        }
        else {
            $null = $sb.AppendLine("    style VS fill:#ccddff")
        }
        
        return $sb.ToString()
    }
}
