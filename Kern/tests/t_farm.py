#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Farmland/Farm/Anwesen: Familie Molerat (PTY)
# ------------------------------------------------------------
#  Prüft:
#    1) Das Anwesen ist über Steppe/Farmland/Farm erreichbar; im
#       Erdgeschoss stehen Gregor, Marlene und Chantal Molerat.
#    2) Vor Neks Beerdigung haben alle drei ihren Vor-Dialog.
#    3) Nach Neks Beerdigung haben alle drei ihren Nach-Dialog;
#       er nimmt nur vage Bezug und nennt keine Einzelheiten
#       zum Umgang mit der Leiche.
#    4) Am Beerdigungstag steht die Familie im Friedhof und
#       nicht zusätzlich im Erdgeschoss des Anwesens.
#
#  Aufruf:  python3 Kern/tests/t_farm.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
DESK = H + "/Schreibtisch"
STEPPE = DESK + "/Brachland/Steppe"
FARMLAND = STEPPE + "/Farmland"
FARM = FARMLAND + "/Farm"
ERDGESCHOSS = FARM + "/Anwesen/Haupteingang/Erdgeschoss"
CEMETERY = DESK + "/Brachland/Friedhof"

DAY6_0600 = 21600   # Beginn des Folgetags nach der Beerdigung


def start(name, cwd, scalars=None):
    d = os.path.join(TMP, name)
    sv = {"CWD": cwd, "OLDPWD": DESK, "VIEW_DIR": cwd,
          "SHOW_PATH": 1, "SHOW_LS": 1, "HOME_FIRST_VISIT": 1,
          "TUT_DONE": 1, "TORWAEHTER_DONE": 1, "WORLD_STARTED": 1,
          "MOLERATS_DEAD": 7,
          "GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
          "GUY_SUS_CAVE_DONE": 1, "GUY_SUS_OUTSIDE_DONE": 1}
    sv.update(scalars or {})
    write_save(os.path.join(d, "manual1.save"), scalars=sv,
               learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual", "TH_SAY_SECS": "0.01"},
               saves=d, rows=40, cols=120)


def dismiss(s):
    s.send(b"\r")
    s.drain(0.25)


FAMILY = ("GregorMolerat", "MarleneMolerat", "ChantalMolerat")

# ================================================== §1 Vor der Beerdigung
with start("farm_vor", ERDGESCHOSS,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 99, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": 0}) as s:
    r = Report("1) Anwesen & Familie vor Neks Beerdigung")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    for name in FAMILY:
        r.check("Erdgeschoss zeigt %s" % name, s.wait_from(m, name, 10))

    m = s.mark()
    s.cmd("cat GregorMolerat")
    r.check("Gregor-Datei nennt das Anwesen",
            s.wait_from(m, "ANWESEN // Gregor Molerat", 10))

    for name, key, label in (
            ("GregorMolerat", "Die Beerdigung ist angesetzt", "Vater"),
            ("MarleneMolerat", "Ich habe seine Uniform gebügelt", "Mutter"),
            ("ChantalMolerat", "Alle reden über den Nachmittag", "Tochter")):
        m = s.mark()
        s.cmd("touch %s" % name)
        r.check("%s hat den Vor-Dialog" % label,
                s.wait_from(m, key, 10))
        if name == "GregorMolerat":
            s.send(b"2")      # Menü: »Nichts weiter.«
            s.drain(0.25)
        dismiss(s)

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §2 Nach der Beerdigung
with start("farm_nach", ERDGESCHOSS,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 1,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY6_0600}) as s:
    r = Report("2) Familie nach Neks Beerdigung")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    for name in FAMILY:
        r.check("Erdgeschoss zeigt %s" % name, s.wait_from(m, name, 10))

    for name, key, label in (
            ("GregorMolerat", "Die Beerdigung liegt hinter uns", "Vater"),
            ("MarleneMolerat", "Ich habe heute Morgen für vier gedeckt", "Mutter"),
            ("ChantalMolerat", "Danke, dass du gekommen bist", "Tochter")):
        m = s.mark()
        s.cmd("touch %s" % name)
        r.check("%s hat den Nach-Dialog" % label,
                s.wait_from(m, key, 10))
        if name == "GregorMolerat":
            s.send(b"2")      # Menü: »Nichts weiter.«
            s.drain(0.25)
        since = s.since(m).lower()
        r.check("%s nennt keine Leichen-Einzelheiten" % label,
                not any(w in since for w in
                        ("leiche", "vergammeln", "liegen lassen", "höhle")))
        dismiss(s)

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §3 Am Beerdigungstag
with start("farm_beerdigung", ERDGESCHOSS,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 0, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": 0}) as s:
    r = Report("3) Am Beerdigungstag ist das Erdgeschoss leer")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("Erdgeschoss zeigt keinen Gregor", not s.wait_from(m, "GregorMolerat", 1.5))
    r.check("Erdgeschoss zeigt keine Marlene", not s.wait_from(m, "MarleneMolerat", 1.0))
    r.check("Erdgeschoss zeigt keine Chantal", not s.wait_from(m, "ChantalMolerat", 1.0))

    m = s.mark()
    s.cmd("cd " + CEMETERY)
    s.cmd("ls")
    r.check("Familie steht stattdessen im Friedhof",
            s.wait_from(m, "GregorMolerat", 10)
            and s.wait_from(m, "MarleneMolerat", 10)
            and s.wait_from(m, "ChantalMolerat", 10))

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §4 Mitternacht
# Beim Wechsel in den Beerdigungstag verschwindet die Familie aus dem
# Erdgeschoss; nach dem Beerdigungstag kehrt sie um Mitternacht zurück.
DAY4_2359 = 17098   # 4 Spieltage + 23:59 ab Start 06:00
DAY5_2359 = 20698   # 5 Spieltage + 23:59 ab Start 06:00

with start("farm_mitternacht_hin", ERDGESCHOSS,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY4_2359}) as s:
    r = Report("4a) Vor dem Beerdigungstag: Familie verlässt das Erdgeschoss")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("vor Mitternacht ist die Familie da",
            s.wait_from(m, "GregorMolerat", 10))

    s.drain(3.2)          # eine Ingame-Minute: Tageswechsel
    m = s.mark()
    s.cmd("ls")
    s.drain(0.5)
    r.check("nach Mitternacht ist das Erdgeschoss leer",
            "GregorMolerat" not in s.since(m))

    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

with start("farm_mitternacht_zurueck", ERDGESCHOSS,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 1,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY5_2359}) as s:
    r = Report("4b) Nach dem Beerdigungstag: Familie kehrt zurück")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    s.drain(0.5)
    r.check("am Beerdigungstag ist das Erdgeschoss leer",
            "GregorMolerat" not in s.since(m))

    s.drain(3.2)          # eine Ingame-Minute: Tageswechsel
    m = s.mark()
    s.cmd("ls")
    r.check("nach Mitternacht ist die Familie zurück",
            s.wait_from(m, "GregorMolerat", 10))

    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

print("\nFARM-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
