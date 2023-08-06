# Check if script is run with admin priviledges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Output "This script needs to be run Administrator Priviledges."
  exit
}

# Setup winget
Function Install-Winget {
  if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
    Write-Host "Winget Already Installed" -ForegroundColor Green
  }
  else {
    Write-Host "Winget is not installed. Installing Winget...." -ForegroundColor Yellow
    $ErrorActionPreference = "Stop"
    $apiLatestUrl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Hide the progress bar of Invoke-WebRequest
    $ProgressPreference = 'SilentlyContinue'

    $desktopAppInstaller = @{
      fileName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
      url      = $(((Invoke-WebRequest $apiLatestUrl -UseBasicParsing | ConvertFrom-Json).assets | Where-Object { $_.name -match '^Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle$' }).browser_download_url)
    }

    $vcLibsUwp = @{
      fileName = 'Microsoft.VCLibs.x64.14.00.Desktop.appx'
      url      = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    }
    $uiLibs = @{
      nupkg = @{
        fileName = 'microsoft.ui.xaml.2.7.0.nupkg'
        url      = 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0'
      }
      uwp   = @{
        fileName = 'Microsoft.UI.Xaml.2.7.appx'
      }
    }
    $uiLibs.uwp.file = $PWD.Path + '\' + $uiLibs.uwp.fileName
    $uiLibs.uwp.zipPath = '*/x64/*/' + $uiLibs.uwp.fileName

    $dependencies = @($desktopAppInstaller, $vcLibsUwp, $uiLibs.nupkg)

    foreach ($dependency in $dependencies) {
      $dependency.file = $dependency.fileName
      Invoke-WebRequest $dependency.url -OutFile $dependency.file
    }

    $uiLibs.nupkg.file = $PWD.Path + '\' + $uiLibs.nupkg.fileName
    Add-Type -Assembly System.IO.Compression.FileSystem
    $uiLibs.nupkg.zip = [IO.Compression.ZipFile]::OpenRead($uiLibs.nupkg.file)
    $uiLibs.nupkg.zipUwp = $uiLibs.nupkg.zip.Entries | Where-Object { $_.FullName -like $uiLibs.uwp.zipPath }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($uiLibs.nupkg.zipUwp, $uiLibs.uwp.file, $true)
    $uiLibs.nupkg.zip.Dispose()

    Add-AppxPackage -Path $desktopAppInstaller.file -DependencyPath $vcLibsUwp.file, $uiLibs.uwp.file

    Remove-Item $desktopAppInstaller.file
    Remove-Item $vcLibsUwp.file
    Remove-Item $uiLibs.nupkg.file
    Remove-Item $uiLibs.uwp.file

    Write-Host "WinGet installed!" -ForegroundColor Green
  }
}

