@{
    # Module manifest for psNetConfigParser
    
    # Script module or binary module file associated with this manifest
    RootModule = 'psNetConfigParser.psm1'
    
    # Version number of this module
    ModuleVersion = '0.1.0'
    
    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-4a5b-9c8d-7e6f5a4b3c2d'
    
    # Author of this module
    Author = 'David'
    
    # Company or vendor of this module
    CompanyName = 'Unknown'
    
    # Copyright statement for this module
    Copyright = '(c) 2026. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'A modular PowerShell framework for parsing network device configurations (FortiADC, FortiGate, Cisco, etc.) into structured models and rendering them as Markdown documentation, YAML, or CLI commands.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'ConvertFrom-FortiADCConfig'
        'ConvertTo-Markdown'
        'ConvertTo-Yaml'
        'ConvertTo-MermaidDiagram'
        'ConvertFrom-YamlToFortiADCCli'
        'Export-VirtualServerDocumentation'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('NetworkConfiguration', 'FortiADC', 'LoadBalancer', 'ConfigParser', 'Documentation')
            
            # A URL to the license for this module
            # LicenseUri = ''
            
            # A URL to the main website for this project
            # ProjectUri = ''
            
            # Release notes of this module
            ReleaseNotes = @'
Version 0.1.0:
- Initial release
- FortiADC configuration parser
- Support for virtual servers, pools, real servers, health monitors, and certificates
- Markdown, YAML, and Mermaid diagram renderers
- CLI generator stub (requires powershell-yaml for full implementation)
'@
        }
    }
}
