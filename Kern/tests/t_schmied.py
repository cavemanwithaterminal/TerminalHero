#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Schmiede Bruno Amboss (PTY)
# ------------------------------------------------------------
#  Prüft den neuen Laden im Zentrum:
#
#    1) Der Ordner »Schmiede« enthält BrunoAmboss und den Amboss.
#    2) Bruno hat den Standard-Dialog mit 1) Handeln / 2) Tschau.
#    3) »Handeln« öffnet das Handelsfenster mit beiden Sets:
#       Einfaches Set, Kampfschwert, Kampfhaube, Kettenhemd,
#       Kettenhose, Kampfschild, Kampfring und Kampfamulett.
#    4) Der Händler ist auch über »trade Schmied« erreichbar.
#
#  Aufruf:  python3 Kern/tests/t_schmied.py
# ============================================================
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL, ESC

reset_tmp()
fails = 0
H = "/home/benutzer"
BASE = H + "/Schreibtisch/DesktopCity/Haupteingang"
SCHMIEDE = BASE + "/Zentrum/Schmiede"


def start(name, scalars=None, inv=None):
    sv = os.path.join(TMP, name, "manual1.save")
    vals = {"CWD": SCHMIEDE, "BITS": 500}
    vals.update(scalars or {})
    write_save(sv, scalars=vals, learned=LEARNED_ALL + ["trade"], inv=inv)
    return Sim(env={"TERMINALHERO_LOAD": "manual"},
               saves=os.path.join(TMP, name), rows=40, cols=150)


# ================================================== §1 Ordner & Dialog
with start("schmied_dialog") as s:
    r = Report("1) Schmiede: Ordner, Bruno & Standard-Dialog")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("Ordner zeigt BrunoAmboss",
            s.wait_from(m, "BrunoAmboss", 10))
    txt = s.since(m)
    r.check("Ordner zeigt den Amboss",
            bool(re.search(r"\bAmboss\b", txt)))

    m = s.mark()
    s.cmd("touch BrunoAmboss")
    r.check("Bruno begrüßt in der Schmiede",
            s.wait_from(m, "Bruno Amboss. Schmied.", 15))
    r.check("Dialog bietet »Handeln«", s.wait_from(m, "1) Handeln", 5))
    r.check("Dialog bietet »Tschau«", s.wait_from(m, "2) Tschau", 5))
    r.check("keine Skriptfehler",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))

    m = s.mark()
    s.send("2"); s.drain(0.8)
    r.check("»Tschau« verabschiedet Bruno",
            s.wait_from(m, "Tschau. Und lass die Finger", 8))
    r.check("danach wieder die Spiel-GUI", s.wait_from(m, "◈ TOKENS", 8))
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §2 Sortiment
with start("schmied_handel") as s:
    r = Report("2) Schmiede: Einfaches Set & Kampfset")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch BrunoAmboss")
    s.wait_from(m, "Bruno Amboss. Schmied.", 15)
    s.send("1"); s.drain(0.8)
    r.check("»Handeln« öffnet das Handelsfenster",
            s.wait_from(m, "TRADE TABLE", 15))
    r.check("Händler ist Bruno Amboss", s.wait_from(m, "Bruno Amboss", 5))

    # Auf die Händlerseite und vier Reiter weiter zu Waffen.
    m = s.mark()
    s.send("q"); s.send("d"); s.send("d"); s.send("d"); s.send("d")
    s.drain(0.8)
    txt = s.since(m)
    r.check("Bruno hat das Einfache Schwert",
            bool(re.search(r"Einfaches Schwert\s*×1", txt)))
    r.check("Bruno hat das Kampfschwert",
            bool(re.search(r"Kampfschwert\s*×1", txt)))
    r.check("Kampfschwert kostet 80 Bits",
            bool(re.search(r"Kampfschwert\s*×1", txt)) and "80 B" in txt)

    # Ein Reiter weiter: Rüstung.
    m = s.mark()
    s.send("d"); s.drain(0.8)
    txt = s.since(m)
    r.check("Bruno hat die Kampfhaube",
            bool(re.search(r"Kampfhaube\s*×1", txt)))
    r.check("Kampfhaube kostet 40 Bits",
            bool(re.search(r"Kampfhaube\s*×1", txt)) and "40 B" in txt)
    r.check("Bruno hat das Kettenhemd",
            bool(re.search(r"Kettenhemd\s*×1", txt)))
    r.check("Bruno hat die Kettenhose",
            bool(re.search(r"Kettenhose\s*×1", txt)))
    r.check("Bruno hat den Kampfschild",
            bool(re.search(r"Kampfschild\s*×1", txt)))
    r.check("Kampfschild kostet 90 Bits",
            bool(re.search(r"Kampfschild\s*×1", txt)) and "90 B" in txt)

    # Zwei Reiter zurück: Schmuck.
    m = s.mark()
    s.send("a"); s.send("a"); s.drain(0.8)
    txt = s.since(m)
    r.check("Bruno hat den Kampfring",
            bool(re.search(r"Kampfring\s*×1", txt)))
    r.check("Kampfring kostet 100 Bits",
            bool(re.search(r"Kampfring\s*×1", txt)) and "100 B" in txt)
    r.check("Bruno hat das Kampfamulett",
            bool(re.search(r"Kampfamulett\s*×1", txt)))
    r.check("Kampfamulett kostet 100 Bits",
            bool(re.search(r"Kampfamulett\s*×1", txt)) and "100 B" in txt)
    r.check("keine Skriptfehler",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))

    m2 = s.mark()
    s.send(ESC); s.drain(0.7)
    s.send("3"); s.drain(1.0)       # Handel abbrechen
    r.check("Brunos Dialog kehrt nach dem Handel zurück",
            s.wait_from(m2, "2) Tschau", 10))
    s.send("2", 0.6)                # Tschau
    s.send(b"\r", 0.8)              # dialog_pause
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §3 Alias
with start("schmied_alias") as s:
    r = Report("3) Schmied über »trade Schmied« erreichbar")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("trade Schmied", wait="TRADE TABLE", timeout=15)
    r.check("Händler ist Bruno Amboss", s.wait_from(m, "Bruno Amboss", 5))
    s.send(ESC); s.drain(0.7)
    s.send("3"); s.drain(1.0)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

print("\nSCHMIEDE-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
