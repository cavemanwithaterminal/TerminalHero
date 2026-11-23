#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Neks Leiche, search & Ziehen (PTY)
# ------------------------------------------------------------
#  Prüft:
#    1) In der Molerathöhle liegt NeksLeiche. ls zeigt sie, cat und
#       file funktionieren, touch beginnt den Dialog mit dem Satz des
#       Agenten (»Ah. Ich glaube der sagt nichts mehr.«).
#    2) »search NeksLeiche« ist erst nach dem Erlernen nutzbar und
#       findet Neks Amulett, das im Inventar landet.
#    3) »grep NeksLeiche« zieht die Leiche; sie folgt per cd in die
#       Stadt, erscheint dort im ls-Fenster mit dem Symbol »↳« und
#       kostet 20 Tokens / 4 EXP. Ein zweites grep legt sie ab.
#    4) Ziehen, Ort und Loot überleben Speichern/Laden.
#
#  Aufruf:  python3 Kern/tests/t_neksleiche.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
DESK = H + "/Schreibtisch"
HOEHLE = DESK + "/Höhleneingang/Molerathöhle"
BASE = H + "/Schreibtisch/DesktopCity/Haupteingang"
CORPSE = HOEHLE + "/NeksLeiche"
DRAG = "NeksLeiche \u21b3"


def start(name, cwd, learn=None, tokens=1000, saves=None):
    d = saves or os.path.join(TMP, name)
    write_save(os.path.join(d, "manual1.save"),
               scalars={"CWD": cwd, "OLDPWD": DESK, "VIEW_DIR": cwd,
                        "SHOW_PATH": 1, "SHOW_LS": 1,
                        "HOME_FIRST_VISIT": 1, "TUT_DONE": 1,
                        "TOKENS_CUR": tokens,
                        # Nek-Test: keine Molerat-Angriffe, keine Guy-Szene.
                        "MOLERATS_DEAD": 7, "GUY_SUS_MET": 1,
                        "GUY_SUS_GONE": 1, "GUY_SUS_CAVE_DONE": 1},
               learned=learn or LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=d,
               rows=40, cols=120)


# ================================================== §1 Inhalt & search
with start("nek_inhalt", HOEHLE, learn=LEARNED_ALL + ["file"]) as s:
    r = Report("1) Neks Leiche: ls, cat, file, touch & search")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("ls zeigt NeksLeiche", s.wait_from(m, "NeksLeiche", 12))
    r.check("ungezogen ohne Folge-Symbol", DRAG not in s.since(m))

    m = s.mark()
    s.cmd("cat NeksLeiche")
    r.check("cat zeigt den Befund", s.wait_from(m, "Nek Molerat. Stadtwache.", 12))
    r.check("cat nennt das Amulett", s.wait_from(m, "Amulett", 12))

    m = s.mark()
    s.cmd("file NeksLeiche")
    r.check("file erkennt die beseelte Leiche",
            s.wait_from(m, "»Neks Leiche«", 12))
    r.check("file verweist auf search",
            s.wait_from(m, "search NeksLeiche", 12))

    m = s.mark()
    s.cmd("touch NeksLeiche")
    r.check("touch beginnt den Dialog",
            s.wait_from(m, "MOLERATHÖHLE · NEKS LEICHE", 15))
    r.check("der Agent sagt den geforderten Satz",
            s.wait_from(m, "Ah. Ich glaube der sagt nichts mehr.", 20))
    r.check("der Dialog weist auf search hin",
            s.wait_from(m, "search NeksLeiche", 15))
    s.send(b"\r", 0.8)
    r.check("Enter beendet den Dialog",
            s.wait_from(m, "◈ TOKENS", 12))

    m = s.mark()
    s.cmd("search NeksLeiche")
    r.check("search durchsucht die Leiche",
            s.wait_from(m, "Du durchsuchst Neks Leiche.", 12))
    r.check("search findet Neks Amulett",
            s.wait_from(m, "Neks Amulett", 12))

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    save = open(os.path.join(TMP, "nek_inhalt", "manual1.save"),
                encoding="utf-8").read()
    r.check("Amulett liegt im Inventar", "[neksamulett]=1" in save)
    r.check("Suche ist gespeichert", "NEKS_LEICHE_SEARCHED=1" in save)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §2 search gesperrt
