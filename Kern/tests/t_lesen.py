#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Lesbare Zeitungen (PTY)
# ------------------------------------------------------------
#  Prüft die neue Lese-Mechanik:
#
#    1) Die erste DailyPulse-Ausgabe liegt im Inventar (Quest),
#       zeigt die drei Standardoptionen und öffnet mit »benutzen«
#       das Lesefenster. Der Artikel ist scrollbar; Q schließt nur
#       das Lesefenster, nicht das Inventar.
#    2) Die Sperrzone-Ausgabe funktioniert genauso; Esc schließt
#       das Lesefenster und danach das Inventar.
#
#  Aufruf:  python3 Kern/tests/t_lesen.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL, ESC, RIGHT, DOWN

reset_tmp()
fails = 0
H = "/home/benutzer"
PAGE_DOWN = b"\x1b[6~"


def start(name, inv):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars={"CWD": H, "SHOW_LS": 0},
               learned=LEARNED_ALL, inv=inv)
    return Sim(env={"TERMINALHERO_LOAD": "manual"},
               saves=os.path.join(TMP, name))


def open_quest_item(s):
    """Inventar öffnen, auf den Quest-Reiter und in die Item-Liste."""
    s.cmd("inventar", wait="INVENTAR", timeout=15)
    s.send(RIGHT); s.drain(0.25)      # Spezial -> Quest
    s.send(DOWN);  s.drain(0.25)      # Reiter -> Item-Liste


# ================================================== §1 Bezirke der Stadt
with start("lesen_bezirke", ["bezirke"]) as s:
    r = Report("1) Bezirke der Stadt: Artikel lesen und scrollen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    open_quest_item(s)
    m = s.mark()
    s.send("e"); s.drain(0.7)
    r.check("Item-Fenster zeigt die Zeitung",
            s.wait_from(m, 'Item "Bezirke der Stadt" benutzen?', 8))
    r.check("Option 1: benutzen", s.wait_from(m, "1) benutzen", 3))
    r.check("Option 2: ablegen", s.wait_from(m, "2) ablegen", 3))
    r.check("Option 3: nichts tun", s.wait_from(m, "3) nichts tun", 3))

    m = s.mark()
    s.send(b"\r"); s.drain(1.0)
    r.check("Lesefenster öffnet sich", s.wait_from(m, "LESEN", 8))
    r.check("Lesefenster nennt den Titel",
            s.wait_from(m, "Bezirke der Stadt", 3))
    r.check("Artikelkopf ist sichtbar",
            s.wait_from(m, "DAILYPULSE · AUSGABE 1 · 10 BITS", 5))
    r.check("erste Seite ist sichtbar",
            s.wait_from(m, "Der Norddistrikt liegt im Norden.", 5))

    # Mehrfach blättern: Der Text ist länger als eine Bildschirmseite.
    m = s.mark()
    for _ in range(10):
        s.send(PAGE_DOWN); s.drain(0.12)
    r.check("Artikel lässt sich bis zum Ende scrollen",
            s.wait_from(m, "Schlussbemerkung", 8))

    # Q schließt nur das Lesefenster; das Inventar bleibt offen.
    m = s.mark()
    s.send("q"); s.drain(0.7)
    r.check("Q schließt das Lesefenster", s.wait_from(m, "INVENTAR", 8))
    r.check("Q beendet nicht das Inventar", "◈ TOKENS" not in s.since(m))

    m = s.mark()
    s.send(ESC); s.drain(0.8)
    r.check("Esc schließt danach das Inventar",
            s.wait_from(m, "◈ TOKENS", 8))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §2 Die Sperrzone
with start("lesen_sperrzone", ["sperrzone"]) as s:
    r = Report("2) Die Sperrzone: Artikel lesen und mit Esc schließen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    open_quest_item(s)
    m = s.mark()
    s.send("e"); s.drain(0.7)
    r.check("Item-Fenster zeigt die Sperrzone",
            s.wait_from(m, 'Item "Die Sperrzone" benutzen?', 8))
    r.check("auch hier gibt es drei Optionen",
            s.wait_from(m, "3) nichts tun", 3))

    m = s.mark()
    s.send(b"\r"); s.drain(1.0)
    r.check("Lesefenster öffnet sich", s.wait_from(m, "LESEN", 8))
    r.check("Lesefenster nennt den Titel",
            s.wait_from(m, "Die Sperrzone", 3))
    r.check("Kernsatz steht auf Seite 1",
            s.wait_from(m, "Die Sperrzone ist kein Ort", 5))

    m = s.mark()
    for _ in range(10):
        s.send(PAGE_DOWN); s.drain(0.12)
    r.check("Bericht lässt sich bis zum Impressum scrollen",
            s.wait_from(m, "Erscheinungsweise: wenn die Stadt bereit ist", 8))

    # Esc schließt das Lesefenster; das Inventar bleibt zunächst offen.
    m = s.mark()
    s.send(ESC); s.drain(0.7)
    r.check("Esc schließt das Lesefenster", s.wait_from(m, "INVENTAR", 8))

    m = s.mark()
    s.send(ESC); s.drain(0.8)
    r.check("Esc schließt danach das Inventar",
            s.wait_from(m, "◈ TOKENS", 8))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

print("\nLESEN-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
