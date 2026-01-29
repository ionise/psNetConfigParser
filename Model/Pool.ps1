class Pool {
    [string]$Name
    [string]$Type  # static, dynamic
    [string]$AddrType  # ipv4, ipv6
    [bool]$HealthCheckCtrl
    [string]$HealthCheckDownAction  # reject, maintain
    [string[]]$HealthCheckList  # Array of health check names
    [object[]]$HealthChecks  # Resolved health check objects
    [string]$HealthCheckRelation  # AND, OR
    [bool]$DirectRouteMode
    [string]$RealServerSslProfile
    [System.Collections.Generic.List[object]]$Members
    
    # Constructor
    Pool() {
        $this.Type = 'static'
        $this.AddrType = 'ipv4'
        $this.HealthCheckCtrl = $true
        $this.HealthCheckDownAction = 'reject'
        $this.HealthCheckList = @()
        $this.HealthChecks = @()
        $this.HealthCheckRelation = 'AND'
        $this.DirectRouteMode = $false
        $this.RealServerSslProfile = 'NONE'
        $this.Members = [System.Collections.Generic.List[object]]::new()
    }
    
    [string] ToString() {
        return "$($this.Name) ($($this.Members.Count) members)"
    }
}
