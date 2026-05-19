# psmux installation script for Windows
# Safe usage: download to a local file first, then run it.
#   Invoke-WebRequest -Uri https://raw.githubusercontent.com/psmux/psmux/master/scripts/install.ps1 -OutFile install-psmux.ps1
#   powershell -ExecutionPolicy Bypass -File install-psmux.ps1
#   Remove-Item install-psmux.ps1
# Or locally: .\scripts\install.ps1

param(
    [string]$InstallDir = "$env:LOCALAPPDATA\psmux",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "psmux installer" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

# Determine if we're installing from local build or downloading
# When run via iex, $PSScriptRoot is empty
$LocalBuild = $false
if ($PSScriptRoot -and (Test-Path "$PSScriptRoot\..\target\release\psmux.exe")) {
    $LocalBuild = $true
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}

if ($LocalBuild) {
    Write-Host "Installing from local build..." -ForegroundColor Yellow
    $SourceDir = "$RepoRoot\target\release"
} else {
    Write-Host "Downloading latest release..." -ForegroundColor Yellow
    
    # Detect architecture using PROCESSOR_ARCHITECTURE env var
    # (RuntimeInformation::OSArchitecture returns $null in PS 5.1 when piped via iex)
    $arch = $env:PROCESSOR_ARCHITECTURE
    # WoW64 correction: 32-bit process on 64-bit OS reports x86; use the real OS arch
    if ($arch -eq "x86" -and $env:PROCESSOR_ARCHITEW6432) {
        $arch = $env:PROCESSOR_ARCHITEW6432
    }
    switch ($arch) {
        "AMD64" { $archLabel = "x64";   $assetPattern = "windows-x64" }
        "x86"   { $archLabel = "x86";   $assetPattern = "windows-x86" }
        "ARM64" { $archLabel = "arm64"; $assetPattern = "windows-arm64" }
        default {
            Write-Host "Unsupported architecture: $arch" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "Detected architecture: $archLabel" -ForegroundColor Cyan
    
    # Get latest release info
    $ReleasesUrl = "https://api.github.com/repos/psmux/psmux/releases/latest"
    try {
        $Release = Invoke-RestMethod -Uri $ReleasesUrl -Headers @{ "User-Agent" = "psmux-installer" }
        $Asset = $Release.assets | Where-Object { $_.name -match "$assetPattern.*zip" } | Select-Object -First 1
        
        # Fallback: if no arch-specific asset, try x64 (Windows on ARM can run x64 via emulation)
        if (-not $Asset -and $archLabel -eq "arm64") {
            Write-Host "No ARM64 build found, falling back to x64 (runs via emulation)..." -ForegroundColor Yellow
            $Asset = $Release.assets | Where-Object { $_.name -match "windows-x64.*zip" } | Select-Object -First 1
        }
        
        if (-not $Asset) {
            throw "No compatible release asset found for $archLabel"
        }
        
        $DownloadUrl = $Asset.browser_download_url
        $AssetName = $Asset.name

        # Use a randomized temp directory to avoid predictable path races
        $TempDir     = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
        $TempZip     = Join-Path $TempDir "psmux-download.zip"
        $TempExtract = Join-Path $TempDir "extract"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

        # Download SHA256SUMS manifest for verification
        $checksumUrl = "https://github.com/psmux/psmux/releases/download/$($Release.tag_name)/SHA256SUMS.txt"
        $sumFile = Join-Path $TempDir "SHA256SUMS.txt"
        $expectedHash = $null
        try {
            Invoke-WebRequest -Uri $checksumUrl -OutFile $sumFile -ErrorAction Stop
            # Parse SHA256SUMS.txt: lines of "<hash>  <path>" or "<hash> *<path>"
            foreach ($line in (Get-Content $sumFile)) {
                $parts = $line -split '\s+\*?', 2
                if ($parts.Length -eq 2 -and $parts[1] -like "*$AssetName*") {
                    $expectedHash = $parts[0].ToUpper()
                    break
                }
            }
        } catch {
            Write-Host "  Note: Could not download checksum manifest ($($_.Exception.Message))" -ForegroundColor Yellow
            Write-Host "  Proceeding without integrity verification." -ForegroundColor Yellow
        }

        Write-Host "Downloading from: $DownloadUrl"
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

        # Verify hash if we obtained one from the manifest
        if ($expectedHash) {
            $actualHash = (Get-FileHash $TempZip -Algorithm SHA256).Hash.ToUpper()
            if ($actualHash -ne $expectedHash) {
                Write-Host "SHA256 mismatch for $AssetName!" -ForegroundColor Red
                Write-Host "  Expected: $expectedHash" -ForegroundColor Red
                Write-Host "  Got:      $actualHash" -ForegroundColor Red
                Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
                exit 1
            }
            Write-Host "  SHA256 verified OK" -ForegroundColor Green
        }

        # Extract
        Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force

        $SourceDir = $TempExtract
        
    } catch {
        Write-Host "Error downloading release: $_" -ForegroundColor Red
        Write-Host "Try installing from a local build instead:" -ForegroundColor Yellow
        Write-Host "  cargo build --release" -ForegroundColor White
        Write-Host "  .\scripts\install.ps1" -ForegroundColor White
        exit 1
    }
}

# Create install directory
if (-not (Test-Path $InstallDir)) {
    Write-Host "Creating install directory: $InstallDir"
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Copy binaries
$Binaries = @("psmux.exe", "pmux.exe", "tmux.exe")
foreach ($bin in $Binaries) {
    $src = Join-Path $SourceDir $bin
    $dst = Join-Path $InstallDir $bin
    
    if (Test-Path $src) {
        Write-Host "  Installing $bin..." -ForegroundColor Green
        Copy-Item -Path $src -Destination $dst -Force
    } else {
        Write-Host "  Warning: $bin not found" -ForegroundColor Yellow
    }
}

# Add to PATH if not already there
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$InstallDir*") {
    Write-Host "Adding to PATH..." -ForegroundColor Green
    $NewPath = "$UserPath;$InstallDir"
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    $env:Path = "$env:Path;$InstallDir"
    Write-Host "  Added $InstallDir to user PATH" -ForegroundColor Green
} else {
    Write-Host "Already in PATH" -ForegroundColor Gray
}

# Cleanup temp files if downloaded
if (-not $LocalBuild) {
    if (Test-Path $TempDir) { Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now use:" -ForegroundColor Cyan
Write-Host "  psmux    - Start/attach to terminal multiplexer"
Write-Host "  pmux     - Alias for psmux"  
Write-Host "  tmux     - tmux-compatible alias"
Write-Host ""
Write-Host "Quick start:" -ForegroundColor Cyan
Write-Host "  psmux                    # Start new session or attach to 'default'"
Write-Host "  psmux new -s mysession   # Create named session"
Write-Host "  psmux ls                 # List sessions"
Write-Host "  psmux attach -t name     # Attach to session"
Write-Host ""
Write-Host "Note: Restart your terminal or run:" -ForegroundColor Yellow
Write-Host '  $env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + [Environment]::GetEnvironmentVariable("Path", "Machine")'
