#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Ordnerfenster: Sortierung & Scrollen (PTY)
# ------------------------------------------------------------
#  §1 Sortierung im Ostdistrikt:
#       1 Ordner -> 2 Datei/Figur -> 3 benutzbares Objekt -> 4 Sammelbares
#       (innerhalb jeder Gruppe alphabetisch)
#  §2 Bild↑/Bild↓ blättert das ORDNER-Fenster seitenweise; der Titel
#       zeigt ▲<Offset> und/oder ▼. Bei einem neuen »ls« beginnt es oben.
#  §3 In Menü-Dialogen (ask) blättert NUR ↑/↓. Bild↑/Bild↓ werden
#       ignoriert und lösen kein Neuzeichnen aus.
#
#  Aufruf:  python3 Kern/tests/t_ordner.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, Screen, reset_tmp, TMP, write_save,
                     LEARNED_ALL)

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity"
OST = CITY + "/Haupteingang/Ostdistrikt"

PAGE_UP = b"\x1b[5~"
PAGE_DOWN = b"\x1b[6~"


def start(name, cwd, **scalars):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=dict({"CWD": cwd}, **scalars), learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name),
               rows=40, cols=130)


def screen_of(s, mark, rows=40, cols=130):
    sc = Screen(rows, cols)
    sc.feed(bytes(s.buf[mark:]))
    return sc


def right_rows(sc):
    """Nur die rechte Fensterspalte (ORDNER) je Bildschirmzeile."""
    # Bei cols=130 liegt LEFT_W bei 78, RIGHT_X bei 80 (0-basiert 80).
    return [line[80:] for line in sc.lines()]


def find_row(rows, needle):
    """Zeile, deren Eintrag exakt <needle> heißt (nicht BarbarConan.tar.gz)."""
    for i, line in enumerate(rows):
        t = line.rstrip().rstrip("║").rstrip()
        if t.endswith(needle) or t.endswith(needle + "/"):
            return i
    return -1


def is_centered(rows, needle):
    """Steht <needle> mittig in der Inhaltsbreite des rechten Fensters?"""
    row = find_row(rows, needle)
    if row < 0:
        return False
    right = rows[row]
    border = right.rfind("║")
    inner = border if border >= 0 else len(right)
    txt = right[:inner]
    lead = len(txt) - len(txt.lstrip(" "))
    return lead == (inner - len(needle)) // 2


# ================================================== §1 Sortierung
with start("ord_sort", OST) as s:
    r = Report("1) Ordnerfenster: Sortierung im Ostdistrikt")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("Ordnerfenster zeigt den Ostdistrikt",
            s.wait_from(m, "ORDNER: Ostdistrikt", 10))
    s.drain(0.4)
    rows = right_rows(screen_of(s, m))

    order = [
        "DetekteiHolmes",             # 1 Ordner (alphabetisch)
        "JimmysHaus",
        "KneipeZumGoldenenLächeln",
        "TraceyBriggs",               # 2 Datei/Figur
        "Sitzbank",                   # 3 benutzbares Objekt (alphabetisch)
        "Zeitungskasten",
        "Bits",                       # 4 Sammelbares
    ]
    pos = []
    for name in order:
        row = find_row(rows, name)
        r.check("Eintrag sichtbar: %s" % name, row >= 0)
        pos.append(row)

    r.check("Reihenfolge Ordner < Figur < benutzbar < Sammelbar",
            all(a < b for a, b in zip(pos, pos[1:])))
    r.check("Sitzbank steht vor Zeitungskasten (alphabetisch)",
            find_row(rows, "Sitzbank") < find_row(rows, "Zeitungskasten"))

    # Trenn-Überschriften vor jeder Gruppe (nur wenn die Gruppe Einträge hat).
    heads = ["---Orte---", "---Charaktere---", "---Interaktiv---", "---Sammelbar---"]
    hpos = []
    for h in heads:
        row = find_row(rows, h)
        r.check("Überschrift sichtbar: %s" % h, row >= 0)
        hpos.append(row)
    r.check("Orte-Überschrift vor DetekteiHolmes",
            hpos[0] < find_row(rows, "DetekteiHolmes"))
    r.check("Charaktere-Überschrift vor TraceyBriggs",
            hpos[1] < find_row(rows, "TraceyBriggs"))
    r.check("Interaktiv-Überschrift vor Sitzbank",
            hpos[2] < find_row(rows, "Sitzbank"))
    r.check("Sammelbar-Überschrift vor Bits",
            hpos[3] < find_row(rows, "Bits"))
    for h in heads:
        r.check("Überschrift mittig: %s" % h, is_centered(rows, h))
    r.check("Scroll-Hinweis unter dem LS-Fenster",
            "Bild↑/↓ blättern" in s.since(m))

    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §2 Seiten-Scrollen
