function ConvertFrom-F5BigIPConfig {
    <#
    .SYNOPSIS
        Parses an F5 BigIP configuration file into a structured NetworkConfiguration object.
    
    .DESCRIPTION
        Reads an F5 BigIP configuration file (tmsh format) and extracts virtual servers, pools, 
        nodes (real servers), health monitors, and certificates into PowerShell class objects 
        for further processing.
    
    .PARAMETER Path
        Path to the F5 BigIP configuration file.
    
    .PARAMETER ConfigText
        Raw configuration text as a string (alternative to Path).
    
    .EXAMPLE
        $config = ConvertFrom-F5BigIPConfig -Path "C:\configs\bigip.conf"
    
    .EXAMPLE
        $config = Get-Content "bigip.conf" -Raw | ConvertFrom-F5BigIPConfig
    
    .EXAMPLE
        # Parse and export documentation
        $config = ConvertFrom-F5BigIPConfig -Path "bigip.conf"
        $config | Export-VirtualServerDocumentation -OutputDirectory "./docs"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path', Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,
        
        [Parameter(Mandatory, ParameterSetName = 'Text', ValueFromPipeline)]
        [string]$ConfigText
    )
    
    begin {
        # Helper function to skip a block without parsing (just count braces)
        function Skip-F5Block {
            param(
                [string[]]$Lines,
                [ref]$Index
            )
            
            $bracketDepth = 1  # We're already past the opening brace
            
            while ($Index.Value -lt $Lines.Count -and $bracketDepth -gt 0) {
                $line = $Lines[$Index.Value]
                $Index.Value++
                
                # Count opening and closing braces
                $bracketDepth += ($line | Select-String -Pattern '\{' -AllMatches).Matches.Count
                $bracketDepth -= ($line | Select-String -Pattern '\}' -AllMatches).Matches.Count
            }
        }
        
        # Helper to parse F5 configuration blocks for objects we care about
        function Parse-F5ObjectBlock {
            param(
                [string[]]$Lines,
                [ref]$Index
            )
            
            $block = @{}
            
            while ($Index.Value -lt $Lines.Count) {
                $line = $Lines[$Index.Value].Trim()
                $Index.Value++
                
                # Skip empty lines and comments
                if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
                    continue
                }
                
                # End of block
                if ($line -eq '}') {
                    break
                }
                
                # Handle nested blocks (like "members {" or "persist {")
                if ($line -match '^([^\s]+)\s*\{$') {
                    $key = $Matches[1]
                    $nestedBlock = Parse-F5ObjectBlock -Lines $Lines -Index $Index
                    $block[$key] = $nestedBlock
                    continue
                }
                
                # Handle key-value pairs
                if ($line -match '^([^\s]+)\s+(.+)$') {
                    $key = $Matches[1].Trim()
                    $value = $Matches[2].Trim()
                    
                    # Remove quotes if present
                    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                        $value = $value.Substring(1, $value.Length - 2)
                    }
                    
                    # Handle 'none' special value
                    if ($value -eq 'none') {
                        $value = $null
                    }
                    
                    $block[$key] = $value
                }
            }
            
            return $block
        }
        
        # Helper to extract partition and object name
        function Split-F5ObjectName {
            param([string]$FullName)
            
            if ($FullName -match '^/([^/]+)/(.+)$') {
                return @{
                    Partition = $Matches[1]
                    Name = $Matches[2]
                    FullName = $FullName
                }
            }
            else {
                return @{
                    Partition = 'Common'
                    Name = $FullName
                    FullName = $FullName
                }
            }
        }
        
        # Helper to convert string value to appropriate type
        function Convert-F5Value {
            param([string]$Value, [type]$TargetType)
            
            if ([string]::IsNullOrWhiteSpace($Value) -or $Value -in @('none', 'null')) {
                return $null
            }
            
            if ($TargetType -eq [bool]) {
                return $Value -in @('enabled', 'true', '1', 'yes')
            }
            elseif ($TargetType -eq [int]) {
                [int]$result = 0
                # Handle values like "1000" or "infinite"
                if ($Value -eq 'infinite' -or $Value -eq 'indefinite') {
                    return 0
                }
                if ([int]::TryParse($Value, [ref]$result)) {
                    return $result
                }
                return 0
            }
            elseif ($TargetType -eq [string[]]) {
                # Handle both space-separated and bracketed lists
                if ($Value -match '^\{(.+)\}$') {
                    $Value = $Matches[1]
                }
                return $Value -split '\s+' | Where-Object { $_ -ne '' }
            }
            else {
                return $Value
            }
        }
        
        # Helper to extract IP and port from destination
        function Parse-F5Destination {
            param([string]$Destination)
            
            $result = @{
                Address = $null
                Port = 0
                PortName = $null  # Store service name if provided
                IsIPv6 = $false
            }
            
            if ([string]::IsNullOrWhiteSpace($Destination)) {
                return $result
            }
            
            # Handle IPv6: /partition/2001:db8::1.80
            if ($Destination -match '^(/.+/)?([0-9a-fA-F:]+)\.(\d+|any)$') {
                $result.Address = $Matches[2]
                $result.Port = if ($Matches[3] -eq 'any') { 0 } else { [int]$Matches[3] }
                $result.IsIPv6 = $true
            }
            # Handle IPv4 with colon: /partition/192.168.1.100:80 or 192.168.1.100:80 or service name 192.168.1.100:imap
            elseif ($Destination -match '^(/.+/)?([0-9\.]+):(.+)$') {
                $result.Address = $Matches[2]
                $portPart = $Matches[3]
                if ($portPart -eq 'any') {
                    $result.Port = 0
                } elseif ($portPart -match '^\d+$') {
                    $result.Port = [int]$portPart
                } else {
                    # It's a service name like 'imap', 'https', 'tungsten-https'
                    # Keep it as-is without assuming port numbers
                    $result.PortName = $portPart
                    $result.Port = 0  # Indicate service name is provided
                }
                $result.IsIPv6 = $false
            }
            # Handle format with dot separator: 192.168.1.100.80
            elseif ($Destination -match '^(/.+/)?([0-9\.]+)\.(\d+|any)$') {
                $result.Address = $Matches[2]
                $result.Port = if ($Matches[3] -eq 'any') { 0 } else { [int]$Matches[3] }
                $result.IsIPv6 = $false
            }
            # Handle service names alone (just the service name): imap, https, etc.
            elseif ($Destination -match '^([a-zA-Z][\w-]*)$') {
                $result.PortName = $Destination
                $result.Port = 0
            }
            
            return $result
        }

    }
    
    process {
        # Load config text
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $ConfigText = Get-Content -Path $Path -Raw
        }
        
        # Create the network configuration object
        $config = [NetworkConfiguration]::new()
        
        # Split into lines
        $lines = $ConfigText -split "`r?`n"
        
        # Parse line by line
        $index = 0
        
        while ($index -lt $lines.Count) {
            $line = $lines[$index].Trim()
            $index++
            
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
                continue
            }
            
            # Detect and skip ltm rule (iRules)
            if ($line -match '^ltm\s+rule\s+(.+?)\s*\{$') {
                $ruleName = $Matches[1]
                Skip-F5Block -Lines $lines -Index ([ref]$index)
                Write-Verbose "Skipped iRule: $ruleName"
                continue
            }
            
            # Detect and skip ltm profile (we don't need profiles for documentation)
            if ($line -match '^ltm\s+profile\s+\S+\s+(.+?)\s*\{$') {
                $profileName = $Matches[1]
                Skip-F5Block -Lines $lines -Index ([ref]$index)
                Write-Verbose "Skipped profile: $profileName"
                continue
            }
            
            # Detect ltm node
            if ($line -match '^ltm\s+node\s+(.+?)\s*\{$') {
                $nodeName = $Matches[1].Trim()
                $nodeBlock = Parse-F5ObjectBlock -Lines $lines -Index ([ref]$index)
                
                $rs = [RealServer]::new()
                $nameInfo = Split-F5ObjectName -FullName $nodeName
                $rs.Name = $nameInfo.Name
                $rs.Address = Convert-F5Value $nodeBlock['address'] ([string])
                $rs.Status = if ($nodeBlock.ContainsKey('session')) { 
                    Convert-F5Value $nodeBlock['session'] ([string]) 
                } else { 
                    'user-enabled' 
                }
                $rs.Type = 'static'
                $rs.ServerType = 'node'
                
                # Detect IPv6
                if ($rs.Address -and $rs.Address -match ':') {
                    $rs.Ipv6Address = $rs.Address
                    $rs.Address = $null
                }
                
                $config.RealServers.Add($rs)
                Write-Verbose "Parsed node: $($rs.Name)"
                continue
            }
            
            # Detect ltm monitor
            if ($line -match '^ltm\s+monitor\s+(\S+)\s+(.+?)\s*\{$') {
                $monitorType = $Matches[1].Trim()
                $monitorName = $Matches[2].Trim()
                $monitorBlock = Parse-F5ObjectBlock -Lines $lines -Index ([ref]$index)
                
                $hc = [HealthMonitor]::new()
                $nameInfo = Split-F5ObjectName -FullName $monitorName
                $hc.Name = $nameInfo.Name
                $hc.Type = $monitorType
                
                # Parse common monitor properties
                $hc.Interval = Convert-F5Value $monitorBlock['interval'] ([int])
                $hc.Timeout = Convert-F5Value $monitorBlock['timeout'] ([int])
                $hc.UpRetry = Convert-F5Value $monitorBlock['up-interval'] ([int])
                
                # Destination (IP:port)
                if ($monitorBlock.ContainsKey('destination')) {
                    $dest = Parse-F5Destination -Destination $monitorBlock['destination']
                    $hc.DestAddr = $dest.Address
                    $hc.Port = $dest.Port
                }
                
                # HTTP/HTTPS specific
                if ($monitorType -in @('http', 'https')) {
                    $hc.SendString = Convert-F5Value $monitorBlock['send'] ([string])
                    $hc.Hostname = Convert-F5Value $monitorBlock['hostname'] ([string])
                    
                    # Extract receive string (expected response)
                    if ($monitorBlock.ContainsKey('recv')) {
                        $recv = Convert-F5Value $monitorBlock['recv'] ([string])
                        $hc.StatusCode = if ($recv -match '\d{3}') { [int]$Matches[0] } else { 200 }
                    }
                }
                
                # TCP specific
                if ($monitorType -eq 'tcp') {
                    $hc.SendString = Convert-F5Value $monitorBlock['send'] ([string])
                }
                
                $config.HealthMonitors.Add($hc)
                Write-Verbose "Parsed monitor: $($hc.Name) (type: $monitorType)"
                continue
            }
            
            # Detect ltm pool
            if ($line -match '^ltm\s+pool\s+(.+?)\s*\{$') {
                $poolName = $Matches[1].Trim()
                $poolBlock = Parse-F5ObjectBlock -Lines $lines -Index ([ref]$index)
                
                $pool = [Pool]::new()
                $nameInfo = Split-F5ObjectName -FullName $poolName
                $pool.Name = $nameInfo.Name
                $pool.Type = 'static'
                
                # Health monitor
                if ($poolBlock.ContainsKey('monitor')) {
                    $monitorStr = Convert-F5Value $poolBlock['monitor'] ([string])
                    # Parse monitor references (can be "monitor1 and monitor2" or just "monitor1")
                    $monitors = $monitorStr -split '\s+and\s+|\s+or\s+' | ForEach-Object {
                        $m = $_.Trim()
                        if ($m -match '/([^/]+)$') {
                            $Matches[1]
                        } else {
                            $m
                        }
                    } | Where-Object { $_ -and $_ -ne '' }
                    $pool.HealthCheckList = $monitors
                    $pool.HealthCheckRelation = if ($monitorStr -match '\s+and\s+') { 'AND' } else { 'OR' }
                }
                
                # Parse pool members
                if ($poolBlock.ContainsKey('members') -and $poolBlock['members'] -is [hashtable]) {
                    $memberIndex = 1
                    foreach ($memberKey in $poolBlock['members'].Keys) {
                        $memberData = $poolBlock['members'][$memberKey]
                        
                        $member = [PoolMember]::new()
                        $member.Id = $memberIndex++
                        
                        # Parse member name and address
                        # Format can be:
                        # - /partition/node:port (node reference)
                        # - node:port (node reference)
                        # - IP:service-name (direct IP with service name)
                        # - IP:port-number (direct IP with port)
                        
                        if ($memberKey -match '^(.+?):(.+)$') {
                            $addressPart = $Matches[1]
                            $portPart = $Matches[2]
                            
                            # Try to parse as node reference
                            if ($addressPart -match '/([^/]+)$') {
                                $member.RealServerName = $Matches[1]
                            } else {
                                $member.RealServerName = $addressPart
                            }
                            
                            # Parse port part - could be numeric or service name
                            if ($portPart -match '^\d+$') {
                                $member.Port = [int]$portPart
                                $member.ServiceName = $null
                            } else {
                                # Service name like 'imap', 'https', 'http', 'tungsten-https'
                                $member.ServiceName = $portPart
                                $member.Port = 0  # Indicate service name is used
                            }
                        }
                        
                        # Member properties - get address from member data if not from key
                        if ($memberData -is [hashtable]) {
                            $member.Status = Convert-F5Value $memberData['session'] ([string])
                            
                            # If we have address in the member data, use that
                            if ($memberData.ContainsKey('address')) {
                                $addressFromData = Convert-F5Value $memberData['address'] ([string])
                                # Only override if we don't have a server name yet
                                if ([string]::IsNullOrWhiteSpace($member.RealServerName) -or $member.RealServerName -match '^[0-9\.]+$') {
                                    $member.RealServerName = $addressFromData
                                }
                            }
                            
                            if ($memberData.ContainsKey('ratio')) {
                                $member.Weight = Convert-F5Value $memberData['ratio'] ([int])
                            }
                            
                            if ($memberData.ContainsKey('connection-limit')) {
                                $member.ConnectionLimit = Convert-F5Value $memberData['connection-limit'] ([int])
                            }
                            
                            if ($memberData.ContainsKey('priority-group')) {
                                $member.Backup = (Convert-F5Value $memberData['priority-group'] ([int])) -gt 0
                            }
                        }
                        
                        $pool.Members.Add($member)
                    }
                }
                
                $config.Pools.Add($pool)
                Write-Verbose "Parsed pool: $($pool.Name) with $($pool.Members.Count) members"
                continue
            }
            
            # Detect ltm virtual
            if ($line -match '^ltm\s+virtual\s+(.+?)\s*\{$') {
                $vsName = $Matches[1].Trim()
                $vsBlock = Parse-F5ObjectBlock -Lines $lines -Index ([ref]$index)
                
                $vs = [VirtualServer]::new()
                $nameInfo = Split-F5ObjectName -FullName $vsName
                $vs.Name = $nameInfo.Name
                
                # Destination (VIP:port)
                if ($vsBlock.ContainsKey('destination')) {
                    $dest = Parse-F5Destination -Destination $vsBlock['destination']
                    $vs.Ip = $dest.Address
                    $vs.Port = $dest.Port
                    $vs.ServiceName = $dest.PortName
                    $vs.AddrType = if ($dest.IsIPv6) { 'ipv6' } else { 'ipv4' }
                }
                
                # Pool reference
                if ($vsBlock.ContainsKey('pool')) {
                    $poolRef = Convert-F5Value $vsBlock['pool'] ([string])
                    if ($poolRef -match '/([^/]+)$') {
                        $vs.LoadBalancePoolName = $Matches[1]
                    } else {
                        $vs.LoadBalancePoolName = $poolRef
                    }
                }
                
                # Status
                $vs.Status = if ($vsBlock.ContainsKey('disabled')) { 'disable' } else { 'enable' }
                
                # Type - determine from profiles or defaults
                $vs.Type = 'l4-load-balance'
                if ($vsBlock.ContainsKey('profiles') -and $vsBlock['profiles'] -is [hashtable]) {
                    foreach ($profileName in $vsBlock['profiles'].Keys) {
                        if ($profileName -match 'http') {
                            $vs.Type = 'l7-load-balance'
                            break
                        }
                    }
                }
                
                # SSL Profiles
                if ($vsBlock.ContainsKey('profiles') -and $vsBlock['profiles'] -is [hashtable]) {
                    $sslProfiles = $vsBlock['profiles'].Keys | Where-Object { $_ -match 'clientssl|ssl' }
                    if ($sslProfiles) {
                        $vs.ClientSslProfile = ($sslProfiles -join ', ')
                    }
                }
                
                # Persistence
                if ($vsBlock.ContainsKey('persist') -and $vsBlock['persist'] -is [hashtable]) {
                    $persistTypes = $vsBlock['persist'].Keys -join ', '
                    $vs.LoadBalancePersistence = $persistTypes
                }
                
                # Connection limit
                if ($vsBlock.ContainsKey('connection-limit')) {
                    $vs.ConnectionLimit = Convert-F5Value $vsBlock['connection-limit'] ([int])
                }
                
                # Description/Comments
                if ($vsBlock.ContainsKey('description')) {
                    $vs.Comments = Convert-F5Value $vsBlock['description'] ([string])
                }
                
                $config.VirtualServers.Add($vs)
                Write-Verbose "Parsed virtual server: $($vs.Name) ($($vs.Ip):$($vs.Port))"
                continue
            }
            
            # Detect sys file ssl-cert (certificates)
            if ($line -match '^sys\s+file\s+ssl-cert\s+(.+?)\s*\{$') {
                $certName = $Matches[1].Trim()
                $certBlock = Parse-F5ObjectBlock -Lines $lines -Index ([ref]$index)
                
                $cert = [Certificate]::new()
                $nameInfo = Split-F5ObjectName -FullName $certName
                $cert.Name = $nameInfo.Name
                $cert.CertificateFile = Convert-F5Value $certBlock['source-path'] ([string])
                
                if ($certBlock.ContainsKey('subject-alternative-name')) {
                    $cert.Comments = "SAN: " + (Convert-F5Value $certBlock['subject-alternative-name'] ([string]))
                }
                
                $config.Certificates.Add($cert)
                Write-Verbose "Parsed certificate: $($cert.Name)"
                continue
            }
            
            # Detect sys file ssl-key (private keys)
            if ($line -match '^sys\s+file\s+ssl-key\s+(.+?)\s*\{$') {
                $keyName = $Matches[1].Trim()
                $keyBlock = Parse-F5ObjectBlock -Lines $lines -Index ([ref]$index)
                
                # Try to find matching certificate
                $nameInfo = Split-F5ObjectName -FullName $keyName
                $matchingCert = $config.Certificates | Where-Object { $_.Name -eq $nameInfo.Name } | Select-Object -First 1
                
                if ($matchingCert) {
                    $matchingCert.PrivateKeyFile = Convert-F5Value $keyBlock['source-path'] ([string])
                }
                else {
                    # Create a new certificate entry for the key
                    $cert = [Certificate]::new()
                    $cert.Name = $nameInfo.Name
                    $cert.PrivateKeyFile = Convert-F5Value $keyBlock['source-path'] ([string])
                    $config.Certificates.Add($cert)
                }
                continue
            }
            
            # Skip anything else we don't explicitly handle
            if ($line -match '^\w+\s+.+?\s*\{$') {
                Skip-F5Block -Lines $lines -Index ([ref]$index)
                Write-Verbose "Skipped unhandled block: $($line.Substring(0, [Math]::Min(40, $line.Length)))"
            }
        }
        
        # Resolve all object references
        $config.ResolveReferences()
        
        # Add metadata
        $config.Metadata['ParsedAt'] = Get-Date
        $config.Metadata['Vendor'] = 'F5 BigIP'
        
        Write-Verbose "Parsed F5 BigIP configuration: $($config.VirtualServers.Count) virtual servers, $($config.Pools.Count) pools, $($config.RealServers.Count) nodes, $($config.HealthMonitors.Count) monitors"
        
        return $config
    }
}
