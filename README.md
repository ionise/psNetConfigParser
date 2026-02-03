# psNetConfigParser

A modular PowerShell framework for parsing network device configurations into structured models and rendering them as documentation, YAML, or CLI commands.

## Overview

This module provides a vendor-neutral approach to parsing and documenting network configurations. Currently supports **FortiADC** and **F5 BigIP** load balancer configurations with an architecture designed for easy extension to other vendors (FortiGate, Cisco, Juniper, etc.).

## Features

- **Parse Load Balancer Configurations**: 
  - FortiADC configuration files
  - F5 BigIP tmsh configuration files
- **Vendor-Neutral Model**: PowerShell classes represent configuration in a vendor-agnostic way
- **Multiple Output Formats**:
  - Markdown documentation with tables and diagrams
  - YAML for declarative configuration
  - Mermaid diagrams for visual architecture
  - CLI command generation (round-trip capability)
- **Per-Virtual Server Documentation**: Individual markdown files with index page

## Installation

```powershell
# Import the module
Import-Module ./psNetConfigParser
```

## Quick Start

### Parse a FortiADC Configuration

```powershell
# Parse from file
$config = ConvertFrom-FortiADCConfig -Path "fortiadc.conf"

# Or from text
$configText = Get-Content "fortiadc.conf" -Raw
$config = $configText | ConvertFrom-FortiADCConfig
```

### Parse an F5 BigIP Configuration

```powershell
# Parse from file
$config = ConvertFrom-F5BigIPConfig -Path "bigip.conf"

# Or from text
$configText = Get-Content "bigip.conf" -Raw
$config = $configText | ConvertFrom-F5BigIPConfig
```

### Export Per-Virtual Server Documentation

```powershell
# Generate individual markdown files for each virtual server
$config | Export-VirtualServerDocumentation -OutputDirectory "./docs" -IncludeDiagrams

# This creates:
#   ./docs/index.md           - Table of contents
#   ./docs/vs_MyServer.md     - Individual VS documentation
```

### Generate Markdown Documentation

```powershell
# Basic documentation
$config | ConvertTo-Markdown | Out-File "documentation.md"

# With Mermaid diagrams
$config | ConvertTo-Markdown -IncludeDiagrams | Out-File "documentation-with-diagrams.md"
```

### Generate YAML Configuration

```powershell
$config | ConvertTo-Yaml | Out-File "config.yaml"
```

### Generate Mermaid Diagram for a Specific Virtual Server

```powershell
$vs = $config.VirtualServers | Where-Object { $_.Name -eq "VS_WebApp" }
$vs | ConvertTo-MermaidDiagram
```

### Generate CLI Commands from YAML

```powershell
# Note: Full implementation requires powershell-yaml module
ConvertFrom-YamlToFortiADCCli -Path "config.yaml" | Out-File "commands.cli"
```

## Architecture

```
psNetConfigParser/
├── Model/                      # PowerShell classes (vendor-neutral)
│   ├── NetworkConfiguration.ps1
│   ├── VirtualServer.ps1
│   ├── Pool.ps1
│   ├── PoolMember.ps1
│   ├── RealServer.ps1
│   ├── HealthMonitor.ps1
│   └── Certificate.ps1
├── Parsers/                    # Vendor-specific parsers
│   ├── ConvertFrom-FortiADCConfig.ps1
│   └── ConvertFrom-F5BigIPConfig.ps1
├── Renderers/                  # Output formatters
│   ├── ConvertTo-Markdown.ps1
│   ├── ConvertTo-Yaml.ps1
│   ├── ConvertTo-MermaidDiagram.ps1
│   ├── Export-VirtualServerDocumentation.ps1
│   └── ConvertFrom-YamlToFortiADCCli.ps1
├── Tests/                      # Pester tests (future)
├── psNetConfigParser.psd1      # Module manifest
└── psNetConfigParser.psm1      # Main module file
```

## Parsed Objects

### NetworkConfiguration

The root object containing all parsed configuration elements:

- `VirtualServers` - List of virtual server objects
- `Pools` - List of pool objects
- `RealServers` - List of backend server objects
- `HealthMonitors` - List of health check objects
- `Certificates` - List of SSL certificate objects
- `Metadata` - Additional information (vendor, parse time, etc.)

### Example Usage

```powershell
# Access virtual servers
$config.VirtualServers | Select-Object Name, Ip, Port, Status

# Find a specific pool
$pool = $config.Pools | Where-Object { $_.Name -eq "POOL_WebApp" }

# Check pool members
$pool.Members | Select-Object @{Name='Server';Expression={$_.RealServer.Address}}, Port, Weight, Status

# View health monitors
$config.HealthMonitors | Select-Object Name, Type, Interval, Port
```

## Extending to Other Vendors

To add support for another vendor:

1. Create a new parser in `Parsers/` (e.g., `ConvertFrom-CiscoConfig.ps1`)
2. Parse vendor-specific syntax into the existing model classes
3. Add any vendor-specific fields to the model if needed
4. Optionally create vendor-specific CLI generator in `Renderers/`
5. Update the module manifest to export the new functions

The model classes and renderers remain unchanged, providing consistency across vendors.

## Requirements

- PowerShell 5.1 or later
- Optional: `powershell-yaml` module for full YAML round-trip support

```powershell
Install-Module powershell-yaml -Scope CurrentUser
```

## Examples

See the `Tests/` directory for more usage examples (coming soon).

## Roadmap

- [ ] Pester tests for parser and renderers
- [ ] Full YAML-to-CLI round-trip implementation
- [ ] FortiGate configuration parser
- [ ] Cisco ASA/ACE configuration parser
- [x] ~~F5 BIG-IP configuration parser~~ ✅ Added in v0.2.0
- [ ] Configuration diff/comparison tools
- [ ] Migration helpers between vendors
- [ ] HTML documentation export option

## Contributing

Contributions welcome! Please follow the existing code structure and add appropriate tests.

## AI Assistance Disclosure

Parts of this project were created with assistance from AI coding tools, including GitHub Copilot in Visual Studio Code.
AI suggestions were used to help draft code, documentation, and implementation patterns. All AI-assisted output has been:

Reviewed and validated manually
Modified to fit the project’s conventions and requirements
Tested to ensure correctness and security
AI tools were used as accelerators, not as autonomous code authors.
The maintainers take full responsibility for all code committed to this repository.

For transparency, this disclosure aligns with industry recommendations encouraging contributors to declare meaningful AI involvement in software development.

## License

TBD
