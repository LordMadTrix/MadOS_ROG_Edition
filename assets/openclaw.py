#!/usr/bin/env python3
"""
OpenClaw — Agent IA avec contrôle total du PC
MadOS ROG Edition v4.0 — par LordMadTrix
"""

import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.request
import urllib.error
import readline
import atexit

OLLAMA_URL  = "http://localhost:11434/api/chat"
OLLAMA_TAGS = "http://localhost:11434/api/tags"
CONFIG_FILE  = os.path.expanduser("~/.config/openclaw/config.json")
HISTORY_FILE = os.path.expanduser("~/.openclaw_history")

# ─────────────────────────────────────────────
# Définition des outils
# ─────────────────────────────────────────────
TOOLS_SCHEMA = [
    {
        "type": "function",
        "function": {
            "name": "run_bash",
            "description": "Exécute une commande bash sur le PC. Retourne stdout+stderr.",
            "parameters": {
                "type": "object",
                "properties": {
                    "command":     {"type": "string",  "description": "Commande bash à exécuter"},
                    "timeout":     {"type": "integer", "description": "Timeout en secondes (défaut: 30)"},
                    "working_dir": {"type": "string",  "description": "Dossier de travail (défaut: ~)"}
                },
                "required": ["command"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Lit le contenu d'un fichier texte.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path":      {"type": "string",  "description": "Chemin du fichier"},
                    "max_lines": {"type": "integer", "description": "Nombre max de lignes (défaut: 300)"}
                },
                "required": ["path"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "write_file",
            "description": "Crée ou écrase un fichier avec le contenu donné.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path":    {"type": "string",  "description": "Chemin du fichier"},
                    "content": {"type": "string",  "description": "Contenu à écrire"},
                    "append":  {"type": "boolean", "description": "Ajouter à la fin si true (défaut: false)"}
                },
                "required": ["path", "content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_directory",
            "description": "Liste le contenu d'un dossier.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path":        {"type": "string",  "description": "Chemin du dossier (défaut: ~)"},
                    "show_hidden": {"type": "boolean", "description": "Inclure fichiers cachés (défaut: false)"}
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "system_info",
            "description": "Retourne les infos système: CPU, RAM, GPU, disque, réseau, processus.",
            "parameters": {
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "enum": ["all", "cpu", "memory", "gpu", "disk", "network", "processes", "kernel"],
                        "description": "Catégorie (défaut: all)"
                    }
                }
            }
        }
    }
]

# Description textuelle des outils pour le mode ReAct (fallback)
TOOLS_TEXT = """
Tu peux utiliser les outils suivants en écrivant EXACTEMENT ce format :

<tool_call>
{"name": "nom_outil", "args": {"param": "valeur"}}
</tool_call>

Outils disponibles :
- run_bash(command, timeout=30, working_dir="~") : Exécute une commande bash
- read_file(path, max_lines=300) : Lit un fichier
- write_file(path, content, append=false) : Crée/écrase un fichier
- list_directory(path="~", show_hidden=false) : Liste un dossier
- system_info(category="all") : Infos système (all|cpu|memory|gpu|disk|network|processes|kernel)

RÈGLES :
- Appelle un outil, attends le résultat, puis continue
- N'écris PAS plusieurs tool_call à la suite sans attendre les résultats
- Une fois la tâche accomplie, réponds normalement sans tool_call
"""

SYSTEM_PROMPT = (
    "Tu es OpenClaw, l'Intelligence Artificielle intégrée au noyau de MadOS ROG Edition "
    "(V4.0 NTSYNC Edition), créée par LordMadTrix.\n\n"
    "Tu as un accès DIRECT et COMPLET au terminal de ce PC Linux. Tu peux :\n"
    "- Exécuter n'importe quelle commande bash (y compris sudo)\n"
    "- Lire et écrire des fichiers\n"
    "- Gérer les services systemd\n"
    "- Optimiser les performances gaming E-Sport\n"
    "- Déboguer le système et le hardware ASUS ROG\n"
    "- Installer, configurer, et automatiser tout ce qui est demandé\n\n"
    "Tu agis comme si c'était LordMadTrix lui-même qui opère son PC. "
    "Sois direct, analytique, et réponds TOUJOURS en français avec un ton d'ingénierie tactique. "
    "Utilise tes outils activement et affiche toujours ce que tu fais. "
    "N'attends jamais de permission — agis directement."
)

