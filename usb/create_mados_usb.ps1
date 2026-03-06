# ==============================================================================
# MadOS ROG Edition - Preparateur de Cle USB Offline
# usb/create_mados_usb.ps1
# ==============================================================================
# Usage  : Lance via usb/create_mados_usb.bat (double-clic)
# Resultat : Cle USB "MADOS" prete a lancer l'installateur sans Internet
# Structure USB generee :
#   USB MADOS/
#   |-- start.sh            <- commande rapide
#   |-- LISEZ_MOI.txt
#   |-- logo.ico (cache)
#   |-- autorun.inf (cache)
#   +-- mados/
#       |-- install_local.sh
#       +-- modules/        <- 28 scripts
# ==============================================================================

$Host.UI.RawUI.WindowTitle = "MadOS USB Maker v3.2"

Clear-Host
Write-Host ""
Write-Host "  ===  MadOS ROG Edition - USB Maker  ===" -ForegroundColor Red
Write-Host "           by LordMadTrix  v3.2" -ForegroundColor White
Write-Host "  =======================================" -ForegroundColor Red
Write-Host ""

# --- Verification Admin ---
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$currentUser
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "  [ERREUR] Ce script doit etre lance en Administrateur !" -ForegroundColor Red
    Read-Host "`n  Appuyez sur Entree pour quitter"
    exit 1
}

# --- Dossier source : remonter d'un niveau (usb/ -> racine projet) ---
$UsbScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Split-Path -Parent $UsbScriptDir   # = racine du projet

Write-Host "  [INFO] Racine projet : $SourceDir" -ForegroundColor Cyan

# --- Verification fichiers sources ---
if (-not (Test-Path "$SourceDir\install_local.sh")) {
    Write-Host "  [ERREUR] install_local.sh introuvable dans $SourceDir" -ForegroundColor Red
    Read-Host "`n  Appuyez sur Entree pour quitter"
    exit 1
}
if (-not (Test-Path "$SourceDir\modules")) {
    Write-Host "  [ERREUR] Dossier modules/ introuvable" -ForegroundColor Red
    Read-Host "`n  Appuyez sur Entree pour quitter"
    exit 1
}

# ==============================================================================
# ETAPE 1 : Detection des cles USB
# ==============================================================================
Write-Host ""
Write-Host "  [1/4] Detection des cles USB connectees..." -ForegroundColor Yellow
Write-Host ""

$removableDrives = @(Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 })

if ($removableDrives.Count -eq 0) {
    Write-Host "  [ERREUR] Aucune cle USB detectee !" -ForegroundColor Red
    Read-Host "`n  Appuyez sur Entree pour quitter"
    exit 1
}

Write-Host "  Cles USB disponibles :" -ForegroundColor White
$i = 1
$driveList = @()
foreach ($drive in $removableDrives) {
    $sizeGB = [math]::Round([double]$drive.Size / 1GB, 1)
    $freeGB = [math]::Round([double]$drive.FreeSpace / 1GB, 1)
    $label = if ($drive.VolumeName) { $drive.VolumeName } else { "Sans nom" }
    Write-Host "    [$i] $($drive.DeviceID)  -  $label  ($sizeGB GB total, $freeGB GB libres)" -ForegroundColor Cyan
    $driveList += $drive.DeviceID
    $i++
}
Write-Host ""

$selection = Read-Host "  Numero de la cle USB cible (ou Q pour annuler)"
if ($selection -eq "Q" -or $selection -eq "q") { exit 0 }

$selIndex = 0
if (-not [int]::TryParse($selection, [ref]$selIndex)) {
    Write-Host "  [ERREUR] Entree invalide." -ForegroundColor Red
    Read-Host "  Appuyez sur Entree pour quitter"
    exit 1
}
$selIndex = $selIndex - 1
if ($selIndex -lt 0 -or $selIndex -ge $driveList.Count) {
    Write-Host "  [ERREUR] Selection invalide." -ForegroundColor Red
    Read-Host "  Appuyez sur Entree pour quitter"
    exit 1
}

$TargetDrive = $driveList[$selIndex]
Write-Host ""
Write-Host "  ATTENTION : Toutes les donnees sur $TargetDrive seront EFFACEES !" -ForegroundColor Red
$confirm = Read-Host "  Tapez MADOS pour confirmer le formatage"
if ($confirm -ne "MADOS") {
    Write-Host "  Annulation." -ForegroundColor Yellow
    exit 0
}

# ==============================================================================
# ETAPE 2 : Formatage FAT32
# ==============================================================================
Write-Host ""
Write-Host "  [2/4] Formatage de $TargetDrive en FAT32 (label: MADOS)..." -ForegroundColor Yellow

$diskLetter = $TargetDrive.TrimEnd(":")
try {
    Format-Volume -DriveLetter $diskLetter -FileSystem FAT32 -NewFileSystemLabel "MADOS" -Force -Confirm:$false | Out-Null
    Write-Host "  OK Formatage termine." -ForegroundColor Green
}
catch {
    Write-Host "  [ERREUR] Echec du formatage : $_" -ForegroundColor Red
    Read-Host "  Appuyez sur Entree pour quitter"
    exit 1
}

Start-Sleep -Seconds 2
$UsbRoot = "$TargetDrive\"
$UsbMados = "${UsbRoot}mados\"    # sous-dossier mados/ sur la cle

