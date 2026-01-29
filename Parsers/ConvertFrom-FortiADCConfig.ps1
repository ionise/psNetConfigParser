function ConvertFrom-FortiADCConfig {
    <#
    .SYNOPSIS
        Parses a FortiADC configuration file into a structured NetworkConfiguration object.
    
    .DESCRIPTION
        Reads a FortiADC configuration file and extracts virtual servers, pools, real servers,
        health checks, and certificates into PowerShell class objects for further processing.
    
    .PARAMETER Path
        Path to the FortiADC configuration file.
    
    .PARAMETER ConfigText
        Raw configuration text as a string (alternative to Path).
    
    .EXAMPLE
        $config = ConvertFrom-FortiADCConfig -Path "C:\configs\fortiadc.conf"
    
    .EXAMPLE
        $config = Get-Content "fortiadc.conf" -Raw | ConvertFrom-FortiADCConfig
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
        # Helper function to parse a config block
        function Parse-ConfigBlock {
            param(
                [string[]]$Lines,
                [ref]$Index
            )
            
            $block = @{}
            $currentKey = $null
            $nestedBlocks = @{}
            
            while ($Index.Value -lt $Lines.Count) {
                $line = $Lines[$Index.Value].Trim()
                $Index.Value++
                
                # Skip empty lines and comments
                if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
                    continue
                }
                
                # End of block
                if ($line -eq 'end' -or $line -eq 'next') {
                    break
                }
                
                # Nested config block
                if ($line -match '^config\s+(.+)$') {
                    $nestedKey = $Matches[1].Trim()
                    $nestedBlocks[$nestedKey] = Parse-ConfigBlock -Lines $Lines -Index $Index
                    continue
                }
                
                # Edit statement (starts a new item in a collection)
                if ($line -match '^edit\s+"?([^"]+)"?$') {
                    $editName = $Matches[1].Trim('"')
                    if (-not $block.ContainsKey('_items')) {
                        $block['_items'] = @()
                    }
                    $itemBlock = Parse-ConfigBlock -Lines $Lines -Index $Index
                    $itemBlock['_name'] = $editName
                    $block['_items'] += $itemBlock
                    continue
                }
                
                # Set statement
                if ($line -match '^set\s+(\S+)\s+(.+)$') {
                    $key = $Matches[1]
                    $value = $Matches[2].Trim()
                    $block[$key] = $value
                    continue
                }
                
                # Unset statement
                if ($line -match '^unset\s+(\S+)$') {
                    $key = $Matches[1]
                    $block[$key] = $null
                    continue
                }
            }
            
            # Add nested blocks to the result
            foreach ($key in $nestedBlocks.Keys) {
                $block[$key] = $nestedBlocks[$key]
            }
            
            return $block
        }
        
        # Helper to convert string value to appropriate type
        function Convert-Value {
            param([string]$Value, [type]$TargetType)
            
            if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq 'null') {
                return $null
            }
            
            # Remove quotes
            $Value = $Value.Trim('"')
            
            if ($TargetType -eq [bool]) {
                return $Value -in @('enable', 'true', '1', 'yes')
            }
            elseif ($TargetType -eq [int]) {
                [int]$result = 0
                if ([int]::TryParse($Value, [ref]$result)) {
                    return $result
                }
                return 0
            }
            elseif ($TargetType -eq [string[]]) {
                return $Value -split '\s+'
            }
            else {
                return $Value
            }
        }
    }
    
    process {
        # Load config text
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $ConfigText = Get-Content -Path $Path -Raw
        }
        
        # Split into lines
        $lines = $ConfigText -split "`r?`n"
        
        # Parse the entire config
        $index = 0
        $parsedConfig = Parse-ConfigBlock -Lines $lines -Index ([ref]$index)
        
        # Create the network configuration object
        $config = [NetworkConfiguration]::new()
        
        # Parse real servers
        if ($parsedConfig.ContainsKey('load-balance real-server') -and 
            $parsedConfig['load-balance real-server'].ContainsKey('_items')) {
            
            foreach ($rsData in $parsedConfig['load-balance real-server']['_items']) {
                $rs = [RealServer]::new()
                $rs.Name = $rsData['_name']
                $rs.ServerType = Convert-Value $rsData['server-type'] ([string])
                $rs.Status = Convert-Value $rsData['status'] ([string])
                $rs.Type = Convert-Value $rsData['type'] ([string])
                $rs.Address = Convert-Value $rsData['ip'] ([string])
                $rs.Ipv6Address = Convert-Value $rsData['ip6'] ([string])
                
                $config.RealServers.Add($rs)
            }
        }
        
        # Parse health checks
        if ($parsedConfig.ContainsKey('system health-check') -and 
            $parsedConfig['system health-check'].ContainsKey('_items')) {
            
            foreach ($hcData in $parsedConfig['system health-check']['_items']) {
                $hc = [HealthMonitor]::new()
                $hc.Name = $hcData['_name']
                $hc.Type = Convert-Value $hcData['type'] ([string])
                $hc.Interval = Convert-Value $hcData['interval'] ([int])
                $hc.Timeout = Convert-Value $hcData['timeout'] ([int])
                $hc.Retry = Convert-Value $hcData['retry'] ([int])
                $hc.UpRetry = Convert-Value $hcData['up-retry'] ([int])
                $hc.Port = Convert-Value $hcData['port'] ([int])
                $hc.DestAddr = Convert-Value $hcData['dest-addr'] ([string])
                $hc.DestAddrType = Convert-Value $hcData['dest-addr-type'] ([string])
                
                # HTTP/HTTPS specific
                $hc.Hostname = Convert-Value $hcData['hostname'] ([string])
                $hc.HttpVersion = Convert-Value $hcData['http-version'] ([string])
                $hc.MethodType = Convert-Value $hcData['method-type'] ([string])
                $hc.SendString = Convert-Value $hcData['send-string'] ([string])
                $hc.StatusCode = Convert-Value $hcData['status-code'] ([int])
                $hc.Username = Convert-Value $hcData['username'] ([string])
                $hc.HttpConnect = Convert-Value $hcData['http-connect'] ([string])
                
                # HTTPS specific
                if ($hcData.ContainsKey('allow-ssl-versions')) {
                    $hc.AllowSslVersions = Convert-Value $hcData['allow-ssl-versions'] ([string[]])
                }
                if ($hcData.ContainsKey('ssl-ciphers')) {
                    $hc.SslCiphers = Convert-Value $hcData['ssl-ciphers'] ([string[]])
                }
                $hc.LocalCert = Convert-Value $hcData['local-cert'] ([string])
                
                # RADIUS specific
                $hc.PasswordType = Convert-Value $hcData['password-type'] ([string])
                $hc.SecretKey = Convert-Value $hcData['secret-key'] ([string])
                $hc.RadiusRejectEnable = Convert-Value $hcData['radius-reject-enable'] ([bool])
                
                $config.HealthMonitors.Add($hc)
            }
        }
        
        # Parse certificates
        if ($parsedConfig.ContainsKey('system certificate local') -and 
            $parsedConfig['system certificate local'].ContainsKey('_items')) {
            
            foreach ($certData in $parsedConfig['system certificate local']['_items']) {
                $cert = [Certificate]::new()
                $cert.Name = $certData['_name']
                $cert.Password = Convert-Value $certData['password'] ([string])
                $cert.Comments = Convert-Value $certData['comments'] ([string])
                $cert.Vdom = Convert-Value $certData['vdom'] ([string])
                $cert.AcmeStatus = Convert-Value $certData['acme-status'] ([string])
                $cert.PrivateKeyFile = Convert-Value $certData['private-key-file'] ([string])
                $cert.CertificateFile = Convert-Value $certData['certificate-file'] ([string])
                $cert.CsrFile = Convert-Value $certData['csr-file'] ([string])
                $cert.IsHsm = Convert-Value $certData['is-hsm'] ([string])
                
                $config.Certificates.Add($cert)
            }
        }
        
        # Parse pools
        if ($parsedConfig.ContainsKey('load-balance pool') -and 
            $parsedConfig['load-balance pool'].ContainsKey('_items')) {
            
            foreach ($poolData in $parsedConfig['load-balance pool']['_items']) {
                $pool = [Pool]::new()
                $pool.Name = $poolData['_name']
                $pool.Type = Convert-Value $poolData['type'] ([string])
                $pool.AddrType = Convert-Value $poolData['addr-type'] ([string])
                $pool.HealthCheckCtrl = Convert-Value $poolData['health-check-ctrl'] ([bool])
                $pool.HealthCheckDownAction = Convert-Value $poolData['health-check-down-action'] ([string])
                
                if ($poolData.ContainsKey('health-check-list')) {
                    $pool.HealthCheckList = Convert-Value $poolData['health-check-list'] ([string[]])
                }
                
                $pool.HealthCheckRelation = Convert-Value $poolData['health-check-relation'] ([string])
                $pool.DirectRouteMode = Convert-Value $poolData['direct-route-mode'] ([bool])
                $pool.RealServerSslProfile = Convert-Value $poolData['real-server-ssl-profile'] ([string])
                
                # Parse pool members
                if ($poolData.ContainsKey('pool_member') -and $poolData['pool_member'].ContainsKey('_items')) {
                    foreach ($memberData in $poolData['pool_member']['_items']) {
                        $member = [PoolMember]::new()
                        $member.Id = [int]$memberData['_name']
                        $member.HealthCheckInherit = Convert-Value $memberData['health-check-inherit'] ([bool])
                        $member.Status = Convert-Value $memberData['status'] ([string])
                        $member.RealServerSslProfileInherit = Convert-Value $memberData['real-server-ssl-profile-inherit'] ([bool])
                        $member.Backup = Convert-Value $memberData['backup'] ([bool])
                        $member.Port = Convert-Value $memberData['pool_member_service_port'] ([int])
                        $member.Weight = Convert-Value $memberData['pool_member_weight'] ([int])
                        $member.ConnectionLimit = Convert-Value $memberData['connection-limit'] ([int])
                        $member.Recover = Convert-Value $memberData['recover'] ([int])
                        $member.WarmUp = Convert-Value $memberData['warm-up'] ([int])
                        $member.WarmRate = Convert-Value $memberData['warm-rate'] ([int])
                        $member.ConnectionRateLimit = Convert-Value $memberData['connection-rate-limit'] ([int])
                        $member.Cookie = Convert-Value $memberData['pool_member_cookie'] ([string])
                        $member.RealServerName = Convert-Value $memberData['real-server'] ([string])
                        $member.MysqlReadOnly = Convert-Value $memberData['mysql-read-only'] ([bool])
                        $member.MysqlGroupId = Convert-Value $memberData['mysql-group-id'] ([int])
                        $member.ProxyProtocol = Convert-Value $memberData['proxy-protocol'] ([string])
                        $member.MssqlReadOnly = Convert-Value $memberData['mssql-read-only'] ([bool])
                        $member.ModifyHost = Convert-Value $memberData['modify-host'] ([bool])
                        $member.AutoPopulateFrom = Convert-Value $memberData['auto-populate-from'] ([int])
                        
                        $pool.Members.Add($member)
                    }
                }
                
                $config.Pools.Add($pool)
            }
        }
        
        # Parse virtual servers
        if ($parsedConfig.ContainsKey('load-balance virtual-server') -and 
            $parsedConfig['load-balance virtual-server'].ContainsKey('_items')) {
            
            foreach ($vsData in $parsedConfig['load-balance virtual-server']['_items']) {
                $vs = [VirtualServer]::new()
                $vs.Name = $vsData['_name']
                $vs.Status = Convert-Value $vsData['status'] ([string])
                $vs.Type = Convert-Value $vsData['type'] ([string])
                $vs.MultiProcess = Convert-Value $vsData['multi-process'] ([int])
                $vs.PacketForwardingMethod = Convert-Value $vsData['packet-forwarding-method'] ([string])
                $vs.Interface = Convert-Value $vsData['interface'] ([string])
                $vs.AddrType = Convert-Value $vsData['addr-type'] ([string])
                $vs.Ip = Convert-Value $vsData['ip'] ([string])
                $vs.PublicIpType = Convert-Value $vsData['public-ip-type'] ([string])
                $vs.PublicIp = Convert-Value $vsData['public-ip'] ([string])
                $vs.Port = Convert-Value $vsData['port'] ([int])
                
                if ($vsData.ContainsKey('protocol-numbers')) {
                    $vs.ProtocolNumbers = Convert-Value $vsData['protocol-numbers'] ([string[]])
                }
                
                $vs.ConnectionLimit = Convert-Value $vsData['connection-limit'] ([int])
                $vs.LoadBalanceProfile = Convert-Value $vsData['load-balance-profile'] ([string])
                $vs.DosProfile = Convert-Value $vsData['dos-profile'] ([string])
                $vs.ClientSslProfile = Convert-Value $vsData['client-ssl-profile'] ([string])
                $vs.ContentRewriting = Convert-Value $vsData['content-rewriting'] ([bool])
                $vs.ScheduleList = Convert-Value $vsData['schedule-list'] ([bool])
                $vs.ContentRouting = Convert-Value $vsData['content-routing'] ([bool])
                $vs.LoadBalancePersistence = Convert-Value $vsData['load-balance-persistence'] ([string])
                $vs.LoadBalanceMethod = Convert-Value $vsData['load-balance-method'] ([string])
                $vs.ConnectionPool = Convert-Value $vsData['connection-pool'] ([string])
                $vs.LoadBalancePoolName = Convert-Value $vsData['load-balance-pool'] ([string])
                $vs.IppoolList = Convert-Value $vsData['ippool-list'] ([string])
                $vs.TrafficLog = Convert-Value $vsData['traffic-log'] ([bool])
                $vs.Alone = Convert-Value $vsData['alone'] ([bool])
                $vs.WarmUp = Convert-Value $vsData['warm-up'] ([int])
                $vs.WarmRate = Convert-Value $vsData['warm-rate'] ([int])
                $vs.ErrorPage = Convert-Value $vsData['error-page'] ([string])
                $vs.ErrorMsg = Convert-Value $vsData['error-msg'] ([string])
                $vs.TransRateLimit = Convert-Value $vsData['trans-rate-limit'] ([int])
                $vs.WafProfile = Convert-Value $vsData['waf-profile'] ([string])
                $vs.AuthPolicy = Convert-Value $vsData['auth-policy'] ([string])
                $vs.ScriptingFlag = Convert-Value $vsData['scripting-flag'] ([bool])
                $vs.Pagespeed = Convert-Value $vsData['pagespeed'] ([string])
                $vs.Comments = Convert-Value $vsData['comments'] ([string])
                $vs.SslMirror = Convert-Value $vsData['ssl-mirror'] ([bool])
                $vs.TrafficGroup = Convert-Value $vsData['traffic-group'] ([string])
                $vs.Fortiview = Convert-Value $vsData['fortiview'] ([bool])
                $vs.Http2HttpsPort = Convert-Value $vsData['http2https-port'] ([int])
                $vs.MaxPersistenceEntries = Convert-Value $vsData['max-persistence-entries'] ([int])
                $vs.AvProfile = Convert-Value $vsData['av-profile'] ([string])
                $vs.ClonePool = Convert-Value $vsData['clone-pool'] ([string])
                $vs.CloneTrafficType = Convert-Value $vsData['clone-traffic-type'] ([string])
                $vs.AdfsPublishedService = Convert-Value $vsData['adfs-published-service'] ([string])
                $vs.Wccp = Convert-Value $vsData['wccp'] ([bool])
                $vs.OneClickGslbServerOption = Convert-Value $vsData['one-click-gslb-server-option'] ([bool])
                $vs.StreamScriptingFlag = Convert-Value $vsData['stream-scripting-flag'] ([bool])
                
                if ($vsData.ContainsKey('stream-scripting-list')) {
                    $vs.StreamScriptingList = Convert-Value $vsData['stream-scripting-list'] ([string[]])
                }
                
                $vs.IngressTag = Convert-Value $vsData['ingress-tag'] ([int])
                $vs.ConnectionRateLimit = Convert-Value $vsData['connection-rate-limit'] ([int])
                $vs.IpsProfile = Convert-Value $vsData['ips-profile'] ([string])
                
                $config.VirtualServers.Add($vs)
            }
        }
        
        # Resolve all object references
        $config.ResolveReferences()
        
        # Add metadata
        $config.Metadata['ParsedAt'] = Get-Date
        $config.Metadata['Vendor'] = 'FortiADC'
        
        return $config
    }
}
