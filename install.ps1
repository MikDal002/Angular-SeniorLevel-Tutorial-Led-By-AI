Import-Certificate -FilePath C:\Users\WDAGUtilityAccount\Desktop\Private\zscaler.cer -CertStoreLocation Cert:\LocalMachine\Root

$progressPreference = 'silentlyContinue'
Write-Host "Installing WinGet PowerShell module from PSGallery..."
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
Repair-WinGetPackageManager -AllUsers
Write-Host "Done."

# Install Visual C++ Redistributable to resolve MSVCP140.dll issues
winget install --id Microsoft.VCRedist.2015+.x64 -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.VCRedist.2015+.x86 -e --source winget --accept-package-agreements --accept-source-agreements

# Install Windows App SDK and related dependencies to fix COM registration issues
winget install --id Microsoft.WindowsAppRuntime.1.4 -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.VCLibs.140.00.UWP.Desktop -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.UI.Xaml.2.8 -e --source winget --accept-package-agreements --accept-source-agreements

# Install basic development tools
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id TortoiseGit.TortoiseGit -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.VisualStudioCode -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.WindowsTerminal -e --source winget --accept-package-agreements --accept-source-agreements

# Configure Git for sandbox environment
Write-Host "Configuring Git for sandbox environment..."
git config --global --add safe.directory "C:/Users/WDAGUtilityAccount/Desktop/Shared"
git config --global --add safe.directory "*"
git config --global user.name "Angular Developer"
git config --global user.email "developer@angular-tutorial.local"

Write-Host "Installation completed successfully!"

# Install Node.js and package managers for Angular development
# winget install --id OpenJS.NodeJS -e --source winget --accept-package-agreements --accept-source-agreements

# Wait for Node.js installation to complete and refresh environment variables
Start-Sleep -Seconds 10
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

# Install yarn package manager globally
# npm install -g yarn

# Install Angular CLI globally
# npm install -g @angular/cli

