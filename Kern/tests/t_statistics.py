#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Michael Mitch & Statistics (PTY)
# ------------------------------------------------------------
#    1) Restaurantszene: MichaelMitch steht im Westdistrikt und stellt
#       sich beim ersten »touch« vor.
#    2) Ingame-Befehl »statistics«: eigenes Fenster mit echter Spielzeit,
#       Questzahlen (Haupt/Neben), Zeitungs-Ausgaben und verdienten Bits.
#
#  Aufruf:  python3 Kern/tests/t_statistics.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL,
                     Screen, ESC)

reset_tmp()
fails = 0
H = "/home/benutzer"
RESTAURANT = H + "/Schreibtisch/DesktopCity/Haupteingang/Westdistrikt/Restaurant"


def start(name, scalars, inv=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=LEARNED_ALL, inv=inv)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


with start("statistics",
           {"CWD": RESTAURANT, "BITS": 42, "BITS_EARNED": 1234,
            "PLAYTIME_BASE": 3723,
            "VERLAG_DONE": 1, "BARACKE_SCENE_DONE": 1,
            "BIER_FAILED": 1, "MICHAEL_INTRO_DONE": 0},
           inv=["bezirke"]) as s:
    r = Report("1) Restaurant, Michael Mitch & Statistics")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    # --- Michael Mitch steht im Restaurant -----------------------------
    m = s.mark()
    s.cmd("ls")
    r.check("MichaelMitch steht im Restaurant",
            s.wait_from(m, "MichaelMitch", 15))

    m = s.mark()
    s.cmd("cat MichaelMitch")
    r.check("die Datei nennt seinen Namen",
            s.wait_from(m, "MICHAEL MITCH", 15))
    r.check("und seine Rolle", s.wait_from(m, "Service & Küche", 15))

    m = s.mark()
    s.cmd("touch MichaelMitch")
    r.check("er stellt sich vor", s.wait_from(m, "Michael Mitch.", 20))
    r.check("er war Börtys Lagergehilfe",
            s.wait_from(m, "Ich war Börtys Lagergehilfe", 20))
    r.check("und arbeitet jetzt im Restaurant",
            s.wait_from(m, "Jetzt arbeite ich hier", 20))
    r.check("keine Skriptfehler im Gespräch",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))
    s.send(b"\r", 1.2)

    # --- Statistics-Fenster -------------------------------------------
    m = s.mark()
    s.cmd("statistics")
    r.check("Statistik-Fenster öffnet", s.wait_from(m, "STATISTICS", 15))
    r.check("echte Spielzeit wird angezeigt",
            s.wait_from(m, "Echtzeit gesamt", 15)
            and s.wait_from(m, "01 h 02 min", 15))

    r.check("Hauptquests: erledigt", s.wait_from(m, "erledigt 2", 15))
    r.check("Hauptquests: gescheitert", s.wait_from(m, "gescheitert 0", 15))
    r.check("Hauptquests: gesamt", s.wait_from(m, "gesamt 7", 15))
    r.check("Nebenquests: erledigt", s.wait_from(m, "erledigt 1", 15))
    r.check("Nebenquests: gescheitert", s.wait_from(m, "gescheitert 1", 15))
    r.check("Nebenquests: gesamt", s.wait_from(m, "gesamt 14", 15))
    r.check("Zeitungen: im Besitz", s.wait_from(m, "im Besitz 1", 15))
    r.check("Zeitungen: gesamt", s.wait_from(m, "gesamt 3", 15))
    r.check("verdiente Bits label", s.wait_from(m, "Gesammelt", 15))
    r.check("verdiente Bits", s.wait_from(m, "1234 Bits", 15))
    # --- Layout: »LIVE« darf das Eckzeichen nicht berühren --------------
    # ui_corners zeichnet das ◢ NACH dem Inhalt. Kurz fertig zeichnen
    # lassen, sonst kann der Screen-Snapshot mitten im letzten Frame
    # entstehen (Flake ohne echten Layoutfehler).
    s.drain(0.5)
    sc = Screen(40, 110)
    sc.feed(bytes(s.buf[m:]))
    top = next((ln for ln in sc.lines() if "STATISTICS" in ln), "")
    r.check("LIVE lässt die Ecke frei", "LIVE ◢" in top,
            "  [" + top.strip() + "]")
    r.check("keine Skriptfehler im Fenster",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))

    s.send(ESC, 0.8)
    m = s.mark()
    s.cmd("save")
    r.check("Statistik wird gespeichert",
            s.wait_from(m, "Spielstand in Slot", 15))
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# Der Spielstand muss die Statistikwerte mitschreiben.
save_text = open(os.path.join(TMP, "statistics", "manual1.save"),
                 encoding="utf-8").read()
print("OK   Save enthält verdiente Bits" if "BITS_EARNED=1234" in save_text
      else "FAIL Save enthält verdiente Bits")
print("OK   Save enthält echte Spielzeit" if "PLAYTIME_BASE=" in save_text
      else "FAIL Save enthält echte Spielzeit")
if "BITS_EARNED=1234" not in save_text or "PLAYTIME_BASE=" not in save_text:
    fails += 1

print("\nSTATISTICS-TESTS: %d Fehler" % fails)
sys.exit(1 if fails else 0)
