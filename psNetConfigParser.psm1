# psNetConfigParser Module
# A modular PowerShell framework for parsing network device configurations

# Load all model classes
$modelFiles = Get-ChildItem -Path "$PSScriptRoot/Model" -Filter "*.ps1" -File
foreach ($file in $modelFiles) {
    . $file.FullName
}

# Load parser functions
$parserFiles = Get-ChildItem -Path "$PSScriptRoot/Parsers" -Filter "*.ps1" -File
foreach ($file in $parserFiles) {
    . $file.FullName
}

# Load renderer functions
$rendererFiles = Get-ChildItem -Path "$PSScriptRoot/Renderers" -Filter "*.ps1" -File
foreach ($file in $rendererFiles) {
    . $file.FullName
}

# Export public functions
Export-ModuleMember -Function @(
    'ConvertFrom-FortiADCConfig'
    'ConvertFrom-F5BigIPConfig'
    'ConvertTo-Markdown'
    'ConvertTo-Yaml'
    'ConvertTo-MermaidDiagram'
    'ConvertFrom-YamlToFortiADCCli'
    'ConvertFrom-YamlToF5BigIPCli'
    'Export-VirtualServerDocumentation'
)
