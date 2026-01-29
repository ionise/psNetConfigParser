class VirtualServer {
    [string]$Name
    [string]$Status  # enable, disable
    [string]$Type  # l7-load-balance, l4-load-balance, etc.
    [int]$MultiProcess
    [string]$PacketForwardingMethod  # NAT, DR, etc. (L4 only)
    [string]$Interface
    [string]$AddrType  # ipv4, ipv6
    [string]$Ip
    [string]$PublicIpType
    [string]$PublicIp
    [int]$Port
    [string[]]$ProtocolNumbers
    [int]$ConnectionLimit
    [string]$LoadBalanceProfile
    [string]$DosProfile
    [string]$ClientSslProfile
    [bool]$ContentRewriting
    [bool]$ScheduleList
    [bool]$ContentRouting
    [string]$LoadBalancePersistence
    [string]$LoadBalanceMethod
    [string]$ConnectionPool
    [string]$LoadBalancePoolName  # Reference to pool
    [object]$LoadBalancePool  # Resolved pool object
    [string]$IppoolList
    [bool]$TrafficLog
    [bool]$Alone
    [int]$WarmUp
    [int]$WarmRate
    [string]$ErrorPage
    [string]$ErrorMsg
    [int]$TransRateLimit
    [string]$WafProfile
    [string]$AuthPolicy
    [bool]$ScriptingFlag
    [string]$Pagespeed
    [string]$Comments
    [bool]$SslMirror
    [string]$TrafficGroup
    [bool]$Fortiview
    [int]$Http2HttpsPort
    [int]$MaxPersistenceEntries
    [string]$AvProfile
    [string]$ClonePool
    [string]$CloneTrafficType
    [string]$AdfsPublishedService
    [bool]$Wccp
    [bool]$OneClickGslbServerOption
    [bool]$StreamScriptingFlag
    [string[]]$StreamScriptingList
    [int]$IngressTag
    [int]$ConnectionRateLimit  # L4 only
    [string]$IpsProfile  # L4 only
    
    # Constructor
    VirtualServer() {
        $this.Status = 'enable'
        $this.Type = 'l7-load-balance'
        $this.MultiProcess = 1
        $this.AddrType = 'ipv4'
        $this.PublicIpType = 'ipv4'
        $this.PublicIp = '0.0.0.0'
        $this.Port = 80
        $this.ProtocolNumbers = @('0')
        $this.ConnectionLimit = 0
        $this.ContentRewriting = $false
        $this.ScheduleList = $false
        $this.ContentRouting = $false
        $this.LoadBalanceMethod = 'LB_METHOD_ROUND_ROBIN'
        $this.TrafficLog = $false
        $this.Alone = $true
        $this.WarmUp = 0
        $this.WarmRate = 100
        $this.ErrorMsg = 'Server-unavailable!'
        $this.TransRateLimit = 0
        $this.ScriptingFlag = $false
        $this.SslMirror = $false
        $this.Fortiview = $true
        $this.Http2HttpsPort = 80
        $this.MaxPersistenceEntries = 262144
        $this.CloneTrafficType = 'both-sides'
        $this.Wccp = $false
        $this.OneClickGslbServerOption = $false
        $this.StreamScriptingFlag = $false
        $this.StreamScriptingList = @()
        $this.IngressTag = 0
        $this.ConnectionRateLimit = 0
    }
    
    [string] ToString() {
        return "$($this.Name) - $($this.Ip):$($this.Port)"
    }
}
