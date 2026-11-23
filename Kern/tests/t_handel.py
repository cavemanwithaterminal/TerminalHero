#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Handelsfenster (PTY)
# ------------------------------------------------------------
#  Das Handelsfenster im echten Terminal: Aufbau, Tasten,
#  »Taste halten = Schnellverschieben« und die beiden Wege
#  hinein (Befehl `trade Börty` / Dialogoption »Handeln.«).
#
#    1) Aufbau & Tasten: drei Fenster, Reiter, e/Enter, q, Tab,
#       Esc -> Abschlussfenster (1 bestätigen / 2 zurück /
#       3 abbrechen), Verrechnung unter dem Mittelfenster
#    2) Eine Taste HALTEN: nach 1 s wandern ~10 Stück/s
#    3) Börtys Dialog: Option »Handeln.« öffnet das Fenster
#    4) Börtys Dialog lehrt den Befehl »trade« NICHT (den bringt
#       später ein Lehrer bei) - handeln geht trotzdem
#    5) »trade <name>« nur mit Händlern im SELBEN Ordner
#
#  WICHTIG beim Halten: laufend drain() lesen. Wer nur sendet,
#  stopft den Ausgabepuffer, das Spiel hängt im Schreiben, alle
#  Tasten liegen auf Vorrat - und der Schnellmodus startet nie.
#
#  Aufruf:  python3 Kern/tests/t_handel.py
# ============================================================
import os
import re
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL,
                     Screen, ESC, RIGHT)

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
KNEIPE = CITY + "/Ostdistrikt/KneipeZumGoldenenLächeln"
OST = CITY + "/Ostdistrikt"


def start(name, scalars, inv=None, n=1, learn=None):
    """Session aus einem gepatchten Spielstand starten (Item mit <n> Stück)."""
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=learn or LEARNED_ALL + ["trade"], inv=inv)
    if inv and n != 1:
        src = open(sv, encoding="utf-8").read()
        open(sv, "w", encoding="utf-8").write(
            src.replace("[%s]=1" % inv[0], "[%s]=%d" % (inv[0], n)))
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


def screen_of(s, rows=40, cols=110):
    """Aktuellen Bildschirm nachbauen (ein Tastendruck erzwingt das Neuzeichnen)."""
    m = s.mark()
    s.send("s")
    s.drain(0.6)
    sc = Screen(rows, cols)
    sc.feed(bytes(s.buf[m:]))
    return sc


