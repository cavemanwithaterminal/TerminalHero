#!/usr/bin/env python3
# ============================================================
#  TerminalHero - gemeinsame PTY-Hilfen fuer die Tests
# ------------------------------------------------------------
#  Startet TerminalShell.sh (oder den Startbildschirm) in einem
#  echten PTY, schickt Tasten und wartet auf Textstellen.
#
#  WICHTIG: nicht mit festen Sleeps arbeiten, sondern mit wait(<text>)
#  - Das Spiel zeichnet staendig neu und Gespraeche sind langsam
#    (jede say-Zeile kostet 0,55 s).
# ============================================================
import os, re, pty, time, select, struct, fcntl, termios, shutil, sys

TESTS = os.path.dirname(os.path.abspath(__file__))          # Kern/tests
KERN = os.path.dirname(TESTS)                               # Kern
PROJ = os.path.dirname(KERN)                                # TerminalHero/
SH = os.path.join(PROJ, "shDateien")
SHELL = os.path.join(SH, "TerminalShell.sh")
STARTER = os.path.join(SH, "TerminalHero.sh")
TMP = os.path.join(TESTS, ".tmp")

ESC = b"\x1b"
UP, DOWN, LEFT, RIGHT = b"\x1b[A", b"\x1b[B", b"\x1b[D", b"\x1b[C"

_ANSI = re.compile(r'\x1b\[[0-9;?]*[A-Za-z]')


def clean(buf):
    """Rohe PTY-Bytes -> lesbarer Text ohne Steuersequenzen."""
    t = _ANSI.sub('', buf.decode("utf-8", "replace")).replace('\x1b', '')
    return re.sub(r'\s+', ' ', t)


class Screen:
    """Baut aus dem Byte-Strom den echten Bildschirm nach (fuer Layout-Pruefungen).

    clean() wirft die Steuersequenzen weg - damit laesst sich pruefen, WAS auf
    dem Schirm steht, aber nicht WO. Diese Klasse baut CUP/ED/EL/CUU/CUD/CUF/CUB
    nach (Farben egal); mehr braucht das Spiel nicht. So sieht ein Test z. B.,
    ob ein Fenster den Item-Namen abschneidet.

        sc = Screen(40, 110); sc.feed(bytes(s.buf[mark:])); print(sc.dump())
    """

    def __init__(self, rows=40, cols=110):
        self.rows, self.cols = rows, cols
        self.g = [[" "] * cols for _ in range(rows)]
        self.r = self.c = 0

    def feed(self, data):
        s = data.decode("utf-8", "replace")
        i = 0
        while i < len(s):
            ch = s[i]
            if ch == "\x1b":
                if i + 1 < len(s) and s[i + 1] == "[":
                    j = i + 2
                    params = ""
                    while j < len(s) and not ("@" <= s[j] <= "~"):
                        params += s[j]; j += 1
                    fin = s[j] if j < len(s) else ""
                    i = j + 1
                    p = ([int(x) if x.isdigit() else 0 for x in params.split(";")]
                         if params else [])
                    if fin == "H":
                        row = p[0] if len(p) > 0 else 1
                        col = p[1] if len(p) > 1 else 1
                        self.r = max(0, min(self.rows - 1, (row or 1) - 1))
                        self.c = max(0, min(self.cols - 1, (col or 1) - 1))
                    elif fin == "J" and (p[0] if p else 0) == 2:
                        self.g = [[" "] * self.cols for _ in range(self.rows)]
                    elif fin == "K":
                        n = p[0] if p else 0
                        rng = (range(self.cols) if n == 2
                               else range(self.c, self.cols))
                        for c in rng:
                            self.g[self.r][c] = " "
                    elif fin == "A": self.r = max(0, self.r - (p[0] or 1))
                    elif fin == "B": self.r = min(self.rows - 1, self.r + (p[0] or 1))
                    elif fin == "C": self.c = min(self.cols - 1, self.c + (p[0] or 1))
                    elif fin == "D": self.c = max(0, self.c - (p[0] or 1))
                    continue
                i += 2
                continue
            if ch == "\r":
                self.c = 0
            elif ch == "\n":
                self.r = min(self.rows - 1, self.r + 1); self.c = 0
            elif ch == "\b":
                self.c = max(0, self.c - 1)
            elif ch in "\x07\x0e\x0f":
                pass
            else:
                if self.r < self.rows and self.c < self.cols:
                    self.g[self.r][self.c] = ch
                self.c += 1
                if self.c >= self.cols:
                    self.c = 0; self.r = min(self.rows - 1, self.r + 1)
            i += 1

    def lines(self):
        return ["".join(row).rstrip() for row in self.g]

    def dump(self):
        return "\n".join("%2d|%s" % (n + 1, l) for n, l in enumerate(self.lines()))


