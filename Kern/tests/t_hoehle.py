#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Höhleneingang, Molerathöhle & Ausrüstungs-Slots (PTY)
# ------------------------------------------------------------
#  Prüft:
#    1) ~/Schreibtisch enthält den Ordner Höhleneingang.
#    2) Im Höhleneingang liegt die Molerathöhle; beide sind per
#       cd/pwd/ls erreichbar.
#    3) Der Charakterbogen zeigt das Ausrüstungs-Panel mit allen
#       acht Slots (Kopf, Oberkörper, Beine, Linke Hand, Rechte
#       Hand, Amulett, Ring1, Ring2) und acht leeren Werten.
#    4) Das gilt auch im schmalen 80x24-Layout (Panel rechts neben
#       den Werten, Portrait bleibt sichtbar) und im 60x24-Layout
#       (Portrait entfällt, alle acht Slots bleiben sichtbar); die
#       Fußzeile bleibt erreichbar.
#
#  Aufruf:  python3 Kern/tests/t_hoehle.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, Screen, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
DESK = H + "/Schreibtisch"
HOEHLE = DESK + "/Höhleneingang"
MOLERAT = HOEHLE + "/Molerathöhle"

SLOTS = ("Kopf", "Oberkörper", "Beine", "Linke Hand",
         "Rechte Hand", "Amulett", "Ring1", "Ring2")


def start(name, cwd, rows=40, cols=110):
    d = os.path.join(TMP, name)
    write_save(os.path.join(d, "manual1.save"),
               scalars={"CWD": cwd, "OLDPWD": DESK, "VIEW_DIR": cwd,
                        "SHOW_PATH": 1, "SHOW_LS": 1,
                        "HOME_FIRST_VISIT": 1,
                        # Höhlen-Test: Guy/Molerats sind eigene Tests.
                        "MOLERATS_DEAD": 7, "GUY_SUS_MET": 1,
                        "GUY_SUS_GONE": 1, "GUY_SUS_CAVE_DONE": 1},
               learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=d,
               rows=rows, cols=cols)


def screen_lines(s, mark, rows, cols):
    sc = Screen(rows, cols)
    sc.feed(bytes(s.buf[mark:]))
    return sc.lines()


def check_character(r, s, rows, cols, title, portrait=True):
    m = s.mark()
    s.cmd("character")
    r.check("%s: Charakterbogen öffnet" % title,
            s.wait_from(m, "CHARAKTERBOGEN", 12))
    s.drain(0.8)
    lines = screen_lines(s, m, rows, cols)
    dump = "\n".join(lines)
    r.check("%s: Ausrüstungs-Panel sichtbar" % title, "AUSRÜSTUNG" in dump)
    for label in SLOTS:
        r.check("%s: Slot %s" % (title, label), label in dump)
    r.check("%s: alle acht Slots sind leer" % title,
            dump.count("— leer —") == 8)
    r.check("%s: Fußzeile bleibt sichtbar" % title,
            "zurück zur Shell" in dump)
    r.check("%s: keine Shell-Fehlermeldung" % title,
            "command not found" not in dump and "No such file" not in dump)
    r.check("%s: Portrait %s" % (title, "sichtbar" if portrait else "ausgeblendet"),
            ("PROFIL" in dump) == portrait)
    s.esc()
    r.check("%s: Esc schließt den Bogen" % title,
            s.wait_from(m, "◈ TOKENS", 10))


# ================================================== §1 Höhlen & 40x110
with start("hoehle_40", DESK) as s:
    r = Report("1) Höhleneingang & Molerathöhle, Charakterbogen 110x40")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("~/Schreibtisch zeigt Höhleneingang",
            s.wait_from(m, "Höhleneingang", 10))

    m = s.mark()
    s.cmd("cd Höhleneingang")
    s.cmd("pwd")
    r.check("cd betritt den Höhleneingang", s.wait_from(m, HOEHLE, 10))

    m = s.mark()
    s.cmd("ls")
    r.check("Höhleneingang zeigt Molerathöhle",
            s.wait_from(m, "Molerathöhle", 10))

    m = s.mark()
    s.cmd("cd Molerathöhle")
    s.cmd("pwd")
    r.check("cd betritt die Molerathöhle", s.wait_from(m, MOLERAT, 10))

    check_character(r, s, 40, 110, "110x40")
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §2 80x24
with start("hoehle_24", MOLERAT, rows=24, cols=80) as s:
    r = Report("2) Charakterbogen im 80x24-Layout")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    check_character(r, s, 24, 80, "80x24")
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §3 60x24 (ohne Portrait)
with start("hoehle_60", MOLERAT, rows=24, cols=60) as s:
    r = Report("3) Charakterbogen im 60x24-Layout (ohne Portrait)")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    check_character(r, s, 24, 60, "60x24", portrait=False)
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

sys.exit(1 if fails else 0)
