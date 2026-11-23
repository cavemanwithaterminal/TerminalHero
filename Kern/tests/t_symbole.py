#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Ordnerfenster: Symbole & Farben (PTY)
# ------------------------------------------------------------
#  Prüft die neuen, typabhängigen Einträge im rechten Ordnerfenster:
#     Weltgegenstand (Bits)   -> ✦  grün, mit Menge (»12x Bits«)
#     Möbel (Sitzbank)        -> ▥  hellblau
#     Stadtobjekt (Kasten)    -> ▣  amber
#     Figur (TraceyBriggs)    -> ◉  Tracey-Farbe
#     Figur (README)          -> ◉  Farbe je Herkunft (Kriegsrat/Chefermittler)
#  Außerdem: die zusätzlichen Sitzbänke in DesktopCity und Haupteingang
#  sowie die Menge der Weltgegenstände (»12x Bits«).
#
#  Aufruf:  python3 Kern/tests/t_symbole.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity"
BASE = CITY + "/Haupteingang"
OST = BASE + "/Ostdistrikt"

# Farben exakt wie in kern/theme.sh (inkl. BOLD, wo gesetzt).
C_GOOD = b"\x1b[1;38;5;112m"
C_WARN = b"\x1b[1;38;5;208m"
C_MENU = b"\x1b[38;5;117m"
C_TITLE = b"\x1b[1;38;5;214m"
C_TRACEY = b"\x1b[38;5;215m"
C_MUTED = b"\x1b[38;5;240m"
# README-Figuren: Kriegsrat (BarbarConan) und Chefermittler (DetektivConan)
# liegen beide als Datei »README« in ihrem Download-Ordner.
C_RAT = b"\x1b[1;38;5;174m"
C_ERM = b"\x1b[1;38;5;111m"
C_GENERAL = b"\x1b[38;5;179m"


def start(name, cwd):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars={"CWD": cwd}, learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name),
               rows=40, cols=130)


def raw(s, mark):
    return bytes(s.buf[mark:])


def line(color, icon, name):
    """Rohe Bytefolge, die put_file für einen Eintrag ausgibt."""
    return color + (icon + " " + name).encode()


# ================================================== §1 Ostdistrikt
with start("sym_ost", OST) as s:
    r = Report("1) Typabhängige Symbole im Ostdistrikt")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("Ordnerfenster zeigt den Ostdistrikt",
            s.wait_from(m, "ORDNER: Ostdistrikt", 10))
    out = raw(s, m)

    r.check("Bits ist grün mit ✦ und Menge",
            line(C_GOOD, "✦", "12x Bits") in out)
    r.check("Sitzbank ist hellblau mit ▥", line(C_MENU, "▥", "Sitzbank") in out)
    r.check("Zeitungskasten ist amber mit ▣",
            line(C_TITLE, "▣", "Zeitungskasten") in out)
    r.check("TraceyBriggs ist eine Figur mit ◉",
            line(C_TRACEY, "◉", "TraceyBriggs") in out)
    r.check("Bits sieht nicht mehr wie eine graue Datei aus",
            line(C_MUTED, "◆", "12x Bits") not in out)

    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §2 Sitzbänke
with start("sym_benches", CITY) as s:
    r = Report("2) Sitzbank in DesktopCity und Haupteingang")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("DesktopCity-Ordner wird gezeigt",
            s.wait_from(m, "ORDNER: DesktopCity", 10))
    r.check("DesktopCity hat eine Sitzbank",
            line(C_MENU, "▥", "Sitzbank") in raw(s, m))

    m = s.mark()
    s.cmd("cat Sitzbank")
    r.check("DesktopCity-Sitzbank ist ein Möbelstück",
            s.wait_from(m, "[ EINRICHTUNG ] Sitzbank", 8))

    m = s.mark()
    s.cmd("cd Haupteingang")
    s.cmd("ls")
    r.check("Haupteingang-Ordner wird gezeigt",
            s.wait_from(m, "ORDNER: Haupteingang", 10))
    s.drain(0.5)   # Ordnerliste fertig zeichnen lassen
    r.check("Haupteingang hat eine Sitzbank",
            line(C_MENU, "▥", "Sitzbank") in raw(s, m))

    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §3 README-Figuren
DL = H + "/Downloads"
with start("sym_readme", DL) as s:
    r = Report("3) README-Figuren tragen ihre eigene Farbe")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("cd BarbarConan")
    s.cmd("ls")
    r.check("Download-Ordner BarbarConan",
            s.wait_from(m, "ORDNER: BarbarConan", 10))
    r.check("Kriegsrat-README in eigener Farbe",
            line(C_RAT, "◉", "README") in raw(s, m))
    r.check("Kriegsrat-README nicht in General-Farbe",
            line(C_GENERAL, "◉", "README") not in raw(s, m))

    m = s.mark()
    s.cmd("cd ../DetektivConan")
    s.cmd("ls")
    r.check("Download-Ordner DetektivConan",
            s.wait_from(m, "ORDNER: DetektivConan", 10))
    s.drain(0.5)   # Ordnerliste fertig zeichnen lassen
    r.check("Chefermittler-README in eigener Farbe",
            line(C_ERM, "◉", "README") in raw(s, m))
    r.check("Chefermittler-README nicht in General-Farbe",
            line(C_GENERAL, "◉", "README") not in raw(s, m))

    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


print("\nSYMBOL-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
