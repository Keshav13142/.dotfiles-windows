# Check if script is run with admin priviledges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Output "This script needs to be run as an Administrator. Attempting to relaunch."
  Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://gist.github.com/Keshav13142/ebf0cfae8335cbbc50e606462672cd80 | iex"
  break
}

$winget_pkgs = 
"7zip.7zip",
"ajeetdsouza.zoxide",
"AntibodySoftware.WizTree",
"Balena.Etcher",
"Bitwarden.Bitwarden",
"Brave.Brave",
"BurntSushi.ripgrep.MSVC",
"Chocolatey.ChocolateyGUI",
"EpicGames.EpicGamesLauncher",
"Espanso.Espanso",
"File-New-Project.EarTrumpet",
"Flameshot.Flameshot",
"GIMP.GIMP",
"Git.Git",
"Google.Drive",
"JesseDuffield.lazygit",
"junegunn.fzf",
"LibreWolf.LibreWolf",
"Microsoft.PowerShell",
"Microsoft.PowerToys",
"Microsoft.VisualStudioCode",
"Microsoft.WindowsTerminal",
"Neovim.Neovim",
"Notepad++.Notepad++",
"o2sh.onefetch",
"Obsidian.Obsidian",
"OBSProject.OBSStudio",
"OpenJS.NodeJS",
"Oracle.VirtualBox",
"Python.Python.3.12",
"qBittorrent.qBittorrent",
"Rufus.Rufus_Microsoft.Winget.Source_8wekyb3d8bbwe",
"Rustlang.Rust.MSVC",
"Schniz.fnm",
"sharkdp.bat",
"SomePythonThings.WingetUIStore",
"Starship.Starship",
"SyncTrayzor.SyncTrayzor",
"TechPowerUp.NVCleanstall",
"Twilio.Authy",
"Valve.Steam",
"VideoLAN.VLC",
"voidtools.Everything.Alpha",
"wez.wezterm",
"xanderfrangos.twinkletray"

$choco_pkgs =
"chocolateygui",
"lsd",
"make",
"mingw",
"winfetch"

# Setup winget
if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
  Write-Host "Winget Already Installed" -ForegroundColor Green 
}
else {
  Write-Host "Winget is not installed. Installing Winget...."
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

# Setup chocolatey
if ((Get-Command -Name choco -ErrorAction Ignore) -and (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion) {
  Write-Host "Chocolatey Already Installed" -ForegroundColor Green 
}
else {
  Write-Host "Chocolatey is not installed. Installing Winget...."
  Set-ExecutionPolicy Bypass -Scope Process -Force
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop 4>&1>$null
  powershell choco feature enable -n allowGlobalConfirmation 4>&1>$null

  Write-Host "Chocolatey installed!" -ForegroundColor Green 
}

# Install winget pkgs
Write-Host "Installing Winget packages"
foreach ($pkg in $winget_pkgs) {
  Write-Host "Installing $pkg"
  winget install --id=$pkg --source winget --exact --silent --accept-package-agreements 4>&1>$null 
}

# Install chocolatey pkgs
Write-Host "Installing Choco packages"
foreach ($pkg in $choco_pkgs) {
  Write-Host "Installing $pkg"
  choco install $pkg -y --limit-output 4>&1>$null
}

# Setup wsl
Write-Host "Setting up WSL"
wsl --install --no-distribution
wsl --set-default-version 2
wsl --install Ubuntu-22.04

Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

#Install Powershell modules
Install-Module PowerShellGet -Force -AllowClobberc
Install-Module PSReadLine -AllowPrerelease -Force
Install-Module -Name PSFzf