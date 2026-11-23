#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Beschreibungsfenster im Handelsfenster (PTY)
# ------------------------------------------------------------
#  Das untere Drittel des TRADE TABLE zeigt Name und
#  Beschreibung des Gegenstands unter dem Cursor:
#
#    1) Das Fenster »BESCHREIBUNG« ist da, VERKAUF/KAUF
#       bleiben darüber sichtbar.
#    2) Cursor auf LightBeer (Reiter Plunder) -> Name und
#       Beschreibung stehen im Infofenster.
#    3) Ein Stück ins Verkaufsfach legen und mit Tab ins
#       Trade Table: der Text folgt der Auswahl im Fach.
#
#  Aufruf:  python3 Kern/tests/t_handel_info.py
# ============================================================
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL,
                     Screen, ESC)

reset_tmp()
H = "/home/benutzer"
KNEIPE = (H + "/Schreibtisch/DesktopCity/Haupteingang"
          "/Ostdistrikt/KneipeZumGoldenenLächeln")


def start(name, inv=None, n=1):
    """Session aus einem gepatchten Spielstand starten (Item mit <n> Stück)."""
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars={"CWD": KNEIPE, "BITS": 50},
               learned=LEARNED_ALL + ["trade"], inv=inv)
    if inv and n != 1:
        src = open(sv, encoding="utf-8").read()
        open(sv, "w", encoding="utf-8").write(
            src.replace("[%s]=1" % inv[0], "[%s]=%d" % (inv[0], n)))
    return Sim(env={"TERMINALHERO_LOAD": "manual"},
               saves=os.path.join(TMP, name))


def screen_of(s, rows=40, cols=110):
    """Aktuellen Bildschirm nachbauen (Tastendruck erzwingt Neuzeichnen)."""
    m = s.mark()
    s.send("s")
    s.drain(0.8)
    sc = Screen(rows, cols)
    sc.feed(bytes(s.buf[m:]))
    return sc


with start("hs_info", inv=["lightbeer"], n=30) as s:
    r = Report("Beschreibungsfenster im Trade Table")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("trade Börty", wait="TRADE TABLE", timeout=15)
    txt = s.since(m)
    r.check("Fenster öffnet (TRADE TABLE)", "TRADE TABLE" in txt)
    r.check("keine Skriptfehler im Fenster",
            "command not found" not in txt and "bad array subscript" not in txt
            and "unbound variable" not in txt)

    d = screen_of(s).dump()
    r.check("Infofenster vorhanden (BESCHREIBUNG)", "BESCHREIBUNG" in d)
    r.check("Fächer bleiben sichtbar (VERKAUF/KAUF)",
            "VERKAUF" in d and "KAUF" in d)
    r.check("Infofenster liegt unter den Fächern",
            d.find("BESCHREIBUNG") > d.find("VERKAUF") > -1)

    # Zwei Reiter weiter: Spezial -> Quest -> Plunder.
    s.send("d"); s.send("d"); s.drain(0.6)
    d = screen_of(s).dump()
    r.check("Name im Infofenster", "LightBeer" in d)
    r.check("Titel des Infofensters ist der Item-Name",
            re.search(r"╡\s*LightBeer\s*╞", d) is not None)
    r.check("Beschreibung im Infofenster", "Eine Flasche der Marke" in d)

    # Ein Stück ins Verkaufsfach, dann Tab ins Trade Table:
    # das Infofenster folgt der Auswahl im Fach.
    s.send("e"); s.drain(0.6)
    s.send(b"\t"); s.drain(0.5)
    d = screen_of(s).dump()
    r.check("Verkaufsfach zeigt das Stück", "LightBeer" in d and "×1" in d)
    r.check("Text folgt der Auswahl im Verkaufsfach",
            "Eine Flasche der Marke" in d)

    # Abschlussdialog öffnen und abbrechen, dann sauber beenden.
    s.send(ESC, 0.4)
    s.send("3", 0.8)
    s.cmd("exit")
    s.drain(1.0)
    fails = r.done()

print("\nHANDEL-INFO-TEST: %d Fehler" % fails)
sys.exit(1 if fails else 0)