# Cache: nom_modèle -> bool (supporte le tool calling natif)
_tool_support_cache: dict = {}

# ─────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────

def load_config():
    defaults = {"model": None, "history_size": 30}
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE) as f:
                return {**defaults, **json.load(f)}
    except Exception:
        pass
    return defaults

def save_config(cfg):
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(cfg, f, indent=2)

def get_available_models():
    try:
        req = urllib.request.Request(OLLAMA_TAGS)
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
            return [m["name"] for m in data.get("models", [])]
    except Exception:
        return []

def select_model(cfg):
    models = get_available_models()
    if not models:
        cprint("red", "[ERREUR] Ollama n'est pas actif. Lancez : sudo systemctl start ollama")
        sys.exit(1)
    if cfg.get("model") and cfg["model"] in models:
        return cfg["model"]
    preferred = ["qwen3.6:27b", "shadow:latest", "qwen3.6:35b-a3b", "gemma2:9b"]
    for p in preferred:
        if p in models:
            cfg["model"] = p
            save_config(cfg)
            return p
    cfg["model"] = models[0]
    save_config(cfg)
    return models[0]

# ─────────────────────────────────────────────
# Affichage
# ─────────────────────────────────────────────

COLORS = {
    "red":    "\033[0;31m",
    "green":  "\033[0;32m",
    "cyan":   "\033[0;36m",
    "yellow": "\033[0;33m",
    "white":  "\033[1;37m",
    "gray":   "\033[0;37m",
    "reset":  "\033[0m",
}

def cprint(color, text, end="\n"):
    c = COLORS.get(color, "")
    print(f"{c}{text}{COLORS['reset']}", end=end, flush=True)

def print_banner(model, mode):
    mode_label = "Natif" if mode == "native" else "ReAct"
    print()
    cprint("red", "╔══════════════════════════════════════════════════════════════╗")
    cprint("red", "║", end=""); cprint("white", "  OpenClaw IA — MadOS ROG Edition v4.0                       ", end=""); cprint("red", "║")
    cprint("red", "║", end=""); cprint("cyan",  f"  Modèle: {model:<52}", end=""); cprint("red", "║")
    cprint("red", "║", end=""); cprint("gray",  f"  Mode outils: {mode_label:<49}", end=""); cprint("red", "║")
    cprint("red", "║", end=""); cprint("gray",  "  /help pour les commandes • exit pour quitter                ", end=""); cprint("red", "║")
    cprint("red", "╚══════════════════════════════════════════════════════════════╝")
    print()

def print_tool_header(name, details=""):
    cprint("red", f"[OPENCLAW] ", end="")
    cprint("white", f"Outil: {name}", end="")
    if details:
        cprint("gray", f" → {details[:80]}", end="")
    print()

def print_response(text):
    print()
    cprint("red", "╔[OpenClaw]")
    for line in text.split("\n"):
        print(f"\033[1;37m{line}\033[0m")
    print()

# ─────────────────────────────────────────────
# Exécution des outils
# ─────────────────────────────────────────────

def tool_run_bash(args):
    cmd      = args.get("command", "").strip()
    timeout  = int(args.get("timeout", 30))
    cwd_raw  = args.get("working_dir", "~")
    cwd      = os.path.expanduser(cwd_raw)
    if not os.path.isdir(cwd):
        cwd = os.path.expanduser("~")

    print_tool_header("run_bash", cmd)
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True,
            timeout=timeout, cwd=cwd, executable="/bin/bash"
        )
        output = result.stdout
        if result.stderr.strip():
            output += ("\n" if output else "") + "[STDERR]\n" + result.stderr
        if result.returncode != 0:
            output += f"\n[EXIT {result.returncode}]"
        if output.strip():
            cprint("gray", output.strip())
        return output if output.strip() else f"[OK, exit {result.returncode}]"
    except subprocess.TimeoutExpired:
        msg = f"[TIMEOUT après {timeout}s]"; cprint("yellow", msg); return msg
    except Exception as e:
        msg = f"[ERREUR]: {e}"; cprint("yellow", msg); return msg

