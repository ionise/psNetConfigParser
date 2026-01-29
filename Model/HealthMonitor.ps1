class HealthMonitor {
    [string]$Name
    [string]$Type  # icmp, http, https, tcp-echo, radius, etc.
    [int]$Interval
    [int]$Timeout
    [int]$Retry
    [int]$UpRetry
    [int]$Port
    [string]$DestAddr
    [string]$DestAddrType
    
    # HTTP/HTTPS specific
    [string]$Hostname
    [string]$HttpVersion
    [string]$MethodType
    [string]$SendString
    [int]$StatusCode
    [string]$Username
    [string]$HttpConnect
    
    # HTTPS specific
    [string[]]$AllowSslVersions
    [string[]]$SslCiphers
    [string]$LocalCert
    
    # RADIUS specific
    [string]$PasswordType
    [string]$SecretKey
    [bool]$RadiusRejectEnable
    
    # Constructor
    HealthMonitor() {
        $this.Interval = 5
        $this.Timeout = 3
        $this.Retry = 3
        $this.UpRetry = 1
        $this.Port = 0
        $this.DestAddrType = 'ipv4'
        $this.DestAddr = '0.0.0.0'
    }
    
    [string] ToString() {
        return "$($this.Name) ($($this.Type))"
    }
}
