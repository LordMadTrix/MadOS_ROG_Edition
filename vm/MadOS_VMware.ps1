<#
.SYNOPSIS
    MadOS 3.0 VMware Auto-VM - Deploiement et Lancement pour VMware Workstation/Player
    Version 3.5 - Gestion de la persistance (Demarrage vs Re-deploiement)
#>

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# --- CONFIGURATION ---
$VMName = "MadOS_3.0_AutoVM"
$VMPath = Join-Path $PSScriptRoot $VMName
$VmxPath = Join-Path $VMPath "$VMName.vmx"
$VmdkPath = Join-Path $VMPath "$VMName.vmdk"

# --- 1. DETECTION DE LA VM EXISTANTE ---
if (Test-Path $VmxPath) {
    Write-Host "`n[!] Une machine MadOS 3.0 a ete detectee dans le dossier." -ForegroundColor Yellow
    Write-Host "    1. DEMARRER la machine (Continuer ton travail)" -ForegroundColor Green
    Write-Host "    2. RE-DEPLOYER (TOUT EFFACER et recommencer l'install)" -ForegroundColor Red
    $ModeChoice = Read-Host "`nVotre choix (1 ou 2)"

    if ($ModeChoice -eq "1") {
        # --- MODE LANCEMENT DIRECT ---
        $VmRun = Join-Path $PSScriptRoot "VMwarePortable\vmrun.exe"
        if (-not (Test-Path $VmRun)) { $VmRun = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" }
        if (-not (Test-Path $VmRun)) { $VmRun = "C:\Program Files (x86)\VMware\VMware Player\vmrun.exe" }

        Write-Host "`n[🚀] RE-LANCEMENT DE LA MATRICE..." -ForegroundColor Cyan
        if (Test-Path $VmRun) {
            & $VmRun -T ws start "$VmxPath" gui
        }
        else {
            Write-Host "    [!] Appuyez sur Entree pour ouvrir le fichier .vmx..." -ForegroundColor Yellow
            Read-Host
            Start-Process "$VmxPath"
        }
        exit
    }
}

# --- 2. MODE INSTALLATION (Si on continue ici) ---
Write-Host "`n[?] Quelle version de la matrice voulez-vous deployer sur VMware ?" -ForegroundColor Cyan
Write-Host "    1. Ultra-Light  (ISO 100 Mo - Ubuntu 24.04 LTS)" -ForegroundColor White
Write-Host "    2. Full Experience (ISO 1.9 Go - Ubuntu 25.10 Questing)" -ForegroundColor White
$Choice = Read-Host "`nVotre choix (1 ou 2)"

if ($Choice -eq "1") {
    $IsoName = "ubuntu-24.04-mini-iso-amd64.iso"; $IsoUrl = "https://releases.ubuntu.com/noble/ubuntu-24.04-mini-iso-amd64.iso"
    $MinSize = 90MB
}
else {
    $IsoName = "ubuntu-25.10-live-server-amd64.iso"; $IsoUrl = "https://releases.ubuntu.com/25.10/$IsoName"
    $MinSize = 1.8GB
}
$IsoPath = Join-Path $PSScriptRoot $IsoName

# --- 3. VERIFICATION ISO ---
Write-Host "[!] Etape 1 : Verification de l'ISO..." -ForegroundColor Cyan
if (Test-Path $IsoPath) {
    if ((Get-Item $IsoPath).Length -lt $MinSize) { Remove-Item $IsoPath }
}
if (-not (Test-Path $IsoPath)) {
    Write-Host "    [?] Telechargement de l'ISO (patience)..." -ForegroundColor Yellow
    try { Start-BitsTransfer -Source $IsoUrl -Destination $IsoPath } catch { Invoke-WebRequest -Uri $IsoUrl -OutFile $IsoPath }
}

# --- 4. PREPARATION DU DOSSIER VM ---
if (Test-Path $VMPath) {
    Write-Host "    [!] Nettoyage de l'ancienne VM pour re-deploiement..." -ForegroundColor Red
    Remove-Item $VMPath -Recurse -Force -ErrorAction SilentlyContinue
    # Attendre que Windows libere les handles (VMware peut verrouiller le dossier)
    $retries = 0
    while ((Test-Path $VMPath) -and $retries -lt 10) {
        Start-Sleep -Milliseconds 500
        Remove-Item $VMPath -Recurse -Force -ErrorAction SilentlyContinue
        $retries++
    }
    if (Test-Path $VMPath) {
        Write-Host "    [ERREUR] Impossible de supprimer $VMPath" -ForegroundColor Red
        Write-Host "    => Fermez VMware Workstation completement et relancez." -ForegroundColor Yellow
        Read-Host "`n  Appuyez sur Entree pour quitter"
        exit 1
    }
}
New-Item -Path $VMPath -ItemType Directory | Out-Null

# --- 5. CREATION DU DISQUE VIRTUEL ---
Write-Host "[!] Etape 2 : Creation du disque virtuel (60GB)..." -ForegroundColor Cyan
$VDiskManager = Join-Path $PSScriptRoot "VMwarePortable\vmware-vdiskmanager.exe"
if (-not (Test-Path $VDiskManager)) { $VDiskManager = "C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe" }
if (-not (Test-Path $VDiskManager)) { $VDiskManager = "C:\Program Files (x86)\VMware\VMware Player\vmware-vdiskmanager.exe" }

if (Test-Path $VDiskManager) {
    & $VDiskManager -c -s 60GB -a lsilogic -t 0 "$VmdkPath"
}

# --- 6. GENERATION DU FICHIER VMX ---
Write-Host "[!] Etape 3 : Generation de la configuration VMware (.vmx)..." -ForegroundColor Cyan
$VmxContent = @(
    '.encoding = "windows-1252"',
    'config.version = "8"',
    'virtualHW.version = "21"',
    'mks.enable3d = "TRUE"',
    # Bridges PCIe necessaires (evite l erreur "Aucun emplacement PCIe")
    'pciBridge0.present = "TRUE"',
    'pciBridge4.present = "TRUE"',
    'pciBridge4.virtualDev = "pcieRootPort"',
    'pciBridge5.present = "TRUE"',
    'pciBridge5.virtualDev = "pcieRootPort"',
    'pciBridge6.present = "TRUE"',
    'pciBridge6.virtualDev = "pcieRootPort"',
    'pciBridge7.present = "TRUE"',
    'pciBridge7.virtualDev = "pcieRootPort"',
    'displayName = "MadOS 3.0 AutoVM"',
    'guestOS = "ubuntu-64"',
    'numvcpus = "8"',
    'cpuid.coresPerSocket = "4"',
    'memsize = "8192"',
    'scsi0.present = "TRUE"',
    'scsi0.virtualDev = "lsilogic"',
    'scsi0:0.present = "TRUE"',
    "scsi0:0.fileName = `"$VMName.vmdk`"",
    'ide1:0.present = "TRUE"',
    "ide1:0.fileName = `"$IsoPath`"",
    'ide1:0.deviceType = "cdrom-image"',
    # Carte reseau e1000e
    'ethernet0.present = "TRUE"',
    'ethernet0.connectionType = "nat"',
    'ethernet0.virtualDev = "e1000e"',
    
    # Controleur USB (necessaire pour brancher la cle USB MadOS)
    'usb.present = "TRUE"',
    'usb.generic.allowHID = "TRUE"',
    'usb_xhci.present = "TRUE"',
    'usb_xhci.pciSlotNumber = "192"',
    'usb.autoConnect.device0 = ""'
)
[System.IO.File]::WriteAllLines($VmxPath, $VmxContent)

# --- 7. LANCEMENT DE VMWARE ---
$VmRun = Join-Path $PSScriptRoot "VMwarePortable\vmrun.exe"
if (-not (Test-Path $VmRun)) { $VmRun = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" }
if (-not (Test-Path $VmRun)) { $VmRun = "C:\Program Files (x86)\VMware\VMware Player\vmrun.exe" }

Write-Host "`n[🚀] LANCEMENT DE VMWARE..." -ForegroundColor Red
if (Test-Path $VmRun) {
    & $VmRun -T ws start "$VmxPath" gui
}
else {
    Start-Process "$VmxPath"
}

Write-Host "`n[!] Script termine. Bonne installation !" -ForegroundColor Cyan
Read-Host "Appuyez sur Entree pour quitter..."