# ================================================== §1 Aufbau & Tasten
with start("hs_aufbau", {"CWD": KNEIPE, "BITS": 50}, inv=["lightbeer"], n=30) as s:
    r = Report("1) Handelsfenster: Aufbau & Tasten")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("trade Börty", wait="TRADE TABLE", timeout=15)
    txt = s.since(m)
    r.check("Fenster öffnet (TRADE TABLE)", "TRADE TABLE" in txt)
    r.check("keine Skriptfehler im Fenster",
            "command not found" not in txt and "bad array subscript" not in txt
            and "unbound variable" not in txt)
    r.check("links: DEIN INVENTAR", "DEIN INVENTAR" in txt)
    r.check("links oben: Bits des Spielers", "50 Bits" in txt)
    r.check("rechts: Händlername", "Börty Smiles" in txt)
    r.check("rechts: dem Händler geht nie das Geld aus", "∞ Bits" in txt)
    r.check("Fächer: VERKAUF und KAUF", "VERKAUF" in txt and "KAUF" in txt)
    r.check("Fußzeile nennt das Halten", "halten = schnell" in txt)
    # Bei dieser Fensterbreite passen nicht alle drei Reiter ins Bild:
    # der letzte wird durch »▶« angedeutet (mit »d« kommt er ins Bild).
    r.check("Reiterleiste sichtbar (Spezial + ▶)", "Spezial" in txt and "▶" in txt)

    # Zwei Reiter weiter: Spezial -> Quest -> Plunder
    m = s.mark()
    s.send("d"); s.send("d"); s.drain(0.6)
    txt = s.since(m)
    r.check("Spieler-Reiter Plunder zeigt die Ware", "LightBeer ×30" in txt)
    r.check("Verkaufspreis steht dabei (3 B)", "3 B" in txt)

    m = s.mark()
    s.send("e"); s.drain(0.6)
    txt = s.since(m)
    r.check("e legt genau 1 Stück ins Verkaufsfach", "LightBeer ×1" in txt)
    r.check("Verrechnung: Händler zahlt 3 Bits",
            "Börty Smiles zahlt dir 3 Bits." in txt)

    # auf die Händlerseite wechseln (eigener Reiterstand)
    m = s.mark()
    s.send("q"); s.send("d"); s.send("d"); s.drain(0.6)
    txt = s.since(m)
    r.check("q wechselt zur Händlerseite", "LightBeer ×10" in txt)
    r.check("Kaufpreis 7 B", "7 B" in txt)

    m = s.mark()
    s.send("e"); s.drain(0.6)
    txt = s.since(m)
    r.check("Kauf wird saldiert (7-3=4)", "Du zahlst 4 Bits." in txt)
    r.check("unter dem Fenster: Einzelsummen",
            "Verkauf 3 B · Kauf 7 B" in txt)

    # Rahmen nachbauen: die zwei Fächer des Trade Table müssen den Namen VOLL
    # zeigen - in einem Drittel Fensterbreite wurde er früher zu »LightBe«
    # abgeschnitten (deshalb ist die Mitte breiter als die Inventarfenster).
    d = screen_of(s).dump()
    r.check("Kopfzeile: drei Fenster nebeneinander",
            d.split("\n")[0].count("╗") == 3)
    r.check("beide Fächer zeigen Name und Stückzahl voll",
            re.search(r"LightBeer\s+×1 ║ ║ [·▸] LightBeer\s+×1 ║", d) is not None)

    # Tab ins Trade Table: dort zurücknehmen
    s.send(b"\t"); s.drain(0.4)
    r.check("Tab führt ins Trade Table", "q Hälfte" in s.text())
    s.send("q"); s.drain(0.3)
    m = s.mark()
    s.send("e"); s.drain(0.6)
    txt = s.since(m)
    r.check("Rücknahme leert das Kauf-Fach", "(nichts)" in txt)
    r.check("Saldo wieder nur Verkauf",
            "Börty Smiles zahlt dir 3 Bits." in txt)
    s.send(b"\t"); s.drain(0.3)

    # Esc -> Abschlussfenster -> abbrechen
    m0 = s.mark()
    s.send(b"\x1b"); s.drain(0.8)
    txt = s.since(m0)
    r.check("Esc fragt: Handel abschließen?", "HANDEL ABSCHLIESSEN?" in txt)
    r.check("Option 1 bestätigen", "1) Handel bestätigen" in txt)
    r.check("Option 2 zurück", "2) zurück ins Handelsfenster" in txt)
    r.check("Option 3 abbrechen", "3) Handel abbrechen" in txt)

    m = s.mark()
    # Auswahl mit ↓↓ auf »3) abbrechen« und Enter bestätigen.
    s.send(b"\x1b[B"); s.drain(0.25)
    s.send(b"\x1b[B"); s.drain(0.25)
    s.send(b"\r"); s.drain(1.2)
    r.check("↑/↓ + Enter: »abbrechen« gewählt",
            s.wait_from(m, "995 / 1000", 8))
    r.check("Abbruch: nichts getauscht", "[ HANDEL ]" not in s.since(m0))

    # ---- echter Tausch ------------------------------------------------
    m = s.mark()
    s.cmd("trade Börty", wait="TRADE TABLE", timeout=15)
    s.send("d"); s.send("d"); s.drain(0.5)
    s.send("e"); s.drain(0.6)
    s.send(b"\x1b"); s.drain(0.8)
    s.send("1"); s.drain(1.5)
    r.check("Handel wird abgeschlossen", s.wait_from(m, "[ HANDEL ]", 10))
    r.check("Bericht: verkauft ×1", s.wait_from(m, "verkauft: LightBeer ×1", 6))
    r.check("Bits 50 + 3 = 53", s.wait_from(m, "53 Bits", 6))
    r.check("danach wieder die Spiel-GUI", s.wait_from(m, "990 / 1000", 8))
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §2 Halten = schnell
with start("hs_halten", {"CWD": KNEIPE, "BITS": 50}, inv=["lightbeer"], n=30) as s:
    r = Report("2) e/Enter halten -> Schnellverschieben")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    s.cmd("trade Börty", wait="TRADE TABLE", timeout=15)
    s.send("d"); s.send("d"); s.drain(0.5)
    m = s.mark()
    # Autorepeat einer gehaltenen Taste: alle 50 ms ein »e« (bei jedem
    # Durchlauf lesen, sonst blockiert das Spiel im Schreiben - s.u.).
    end = time.time() + 2.5
    while time.time() < end:
        s.send(b"e")
        s.drain(0.05)
    s.drain(0.8)
    got = re.findall(r"zahlt dir (\d+) Bits", s.since(m))
    n = int(got[-1]) // 3 if got else -1
    r.check("Halten verschiebt viele Stücke (n >= 8)", n >= 8, extra="  n=%d" % n)
    r.check("Halten bleibt im Rahmen (n <= 24)", 0 <= n <= 24, extra="  n=%d" % n)

    m2 = s.mark()
    s.drain(1.5)
    agot = re.findall(r"zahlt dir (\d+) Bits", s.since(m2))
    n2 = int(agot[-1]) // 3 if agot else n
    r.check("nach dem Loslassen hört es auf", n2 <= n,
            extra="  n=%d n2=%d" % (n, n2))

    s.send(b"\x1b"); s.drain(0.6)
    s.send("3"); s.drain(1.0)
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()


