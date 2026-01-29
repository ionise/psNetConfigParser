# Root configuration model that holds all parsed objects
class NetworkConfiguration {
    [System.Collections.Generic.List[object]]$VirtualServers
    [System.Collections.Generic.List[object]]$Pools
    [System.Collections.Generic.List[object]]$RealServers
    [System.Collections.Generic.List[object]]$HealthMonitors
    [System.Collections.Generic.List[object]]$Certificates
    [hashtable]$Metadata  # For vendor-specific or extra data
    
    # Constructor
    NetworkConfiguration() {
        $this.VirtualServers = [System.Collections.Generic.List[object]]::new()
        $this.Pools = [System.Collections.Generic.List[object]]::new()
        $this.RealServers = [System.Collections.Generic.List[object]]::new()
        $this.HealthMonitors = [System.Collections.Generic.List[object]]::new()
        $this.Certificates = [System.Collections.Generic.List[object]]::new()
        $this.Metadata = @{}
    }
    
    # Helper method to resolve references
    [void] ResolveReferences() {
        # Resolve pool references in virtual servers
        foreach ($vs in $this.VirtualServers) {
            if ($vs.LoadBalancePoolName) {
                $vs.LoadBalancePool = $this.Pools | Where-Object { $_.Name -eq $vs.LoadBalancePoolName } | Select-Object -First 1
            }
        }
        
        # Resolve health check references in pools
        foreach ($pool in $this.Pools) {
            if ($pool.HealthCheckList) {
                $pool.HealthChecks = $this.HealthMonitors | Where-Object { $pool.HealthCheckList -contains $_.Name }
            }
            
            # Resolve real server references in pool members
            foreach ($member in $pool.Members) {
                if ($member.RealServerName) {
                    $member.RealServer = $this.RealServers | Where-Object { $_.Name -eq $member.RealServerName } | Select-Object -First 1
                }
            }
        }
    }
    
    [string] ToString() {
        return "NetworkConfiguration: $($this.VirtualServers.Count) VS, $($this.Pools.Count) Pools, $($this.RealServers.Count) RS"
    }
}
