#!/usr/bin/env python3
# ============================================================
#  TerminalHero - SurvivalShop & Jack Bones (PTY)
# ------------------------------------------------------------
#  Prüft den neuen Laden im Zentrum:
#
#    1) JackBones steht im SurvivalShop und hat den Standard-Dialog
#       mit 1) Handeln / 2) Tschau, sobald alle Lernbefehle bekannt sind.
#    2) »Handeln« öffnet das Handelsfenster mit Jacks Lager:
#       10× Einfache Fackel (20 Bits), 5× Fackel (35 Bits) und
#       1× Einfacher Schlafsack.
#    3) Börty führt weder Fackeln noch Schlafsäcke.
#    4) Je eine Fackel liegt im Download-Ordner und in der
#       eingestürzten Baracke, wird als »1x EinfacheFackel« angezeigt
#       und lässt sich mit »grep EinfacheFackel« aufheben.
#    5) Jack bietet »Befehl lernen« mit grep/search/rm und »zurück«;
#       die Preise stehen in der Auswahl, der Unterricht bucht sie ab.
#
#  Aufruf:  python3 Kern/tests/t_survivalshop.py
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
SHOP = BASE + "/Zentrum/SurvivalShop"
KNEIPE = BASE + "/Ostdistrikt/KneipeZumGoldenenLächeln"
BARACKE = BASE + "/Süddistrikt/EingestürzteBaracke"


def start(name, scalars, inv=None, learn=None):
    sv = os.path.join(TMP, name, "manual1.save")
    # »rm« gehört bei Jack dazu, damit der Standard-Dialog in den alten
    # Abschnitten weiterhin nur 1) Handeln / 2) Tschau anbietet.
    learned = learn if learn is not None else LEARNED_ALL + ["trade", "rm"]
    write_save(sv, scalars=scalars, learned=learned, inv=inv)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name),
               rows=40, cols=150)


# ================================================== §1 Dialog
with start("ss_dialog", {"CWD": SHOP, "BITS": 250}) as s:
    r = Report("1) Jack Bones: Standard-Dialog")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch JackBones")
    r.check("Jack begrüßt im SurvivalShop",
            s.wait_from(m, "Willkommen im SurvivalShop", 15))
    r.check("Dialog bietet »Handeln«", s.wait_from(m, "1) Handeln", 5))
    r.check("Dialog bietet »Tschau«", s.wait_from(m, "2) Tschau", 5))

    m = s.mark()
    s.send("2"); s.drain(0.8)
    r.check("»Tschau« verabschiedet Jack",
            s.wait_from(m, "Tschau. Und denk dran", 8))
    r.check("danach wieder die Spiel-GUI", s.wait_from(m, "◈ TOKENS", 8))
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §2 Handeln
with start("ss_handel", {"CWD": SHOP, "BITS": 250}) as s:
    r = Report("2) SurvivalShop: Sortiment & Preise")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch JackBones")
    s.wait_from(m, "Willkommen im SurvivalShop", 15)
    s.send("1"); s.drain(0.8)
    r.check("»Handeln« öffnet das Handelsfenster",
            s.wait_from(m, "TRADE TABLE", 15))
    r.check("Händler ist Jack Bones", s.wait_from(m, "Jack Bones", 5))

    # Auf die Händlerseite und zwei Reiter weiter zu Plunder.
    m = s.mark()
    s.send("q"); s.send("d"); s.send("d"); s.drain(0.7)
    txt = s.since(m)
    r.check("Händler hat 10 Fackeln",
            bool(re.search(r"Einfache Fackel\s*×10", txt)))
    r.check("Fackel kostet 20 Bits",
            bool(re.search(r"Einfache Fackel\s*×10", txt)) and "20 B" in txt)
    r.check("Händler hat 5 Fackeln",
            bool(re.search(r"Fackel\s*×5\s*35 B", txt)))
    r.check("Händler hat 1 Schlafsack",
            bool(re.search(r"Einfacher Schlafsack\s*×1", txt)))
    r.check("Schlafsack kostet 200 Bits",
            bool(re.search(r"Einfacher Schlafsack\s*×1", txt)) and "200 B" in txt)
    r.check("keine Skriptfehler",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))

    m2 = s.mark()
    s.send(ESC); s.drain(0.7)
    s.send("3"); s.drain(1.0)       # Handel abbrechen
    r.check("Jacks Dialog kehrt nach dem Handel zurück",
            s.wait_from(m2, "2) Tschau", 10))
    s.send("2", 0.6)                # Tschau
    s.send(b"\r", 0.8)              # dialog_pause
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §3 Börty
with start("ss_boerty", {"CWD": KNEIPE, "BITS": 250}) as s:
    r = Report("3) Börty führt keine Survival-Ausrüstung")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("trade Börty", wait="TRADE TABLE", timeout=15)
    s.send("q"); s.send("d"); s.send("d"); s.drain(0.7)
    txt = s.since(m)
    r.check("Börty hat LightBeer", "LightBeer ×10" in txt)
    r.check("Börty hat keine Fackeln", "Einfache Fackel" not in txt)
    r.check("Börty hat keine Schlafsäcke", "Einfacher Schlafsack" not in txt)
    s.send(ESC); s.drain(0.7)
    s.send("3"); s.drain(1.0)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §4 Fackel-Fundorte
