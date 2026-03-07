<#
.SYNOPSIS
    MadOS 3.0 QEMU Portable - Solution 100% Utilisateur (Sans droits Admin requit)
    Version 1.0 - Emulation matérielle et partage de dossier USB Natif
#>

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# --- CONFIGURATION ---
$VMName = "MadOS_3.0_QemuVM"
$VMPath = Join-Path $PSScriptRoot $VMName
$DiskPath = Join-Path $VMPath "$VMName.qcow2"
$UsbFolderPath = Resolve-Path (Join-Path $PSScriptRoot "..\usb") | Select-Object -ExpandProperty Path

# --- 1. LOCALISATION DE QEMU ---
$QemuDir = Join-Path $PSScriptRoot "QemuPortable"
$QemuExe = Join-Path $QemuDir "qemu-system-x86_64.exe"
$QemuImg = Join-Path $QemuDir "qemu-img.exe"

# Fallback si Qemu n'est pas dans le dossier portable
if (-not (Test-Path $QemuExe)) {
    $QemuExe = "C:\Program Files\qemu\qemu-system-x86_64.exe"
    $QemuImg = "C:\Program Files\qemu\qemu-img.exe"
}

if (-not (Test-Path $QemuExe)) {
    Write-Host "`n[ERREUR] QEMU n'est pas installe ou introuvable." -ForegroundColor Red
    Write-Host "Veuillez telecharger QEMU pour Windows (setup officiel) et :" -ForegroundColor Yellow
    Write-Host "1. Soit l'installer normalement sur votre PC." -ForegroundColor Yellow
    Write-Host "2. Soit extraire ses fichiers dans le dossier : $QemuDir" -ForegroundColor Yellow
    Read-Host "`nAppuyez sur Entree pour quitter..."
    exit 1
}

# --- 2. CHOIX DE L'ISO ---
Write-Host "`n[?] Quelle version de la matrice voulez-vous deployer sur QEMU ?" -ForegroundColor Cyan
Write-Host "    1. Ultra-Light  (ISO 100 Mo - Ubuntu 24.04 LTS)" -ForegroundColor White
Write-Host "    2. Full Experience (ISO 1.9 Go - Ubuntu 25.10 Questing)" -ForegroundColor White
$Choice = Read-Host "`nVotre choix (1 ou 2)"

if ($Choice -eq "1") {
    $IsoName = "ubuntu-24.04-mini-iso-amd64.iso"
    $IsoUrl = "https://releases.ubuntu.com/noble/ubuntu-24.04-mini-iso-amd64.iso"
    $MinSize = 90MB
}
else {
    $IsoName = "ubuntu-25.10-live-server-amd64.iso"
    $IsoUrl = "https://releases.ubuntu.com/25.10/$IsoName"
    $MinSize = 1.8GB
}
$IsoPath = Join-Path $PSScriptRoot $IsoName

# --- 3. TELECHARGEMENT DE L'ISO ---
Write-Host "`n[!] Etape 1 : Verification de l'ISO..." -ForegroundColor Cyan
if (Test-Path $IsoPath) {
    if ((Get-Item $IsoPath).Length -lt $MinSize) { Remove-Item $IsoPath }
}
if (-not (Test-Path $IsoPath)) {
    Write-Host "    [?] Telechargement de l'ISO en cours..." -ForegroundColor Yellow
    try { Start-BitsTransfer -Source $IsoUrl -Destination $IsoPath } catch { Invoke-WebRequest -Uri $IsoUrl -OutFile $IsoPath }
}

# --- 4. PREPARATION DU DISQUE VIRTUEL ---
Write-Host "`n[!] Etape 2 : Verification du disque virtuel QCOW2..." -ForegroundColor Cyan
if (-not (Test-Path $VMPath)) {
    New-Item -Path $VMPath -ItemType Directory | Out-Null
}

if (-not (Test-Path $DiskPath)) {
    Write-Host "    [+] Creation du disque virtuel de 60 Go..." -ForegroundColor Green
    & $QemuImg create -f qcow2 "$DiskPath" 60G
}
else {
    Write-Host "    [*] Un disque virtuel existant a ete trouve. Il sera utilise." -ForegroundColor Yellow
    Write-Host "    Pour repartir de zero, supprimez le dossier $VMName" -ForegroundColor DarkGray
}

# --- 5. LANCEMENT DE LA VM QEMU ---
Write-Host "`n[🚀] LANCEMENT DE LA MATRICE QEMU (MADOS)..." -ForegroundColor Red
Write-Host "INFO : Le dossier 'usb' de votre projet est directement partage" -ForegroundColor Cyan
Write-Host "       avec la VM comme s'il s'agissait d'une vraie cle USB !" -ForegroundColor Cyan

# Configuration de QEMU : accelerate WHPX (natif Windows) ou TCG (emulation)
$QemuArgs = @(
    "-name", "MadOS_3.0_Portable",
    "-m", "8G",
    "-smp", "cores=4,threads=2",
    "-machine", "q35",
    "-accel", "whpx,kernel-irqchip=off",
    "-accel", "tcg",             # Fallback si whpx n'est pas actif
    "-vga", "virtio",            # GPU virtuel basique
    "-display", "gtk,gl=off",    # Interface graphique standard
    "-netdev", "user,id=n1",     # Reseau 100% utilisateur (NAT) sans driver
    "-device", "e1000,netdev=n1",
    "-drive", "file=$DiskPath,format=qcow2,if=virtio", # Disque dur principal SSD
    "-cdrom", "$IsoPath",        # L'ISO d'insallation
    
    # Controleur USB virtuel
    "-device", "qemu-xhci,id=usb",
    
    # Partage du dossier physique "usb" comme une cle USB FAT rw
    "-drive", "file=fat:rw:$UsbFolderPath,format=raw,if=none,id=usbdrive",
    "-device", "usb-storage,bus=usb.0,drive=usbdrive"
)

Write-Host "`nCommande a l'execution :" -ForegroundColor DarkGray
Write-Host "$QemuExe $QemuArgs" -ForegroundColor DarkGray

& $QemuExe $QemuArgs

Write-Host "`n[!] Session QEMU terminee." -ForegroundColor Green
Read-Host "Appuyez sur Entree pour quitter..."
