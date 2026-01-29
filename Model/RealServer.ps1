class RealServer {
    [string]$Name
    [string]$ServerType  # static, dynamic
    [string]$Status  # enable, disable
    [string]$Type  # ip, hostname
    [string]$Address  # IP address or hostname
    [string]$Ipv6Address
    
    # Constructor
    RealServer() {
        $this.ServerType = 'static'
        $this.Status = 'enable'
        $this.Type = 'ip'
        $this.Ipv6Address = '::'
    }
    
    [string] ToString() {
        return "$($this.Name) ($($this.Address))"
    }
}