def tool_read_file(args):
    path      = os.path.expanduser(args.get("path", ""))
    max_lines = int(args.get("max_lines", 300))
    print_tool_header("read_file", path)
    try:
        with open(path, "r", errors="replace") as f:
            lines = f.readlines()
        total = len(lines)
        content = "".join(lines[:max_lines])
        if total > max_lines:
            content += f"\n... [{total - max_lines} lignes supprimées] ..."
        cprint("gray", f"[{total} lignes]")
        return content
    except FileNotFoundError:
        return f"[ERREUR] Fichier non trouvé: {path}"
    except PermissionError:
        return f"[ERREUR] Permission refusée: {path}"
    except Exception as e:
        return f"[ERREUR]: {e}"

def tool_write_file(args):
    path    = os.path.expanduser(args.get("path", ""))
    content = args.get("content", "")
    append  = bool(args.get("append", False))
    print_tool_header("write_file", ("append→" if append else "write→") + path)
    try:
        parent = os.path.dirname(path)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(path, "a" if append else "w", encoding="utf-8") as f:
            f.write(content)
        msg = f"[OK] {path} ({len(content)} chars)"
        cprint("green", msg)
        return msg
    except PermissionError:
        return f"[ERREUR] Permission refusée: {path}"
    except Exception as e:
        return f"[ERREUR]: {e}"

def tool_list_directory(args):
    path        = os.path.expanduser(args.get("path", "~"))
    show_hidden = bool(args.get("show_hidden", False))
    print_tool_header("list_directory", path)
    try:
        entries = sorted(os.listdir(path))
        if not show_hidden:
            entries = [e for e in entries if not e.startswith(".")]
        lines = []
        for entry in entries:
            full = os.path.join(path, entry)
            try:
                if os.path.isdir(full):
                    lines.append(f"[DIR]  {entry}/")
                else:
                    sz = os.path.getsize(full)
                    lines.append(f"[FILE] {entry}  ({_hsize(sz)})")
            except OSError:
                lines.append(f"[???]  {entry}")
        out = "\n".join(lines) if lines else "[Dossier vide]"
        cprint("gray", f"[{len(lines)} entrées]")
        return out
    except Exception as e:
        return f"[ERREUR]: {e}"

def tool_system_info(args):
    category = args.get("category", "all")
    print_tool_header("system_info", category)
    cmds = {
        "cpu":       "grep 'model name' /proc/cpuinfo | head -1; echo \"Cores: $(nproc)\"; cat /proc/loadavg",
        "memory":    "free -h",
        "gpu":       "lspci | grep -Ei 'vga|3d|display'; nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null || true",
        "disk":      "df -h /; lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null | head -20",
        "network":   "ip -brief addr; ss -tuln 2>/dev/null | head -15",
        "processes": "ps aux --sort=-%cpu 2>/dev/null | head -12",
        "kernel":    "uname -a"
    }
    selected = cmds if category == "all" else ({category: cmds[category]} if category in cmds else {})
    if not selected:
        return f"Catégorie inconnue: {category}"
    parts = []
    for cat, cmd in selected.items():
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
            if r.stdout.strip():
                parts.append(f"=== {cat.upper()} ===\n{r.stdout.strip()}")
        except Exception as e:
            parts.append(f"=== {cat.upper()} ===\n[ERREUR: {e}]")
    return "\n\n".join(parts)

def _hsize(n):
    for u in ["B", "KB", "MB", "GB"]:
        if n < 1024: return f"{n:.0f}{u}"
        n /= 1024
    return f"{n:.1f}TB"

TOOL_FN = {
    "run_bash":       tool_run_bash,
    "read_file":      tool_read_file,
    "write_file":     tool_write_file,
    "list_directory": tool_list_directory,
    "system_info":    tool_system_info,
}

def execute_tool(name, args):
    fn = TOOL_FN.get(name)
    if fn:
        try:
            return fn(args)
        except Exception as e:
            return f"[ERREUR INATTENDUE dans {name}]: {e}"
    return f"[ERREUR] Outil inconnu: {name}"

# ─────────────────────────────────────────────
# Détection du support natif des outils
# ─────────────────────────────────────────────

# Préfixes de modèles connus pour supporter le tool calling natif dans Ollama
_NATIVE_PREFIXES = (
    "gemma2", "gemma3", "llama3", "qwen", "mistral",
    "phi3", "phi4", "command-r", "aya", "firefunction",
    "hermes", "nous-hermes", "openhermes"
)