class Sim:
    """Eine Spielsitzung im PTY."""

    def __init__(self, env=None, rows=40, cols=110, saves=None, template=None,
                 starter=False, cwd=None, pre=0.6):
        self.saves = saves or os.path.join(TMP, "saves")
        os.makedirs(self.saves, exist_ok=True)
        if template:
            shutil.copy(template, os.path.join(self.saves, "manual1.save"))

        e = dict(os.environ)
        e.update({
            "TERMINALHERO_USER": "benutzer", "TERMINALHERO_HOST": "testhost",
            "TERMINALHERO_AGENT": "Neugier", "TH_SOUND": "0", "LANG": "C.UTF-8",
            "TERM": "xterm-256color", "TH_SAVES_DIR": self.saves,
        })
        if env:
            e.update(env)

        self.buf = bytearray()
        self._plain = ""
        self._plain_len = 0
        self.eof = False

        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', rows, cols, 0, 0))
        pid = os.fork()
        if pid == 0:
            os.setsid()
            fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
            os.dup2(slave, 0); os.dup2(slave, 1); os.dup2(slave, 2)
            if cwd:
                os.chdir(cwd)
            prog = STARTER if starter else SHELL
            os.execve(prog, [os.path.basename(prog)], e)
            os._exit(1)
        os.close(slave)
        self.master, self.pid = master, pid
        if pre:
            self.drain(pre)

    # --- Ausgabe --------------------------------------------------------
    def drain(self, t):
        end = time.time() + t
        while not self.eof:
            left = end - time.time()
            if left <= 0:
                break
            r, _, _ = select.select([self.master], [], [], min(0.05, left))
            if not r:
                continue
            try:
                c = os.read(self.master, 65536)
            except OSError:
                self.eof = True
                return
            if not c:
                self.eof = True
                return
            self.buf.extend(c)

    def text(self):
        if len(self.buf) != self._plain_len:
            self._plain = clean(self.buf)
            self._plain_len = len(self.buf)
        return self._plain

    def wait(self, sub, timeout=25.0):
        """Wartet (drainend), bis <sub> irgendwo im Ausgabestrom steht."""
        end = time.time() + timeout
        while True:
            if sub in self.text():
                return True
            if self.eof or time.time() > end:
                return sub in self.text()
            self.drain(0.1)

    def wait_all(self, subs, timeout=25.0):
        end = time.time() + timeout
        for s in subs:
            if not self.wait(s, max(0.1, end - time.time())):
                return False
        return True

    # --- Nur auf NEUE Ausgabe prüfen (z. B. Fenster auf/zu) -------------
    def mark(self):
        """Merker auf die aktuelle Ausgabelänge setzen."""
        return len(self.buf)

    def since(self, mark):
        """Ausgabe NACH <mark> (bereinigt)."""
        return clean(bytes(self.buf[mark:]))

    def wait_from(self, mark, sub, timeout=25.0):
        """Wartet, bis <sub> in der Ausgabe NACH <mark> auftaucht."""
        end = time.time() + timeout
        while True:
            if sub in self.since(mark):
                return True
            if self.eof or time.time() > end:
                return sub in self.since(mark)
            self.drain(0.1)

    def no_wait(self, sub, t=1.5):
        """Gegenprobe: <sub> darf in den naechsten t Sekunden NICHT auftauchen."""
        self.drain(t)
        return sub not in self.text()

    # --- Eingabe --------------------------------------------------------
    def send(self, b, pause=0.0):
        if isinstance(b, str):
            b = b.encode()
        os.write(self.master, b)
        if pause:
            self.drain(pause)

    def cmd(self, line, wait=None, timeout=25.0, pause=0.0):
        self.send((line + "\r").encode(), pause)
        if wait:
            return self.wait(wait, timeout)
        return True

    def esc(self, wait=None, timeout=8.0, pause=0.2):
        self.send(ESC, pause)
        if wait:
            return self.wait(wait, timeout)
        return True

    def clear_line(self, n=60):
        """Getippte Kommandozeile löschen (Backspace; leer bleibt leer)."""
        self.send(b"\x7f" * n, 0.3)

    # --- Ende -----------------------------------------------------------
    def stop(self):
        try:
            os.kill(self.pid, 9)
        except ProcessLookupError:
            pass
        try:
            os.waitpid(self.pid, 0)
        except ChildProcessError:
            pass
        try:
            os.close(self.master)
        except OSError:
            pass

    def __enter__(self):
        return self

    def __exit__(self, *a):
        self.stop()


# ============================================================
#  Spielstaende
# ============================================================
SAVE_DIR = os.path.join(TMP, "vorlagen")
BASE_SAVE = os.path.join(SAVE_DIR, "base.save")