with start("nek_gating", HOEHLE,
           learn=[c for c in LEARNED_ALL if c not in ("search", "grep")]) as s:
    r = Report("2) search und grep auf der Leiche sind gesperrt")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("search NeksLeiche")
    r.check("search ohne Erlernen wird abgewiesen",
            s.wait_from(m, "»search« …? Diesen Befehl kenne ich nicht mehr.", 12))
    r.check("kein Loot ohne search",
            s.no_wait("Neks Amulett", 0.8))

    m = s.mark()
    s.cmd("grep NeksLeiche")
    r.check("grep ohne Erlernen wird abgewiesen",
            s.wait_from(m, "»grep« …? Diesen Befehl hat der Virus mir genommen.", 12))
    m = s.mark()
    s.cmd("ls")
    r.check("keine gezogene Leiche ohne grep",
            s.wait_from(m, "NeksLeiche", 12) and DRAG not in s.since(m))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §3 Ziehen & ablegen
with start("nek_ziehen", HOEHLE) as s:
    r = Report("3) grep zieht die Leiche in die Stadt und legt sie ab")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("grep NeksLeiche")
    r.check("grep zieht die Leiche",
            s.wait_from(m, "Du ziehst jetzt eine Leiche hinter dir her.", 12))
    r.check("grep auf Leiche kostet 20 Tokens (980)",
            s.wait_from(m, "980 / 1000", 10))

    m = s.mark()
    s.cmd("cd ~/Schreibtisch/DesktopCity/Haupteingang")
    r.check("cd in den Haupteingang kostet 5 Tokens (975)",
            s.wait_from(m, "975 / 1000", 12))

    m = s.mark()
    s.cmd("ls")
    r.check("die Leiche ist beim Agenten", s.wait_from(m, "NeksLeiche", 12))
    r.check("ls markiert die gezogene Leiche mit ↳", DRAG in s.since(m))

    s.cmd("save")
    r.check("gezogener Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    save_path = os.path.join(TMP, "nek_ziehen", "manual1.save")
    save = open(save_path, encoding="utf-8").read()
    r.check("Zieh-Pfad ist gespeichert", "DRAGGED_CORPSE=" in save)
    r.check("Leichenort ist gespeichert", "NEKS_LEICHE_PATH=" in save)
    r.check("vier EXP für das Ziehen", "EXP=7" in save)
    r.check("Ziehen, cd/ls und save kosten 35 Tokens",
            "TOKENS_CUR=965" in save)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §4 Laden & ablegen
with Sim(env={"TERMINALHERO_LOAD": "manual"},
         saves=os.path.join(TMP, "nek_ziehen"), rows=40, cols=120) as s:
    r = Report("4) Gezogene Leiche überlebt Speichern/Laden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("Leiche steht nach dem Laden beim Agenten",
            s.wait_from(m, "NeksLeiche", 12))
    r.check("Folge-Symbol bleibt erhalten", DRAG in s.since(m))

    m = s.mark()
    s.cmd("grep NeksLeiche")
    r.check("zweites grep legt die Leiche ab",
            s.wait_from(m, "Du hast eine Leiche abgelegt.", 12))
    r.check("Ablegen kostet 20 Tokens (940)", s.wait_from(m, "940 / 1000", 10))

    m = s.mark()
    s.cmd("ls")
    r.check("die Leiche bleibt im Ordner", s.wait_from(m, "NeksLeiche", 12))
    r.check("ohne Ziehen kein Folge-Symbol", DRAG not in s.since(m))

    s.cmd("save")
    r.check("abgelegter Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    save_path = os.path.join(TMP, "nek_ziehen", "manual1.save")
    save = open(save_path, encoding="utf-8").read()
    r.check("Ablegen und saves kosten 30 Tokens", "TOKENS_CUR=930" in save)
    r.check("zwei Leichen-greps geben zusammen 8 EXP", "EXP=14" in save)
    r.check("Ablegen löscht den Zieh-Pfad", "DRAGGED_CORPSE=''\n" in save)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


print("\nNEKS-LEICHE-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
