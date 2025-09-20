# =================================================================================================
#
#                                   DEVELOPER ENVIRONMENT SETUP
#
#  This script bootstraps a developer environment by installing necessary tools and dependencies.
#  It handles:
#  - Zscaler Certificate Import
#  - WinGet Package Manager Setup
#  - Core Dependencies (VC++ Redist, Windows App SDK)
#  - Essential Development Tools (Git, VS Code, etc.)
#  - Recording Software (Free Cam)
#  - Git Configuration
#  - (Optional) Angular Development Environment Setup
#
# =================================================================================================

#region Script Configuration and Helpers

# Set preferences for cleaner output and error handling
$progressPreference = 'silentlyContinue'
$ErrorActionPreference = 'Stop'

# Helper function for writing section headers
function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n"
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
}

# Helper function for running WinGet installations
function Invoke-WinGetInstall {
    param([string]$PackageId, [string]$PackageName)
    Write-Host "Installing $PackageName..."
    try {
        winget install --id $PackageId -e --source winget --accept-package-agreements --accept-source-agreements
        Write-Host "Successfully installed $PackageName." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install $PackageName (ID: $PackageId). Please check WinGet logs."
    }
}

# Helper function for refreshing environment variables
function Refresh-EnvironmentVariables {
    Write-Host "Refreshing environment variables..."
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $combinedPaths = @($machinePath, $userPath) | Where-Object { $_ -and $_.Trim() -ne "" }
    $env:PATH = $combinedPaths -join ";"
    Write-Host "Environment variables refreshed." -ForegroundColor Green
}

# Helper function for running commands in new window with fresh environment
function Run-InNewWindow {
    param([string]$FunctionName)
    Write-Host "Running $FunctionName in new window with refreshed environment..." -ForegroundColor Yellow
    $scriptPath = $PSCommandPath
    
    # Create a temporary script that loads functions and runs the specific one
    $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
    $scriptContent = @"
# Load only the functions from the main script
`$scriptContent = Get-Content '$scriptPath' -Raw
`$functionsOnly = `$scriptContent -replace '(?s)#region Main Execution.*?#endregion', ''
Invoke-Expression `$functionsOnly

# Run the specific function
$FunctionName

# Keep window open
Write-Host "Function execution completed. You can close this window." -ForegroundColor Green
Read-Host "Press Enter to close"
"@
    
    Set-Content -Path $tempScript -Value $scriptContent
    
    # Try PowerShell Core first, fallback to Windows PowerShell
    try {
        Start-Process pwsh -ArgumentList "-NoExit", "-File", $tempScript
    }
    catch {
        Write-Host "PowerShell Core not found, using Windows PowerShell..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoExit", "-File", $tempScript
    }
}

#endregion

#region Installation Functions

function Import-Certificates {
    Write-SectionHeader "Importing Zscaler Root Certificate"
    $certPath = "C:\Users\WDAGUtilityAccount\Desktop\Private\zscaler.cer"
    if (Test-Path $certPath) {
        try {
            Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root
            Write-Host "Certificate imported successfully." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to import certificate. Please ensure you have administrator privileges."
        }
    }
    else {
        Write-Warning "Zscaler certificate not found at '$certPath'. Skipping import."
    }
}

function Install-WinGet {
    Write-SectionHeader "Bootstrapping WinGet Package Manager"
    try {
        Write-Host "Installing WinGet PowerShell module from PSGallery..."
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
        Write-Host "Repairing WinGet package manager to ensure it's operational..."
        Repair-WinGetPackageManager -AllUsers
        Write-Host "WinGet is ready." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to bootstrap WinGet, but continuing with script execution..." -ForegroundColor Yellow
        Write-Host "Some installations may fail if WinGet is not properly configured." -ForegroundColor Gray
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Gray
    }
}

function Install-CoreDependencies {
    Write-SectionHeader "Installing Core System Dependencies"
    Invoke-WinGetInstall "Microsoft.VCRedist.2015+.x64" "Visual C++ Redistributable (x64)"
    Invoke-WinGetInstall "Microsoft.VCRedist.2015+.x86" "Visual C++ Redistributable (x86)"
    # Invoke-WinGetInstall "Microsoft.WindowsAppRuntime.1.4" "Windows App SDK Runtime"
    Invoke-WinGetInstall "Microsoft.VCLibs.140.00.UWP.Desktop" "Microsoft Visual C++ 2015 UWP Desktop Runtime"
    # Invoke-WinGetInstall "Microsoft.UI.Xaml.2.8" "Microsoft UI Xaml"
}

