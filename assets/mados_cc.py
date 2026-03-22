import sys
import subprocess
import threading
import os
import json
import re
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                             QHBoxLayout, QPushButton, QLabel, QStackedWidget,
                             QMessageBox, QTextEdit, QProgressBar, QFrame, QLineEdit,
                             QScrollArea, QGraphicsDropShadowEffect)
from PyQt6.QtGui import QFont, QColor, QPalette, QLinearGradient, QBrush, QIcon
from PyQt6.QtCore import Qt, QTimer, pyqtSignal, QObject, QSize

# ── Style de Base (Premium Cyberpunk) ─────────────────────────────────────────
STYLE_CYBER = """
QMainWindow {
    background: qlineargradient(spread:pad, x1:0, y1:0, x2:1, y2:1, stop:0 #0a0a0a, stop:1 #141414);
}
QWidget#Central { background: transparent; }

/* Sidebar Navigation */
QFrame#Sidebar {
    background: #0d0d0d;
    border-right: 1px solid #2a0000;
}
QPushButton#NavBtn {
    background: transparent;
    color: #888;
    text-align: left;
    padding: 14px 20px;
    font-size: 14px;
    font-weight: bold;
    border-radius: 0px;
    border: none;
}
QPushButton#NavBtn:hover {
    background: rgba(232, 0, 61, 0.05);
    color: #fff;
}
QPushButton#NavBtn:checked {
    background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #e8003d, stop:1 transparent);
    color: white;
    border-left: 4px solid #fff;
}

/* Base UI Elements */
QLabel { color: white; }
QLabel#Header { font-size: 20px; font-weight: 900; letter-spacing: 2px; color: #e8003d; }
QLabel#SubHeader { color: #555; font-size: 12px; font-weight: bold; text-transform: uppercase; margin-top: 10px; }

QPushButton#ActionBtn {
    background: #1a1a1a;
    color: white;
    border: 1px solid #333;
    padding: 12px;
    border-radius: 8px;
    font-weight: bold;
}
QPushButton#ActionBtn:hover {
    background: #222;
    border: 1px solid #e8003d;
}
QPushButton#PrimaryBtn {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #e8003d, stop:1 #8c0025);
    color: white;
    border-radius: 8px;
    padding: 12px;
    font-weight: bold;
    font-size: 13px;
}
QPushButton#PrimaryBtn:hover { background: #ff1a1a; }

QTextEdit#LogBox {
    background: rgba(0,0,0,0.4);
    color: #00ff88;
    border: 1px solid #222;
    font-family: 'Share Tech Mono', monospace;
    font-size: 12px;
    border-bottom-left-radius: 12px;
    border-bottom-right-radius: 12px;
}
QLineEdit {
    background: #111;
    border: 1px solid #333;
    color: white;
    padding: 8px;
    border-radius: 4px;
}
"""

