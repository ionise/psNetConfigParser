# Installing Mermaid CLI

This guide provides instructions for installing the Mermaid CLI (`mmdc`) tool, which enables rendering Mermaid diagrams to PNG, SVG, and PDF formats.

## Prerequisites

Mermaid CLI requires Node.js and npm (Node Package Manager). Follow the instructions below for your operating system.

---

## Windows

### Step 1: Install Node.js and npm

**Option A: Using Windows Installer (Recommended)**

1. Visit [https://nodejs.org/](https://nodejs.org/)
2. Download the **LTS (Long Term Support)** version for Windows
3. Run the installer (`.msi` file)
4. Follow the installation wizard, accepting defaults
5. Ensure "npm package manager" is checked during installation

**Option B: Using Chocolatey**

```powershell
# Install Chocolatey if you don't have it
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Node.js
choco install nodejs
```

**Option C: Using Winget**

```powershell
winget install OpenJS.NodeJS.LTS
```

### Step 2: Verify Installation

Open a new PowerShell or Command Prompt window:

```powershell
node --version
npm --version
```

### Step 3: Install Mermaid CLI

```powershell
npm install -g @mermaid-js/mermaid-cli
```

### Step 4: Verify Mermaid CLI

```powershell
mmdc --version
```

### Step 5: Test Mermaid CLI

```powershell
# Create a test file
"graph TD; A-->B;" | Out-File -Encoding utf8 test.mmd

# Generate SVG
mmdc -i test.mmd -o test.svg

# Generate PNG
mmdc -i test.mmd -o test.png

# Clean up
Remove-Item test.mmd, test.svg, test.png
```

---

## macOS

### Step 1: Install Node.js and npm

**Option A: Using Homebrew (Recommended)**

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js (includes npm)
brew install node
```

**Option B: Using Direct Download**

1. Visit [https://nodejs.org/](https://nodejs.org/)
2. Download the **LTS version** installer for macOS
3. Run the `.pkg` installer and follow the prompts

**Option C: Using nvm (Node Version Manager)**

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell configuration
source ~/.zshrc  # or source ~/.bashrc

# Install latest LTS version
nvm install --lts
nvm use --lts
```

### Step 2: Verify Installation

```bash
node --version
npm --version
```

### Step 3: Install Mermaid CLI

```bash
npm install -g @mermaid-js/mermaid-cli
```

### Step 4: Verify Mermaid CLI

```bash
mmdc --version
```

### Step 5: Test Mermaid CLI

```bash
# Create a test file
echo "graph TD; A-->B;" > test.mmd

# Generate SVG
mmdc -i test.mmd -o test.svg

# Generate PNG
mmdc -i test.mmd -o test.png

# Clean up
rm test.mmd test.svg test.png
```

---

## Linux (Ubuntu/Debian - apt)

### Step 1: Install Node.js and npm

**Option A: Using NodeSource Repository (Recommended - Latest LTS)**

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg

# Add NodeSource repository for Node.js 20.x (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js and npm
sudo apt install -y nodejs
```

**Option B: Using Default Ubuntu/Debian Repositories**

```bash
sudo apt update
sudo apt install -y nodejs npm
```

Note: Default repositories may have older versions. Use Option A for the latest LTS.

**Option C: Using nvm (Node Version Manager)**

```bash
# Install prerequisites
sudo apt update
sudo apt install -y curl

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell configuration
source ~/.bashrc

# Install latest LTS version
nvm install --lts
nvm use --lts
```

### Step 2: Verify Installation

```bash
node --version
npm --version
```

### Step 3: Install Mermaid CLI

```bash
npm install -g @mermaid-js/mermaid-cli
```

### Step 4: Install Required Dependencies

Mermaid CLI requires Chromium dependencies for rendering:

```bash
sudo apt install -y \
  libnss3 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libdrm2 \
  libxkbcommon0 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxrandr2 \
  libgbm1 \
  libasound2
```

### Step 5: Verify Mermaid CLI

```bash
mmdc --version
```

### Step 6: Test Mermaid CLI

```bash
# Create a test file
echo "graph TD; A-->B;" > test.mmd

# Generate SVG
mmdc -i test.mmd -o test.svg

# Generate PNG
mmdc -i test.mmd -o test.png

# Clean up
rm test.mmd test.svg test.png
```

---

## Linux (RHEL/CentOS/Fedora - yum/dnf)

### Step 1: Install Node.js and npm

**Option A: Using NodeSource Repository (Recommended - Latest LTS)**

**For RHEL/CentOS 8+ and Fedora (dnf):**

```bash
# Add NodeSource repository for Node.js 20.x (LTS)
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -

# Install Node.js and npm
sudo dnf install -y nodejs
```

**For RHEL/CentOS 7 (yum):**

```bash
# Add NodeSource repository for Node.js 20.x (LTS)
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -

# Install Node.js and npm
sudo yum install -y nodejs
```

**Option B: Using EPEL Repository (Older Versions)**

**For RHEL/CentOS 8+ and Fedora:**

```bash
# Enable EPEL repository
sudo dnf install -y epel-release

# Install Node.js and npm
sudo dnf install -y nodejs npm
```

**For RHEL/CentOS 7:**

```bash
# Enable EPEL repository
sudo yum install -y epel-release

# Install Node.js and npm
sudo yum install -y nodejs npm
```

**Option C: Using nvm (Node Version Manager)**

```bash
# Install prerequisites
sudo dnf install -y curl  # or: sudo yum install -y curl

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell configuration
source ~/.bashrc

# Install latest LTS version
nvm install --lts
nvm use --lts
```

### Step 2: Verify Installation

```bash
node --version
npm --version
```

### Step 3: Install Mermaid CLI

```bash
npm install -g @mermaid-js/mermaid-cli
```

### Step 4: Install Required Dependencies

Mermaid CLI requires Chromium dependencies for rendering:

**For RHEL/CentOS 8+ and Fedora (dnf):**

```bash
sudo dnf install -y \
  nss \
  atk \
  at-spi2-atk \
  cups-libs \
  libdrm \
  libXcomposite \
  libXdamage \
  libXfixes \
  libXrandr \
  mesa-libgbm \
  alsa-lib
```

**For RHEL/CentOS 7 (yum):**

```bash
sudo yum install -y \
  nss \
  atk \
  at-spi2-atk \
  cups-libs \
  libdrm \
  libXcomposite \
  libXdamage \
  libXfixes \
  libXrandr \
  mesa-libgbm \
  alsa-lib
```

### Step 5: Verify Mermaid CLI

```bash
mmdc --version
```

### Step 6: Test Mermaid CLI

```bash
# Create a test file
echo "graph TD; A-->B;" > test.mmd

# Generate SVG
mmdc -i test.mmd -o test.svg

# Generate PNG
mmdc -i test.mmd -o test.png

# Clean up
rm test.mmd test.svg test.png
```

---

## Troubleshooting

### Permission Errors (Linux/macOS)

If you get permission errors when installing global npm packages, you have two options:

**Option 1: Configure npm to use a different directory (Recommended)**

```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc  # or ~/.zshrc for macOS
source ~/.bashrc  # or source ~/.zshrc
```

Then retry the installation:

```bash
npm install -g @mermaid-js/mermaid-cli
```

**Option 2: Use sudo (Not Recommended)**

```bash
sudo npm install -g @mermaid-js/mermaid-cli
```

### Puppeteer/Chromium Issues

If you encounter browser-related errors:

```bash
# Force reinstall of Puppeteer's Chromium
npx puppeteer browsers install chrome
```

### Path Issues (Windows)

If `mmdc` is not found after installation, you may need to add npm's global bin directory to your PATH:

1. Find npm's global directory: `npm config get prefix`
2. Add `<prefix>\node_modules\.bin` to your system PATH
3. Restart your terminal

### Firewall/Proxy Issues

If you're behind a corporate firewall or proxy:

```bash
# Set npm proxy
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080

# Or use environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
```

---

## Usage with psNetConfigParser

Once Mermaid CLI is installed, you can use it with this module:

```powershell
# Generate a Mermaid diagram
$config | ConvertTo-MermaidDiagram | Out-File diagram.mmd

# Render to SVG
mmdc -i diagram.mmd -o diagram.svg

# Render to PNG
mmdc -i diagram.mmd -o diagram.png -b transparent

# Render to PDF
mmdc -i diagram.mmd -o diagram.pdf
```

### Common mmdc Options

- `-i, --input <file>` - Input Mermaid file
- `-o, --output <file>` - Output file (extension determines format: .svg, .png, .pdf)
- `-b, --backgroundColor <color>` - Background color (default: white, use 'transparent' for PNG)
- `-w, --width <width>` - Width of the output image
- `-H, --height <height>` - Height of the output image
- `-s, --scale <scale>` - Scale factor for the output

---

## Additional Resources

- [Node.js Official Website](https://nodejs.org/)
- [npm Documentation](https://docs.npmjs.com/)
- [Mermaid CLI Documentation](https://github.com/mermaid-js/mermaid-cli)
- [Mermaid Syntax Documentation](https://mermaid.js.org/)
