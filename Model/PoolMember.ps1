class PoolMember {
    [int]$Id
    [bool]$HealthCheckInherit
    [string]$Status  # enable, disable
    [bool]$RealServerSslProfileInherit
    [bool]$Backup
    [int]$Port
    [int]$Weight
    [int]$ConnectionLimit
    [int]$Recover
    [int]$WarmUp
    [int]$WarmRate
    [int]$ConnectionRateLimit
    [string]$Cookie
    [string]$RealServerName  # Reference to RealServer
    [object]$RealServer  # Resolved real server object
    [bool]$MysqlReadOnly
    [int]$MysqlGroupId
    [string]$ProxyProtocol
    [bool]$MssqlReadOnly
    [bool]$ModifyHost
    [int]$AutoPopulateFrom
    
    # Constructor
    PoolMember() {
        $this.HealthCheckInherit = $true
        $this.Status = 'enable'
        $this.RealServerSslProfileInherit = $true
        $this.Backup = $false
        $this.Weight = 1
        $this.ConnectionLimit = 0
        $this.Recover = 0
        $this.WarmUp = 0
        $this.WarmRate = 100
        $this.ConnectionRateLimit = 0
        $this.MysqlReadOnly = $false
        $this.MysqlGroupId = 0
        $this.ProxyProtocol = 'none'
        $this.MssqlReadOnly = $false
        $this.ModifyHost = $false
        $this.AutoPopulateFrom = 0
    }
    
    [string] ToString() {
        if ($this.RealServer) {
            return "$($this.RealServer.Address):$($this.Port)"
        }
        return "$($this.RealServerName):$($this.Port)"
    }
}