class MadOSControlCenter(QMainWindow):
    log_signal = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.setWindowTitle("MadOS ROG Edition — Dashboard")
        self.setMinimumSize(950, 680)
        self.setStyleSheet(STYLE_CYBER)
        
        # Racine Centrale
        central = QWidget()
        central.setObjectName("Central")
        self.setCentralWidget(central)
        layout = QHBoxLayout(central)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # ── Sidebar ───────────────────────────────────────────────────────────
        self.sidebar = QFrame()
        self.sidebar.setObjectName("Sidebar")
        self.sidebar.setFixedWidth(220)
        self.side_lay = QVBoxLayout(self.sidebar)
        self.side_lay.setContentsMargins(0, 20, 0, 20)
        self.side_lay.setSpacing(4)
        
        logo = QLabel("  MadOS <span>ROG</span>")
        logo.setStyleSheet("font-size: 20px; font-weight: 900; color: #fff; margin-bottom: 30px;")
        self.side_lay.addWidget(logo)

        self.nav_group = []
        self._add_nav("⚡ PERFORMANCE", 0)
        self._add_nav("🤖 OPENCLAW IA", 1)
        self._add_nav("🏥 DIAGNOSTIC", 2)
        self._add_nav("🔄 MISE À JOUR", 3)
        self._add_nav("🥽 VR / XR", 4)
        self._add_nav("⚙️ SYSTÈME", 5)
        
        self.side_lay.addStretch()
        
        layout.addWidget(self.sidebar)

        # ── Main Area ─────────────────────────────────────────────────────────
        self.main_area = QVBoxLayout()
        layout.addLayout(self.main_area)

        # Header Info
        top_bar = QFrame()
        top_bar.setFixedHeight(60)
        top_lay = QHBoxLayout(top_bar)
        self.status_lbl = QLabel("  ⏳ Chargement MadOS...")
        self.status_lbl.setStyleSheet("color: #00ff88; font-family: monospace; font-size: 13px;")
        top_lay.addWidget(self.status_lbl)
        top_lay.addStretch()
        self.main_area.addWidget(top_bar)

        # Stacked Pages
        self.stack = QStackedWidget()
        self.main_area.addWidget(self.stack, 1)

        # Build Pages
        self.stack.addWidget(self._page_perf())
        self.stack.addWidget(self._page_ai())
        self.stack.addWidget(self._page_diag())
        self.stack.addWidget(self._page_update())
        self.stack.addWidget(self._page_vr())
        self.stack.addWidget(self._page_sys())

        # Console Log
        self.log = QTextEdit()
        self.log.setObjectName("LogBox")
        self.log.setReadOnly(True)
        self.log.setPlaceholderText("$ Console MadOS operative...")
        self.log.setMaximumHeight(160)
        self.main_area.addWidget(self.log)

        # Signals
        self.log_signal.connect(self._append_log)
        self.nav_group[0].setChecked(True)

        # Timers
        self._refresh_status()
        self.timer = QTimer(self)
        self.timer.timeout.connect(self._refresh_status)
        self.timer.start(4000)

    # ── Navigation Methods ────────────────────────────────────────────────────
    def _add_nav(self, text, index):
        btn = QPushButton(f"  {text}")
        btn.setObjectName("NavBtn")
        btn.setCheckable(True)
        btn.clicked.connect(lambda: self._switch_page(index))
        self.side_lay.addWidget(btn)
        self.nav_group.append(btn)

    def _switch_page(self, index):
        for i, b in enumerate(self.nav_group):
            b.setChecked(i == index)
        self.stack.setCurrentIndex(index)

    # ── UI Blocks ─────────────────────────────────────────────────────────────
    def _card(self, title):
        w = QWidget()
        lay = QVBoxLayout(w)
        lbl = QLabel(title)
        lbl.setObjectName("Header")
        lay.addWidget(lbl)
        return w, lay

    def _page_perf(self):
        w, lay = self._card("⚡  PROFIL PERFORMANCE")
        
        sc = QScrollArea(); sc.setWidgetResizable(True); sc.setStyleSheet("border:none; background:transparent;")
        c = QWidget(); sc.setWidget(c); scav = QVBoxLayout(c); scav.setSpacing(12)
        
        # Master Control
        scav.addWidget(QLabel("MODES MATÉRIELS MADOS UNIFIÉS"))
        h_master = QHBoxLayout()
        h_master.addWidget(self._pbtn("🔥  MODE GAME", "mados shift game", "#e8003d"))
        h_master.addWidget(self._pbtn("🍃  MODE ECO", "mados shift eco", "#2e7d32"))
        h_master.addWidget(self._pbtn("💻  MODE DEV", "mados shift dev", "#2196f3"))
        scav.addLayout(h_master)
        
        scav.addWidget(self._lbl("PERSONNALISATION ROG AURA"))
        h_aura = QHBoxLayout()
        h_aura.addWidget(self._abtn("🌈 Rainbow", "mados aura rainbow"))
        h_aura.addWidget(self._abtn("💓 Pulse", "mados aura pulse"))
        h_aura.addWidget(self._abtn("🔴 Static", "mados aura static -c ff0000"))
        h_aura.addWidget(self._abtn("🌑 Off", "mados aura static -c 000000"))
        scav.addLayout(h_aura)

        scav.addWidget(self._lbl("PRÉSERVATION BATTERIE"))
        h_batt = QHBoxLayout()
        h_batt.addWidget(self._abtn("🔋 60% (Bureau)", "mados batt 60"))
        h_batt.addWidget(self._abtn("🔌 80% (Mixte)", "mados batt 80"))
        h_batt.addWidget(self._abtn("⚡ 100% (Voyage)", "mados batt 100"))
        scav.addLayout(h_batt)
        
        scav.addStretch()
        lay.addWidget(sc)
        return w

    def _page_ai(self):
        w, lay = self._card("🤖  OPENCLAW AI ASSISTANT")
        lay.addWidget(QLabel("MOTEUR GÉNÉRATIF LOCAL OPERATIVE."))
        
        box = QFrame(); box.setStyleSheet("background: rgba(255,255,255,0.03); border-radius:12px;")
        bl = QVBoxLayout(box)
        
        bl.addWidget(self._pbtn("▶  Démarrer le Moteur IA", "mados ai start", "#2e7d32"))
        bl.addWidget(self._pbtn("💬  Ouvrir l'Interface de Chat Web", self._open_ai_url, "#0055cc"))
        bl.addWidget(self._abtn("📋  Voir les Logs Diagnostic", "mados ai status", "#444"))
        
        lay.addWidget(box)
        lay.addStretch()
        return w

    def _page_diag(self):
        w, lay = self._card("🏥  DIAGNOSTIC SANTÉ SYSTÈME")
        lay.addWidget(self._pbtn("🏥  Lancer le Checkup de Santé", "mados check", "#005599"))
        lay.addWidget(self._abtn("🐧  Version Kernel", "uname -r"))
        lay.addWidget(self._abtn("🎮  Status GPU (NVIDIA)", "nvidia-smi"))
        lay.addStretch()
        return w

    def _page_update(self):
        w, lay = self._card("🔄  MAINTENANCE & MÀJ")
        lay.addWidget(self._pbtn("🚀  Vérifier les Mises à Jour MadOS", "mados update", "#c1002d"))
        lay.addWidget(self._abtn("📦  Mise à jour Système (APT)", "sudo apt update && sudo apt upgrade -y"))
        lay.addStretch()
        return w

    def _page_vr(self):
        w, lay = self._card("🥽  INTÉGRATION VR")
        lay.addWidget(self._pbtn("🎮  Lancer ALVR (Streaming PCVR)", "mados vr start", "#0055cc"))
        lay.addWidget(self._abtn("📱  Vérifier Connexion USB (ADB)", "adb devices"))
        lay.addStretch()
        return w
        
    def _page_sys(self):
        w, lay = self._card("⚙️  PARAMÈTRES SYSTÈME")
        lay.addWidget(self._abtn("📸  Créer un Snapshot Timeshift", "mados snapshot"))
        lay.addWidget(self._abtn("🧹  Nettoyage Mémoire (Drop Caches)", "pkexec bash -c 'sync; echo 3 > /proc/sys/vm/drop_caches'"))
        lay.addStretch()
        return w

    # ── Buttons Factories ─────────────────────────────────────────────────────
    def _pbtn(self, text, cmd, color="#cc0000"):
        btn = QPushButton(text)
        btn.setObjectName("PrimaryBtn")
        if color != "#cc0000":
            btn.setStyleSheet(f"background: {color}; border-radius: 8px; padding: 12px; font-weight: bold;")
        btn.clicked.connect(lambda: self._run(cmd))
        return btn

    def _abtn(self, text, cmd):
        btn = QPushButton(text)
        btn.setObjectName("ActionBtn")
        btn.clicked.connect(lambda: self._run(cmd))
        return btn

    def _lbl(self, text):
        l = QLabel(text)
        l.setObjectName("SubHeader")
        return l

    # ── Logique Métier ────────────────────────────────────────────────────────
    def _run(self, cmd):
        if callable(cmd):
            cmd()
            return

        self.log_signal.emit(f"<span style='color:#e8003d'>$ {cmd}</span>")
        def _worker():
            try:
                # Si la commande est sudo, on tente pkexec pour l'UI, ou bash -c
                final_cmd = cmd
                if "sudo " in cmd:
                    final_cmd = cmd.replace("sudo ", "pkexec ")
                
                out = subprocess.check_output(final_cmd, shell=True, stderr=subprocess.STDOUT, text=True, timeout=60)
                self.log_signal.emit(f"<span style='color:#00ff88'>{out.strip()[:2000]}</span>")
            except Exception as e:
                self.log_signal.emit(f"<span style='color:#ff4444'>ERREUR: {str(e)[:500]}</span>")
        threading.Thread(target=_worker, daemon=True).start()

    def _append_log(self, html):
        self.log.append(html)
        sb = self.log.verticalScrollBar()
        sb.setValue(sb.maximum())

    def _refresh_status(self):
        def _worker():
            try:
                r = subprocess.run("systemctl --user is-active openclaw.service", shell=True, capture_output=True, text=True)
                claw = r.stdout.strip()
                temp = subprocess.run("sensors | grep 'Package id 0' | awk '{print $4}'", shell=True, capture_output=True, text=True).stdout.strip()
                
                status_text = f"  🟢  CPU: {temp or 'N/A'}  |  🤖  AI: {claw.upper()}  |  Kernel: {os.uname().release}"
                self.status_lbl.setText(status_text)
            except: pass
        threading.Thread(target=_worker, daemon=True).start()

    def _open_ai_url(self):
        import webbrowser
        webbrowser.open("http://localhost:18789")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MadOSControlCenter()
    window.show()
    sys.exit(app.exec())