# rows=18 -> MAIN_H=9 -> 7 sichtbare Zeilen; Downloads hat 8 Einträge.
sv = os.path.join(TMP, "ord_scroll", "manual1.save")
write_save(sv, scalars={"CWD": H + "/Downloads"}, learned=LEARNED_ALL)
with Sim(env={"TERMINALHERO_LOAD": "manual"},
         saves=os.path.join(TMP, "ord_scroll"), rows=18, cols=110) as t:
    r = Report("2) Ordnerfenster: Bild↑/Bild↓ blättert seitenweise")
    r.check("Spielstand geladen (kleines Fenster)",
            t.wait("Spielstand geladen", 20))

    m = t.mark()
    t.cmd("ls")
    r.check("Downloads-Liste erscheint",
            t.wait_from(m, "ORDNER: Downloads [8]", 10))
    t.drain(0.4)
    sc = Screen(18, 110); sc.feed(bytes(t.buf[m:]))
    rows = [line[68:] for line in sc.lines()]   # RIGHT_X=68 bei 110 Spalten
    r.check("oberste Zeile ist ein Ordner (BarbarConan)",
            find_row(rows, "BarbarConan") >= 0)
    r.check("letzter Eintrag (EinfacheFackel) noch verborgen",
            find_row(rows, "EinfacheFackel") < 0)
    r.check("Titel zeigt ▼ (mehr Inhalt darunter)",
            "▼" in t.since(m))
    r.check("Scroll-Hinweis auch im kleinen Fenster",
            "Bild↑/↓ blättern" in t.since(m))

    # --- Bild↓: eine Seite nach unten -----------------------------
    m = t.mark()
    t.send(PAGE_DOWN, 0.6)
    r.check("Bild↓ blättert (Titel mit ▲)",
            t.wait_from(m, "▲", 8))
    sc = Screen(18, 110); sc.feed(bytes(t.buf[m:]))
    rows2 = [line[68:] for line in sc.lines()]
    r.check("jetzt ist EinfacheFackel sichtbar",
            find_row(rows2, "EinfacheFackel") >= 0)
    r.check("erster Ordner ist aus dem Bild gescrollt",
            find_row(rows2, "BarbarConan") < 0)

    # --- Bild↑: wieder nach oben ---------------------------------
    m = t.mark()
    t.send(PAGE_UP, 0.6)
    r.check("Bild↑ blättert zurück (Titel ohne ▲)",
            t.wait_from(m, "ORDNER: Downloads [8]", 8))
    sc = Screen(18, 110); sc.feed(bytes(t.buf[m:]))
    rows3 = [line[68:] for line in sc.lines()]
    r.check("EinfacheFackel wieder verborgen",
            find_row(rows3, "EinfacheFackel") < 0)
    r.check("Titel wieder mit ▼", "▼" in t.since(m))

    t.cmd("exit"); t.drain(1.0)
    fails += r.done()


# ================================================== §3 Dialog nur ↑/↓
with start("ord_dialog", OST + "/DetekteiHolmes", ERMITTLER_DONE=1) as s:
    r = Report("3) Menü-Dialog: nur ↑/↓ blättert, Bild↑/Bild↓ nicht")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Amanda")
    r.check("Amandas Auswahlmenü erscheint",
            s.wait_from(m, "Was möchtest du?", 30))
    r.check("Menüpunkt 1 sichtbar",
            s.wait_from(m, "Kann ich dir helfen?", 10))

    # ↑ blättert einen Schritt hoch -> Titel zeigt ▲ 1.
    m = s.mark()
    s.send(b"\x1b[A", 0.6)
    r.check("Pfeil↑ blättert (Titel ▲ 1)",
            s.wait_from(m, "▲ 1", 8))

    # Bild↓ darf NICHT blättern und kein Neuzeichnen auslösen.
    m = s.mark()
    s.send(PAGE_DOWN, 0.8)
    new = s.since(m)
    r.check("Bild↓ löst kein Neuzeichnen aus", "AUSGABE / DIALOG" not in new)
    r.check("Bild↓ ändert den Scrollstand nicht", "▲ 1" not in new)

    # ↓ zurück nach unten.
    m = s.mark()
    s.send(b"\x1b[B", 0.6)
    r.check("Pfeil↓ blättert zurück",
            s.wait_from(m, "AUSGABE / DIALOG", 8))
    r.check("Titel ohne ▲", "▲ 1" not in s.since(m))

    # Bild↑ darf am oberen Rand ebenfalls nichts tun.
    m = s.mark()
    s.send(PAGE_UP, 0.8)
    new = s.since(m)
    r.check("Bild↑ löst kein Neuzeichnen aus", "AUSGABE / DIALOG" not in new)
    r.check("Bild↑ ändert den Scrollstand nicht", "▲ 1" not in new)

    # Menü verlassen (Punkt 2 = Nichts weiter).
    s.send("2", 0.6)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


print("\nORDNER-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