# Zeilen, die in einem von HAND gepatchten Stand vorkommen muessen.
SAVE_HEAD = """\
# TerminalHero Spielstand v1 (Testvorlage)
#TH_SAVE_INFO|2026-01-01 00:00:00|benutzer@testhost|Neugier|manual
TH_SAVE_VERSION=1
TH_SAVE_TYPE=manual
TH_SAVE_WHEN=2026-01-01 00:00:00
"""

# Alle Skalare, die das Spiel beim Speichern schreibt (Reihenfolge wie save.sh).
SAVE_SCALARS = """\
USERNAME_=benutzer
HOSTNAME_=testhost
AGENT_NAME=Neugier
START_DIR_NAME=Downloads
CWD=/home/benutzer/Schreibtisch/DesktopCity/Haupteingang
OLDPWD=/home/benutzer/Schreibtisch/DesktopCity
VIEW_DIR=/home/benutzer/Schreibtisch/DesktopCity/Haupteingang
SHOW_PATH=1
SHOW_LS=1
TUT_STAGE=0
TUT_HINTED=0
TUT_DONE=1
README_DONE=1
CONAN_DONE=0
DETEKTIV_DONE=0
SAVE_LEARNED=1
TOUCH_CREATE_KNOWN=0
CD_BARE_KNOWN=1
AGENT_ATTITUDE=unbeugsam
AGENT_APPROACH=Aufklaerung
LS_SHOW_ALL=0
HOME_FIRST_VISIT=1
PIXI_DESKTOP_DONE=1
PIXI_GATE_DONE=1
PIXI_HALL_DONE=1
TORWAEHTER_DONE=0
VERLAG_DONE=0
PIXI_GUIDE_DONE=0
BARACKE_SCENE_DONE=0
PIXI_LETTER_DONE=0
AMANDA_INTRO_DONE=0
AMANDA_DONE=0
AMANDA_HELP_GIVEN=0
AMANDA_HELP_ASKED=0
AMANDA_HELP_JACK=0
AMANDA_HELP_DONE=0
SHERLOCK_DONE=0
BOERTY_SH_DONE=0
BOERTY_INTRO_DONE=0
BOERTY_INFO=0
SHERLOCK_HUNT=0
SHERLOCK_NORD=0
SHERLOCK_BRIEF=0
ERMITTLER_DONE=0
SLEEP_HOURS_TODAY=0
SLEEP_DAY=-1
SIT_HOURS_TODAY=0
SIT_DAY=-1
TOKENS_CUR=1000
TOKENS_MAX=1000
TOKENS_REGEN_PCT=1
TOKEN_COST_CMD=5
BITS=0
LEVEL=0
EXP=0
SKILL_POINTS=0
BOERTY_FAVOR_DONE=0
VERMISSTE_GIVEN=0
SIMON_NEK_INFO=0
NEK_GIVEN=0
JON_NEK_INFO=0
JON_NEK_FOUND_INFO=0
BIER_GIVEN=0
BIER_TAKEN=0
BIER_DONE=0
BIER_FAILED=0
BIER_LOST_AT=-1
ZEITUNG_EDITION=bezirke
ZEITUNG_EMPTIED=0
ZEITUNG_GIVEN=0
ZEITUNG_DONE=0
ZEITUNG_EXTRA_DAY=-1
ZEITUNG_EXTRA_UNTIL=-1
ZEITUNG_EXTRA_SHOWN=0
RUNDGANG_GIVEN=0
RUNDGANG_DONE=0
AUFLAGE_GIVEN=0
AUFLAGE_DONE=0
TRACEY_GIVEN=0
TRACEY_FOUND=0
TRACEY_DONE=0
JIMMY_INTRO_DONE=0
JIMMY_TRACEY_DONE=0
JIMMY_GIVEN=0
JIMMY_LAST_SOLD=
JIMMY_FIRST_SALE=0
TRACEY_RIVAL_SEEN=0
SAMY_INTRO_DONE=0
MITCH_GIVEN=0
MITCH_TALKED=0
MITCH_DONE=0
GEHILFE_GIVEN=0
BOERTY_VERMISSTE_INFO=0
SAMY_VERMISSTE_INFO=0
SAMY_MITCH_INFO=0
WORLD_SECS=0
WORLD_STARTED=1
CAL_UNTIL_MIN=0
LAST_CAT_PATH=
LAST_CAT_OK=0
NEKS_LEICHE_PATH=
NEKS_LEICHE_SEARCHED=0
DRAGGED_CORPSE=
NEK_FOUND=0
NEK_REPORTED=0
NEK_MUST_SEARCH=0
NEK_CORPSE_BROUGHT=0
NEK_SIMON_SEARCHED=0
NEK_AMULET_SOLD=0
NEK_AMULET_KEPT=0
NEK_DONE=0
NEK_FUNERAL_GIVEN=0
NEK_FUNERAL_DISPOSITION=
NEK_FUNERAL_DAY=-1
NEK_FUNERAL_DISCOVERY_DAY=-1
NEK_FUNERAL_FOUND=0
NEK_FUNERAL_DONE=0
NEK_FUNERAL_FAILED=0
NEK_FAMILY_GIVEN=0
MOLERATS_DEAD=0
GUY_SUS_MET=0
GUY_SUS_GONE=0
GUY_SUS_CAVE_DONE=0
GUY_SUS_OUTSIDE_DONE=0
"""