function Install-DevTools {
    Write-SectionHeader "Installing Basic Development Tools"
    Invoke-WinGetInstall "Git.Git" "Git"
    Invoke-WinGetInstall "TortoiseGit.TortoiseGit" "TortoiseGit"
    Invoke-WinGetInstall "Microsoft.VisualStudioCode" "Visual Studio Code"
    Invoke-WinGetInstall "Microsoft.WindowsTerminal" "Windows Terminal"

    Refresh-EnvironmentVariables
}

function Install-RecordingSoftware {
    Write-SectionHeader "Installing Recording Software (Free Cam)"
    $freeCamUrl = "https://www.freescreenrecording.com/download/127159/free_cam_en_eu_8_7_0.msi"
    $freeCamInstaller = Join-Path ([Environment]::GetFolderPath('Desktop')) "free_cam.msi"
    try {
        Write-Host "Downloading Free Cam installer..."
        Invoke-WebRequest -Uri $freeCamUrl -OutFile $freeCamInstaller
        Write-Host "Installing Free Cam..."
        Start-Process msiexec -ArgumentList "/i `"$freeCamInstaller`" /qn" -Wait
        Write-Host "Free Cam installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download or install Free Cam."
    }
    finally {
        if (Test-Path $freeCamInstaller) {
            Write-Host "Cleaning up installer..."
            Remove-Item $freeCamInstaller -Force
        }
    }
}

function Configure-Git {
    Write-SectionHeader "Configuring Git Environment"
    try {
        Write-Host "Setting safe directories..."
        git config --global --add safe.directory "C:/Users/WDAGUtilityAccount/Desktop/Shared"
        git config --global --add safe.directory "*"
        
        Write-Host "Setting user name and email..."
        git config --global user.name "Angular Developer"
        git config --global user.email "developer@angular-tutorial.local"
        
        Write-Host "Git configured successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to configure Git. Please ensure Git is installed and in your PATH."
        return
    }
    
    try {
        Write-Host "`nTriggering Git authentication in a new terminal window..."
        Write-Host "Please complete any authentication prompts in the new window." -ForegroundColor Yellow
        Set-Location 'C:/Users/WDAGUtilityAccount/Desktop/Shared'; 
        Write-Host 'Attempting to push to remote to cache credentials...'; 
        git push
    }
    catch {
        Write-Host "Failed to open authentication window, but Git configuration was successful." -ForegroundColor Yellow
        Write-Host "You can manually run 'git push' later for authentication." -ForegroundColor Gray
    }
}

#endregion

#region Main Execution

# Execute all installation and configuration steps
Import-Certificates
Install-WinGet
Install-CoreDependencies
Install-DevTools

# Run Git configuration in new window with fresh environment after dev tools installation
Run-InNewWindow (Get-Command Configure-Git).Name

Install-RecordingSoftware

Write-SectionHeader "Installation Complete"
Write-Host "All setup tasks have been executed." -ForegroundColor Green
Write-Host "Please review any error messages above."
Write-Host "The script for setting up the Angular environment remains commented out." -ForegroundColor Yellow

# The following section for Angular development is commented out by default.
# Uncomment the lines below to install Node.js, Yarn, and the Angular CLI.

# function Install-AngularDevEnvironment {
#     Write-SectionHeader "Installing Angular Development Environment"
#     Invoke-WinGetInstall "OpenJS.NodeJS" "Node.js"
#
#     Write-Host "Waiting for Node.js installation and refreshing environment variables..."
#     Start-Sleep -Seconds 10
#     $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
#
#     Write-Host "Installing yarn..."
#     npm install -g yarn
#
#     Write-Host "Installing @angular/cli..."
#     npm install -g @angular/cli
#
#     Write-Host "Angular development environment setup is complete." -ForegroundColor Green
# }
#
# Install-AngularDevEnvironment

#endregion