def begruessung(s):
    """Erstes Antreffen: Börtys Vorstellung mit Enter wegdrücken."""
    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "frisches Gesicht", 15)
    s.send(b"\r", 1.0)


# ================================================== §3 Dialog: »Handeln.«
with start("hs_dialog", {"CWD": KNEIPE, "BITS": 50}, inv=["lightbeer"]) as s:
    r = Report("3) Börtys Dialog: Option »Handeln.«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    begruessung(s)
    m = s.mark()
    s.cmd("touch Börty")
    r.check("Dialog bietet »Handeln.«",
            s.wait_from(m, "Was darf sein?", 15) and s.wait_from(m, "Handeln.", 5))
    s.send("3\r")
    r.check("»Handeln.« öffnet das Handelsfenster",
            s.wait_from(m, "TRADE TABLE", 15))
    r.check("keine Skriptfehler", "command not found" not in s.since(m))
    m2 = s.mark()
    s.send(b"\x1b"); s.drain(0.6); s.send("3"); s.drain(1.0)
    r.check("Dialog kehrt nach dem Handel zurück",
            s.wait_from(m2, "Ich hab es mir anders überlegt.", 10))
    # Nach dem Handel bleibt der Dialog offen - mit der Abschiedsoption
    # verlassen (ohne ERMITTLER_DONE ist sie die Nummer 4).
    s.send("4\r", 0.6); s.send(b"\r", 0.8)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ================================================== §4 trade wird NICHT gelehrt
with start("hs_ohne_befehl", {"CWD": KNEIPE, "BITS": 50}, inv=["lightbeer"],
           learn=LEARNED_ALL) as s:
    r = Report("4) Börtys Dialog lehrt »trade« nicht")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("trade Börty")
    r.check("unbekannt: klare Antwort (kostenlos)",
            s.wait_from(m, "hat mir keiner gesagt", 12))
    begruessung(s)
    m = s.mark()
    s.cmd("touch Börty")
    r.check("Dialog erscheint", s.wait_from(m, "Was darf sein?", 15))
    s.send("3\r")
    r.check("»Handeln.« öffnet das Fenster trotzdem",
            s.wait_from(m, "TRADE TABLE", 15))
    r.check("kein Nachhilfe-Satz über den Befehl",
            "Also: »trade Börty«" not in s.since(m))
    s.send(b"\x1b"); s.drain(0.6); s.send("3"); s.drain(1.0)
    s.send("4\r", 0.6); s.send(b"\r", 0.8)
    m2 = s.mark()
    s.cmd("trade Börty")
    r.check("danach ist »trade« noch immer unbekannt",
            s.wait_from(m2, "hat mir keiner gesagt", 12))
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ================================================== §5 nur im selben Ordner
with start("hs_ordner", {"CWD": OST, "BITS": 50}, inv=["lightbeer"]) as s:
    r = Report("5) trade nur mit Händlern im selben Ordner")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("trade Börty")
    r.check("einen Ordner weiter: keine Tür", s.wait_from(m, "ist nicht hier", 12)
            and "TRADE TABLE" not in s.since(m))
    m = s.mark()
    s.cmd("trade")
    r.check("Liste hier: niemand", s.wait_from(m, "In diesem Ordner handelt niemand", 12))
    m = s.mark()
    s.cmd("cd KneipeZumGoldenenLächeln")
    s.drain(0.5)
    s.cmd("trade Börty")
    r.check("in der Kneipe klappt es", s.wait_from(m, "TRADE TABLE", 15))
    s.send(b"\x1b"); s.drain(0.6); s.send("3"); s.drain(1.0)
    m = s.mark()
    s.cmd("trade")
    r.check("Liste hier: der Wirt", s.wait_from(m, "trade Börty Smiles", 12))
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ================================================== §6 Jack: Papierhandel
VERLAG = CITY + "/Süddistrikt/DailyPulse"
with start("hs_jack", {"CWD": VERLAG, "BITS": 250,
                       "PIXI_HALL_DONE": 1, "VERLAG_DONE": 1,
                       "PIXI_GUIDE_DONE": 1, "BARACKE_SCENE_DONE": 1,
                       "ZEITUNG_GIVEN": 1, "ZEITUNG_DONE": 1},
           learn=LEARNED_ALL + ["clear", "cal"]) as s:
    r = Report("6) Jack: Dialog »Handeln.« und Papierlager")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Jack")
    r.check("Dialog bietet »Handeln.«", s.wait_from(m, "Handeln.", 15))
    s.send("1\r")
    r.check("»Handeln.« öffnet das Handelsfenster",
            s.wait_from(m, "TRADE TABLE", 15))
    r.check("Händler ist Jack Nullpunkt", s.wait_from(m, "Jack Nullpunkt", 10))
    r.check("keine Skriptfehler im Fenster",
            "command not found" not in s.since(m)
            and "unbound variable" not in s.since(m))

    # Auf die Händlerseite und zwei Reiter weiter zu Plunder.
    s.send("q"); s.drain(0.3)
    s.send("d"); s.drain(0.3)
    s.send("d"); s.drain(0.6)
    d = screen_of(s).dump()
    # In der schmalen Händlerspalte werden lange Namen abgeschnitten; für
    # den Test zählen Anfang, Stückzahl und Preis.
    r.check("Lager: 100 leere Blätter für 2 B",
            re.search(r"Leeres Blatt Pa\s+×100\s+2 B", d) is not None)
    r.check("Lager: 1 Papierbündel für 200 B",
            re.search(r"Bündel Leeres P\s+×1\s+200 B", d) is not None)

    # screen_of drückt »s« zum Neuzeichnen und wählt dabei das Bündel an.
    # Mit »w« zurück auf das einzelne Blatt.
    s.send("w"); s.drain(0.5)
    m = s.mark()
    s.send("e"); s.drain(0.6)
    r.check("Kauf eines Blattes wird verrechnet",
            s.wait_from(m, "Du zahlst 2 Bits.", 8))
    m2 = s.mark()
    s.send(b"\x1b"); s.drain(0.8)
    s.send("1"); s.drain(1.5)
    r.check("Handel wird abgeschlossen", s.wait_from(m, "[ HANDEL ]", 10))
    r.check("Bericht: Leeres Blatt Papier gekauft",
            s.wait_from(m, "gekauft : Leeres Blatt Papier ×1", 6))
    r.check("Bits 250 - 2 = 248", s.wait_from(m, "248 Bits", 6))
    r.check("Jacks Dialog kehrt nach dem Handel zurück",
            s.wait_from(m2, "Nichts weiter.", 10))

    # Nach dem Handel bleibt Jacks Dialog offen - »Nichts weiter.« wählen (2).
    s.send("2\r", 0.6); s.send(b"\r", 0.8)
    m = s.mark()
    s.cmd("inventar")
    s.wait_from(m, "INVENTAR", 20)
    s.send(RIGHT, 0.5)
    s.send(RIGHT, 0.8)
    r.check("Leeres Blatt liegt im Inventar",
            s.wait_from(m, "Leeres Blatt Papier", 20))
    r.check("Inventar: Stückzahl 1", s.wait_from(m, "Stückzahl: 1", 5))
    s.send(ESC, 0.8)
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

print("\nHANDEL-TEST: %d Fehler" % fails)
sys.exit(1 if fails else 0)