SAVE_TAIL = """\
LEARNED=(pwd ls cd cat touch)
CMD_HIST=()
OUT=()
INV_ORDER=()
declare -g -A INV_COUNT=()
declare -g -A WORLD_TAKEN=()
declare -g -A TH_DYN_TYPE=()
"""


def write_save(path, scalars=None, learned=None, inv=None, world_taken=None,
               inv_counts=None, equip=None, dyn_type=None):
    """Schreibt einen gueltigen Spielstand (Vorlage + Abweichungen)."""
    vals = {}
    for line in SAVE_SCALARS.strip().splitlines():
        k, _, v = line.partition("=")
        vals[k] = v
    for k, v in (scalars or {}).items():
        vals[k] = str(v)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    counts = {}
    for i in (inv or []):
        counts[i] = counts.get(i, 0) + 1
    for k, v in (inv_counts or {}).items():
        counts[k] = int(v)
    inv_ids = list(dict.fromkeys(list(inv or []) + list((inv_counts or {}).keys())))
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(SAVE_HEAD)
        for k, v in vals.items():
            fh.write("%s=%s\n" % (k, v))
        fh.write("LEARNED=(%s)\n" % " ".join(learned or ["pwd", "ls", "cd", "cat", "touch"]))
        fh.write("CMD_HIST=()\nOUT=()\n")
        fh.write("INV_ORDER=(%s)\n" % " ".join(inv_ids))
        if counts:
            fh.write("declare -g -A INV_COUNT=(" + " ".join("[%s]=%s" % (i, n) for i, n in counts.items()) + ")\n")
        else:
            fh.write("declare -g -A INV_COUNT=()\n")
        if world_taken:
            fh.write("declare -g -A WORLD_TAKEN=(" + " ".join("[%s]=1" % p for p in world_taken) + ")\n")
        else:
            fh.write("declare -g -A WORLD_TAKEN=()\n")
        if dyn_type:
            fh.write("declare -g -A TH_DYN_TYPE=(" +
                     " ".join("[%s]=%s" % (p, t) for p, t in dyn_type.items()) + ")\n")
        else:
            fh.write("declare -g -A TH_DYN_TYPE=()\n")
        if equip:
            fh.write("declare -g -A EQUIP_SLOT_ITEM=(" +
                     " ".join("[%s]=%s" % (s, i) for s, i in equip.items()) + ")\n")
    return path


# Alles, was ein Agent im späteren Spiel können soll (Tests: "weit gespielt").
# achievements/statistics werden erst im Verlauf gelernt; für Tests, die
# bereits mittendrin starten, gehören sie hier trotzdem dazu.
LEARNED_ALL = ["pwd", "ls", "cd", "cat", "touch", "grep", "use", "search",
               "help", "character", "questlog", "inventar", "save",
               "achievements", "statistics"]
LEARNED_TUT = ["pwd", "ls", "cd", "cat", "touch"]


# ============================================================
#  Testreport
# ============================================================
class Report:
    def __init__(self, title):
        self.title = title
        self.fails = 0
        self.n = 0
        print("=== %s ===" % title)

    def check(self, name, ok, extra=""):
        self.n += 1
        if not ok:
            self.fails += 1
        print(("%s %s%s" % ("OK  " if ok else "FAIL", name, extra)))

    def contains(self, name, hay, needle):
        self.check("%s  (%s)" % (name, needle), needle in hay)

    def missing(self, name, hay, needle, t=1.5):
        # nur sinnvoll, wenn hay eine frische Sitzung ist
        self.check("%s  (kein %s)" % (name, needle), needle not in hay)

    def done(self):
        print("ERGEBNIS %s: %d Checks, %d Fehler" %
              (self.title, self.n, self.fails))
        return self.fails


def reset_tmp():
    """Arbeitsordner der Tests leeren (Spielstaende aus alten Laeufen)."""
    shutil.rmtree(TMP, ignore_errors=True)
    os.makedirs(TMP, exist_ok=True)
