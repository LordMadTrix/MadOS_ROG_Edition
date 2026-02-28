import sys
import subprocess
import threading
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                             QHBoxLayout, QPushButton, QLabel, QTabWidget, 
                             QMessageBox, QTextEdit, QProgressBar, QFrame)
from PyQt6.QtGui import QFont, QColor, QPalette
from PyQt6.QtCore import Qt, QTimer, pyqtSignal, QObject

# ── Signal helper pour thread-safe UI updates ──────────────────────────────
class Worker(QObject):
    finished = pyqtSignal(str, bool)  # output, success

class MadOSControlCenter(QMainWindow):
    log_signal = pyqtSignal(str)  # Thread-safe log updates
    def __init__(self):
        super().__init__()
        self.setWindowTitle("MadOS ROG Edition — Centre de Contrôle")
        self.setMinimumSize(720, 560)
        self.apply_theme()
        
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setSpacing(0)
        root.setContentsMargins(0, 0, 0, 0)
        
        # Header
        hdr = QLabel("  🔴  MAD OS ROG — CENTRE DE CONTRÔLE")
        hdr.setStyleSheet("background:#0d0d0d; color:#ff1a1a; font-size:18px;"
                          "font-weight:bold; padding:14px; letter-spacing:2px;")
        root.addWidget(hdr)

        # Status bar (OpenClaw)
        self.status_bar = QLabel("  ⏳ Vérification du service OpenClaw...")
        self.status_bar.setStyleSheet("background:#111; color:#aaa; padding:6px; font-size:12px;")
        root.addWidget(self.status_bar)

        # Tabs
        self.tabs = QTabWidget()
        self.tabs.setStyleSheet("""
            QTabWidget::pane { border: none; background: #141414; }
            QTabBar::tab { background:#1a1a1a; color:#ccc; padding:10px 18px; font-size:13px; }
            QTabBar::tab:selected { background:#cc0000; color:white; font-weight:bold; }
            QTabBar::tab:hover { background:#2a2a2a; }
        """)
        root.addWidget(self.tabs)

        # Log output
        self.log = QTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(120)
        self.log.setStyleSheet("background:#0a0a0a; color:#00ff00; font-family:monospace;"
                               "font-size:11px; border-top:1px solid #300;")
        root.addWidget(self.log)

        # Build tabs
        self.tabs.addTab(self._tab_perf(),   "⚡  Performance")
        self.tabs.addTab(self._tab_ai(),     "🤖  OpenClaw IA")
        self.tabs.addTab(self._tab_sys(),    "🧹  Système")
        self.tabs.addTab(self._tab_diag(),   "🏥  Diagnostic")
        self.tabs.addTab(self._tab_update(), "🔄  Mise à jour")
        self.tabs.addTab(self._tab_vr(),     "🥽  VR & Casque")

        self.log_signal.connect(self._append_log)

        # Refresh OpenClaw status every 5s
        self._refresh_claw_status()
        self.timer = QTimer(self)
        self.timer.timeout.connect(self._refresh_claw_status)
        self.timer.start(5000)

    # ── Theme ────────────────────────────────────────────────────────────────
    def apply_theme(self):
        p = QPalette()
        p.setColor(QPalette.ColorRole.Window,          QColor(20, 20, 20))
        p.setColor(QPalette.ColorRole.WindowText,      Qt.GlobalColor.white)
        p.setColor(QPalette.ColorRole.Base,            QColor(28, 28, 28))
        p.setColor(QPalette.ColorRole.Button,          QColor(40, 40, 40))
        p.setColor(QPalette.ColorRole.ButtonText,      Qt.GlobalColor.white)
        p.setColor(QPalette.ColorRole.Highlight,       QColor(200, 0, 0))
        p.setColor(QPalette.ColorRole.HighlightedText, Qt.GlobalColor.white)
        self.setPalette(p)

    # ── Helpers ──────────────────────────────────────────────────────────────
    def _btn(self, text, cmd, color="#cc0000", async_run=False):
        b = QPushButton(text)
        b.setFixedHeight(46)
        b.setStyleSheet(f"""
            QPushButton {{ background:{color}; color:white; font-weight:bold;
                           border-radius:6px; font-size:13px; }}
            QPushButton:hover {{ background:#ff3333; }}
            QPushButton:pressed {{ background:#990000; }}
        """)
        if callable(cmd):
            b.clicked.connect(cmd)
        elif async_run:
            b.clicked.connect(lambda: self._run_async(cmd))
        else:
            b.clicked.connect(lambda: self._run(cmd))
        return b

    def _label(self, text):
        l = QLabel(text)
        l.setStyleSheet("color:#888; font-size:12px; margin-top:10px; margin-bottom:4px;")
        return l

    def _separator(self):
        f = QFrame()
        f.setFrameShape(QFrame.Shape.HLine)
        f.setStyleSheet("color:#2a2a2a;")
        return f

    def _append_log(self, html):
        """Toujours appelé depuis le thread principal via signal."""
        self.log.append(html)
        sb = self.log.verticalScrollBar()
        sb.setValue(sb.maximum())

    def _run(self, cmd):
        """Lance cmd en arrière-plan (jamais bloquant)."""
        self._run_async(cmd)

    def _run_async(self, cmd):
        self.log_signal.emit(f"<span style='color:#ff6600'>$ {cmd}</span>")
        def _worker():
            try:
                out = subprocess.check_output(
                    cmd, shell=True, stderr=subprocess.STDOUT, text=True, timeout=30)
                self.log_signal.emit(
                    f"<span style='color:#00ff00'>{out.strip()[:3000]}</span>")
            except subprocess.TimeoutExpired:
                self.log_signal.emit(
                    "<span style='color:#ffaa00'>⚠ Timeout (30s)</span>")
            except subprocess.CalledProcessError as e:
                self.log_signal.emit(
                    f"<span style='color:#ff4444'>ERREUR: {(e.output or '').strip()[:2000]}</span>")
        threading.Thread(target=_worker, daemon=True).start()

    def _open_terminal(self, cmd):
        """Lance une commande dans le bon terminal (KDE=konsole, sinon xterm)."""
        for term in ["konsole -e", "xfce4-terminal -e", "gnome-terminal --", "xterm -e", "x-terminal-emulator -e"]:
            term_bin = term.split()[0]
            if subprocess.run(f"which {term_bin}", shell=True,
                              capture_output=True).returncode == 0:
                full = f"{term} bash -c '{cmd}'"
                subprocess.Popen(full, shell=True)
                return
        self.log_signal.emit("<span style='color:#ff4444'>ERREUR: Aucun terminal trouvé (konsole/xterm/x-terminal-emulator)</span>")

    def _open_url_if_active(self):
        """Ouvre l'interface web OpenClaw seulement si le service est actif."""
        r = subprocess.run("systemctl --user is-active openclaw.service",
                           shell=True, capture_output=True, text=True)
        if r.stdout.strip() == "active":
            log_query = subprocess.run(
                "journalctl --user -u openclaw.service --no-pager | grep '?token=' | tail -n 1",
                shell=True, capture_output=True, text=True
            )
            url_line = log_query.stdout.strip()
            url = "http://localhost:18789"
            
            import re
            match = re.search(r'(https?://[^\s\x1b]+)', url_line)
            if match:
                url = match.group(1)
            
            subprocess.Popen(["xdg-open", url])
        else:
            self.log_signal.emit(
                "<span style='color:#ffaa00'>⚠ OpenClaw est arrêté. Démarrez le moteur d'abord (bouton vert).</span>")

    def _refresh_claw_status(self):
        try:
            r = subprocess.run("systemctl --user is-active openclaw.service",
                               shell=True, capture_output=True, text=True)
            status = r.stdout.strip()
            if status == "active":
                self.status_bar.setText("  ✅  OpenClaw IA : ACTIF  •  Port 18789")
                self.status_bar.setStyleSheet("background:#0d2a0d; color:#00ff88; padding:6px; font-size:12px;")
            elif status == "activating":
                self.status_bar.setText("  ⏳  OpenClaw IA : Démarrage en cours...")
                self.status_bar.setStyleSheet("background:#1a1500; color:#ffcc00; padding:6px; font-size:12px;")
            else:
                self.status_bar.setText(f"  🔴  OpenClaw IA : {status.upper()}  (onglet IA pour démarrer)")
                self.status_bar.setStyleSheet("background:#2a0000; color:#ff4444; padding:6px; font-size:12px;")
        except Exception:
            pass

    # ── Onglet Performances ───────────────────────────────────────────────────
    def _tab_perf(self):
        w = QWidget(); lay = QVBoxLayout(w); lay.setSpacing(8); lay.setContentsMargins(16,16,16,16)
        lay.addWidget(self._label("PROFIL CPU / BATTERIE (asusctl)"))
        lay.addWidget(self._btn("🔇  Mode Silencieux (autonomie max)", "asusctl profile -P Quiet", "#2e7d32"))
        lay.addWidget(self._btn("⚖️  Mode Équilibré", "asusctl profile -P Balanced", "#b8690a"))
        lay.addWidget(self._btn("🔥  Mode Turbo Performance (GAMING)", "asusctl profile -P Performance"))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("GPU (supergfxctl)"))
        lay.addWidget(self._btn("🌿  GPU Intégré — Mode Éco (Batterie)", "supergfxctl -m Integrated", "#2e7d32"))
        lay.addWidget(self._btn("🎮  GPU Dédié NVIDIA/AMD — Mode Gaming", "supergfxctl -m Dedicated"))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("VENTILATEURS (asusctl)"))
        lay.addWidget(self._btn("🌬️  Courbe Fan Auto ROG", "asusctl fan-curve -m Auto"))
        lay.addStretch()
        return w

    # ── Onglet OpenClaw ───────────────────────────────────────────────────────
    def _tab_ai(self):
        w = QWidget(); lay = QVBoxLayout(w); lay.setSpacing(8); lay.setContentsMargins(16,16,16,16)
        lay.addWidget(self._label("CONTRÔLE DU SERVICE"))
        lay.addWidget(self._btn("▶  Démarrer le Moteur IA (Gateway)",
                                "systemctl --user start openclaw.service", "#2e7d32"))
        lay.addWidget(self._btn("🔁  Redémarrer le Moteur IA",
                                "systemctl --user restart openclaw.service", "#b8690a"))
        lay.addWidget(self._btn("⏹  Arrêter le Moteur IA",
                                "systemctl --user stop openclaw.service", "#555"))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("INTERFACE"))
        lay.addWidget(self._btn("💬  Ouvrir l'interface Web Chat (localhost:18789)",
                                self._open_url_if_active, "#0055cc"))
        lay.addWidget(self._btn("🖥️  Lancer le TUI OpenClaw (Terminal)",
                                "x-terminal-emulator -e bash -c 'cd ~/OpenClaw && node scripts/run-node.mjs tui; read'",
                                "#005599"))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("DIAGNOSTIC SERVICE"))
        lay.addWidget(self._btn("📋  Voir les logs du service",
                                "journalctl --user -u openclaw.service -n 40 --no-pager", "#333",
                                async_run=True))
        lay.addStretch()
        return w

    # ── Onglet Système ────────────────────────────────────────────────────────
    def _tab_sys(self):
        w = QWidget(); lay = QVBoxLayout(w); lay.setSpacing(8); lay.setContentsMargins(16,16,16,16)
        lay.addWidget(self._label("MÉMOIRE & STOCKAGE"))
        lay.addWidget(self._btn("🗑️  Purger le Cache RAM",
                                "pkexec bash -c 'sync; echo 3 > /proc/sys/vm/drop_caches'", "#555"))
        lay.addWidget(self._btn("✂️  Forcer le TRIM NVMe/SSD",
                                "pkexec fstrim -av", "#555"))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("RÉSEAU"))
        lay.addWidget(self._btn("🔁  Redémarrer NetworkManager",
                                "pkexec systemctl restart NetworkManager", "#333"))
        lay.addWidget(self._btn("📡  Afficher l'IP et interfaces",
                                "ip addr show", "#333", async_run=True))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("NETTOYAGE"))
        lay.addWidget(self._btn("🧹  Nettoyer paquets inutiles (autoremove)",
                                "x-terminal-emulator -e bash -c 'sudo apt autoremove -y; read'"))
        lay.addStretch()
        return w

    # ── Onglet Diagnostic ─────────────────────────────────────────────────────
    def _tab_diag(self):
        w = QWidget(); lay = QVBoxLayout(w); lay.setSpacing(8); lay.setContentsMargins(16,16,16,16)
        lay.addWidget(self._label("DIAGNOSTIC SYSTÈME COMPLET"))
        lay.addWidget(self._btn("🏥  Lancer le Diagnostic de Santé MadOS",
                                "wget -qO /tmp/mados_diag.sh "
                                "https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/modules/25_sante_systeme.sh "
                                "&& konsole -e bash /tmp/mados_diag.sh 2>/dev/null "
                                "|| xterm -e bash /tmp/mados_diag.sh",
                                "#005599", async_run=True))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("INFORMATIONS SYSTÈME"))
        lay.addWidget(self._btn("🐧  Version du Kernel", "uname -r", "#333", async_run=True))
        lay.addWidget(self._btn("💻  Info CPU & RAM",
                                "grep 'model name' /proc/cpuinfo | head -1 && free -h",
                                "#333", async_run=True))
        lay.addWidget(self._btn("🎮  Info GPU", "nvidia-smi 2>/dev/null || glxinfo 2>/dev/null | grep 'OpenGL renderer' || echo 'GPU: GPU info non disponible'", "#333", async_run=True))
        lay.addWidget(self._btn("🌡️  Températures CPU", "sensors 2>/dev/null || echo 'lm-sensors non installé'", "#333", async_run=True))
        lay.addWidget(self._btn("📊  Utilisation Disque", "df -h /", "#333", async_run=True))
        lay.addStretch()
        return w

    # ── Onglet Mise à Jour ───────────────────────────────────────────────────
    def _tab_update(self):
        w = QWidget(); lay = QVBoxLayout(w); lay.setSpacing(8); lay.setContentsMargins(16,16,16,16)
        lay.addWidget(self._label("MISE À JOUR MADOS"))
        lay.addWidget(self._btn("🔄  Mettre à jour MadOS depuis GitHub",
                                "wget -qO /tmp/mados_update.sh "
                                "https://raw.githubusercontent.com/LordMadTrix/MadOS_ROG_Edition/main/modules/24_mados_update.sh "
                                "&& konsole -e bash -c 'sudo bash /tmp/mados_update.sh; read -p Done' 2>/dev/null "
                                "|| xterm -e bash -c 'sudo bash /tmp/mados_update.sh; read -p Done'",
                                "#005599", async_run=True))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("PAQUETS SYSTÈME"))
        lay.addWidget(self._btn("📦  Mettre à jour APT (apt upgrade)",
                                "x-terminal-emulator -e bash -c 'sudo apt update && sudo apt upgrade -y; read'",
                                "#333"))
        lay.addWidget(self._btn("⬆️  Mettre à jour pnpm / Node.js",
                                "npm update -g pnpm 2>/dev/null; pnpm self-update 2>/dev/null; echo 'Done'",
                                "#333", async_run=True))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("NOYAU"))
        lay.addWidget(self._btn("🔍  Vérifier les versions XanMod disponibles",
                                "apt-cache policy linux-xanmod 2>/dev/null | head -20 || echo 'Repo XanMod non configuré'",
                                "#333", async_run=True))
        lay.addStretch()
        return w

    # ── Onglet VR & Casques Oculus ───────────────────────────────────────────
    def _tab_vr(self):
        w = QWidget(); lay = QVBoxLayout(w); lay.setSpacing(8); lay.setContentsMargins(16,16,16,16)
        lay.addWidget(self._label("LANCEMENT DES OUTILS VR"))
        lay.addWidget(self._btn("🎮  Lancer ALVR (Streaming PCVR Sans-Fil)",
                                "/opt/MadOS_VR/ALVR/alvr_launcher", "#0055cc", async_run=True))
        lay.addWidget(self._btn("🥽  Lancer SideQuest (Gestion Casque)",
                                "/opt/MadOS_VR/SideQuest/sidequest", "#b8690a", async_run=True))
        lay.addWidget(self._separator())
        lay.addWidget(self._label("MAINTENANCE ADB (CONNEXION USB)"))
        lay.addWidget(self._btn("🔄  Redémarrer le service ADB (Si casque non détecté)",
                                "adb kill-server && adb start-server", "#333", async_run=True))
        lay.addWidget(self._btn("📱  Liste des casques détectés en USB",
                                "adb devices", "#333", async_run=True))
        lay.addStretch()
        return w

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = MadOSControlCenter()
    window.show()
    sys.exit(app.exec())