# Setup chocolatey
Function Install-Choco {
  if ((Get-Command -Name choco -ErrorAction Ignore) -and (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion) {
    Write-Host "Chocolatey Already Installed" -ForegroundColor Green
  }
  else {
    Write-Host "Chocolatey is not installed. Installing Winget...." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop 4>&1>$null
    powershell choco feature enable -n allowGlobalConfirmation 4>&1>$null

    Write-Host "Chocolatey installed!" -ForegroundColor Green
  }
}

Function Install-PwshModules {
  Write-Host "#### Installing PowerShell Modules ####" -ForegroundColor Yellow
  Write-Host "Installing PowerShellGet.."-ForegroundColor Cyan
  Install-Module PowerShellGet -Force -AllowClobber
  Write-Host "Installing PSReadLine.." -ForegroundColor Cyan
  Install-Module PSReadLine -AllowPrerelease -Force
  Write-Host "Installing PSFzf.." -ForegroundColor Cyan
  Install-Module -Name PSFzf -Force
  Write-Host "Installing PSDotFiles.." -ForegroundColor Cyan
  Install-Module -Name PSDotFiles -Force
}

Function Install-Wsl {
  Write-Host "#### Setting up WSL ####" -ForegroundColor Yellow
  If (Get-Command -Name wsl -ErrorAction Ignore) {
    Write-Host "WSL is already installed..." -ForegroundColor Green
  }
  Else {
    wsl --install --no-distribution 4>&1>$null
  }
  wsl --set-default-version 2 4>&1>$null
  If ((wsl -l -v) -replace "`0" | Select-String -Pattern "Ubuntu-22.04") {
    Write-Host "Ubuntu 22.04 already installed..." -ForegroundColor Green
  }
  Else {
    Write-Host "Installing Ubuntu 22.04.." -ForegroundColor Cyan
    wsl --install Ubuntu-22.04 4>&1>$null
  }
}

Function Write-Pkg ($name) {
  Write-Host "Installing $($name.split(".")[1]) ..." -ForegroundColor Cyan
}

Function Install-Pkgs ($obj) {
  if (!$obj) {
    Write-Host "Invalid selection" -ForegroundColor red
    return
  }
  Write-Host "#### Installing $($obj.Type) ####" -ForegroundColor Yellow
  if ($obj.Winget) {
    foreach ($pkg in $obj.Winget) {
      Write-Pkg($pkg)
      winget install --id=$pkg --source winget --exact --silent --accept-package-agreements 4>&1>$null
    }
  }
  if ($obj.Choco) {
    foreach ($pkg in $obj.Choco) {
      Write-Host "Installing $pkg ..." -ForegroundColor Cyan
      choco install $pkg -y --limit-output 4>&1>$null
    }
  }
  Write-Host ""
}

$pkgs =
[PSCustomObject]@{
  Type   = "Essentials"
  Winget =
  "7zip.7zip",
  "AutoHotkey.AutoHotkey",
  "Bitwarden.Bitwarden",
  "Brave.Brave",
  "Espanso.Espanso",
  "File-New-Project.EarTrumpet",
  "Flameshot.Flameshot",
  "Google.Drive",
  "Microsoft.PowerToys",
  "Notepad++.Notepad++",
  "Obsidian.Obsidian",
  "OBSProject.OBSStudio",
  "SyncTrayzor.SyncTrayzor",
  "TechPowerUp.NVCleanstall",
  "Twilio.Authy",
  "VideoLAN.VLC",
  "voidtools.Everything.Alpha",
  "xanderfrangos.twinkletray"
},
[PSCustomObject]@{
  Type   = "Utils"
  Winget =
  "AntibodySoftware.WizTree",
  "Balena.Etcher",
  "BleachBit.BleachBit",
  "code52.Carnac", # Screen key
  "CPUID.CPU-Z",
  "CPUID.HWMonitor",
  "geeksoftwareGmbH.PDF24Creator",
  "GIMP.GIMP",
  "Oracle.VirtualBox",
  "qBittorrent.qBittorrent",
  "Rufus.Rufus_Microsoft.Winget.Source_8wekyb3d8bbwe",
  "Wagnardsoft.DisplayDriverUninstaller"
},
[PSCustomObject]@{
  Type   = "Dev Packages"
  Winget =
  "Git.Git",
  "GoLang.Go",
  "JesseDuffield.lazygit",
  "Microsoft.PowerShell",
  "Microsoft.VisualStudioCode",
  "Microsoft.WindowsTerminal",
  "Neovim.Neovim",
  "OpenJS.NodeJS",
  "Python.Python.3.12",
  "Rustlang.Rust.MSVC",
  "Schniz.fnm",
  "wez.wezterm"
  Choco  =
  "make",
  "mingw"
},
[PSCustomObject]@{
  Type   = "CLI Packages"
  Winget =
  "ajeetdsouza.zoxide",
  "BurntSushi.ripgrep.MSVC",
  "junegunn.fzf",
  "o2sh.onefetch",
  "sharkdp.bat",
  "sharkdp.fd",
  "Starship.Starship"
  Choco  =
  "lsd",
  "winfetch"
},
[PSCustomObject]@{
  Type   = "Gaming Packges"
  Winget =
  "EpicGames.EpicGamesLauncher",
  "Valve.Steam"
}

# Check if Package managers are installed
Install-Choco
Install-Winget

Write-Host "
Choose what to install
1. Essentials
2. Utils
3. Dev
4. CLI
5. Gaming
6. PowerShell Modules
7. Install WSL
0. (ALL)

" -ForegroundColor Blue
$selected = Read-Host "Enter Choice (eg: 1,2) "
Write-Host ""

If ($selected -eq "") {
  Write-Host "Invalid Option" -ForegroundColor Red
}
ElseIf ($selected.Length -gt 1) {
  $selected = $selected.split(",")
  ForEach ($i in $selected) {
    If ($i -eq 6) {
      Install-PwshModules
    }
    Else {
      Install-Pkgs($pkgs[$i - 1])
    }
  }
}
Else {
  switch ($selected) {
    0 {
      ForEach ($obj in $pkgs) {
        Install-Pkgs($obj)
      }
      Install-PwshModules
      Install-Wsl
    }
    6 {
      Install-PwshModules
    }
    7 {
      Install-Wsl
    }
    Default {
      Install-Pkgs($pkgs[$selected - 1])
    }
  }
}
