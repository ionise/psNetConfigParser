class Certificate {
    [string]$Name
    [string]$Password
    [string]$Comments
    [string]$Vdom
    [string]$AcmeStatus
    [string]$PrivateKeyFile
    [string]$CertificateFile
    [string]$CsrFile
    [string]$IsHsm  # yes, no
    
    # Constructor
    Certificate() {
        $this.AcmeStatus = 'not_set'
        $this.IsHsm = 'no'
    }
    
    [string] ToString() {
        return "$($this.Name)"
    }
}
