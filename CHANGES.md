# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-02-03

### Added

- **F5 BigIP Configuration Parser** (`ConvertFrom-F5BigIPConfig`)
  - Parses F5 BigIP tmsh configuration files
  - Extracts Virtual Servers, Pools, Nodes (Real Servers), Health Monitors, and SSL Certificates
  - Hybrid parsing architecture: line-by-line scanning with intelligent block skipping for complex objects (iRules, profiles)
  - Handles F5-specific destination formats (IP:port, IP:service-name, IPv6)
  - Gracefully skips unsupported object types without breaking parser

- **F5 BigIP CLI Generator** (`ConvertFrom-YamlToF5BigIPCli`)
  - Generates tmsh commands from NetworkConfiguration objects or YAML
  - Creates commands for monitors, nodes, pools (with members), and virtual servers
  - Supports service names and numeric ports in destinations
  - Configurable partition name (defaults to "Common")
  - Outputs shell script format ready for execution

- **Service Name Support**
  - Added `ServiceName` property to `VirtualServer` and `PoolMember` classes
  - Ports specified as service names (e.g., `imap`, `https`, `tungsten-https`) are preserved as-is
  - No assumptions made about service-to-port mappings - displays exactly what's in the config

- **Updated Documentation Export**
  - Service names displayed correctly in markdown tables, Mermaid diagrams, and YAML output
  - Works with both numeric ports (FortiADC) and service names (F5 BigIP)

### Changed

- Updated `.gitignore` to exclude `samples/` directory for test configurations

### Technical Details

- F5 BigIP parser tested on both development and production configurations
- Successfully parsed: 96 virtual servers, 48 pools, 70 nodes, 8 monitors from production config
- FortiADC parser remains fully functional with all existing features

---

## [0.1.0] - Initial Release

### Added

- **FortiADC Configuration Parser** (`ConvertFrom-FortiADCConfig`)
  - Parses FortiADC configuration files
  - Extracts Virtual Servers, Pools, Real Servers, Health Monitors, and Certificates

- **Model Classes**
  - `NetworkConfiguration` - Root container for all parsed objects
  - `VirtualServer` - Load balancer virtual server configuration
  - `Pool` - Backend server pool with members and health checks
  - `PoolMember` - Individual pool member with weight and status
  - `RealServer` - Backend server definition
  - `HealthMonitor` - Health check configuration
  - `Certificate` - SSL certificate reference

- **Renderers**
  - `Export-VirtualServerDocumentation` - Generates individual markdown files per virtual server with index
  - `ConvertTo-Markdown` - Converts configuration to markdown format
  - `ConvertTo-MermaidDiagram` - Generates Mermaid architecture diagrams
  - `ConvertTo-Yaml` - Exports configuration in YAML format
  - `ConvertFrom-YamlToFortiADCCli` - Generates FortiADC CLI commands from YAML

- **Documentation Features**
  - Per-virtual-server markdown files with full configuration details
  - Table of contents index page with summary statistics
  - Mermaid diagrams showing VS → Pool → Members architecture
  - YAML configuration blocks for configuration reproduction
  - Health check details and pool member tables

### Module Structure

```
psNetConfigParser/
├── psNetConfigParser.psd1    # Module manifest
├── psNetConfigParser.psm1    # Module loader
├── Model/                    # PowerShell class definitions
│   ├── Certificate.ps1
│   ├── HealthMonitor.ps1
│   ├── NetworkConfiguration.ps1
│   ├── Pool.ps1
│   ├── PoolMember.ps1
│   ├── RealServer.ps1
│   └── VirtualServer.ps1
├── Parsers/                  # Configuration parsers
│   ├── ConvertFrom-FortiADCConfig.ps1
│   └── ConvertFrom-F5BigIPConfig.ps1
└── Renderers/                # Output formatters
    ├── ConvertFrom-YamlToFortiADCCli.ps1
    ├── ConvertFrom-YamlToF5BigIPCli.ps1
    ├── ConvertTo-Markdown.ps1
    ├── ConvertTo-MermaidDiagram.ps1
    ├── ConvertTo-Yaml.ps1
    └── Export-VirtualServerDocumentation.ps1
```