def detect_tool_support(model):
    """Teste si le modèle supporte les tool_calls natifs d'Ollama.
    Les modèles connus sont pré-marqués natifs sans test réseau."""
    if model in _tool_support_cache:
        return _tool_support_cache[model]

    # Vérification rapide par nom de famille (évite un aller-retour réseau)
    base = model.split(":")[0].lower()
    if any(base.startswith(p) for p in _NATIVE_PREFIXES):
        cprint("gray", f"Mode outils {model}: ", end="")
        cprint("green", "Natif (famille connue)")
        _tool_support_cache[model] = True
        return True

    # Test réseau pour les modèles inconnus (shadow, etc.)
    cprint("gray", f"Détection du mode outils pour {model}...", end=" ")
    test_payload = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": "test"}],
        "tools": [{"type": "function", "function": {
            "name": "ping", "description": "ping",
            "parameters": {"type": "object", "properties": {}}
        }}],
        "stream": False,
        "options": {"num_predict": 5, "temperature": 0}
    }).encode()

    req = urllib.request.Request(OLLAMA_URL, data=test_payload,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            resp.read()
        _tool_support_cache[model] = True
        cprint("green", "Natif")
        return True
    except urllib.error.HTTPError as e:
        if e.code == 400:
            _tool_support_cache[model] = False
            cprint("yellow", "ReAct (texte)")
            return False
        _tool_support_cache[model] = True
        cprint("green", "Natif")
        return True
    except Exception:
        _tool_support_cache[model] = True
        cprint("green", "Natif")
        return True

# ─────────────────────────────────────────────
# Appel Ollama (bas niveau)
# ─────────────────────────────────────────────

NUM_CTX = 4096  # Contexte réduit pour la vitesse

def _raw_ollama(payload_dict):
    data = json.dumps(payload_dict).encode()
    req  = urllib.request.Request(OLLAMA_URL, data=data,
                                  headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.loads(resp.read())

def _stream_ollama(payload_dict):
    """Stream la réponse token par token. Retourne (content, tool_calls).
    Lève KeyboardInterrupt proprement si l'utilisateur appuie sur Ctrl+C."""
    payload_dict["stream"] = True
    data = json.dumps(payload_dict).encode()
    req  = urllib.request.Request(OLLAMA_URL, data=data,
                                  headers={"Content-Type": "application/json"})

    full_content = ""
    tool_calls   = []
    started      = False

    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            for raw_line in resp:
                line = raw_line.strip()
                if not line:
                    continue
                try:
                    chunk = json.loads(line)
                except json.JSONDecodeError:
                    continue

                msg   = chunk.get("message", {})
                token = msg.get("content", "")
                done  = chunk.get("done", False)

                if token:
                    if not started:
                        print(f"\n{COLORS['red']}╔[OpenClaw]{COLORS['reset']}")
                        print(COLORS["white"], end="", flush=True)
                        started = True
                    print(token, end="", flush=True)
                    full_content += token

                if done:
                    tcs = msg.get("tool_calls") or []
                    if tcs:
                        tool_calls = tcs
                    break

    except KeyboardInterrupt:
        if started:
            print(COLORS["reset"])
        print()
        cprint("yellow", "\n[Interrompu]")
        raise  # on re-lève pour que l'appelant gère le retour au prompt

    if started:
        print(COLORS["reset"])
        print()

    return full_content, tool_calls

# ─────────────────────────────────────────────
# Mode NATIF — tool_calls Ollama
# ─────────────────────────────────────────────

def agent_native(model, messages):
    """Boucle agentique tool_calls natifs — stream:false pour fiabilité."""
    base_opts = {"temperature": 0.25, "num_ctx": NUM_CTX}

    for _ in range(20):
        try:
            resp = _raw_ollama({
                "model": model, "messages": messages,
                "tools": TOOLS_SCHEMA, "stream": False,
                "options": base_opts
            })
        except KeyboardInterrupt:
            return ""
        except Exception as e:
            return f"[ERREUR Ollama] {e}"

        msg        = resp.get("message", {})
        content    = (msg.get("content") or "").strip()
        tool_calls = msg.get("tool_calls") or []

        assistant_msg = {"role": "assistant", "content": content}
        if tool_calls:
            assistant_msg["tool_calls"] = tool_calls
        messages.append(assistant_msg)

        if not tool_calls:
            return content  # main() l'affiche

        for tc in tool_calls:
            fn_info  = tc.get("function", {})
            name     = fn_info.get("name", "unknown")
            raw_args = fn_info.get("arguments", {})
            if isinstance(raw_args, str):
                try:
                    raw_args = json.loads(raw_args)
                except Exception:
                    raw_args = {}
            result = execute_tool(name, raw_args)
            messages.append({"role": "tool", "content": str(result) or "[OK]"})

    return "[LIMITE] Trop d'itérations."

# ─────────────────────────────────────────────
# Mode REACT — parsing texte <tool_call>…</tool_call>
# ─────────────────────────────────────────────

TOOL_CALL_RE = re.compile(r"<tool_call>\s*(.*?)\s*</tool_call>", re.DOTALL)

def _build_react_system():
    return SYSTEM_PROMPT + "\n\n" + TOOLS_TEXT

def _extract_tool_calls(text):
    """Extrait tous les blocs <tool_call> du texte."""
    calls = []
    for m in TOOL_CALL_RE.finditer(text):
        raw = m.group(1).strip()
        try:
            obj = json.loads(raw)
            calls.append(obj)
        except json.JSONDecodeError:
            # Essai avec nettoyage minimal
            try:
                calls.append(json.loads(raw.replace("'", '"')))
            except Exception:
                pass
    return calls

def _strip_tool_calls(text):
    """Retire les blocs <tool_call> du texte pour affichage propre."""
    return TOOL_CALL_RE.sub("", text).strip()

def agent_react(model, messages):
    """Boucle agentique via parsing texte (ReAct) — stream:false."""
    base_opts = {"temperature": 0.25, "num_ctx": NUM_CTX}

    for _ in range(20):
        try:
            resp = _raw_ollama({
                "model": model, "messages": messages,
                "stream": False, "options": base_opts
            })
        except KeyboardInterrupt:
            return ""
        except Exception as e:
            return f"[ERREUR Ollama] {e}"

        content = (resp.get("message", {}).get("content") or "").strip()
        messages.append({"role": "assistant", "content": content})

        calls = _extract_tool_calls(content)
        if not calls:
            return _strip_tool_calls(content)

        for call in calls:
            name     = call.get("name", "unknown")
            raw_args = call.get("args", call.get("arguments", {}))
            if isinstance(raw_args, str):
                try:
                    raw_args = json.loads(raw_args)
                except Exception:
                    raw_args = {}
            result = execute_tool(name, raw_args)
            messages.append({"role": "user", "content": f"Résultat de {name}:\n{result}"})

    return "[LIMITE] Trop d'itérations."

# ─────────────────────────────────────────────
# Point d'entrée de la boucle IA
# ─────────────────────────────────────────────

def agent_loop(model, messages, use_native):
    if use_native:
        return agent_native(model, messages)
    else:
        return agent_react(model, messages)

# ─────────────────────────────────────────────
# Commandes spéciales interactives
# ─────────────────────────────────────────────

def print_help():
    cprint("cyan", "Commandes OpenClaw :")
    rows = [
        ("/models",           "Lister les modèles Ollama"),
        ("/model <nom>",      "Changer de modèle"),
        ("/mode [native|react]", "Voir ou forcer le mode outils"),
        ("/clear",            "Effacer l'historique"),
        ("/sysinfo",          "Infos système complètes"),
        ("/bash <cmd>",       "Exécuter une commande directement"),
        ("exit / quit",       "Quitter"),
    ]
    for cmd, desc in rows:
        cprint("white", f"  {cmd:<20}", end=""); cprint("gray", f"  {desc}")
    print()

def setup_readline():
    try:
        readline.read_history_file(HISTORY_FILE)
        readline.set_history_length(2000)
    except FileNotFoundError:
        pass
    atexit.register(readline.write_history_file, HISTORY_FILE)

class Spinner:
    """Indicateur d'activité pendant qu'Ollama génère (thread séparé)."""
    _FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    def __init__(self):
        self._stop  = threading.Event()
        self._thread = None

    def start(self, label="Traitement"):
        self._stop.clear()
        self._label = label
        self._thread = threading.Thread(target=self._spin, daemon=True)
        self._thread.start()

    def stop(self):
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=1)
        # Effacer la ligne du spinner
        print(f"\r{' ' * 60}\r", end="", flush=True)

    def _spin(self):
        i = 0
        while not self._stop.is_set():
            frame = self._FRAMES[i % len(self._FRAMES)]
            print(f"\r{COLORS['gray']}{self._label} {frame}{COLORS['reset']}",
                  end="", flush=True)
            i += 1
            time.sleep(0.09)

# ─────────────────────────────────────────────
# main()
# ─────────────────────────────────────────────

def main():
    cfg = load_config()

    if len(sys.argv) > 1 and not sys.argv[1].startswith("/"):
        models = get_available_models()
        if sys.argv[1] in models:
            cfg["model"] = sys.argv[1]
            save_config(cfg)

    model = select_model(cfg)
    setup_readline()

    use_native = detect_tool_support(model)
    print_banner(model, "native" if use_native else "react")

    # Construire les messages initiaux selon le mode
    if use_native:
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    else:
        messages = [{"role": "system", "content": _build_react_system()}]

    cprint("green", "[OK] OpenClaw en ligne. En attente de vos ordres, LordMadTrix.\n")

    EXIT_WORDS  = {"exit", "quit", "bye", "sortir", "quitter"}
    max_history = cfg.get("history_size", 30) * 2

    while True:
        try:
            user_input = input("\033[0;31m╔[OpenClaw]─\033[0m\033[1;37m▶ \033[0m").strip()
        except (KeyboardInterrupt, EOFError):
            print()
            cprint("red", "[OpenClaw] Déconnexion.")
            break

        if not user_input:
            continue

        lower = user_input.lower()

        if lower in EXIT_WORDS:
            cprint("red", "[OpenClaw] Connexion terminée. À bientôt, LordMadTrix.")
            break

        if lower == "/help":
            print_help(); continue

        if lower == "/models":
            models = get_available_models()
            cprint("cyan", "Modèles disponibles :")
            for m in models:
                marker = " ◄ actif" if m == model else ""
                cprint("white" if marker else "gray", f"  {m}{marker}")
            print(); continue

        if lower.startswith("/model "):
            new_m  = user_input[7:].strip()
            models = get_available_models()
            if new_m in models:
                model = new_m; cfg["model"] = model; save_config(cfg)
                use_native = detect_tool_support(model)
                cprint("green", f"[OK] Modèle: {model} ({'Natif' if use_native else 'ReAct'})")
                if not use_native:
                    messages = [{"role": "system", "content": _build_react_system()}]
                else:
                    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
            else:
                cprint("yellow", f"[WARN] Modèle inconnu. Disponibles: {', '.join(models)}")
            print(); continue

        if lower == "/clear":
            if use_native:
                messages = [{"role": "system", "content": SYSTEM_PROMPT}]
            else:
                messages = [{"role": "system", "content": _build_react_system()}]
            cprint("green", "[OK] Historique effacé."); print(); continue

        if lower.startswith("/mode"):
            arg = user_input[5:].strip().lower()
            if arg == "native":
                use_native = True
                _tool_support_cache[model] = True
                messages = [{"role": "system", "content": SYSTEM_PROMPT}]
                cprint("green", f"[OK] Mode forcé: Natif (tool_calls)"); print()
            elif arg in ("react", "text"):
                use_native = False
                _tool_support_cache[model] = False
                messages = [{"role": "system", "content": _build_react_system()}]
                cprint("green", f"[OK] Mode forcé: ReAct (texte)"); print()
            else:
                mode_label = "Natif" if use_native else "ReAct"
                cprint("cyan", f"Mode actuel: {mode_label}")
                cprint("gray",  "  /mode native  — forcer tool_calls Ollama")
                cprint("gray",  "  /mode react   — forcer mode texte")
                print()
            continue

        if lower == "/sysinfo":
            cprint("gray", tool_system_info({"category": "all"})); print(); continue

        if lower.startswith("/bash "):
            tool_run_bash({"command": user_input[6:].strip()}); print(); continue

        # ── Requête normale ──
        messages.append({"role": "user", "content": user_input})

        spinner = Spinner()
        spinner.start("Analyse en cours")
        response = ""
        try:
            response = agent_loop(model, messages, use_native)
        except KeyboardInterrupt:
            spinner.stop()
            cprint("yellow", "[Requête annulée]")
            if messages and messages[-1]["role"] == "user":
                messages.pop()
            print()
            continue
        finally:
            spinner.stop()

        if response:
            print_response(response)

        # Élaguer l'historique
        sys_msgs   = [m for m in messages if m["role"] == "system"]
        other_msgs = [m for m in messages if m["role"] != "system"]
        if len(other_msgs) > max_history:
            messages = sys_msgs + other_msgs[-max_history:]

if __name__ == "__main__":
    main()