with start("ss_fackel_downloads", {"CWD": H + "/Downloads"}) as s:
    r = Report("4) Fackel im Download-Ordner")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("ls")
    r.check("Ordner nennt Menge und vollen Namen",
            s.wait_from(m, "1x EinfacheFackel", 10))
    m = s.mark()
    s.cmd("grep EinfacheFackel")
    r.check("Fackel lässt sich aufheben",
            s.wait_from(m, "Einfache Fackel aufgenommen", 10))
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

with start("ss_fackel_baracke", {"CWD": BARACKE}) as s:
    r = Report("5) Fackel in der eingestürzten Baracke")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("grep EinfacheFackel")
    r.check("Fackel lässt sich aufheben",
            s.wait_from(m, "Einfache Fackel aufgenommen", 10))
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ================================================== §6 Befehl lernen
LEARNED_NO_JACK = [x for x in LEARNED_ALL
                   if x not in ("grep", "search", "rm")] + ["trade"]
with start("ss_lernen", {"CWD": SHOP, "BITS": 200, "SKILL_POINTS": 6},
           learn=LEARNED_NO_JACK) as s:
    r = Report("6) Jack Bones: Befehle lernen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch JackBones")
    r.check("Jack begrüßt im SurvivalShop",
            s.wait_from(m, "Willkommen im SurvivalShop", 15))
    r.check("»Befehl lernen« wird angeboten",
            s.wait_from(m, "2) Befehl lernen", 12))
    s.send("2"); s.drain(0.8)

    r.check("grep-Kurs nennt Preis",
            s.wait_from(m, "grep lernen (1 Skillpunkt, 25 Bits)", 12))
    r.check("search-Kurs nennt Preis",
            s.wait_from(m, "search lernen (2 Skillpunkte, 50 Bits)", 12))
    r.check("rm-Kurs nennt Preis",
            s.wait_from(m, "rm lernen (3 Skillpunkte, 100 Bits)", 12))
    r.check("»zurück« ist die vierte Option",
            s.wait_from(m, "4) zurück", 12))

    s.send("1"); s.drain(1.0)
    r.check("grep wird gelernt",
            s.wait_from(m, "Neuer Befehl erlernt: grep", 12))
    r.check("danach bietet das Menü search",
            s.wait_from(m, "1) search lernen", 12))
    r.check("danach bietet das Menü rm",
            s.wait_from(m, "2) rm lernen", 12))
    r.check("»zurück« bleibt am Ende",
            s.wait_from(m, "3) zurück", 12))

    s.send("3"); s.drain(0.8)
    r.check("»zurück« führt in den Standard-Dialog",
            s.wait_from(m, "3) Tschau", 12))
    s.send("3"); s.drain(0.8)
    r.check("Tschau beendet das Gespräch",
            s.wait_from(m, "Tschau. Und denk dran", 8))
    s.send(b"\r"); s.drain(0.8)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = open(os.path.join(TMP, "ss_lernen", "manual1.save"),
              encoding="utf-8").read()
    r.check("1 Skillpunkt bezahlt", "SKILL_POINTS=5" in sv)
    r.check("25 Bits bezahlt", "BITS=175" in sv)
    r.check("grep steht im Spielstand",
            bool(re.search(r"^LEARNED=\(.*\bgrep\b.*\)$", sv, re.M)))
    r.check("search bleibt vorerst gesperrt",
            not re.search(r"^LEARNED=\(.*\bsearch\b.*\)$", sv, re.M))
    r.check("rm bleibt vorerst gesperrt",
            not re.search(r"^LEARNED=\(.*\brm\b.*\)$", sv, re.M))
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ================================================== §7 cal gehört nicht zu Jack
LEARNED_NO_CAL = LEARNED_ALL + ["trade", "rm"]
with start("ss_cal", {"CWD": SHOP, "BITS": 200, "SKILL_POINTS": 1,
                      "ZEITUNG_DONE": 1},
           learn=LEARNED_NO_CAL) as s:
    r = Report("7) Survival Jack lehrt cal nicht")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch JackBones")
    r.check("Jack begrüßt im SurvivalShop",
            s.wait_from(m, "Willkommen im SurvivalShop", 15))
    r.check("ohne offene Kurse kein Lernmenü",
            s.wait_from(m, "2) Tschau", 12))
    s.drain(0.6)
    r.check("kein »Befehl lernen« für cal",
            "Befehl lernen" not in s.since(m))
    r.check("kein cal-Angebot bei Jack Bones",
            "cal" not in s.since(m).lower())
    s.send("2", 0.8)
    s.send(b"\r", 1)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = open(os.path.join(TMP, "ss_cal", "manual1.save"),
              encoding="utf-8").read()
    r.check("cal bleibt ungelernt",
            not re.search(r"^LEARNED=\(.*\bcal\b.*\)$", sv, re.M))
    r.check("cal kostet bei Jack Bones nichts",
            "SKILL_POINTS=1" in sv and "BITS=200" in sv)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

print("\nSURVIVALSHOP-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