# ==============================================================================
# ETAPE 3 : Copie des fichiers (structure mados/)
# ==============================================================================
Write-Host ""
Write-Host "  [3/4] Copie des scripts MadOS sur la cle USB..." -ForegroundColor Yellow

# Creer la structure mados/modules/
if (-not (Test-Path $UsbMados)) { New-Item -ItemType Directory -Path $UsbMados | Out-Null }
$UsbModules = "${UsbMados}modules\"
if (-not (Test-Path $UsbModules)) { New-Item -ItemType Directory -Path $UsbModules | Out-Null }

# mados/install_local.sh
Write-Host "  -> mados/install_local.sh" -ForegroundColor Cyan
Copy-Item "$SourceDir\install_local.sh" "${UsbMados}install_local.sh" -Force

# mados/modules/  (28 scripts)
$moduleFiles = Get-ChildItem "$SourceDir\modules" -Filter "*.sh"
Write-Host "  -> mados/modules/ ($($moduleFiles.Count) scripts)" -ForegroundColor Cyan
Copy-Item "$SourceDir\modules\*.sh" $UsbModules -Force

# start.sh a la racine de la cle (commande rapide)
Write-Host "  -> start.sh (racine cle)" -ForegroundColor Cyan
Copy-Item "$UsbScriptDir\start.sh" "${UsbRoot}start.sh" -Force

# LISEZ_MOI.txt
Write-Host "  -> LISEZ_MOI.txt" -ForegroundColor Cyan
$readmeLines = @(
    "===========================================================",
    "    MadOS ROG Edition - Cle USB Offline  by LordMadTrix",
    "===========================================================",
    "",
    "UTILISATION :",
    "1. Installez Ubuntu Server 25.10 sur votre PC/Laptop ROG",
    "2. Au premier demarrage, connectez-vous",
    "3. Inserez cette cle USB",
    "4. Tapez :",
    '   bash /media/$USER/MADOS/start.sh',
    "",
    "   OU si root :",
    "   bash /media/root/MADOS/start.sh",
    "",
    "-----------------------------------------------------------",
    "STRUCTURE DE LA CLE :",
    "  start.sh       -> Lanceur (commande rapide)",
    "  mados/         -> Fichiers d'installation",
    "    install_local.sh",
    "    modules/     -> 28 scripts",
    "-----------------------------------------------------------",
    "GitHub : https://github.com/LordMadTrix/MadOS_ROG_Edition",
    "Site   : https://lordmadtrix.github.io/MadOS_ROG_Edition/"
)
$readmeLines | Out-File -FilePath "${UsbRoot}LISEZ_MOI.txt" -Encoding utf8 -Force

# ==============================================================================
# ETAPE 4 : Icone USB (logo.png -> .ico + autorun.inf)
# ==============================================================================
Write-Host ""
Write-Host "  [4/4] Configuration de l'icone MadOS..." -ForegroundColor Yellow

$logoPng = "$SourceDir\assets\logo.png"
$icoPath = "${UsbRoot}logo.ico"

if (Test-Path $logoPng) {
    try {
        Add-Type -AssemblyName System.Drawing

        $srcBitmap = [System.Drawing.Bitmap]::FromFile($logoPng)
        $dstBitmap = New-Object System.Drawing.Bitmap(256, 256)
        $g = [System.Drawing.Graphics]::FromImage($dstBitmap)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($srcBitmap, 0, 0, 256, 256)
        $g.Dispose()
        $srcBitmap.Dispose()

        $ms = New-Object System.IO.MemoryStream
        $dstBitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytes = $ms.ToArray()
        $ms.Close()
        $dstBitmap.Dispose()

        $fs = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
        $bw = New-Object System.IO.BinaryWriter($fs)
        $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)
        $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0)
        $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$pngBytes.Length)
        $bw.Write([uint32]22)
        $bw.Write($pngBytes)
        $bw.Close(); $fs.Close()

        try { (Get-Item $icoPath).Attributes = 'Hidden,System' } catch {}
        Write-Host "  OK logo.ico cree (256x256)" -ForegroundColor Green
    }
    catch {
        Write-Host "  [AVERT] Conversion ICO echouee : $_" -ForegroundColor Yellow
    }
}

$autorunPath = "${UsbRoot}autorun.inf"
"[autorun]`r`nlabel=MadOS ROG Edition`r`nicon=logo.ico" | Out-File -FilePath $autorunPath -Encoding ascii -Force
try { (Get-Item $autorunPath).Attributes = 'Hidden,System' } catch {}
Write-Host "  -> autorun.inf cree" -ForegroundColor Cyan

# ==============================================================================
# SUCCES
# ==============================================================================
Write-Host ""
Write-Host "  ===================================================" -ForegroundColor Green
Write-Host "           CLE USB MADOS PRETE !" -ForegroundColor Green
Write-Host "  ===================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Drive   : $TargetDrive (MADOS)" -ForegroundColor White
Write-Host "  Modules : $($moduleFiles.Count) scripts dans mados/modules/" -ForegroundColor White
Write-Host "  Icone   : logo.ico + autorun.inf" -ForegroundColor White
Write-Host ""
Write-Host "  Sous Ubuntu Server, tapez :" -ForegroundColor Yellow
Write-Host '  bash /media/$USER/MADOS/start.sh' -ForegroundColor Green
Write-Host ""
Read-Host "  Appuyez sur Entree pour fermer"
