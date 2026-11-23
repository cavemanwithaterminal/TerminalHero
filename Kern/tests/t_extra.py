#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Extra-Ausgabe nach Neks Beerdigung (PTY)
# ------------------------------------------------------------
#  Prüft die fünftägige Sonderausgabe:
#    1) Sie erscheint erst am Tag nach der Beerdigung, nicht mehr
#       am Trauertag selbst.
#    2) Zeitungskästen zeigen und verkaufen sie zusätzlich zur
#       Hauptausgabe.
#    3) Tracey Briggs verkauft sie ebenfalls für 10 Bits.
#    4) Jimmy verhandelt sie mit denselben drei Preisen und EXP-
#       Stufen wie die Sperrzone-Ausgabe (hier: 50 Bits -> 250 EXP).
#    5) Jack Nullpunkt lehrt »cal« für 2 Skillpunkte + 50 Bits.
#
#  Aufruf:  python3 Kern/tests/t_extra.py
# ============================================================
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
SUED = CITY + "/Süddistrikt"
OST = CITY + "/Ostdistrikt"
VERLAG = SUED + "/DailyPulse"
JIMMY = OST + "/JimmysHaus"

DAY5_1600 = 19500
DAY6_0600 = 21600


def start(name, scalars, inv=None, learned=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, inv=inv, learned=learned or LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual", "TH_SAY_SECS": "0.02"},
               saves=os.path.join(TMP, name))


def save_text(name):
    return open(os.path.join(TMP, name, "manual1.save"), encoding="utf-8").read()


def extra_on(day=0, until=4):
    return {"ZEITUNG_EXTRA_DAY": day, "ZEITUNG_EXTRA_UNTIL": until,
            "ZEITUNG_EXTRA_SHOWN": 1}


# ============================= §1 Erscheinen erst nach der Beerdigung
with start("extra_am_trauertag", {
        "CWD": CITY, "WORLD_SECS": DAY5_1600,
        "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DONE": 1,
        "NEK_FUNERAL_FAILED": 0, "NEK_FUNERAL_DAY": 5,
        "ZEITUNG_EXTRA_DAY": -1, "ZEITUNG_EXTRA_UNTIL": -1,
        "ZEITUNG_EXTRA_SHOWN": 0}) as s:
    r = Report("1) Extra-Ausgabe erscheint nicht am Trauertag")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    s.drain(1.5)
    r.check("kein Erscheinen-Hinweis am selben Tag",
            "Extra-Ausgabe erschienen" not in s.text())
    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    s.drain(0.8)
    sv = save_text("extra_am_trauertag")
    r.check("Zeitraum bleibt ungesetzt", "ZEITUNG_EXTRA_DAY=-1" in sv)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

with start("extra_nach_trauer", {
        "CWD": CITY, "WORLD_SECS": DAY6_0600,
        "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DONE": 1,
        "NEK_FUNERAL_FAILED": 0, "NEK_FUNERAL_DAY": 5,
        "ZEITUNG_EXTRA_DAY": -1, "ZEITUNG_EXTRA_UNTIL": -1,
        "ZEITUNG_EXTRA_SHOWN": 0}) as s:
    r = Report("2) Extra-Ausgabe erscheint nach der Rückkehr")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("DailyPulse meldet die Extra-Ausgabe",
            s.wait("Extra-Ausgabe erschienen", 20))
    r.check("Hinweis nennt Kästen und Tracey",
            s.wait("an allen fünf Zeitungskästen und bei Tracey", 10))
    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    s.drain(0.8)
    sv = save_text("extra_nach_trauer")
    r.check("erster Verkaufstag ist Tag 6", "ZEITUNG_EXTRA_DAY=6" in sv)
    r.check("letzter Verkaufstag ist Tag 10",
            "ZEITUNG_EXTRA_UNTIL=10" in sv)
    r.check("Erscheinen wurde gemeldet", "ZEITUNG_EXTRA_SHOWN=1" in sv)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ==================================== §3 Zeitungskasten verkauft Extra
with start("extra_kasten", {
        "CWD": SUED, "BITS": 30, "ZEITUNG_EDITION": "bezirke",
        "ZEITUNG_EMPTIED": 0, **extra_on()}) as s:
    r = Report("3) Zeitungskasten: Haupt- und Extra-Ausgabe")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("use Zeitungskasten")
    r.check("Kasten zeigt beide Ausgaben",
            s.wait_from(m, "Extra-Ausgabe: Extra-Ausgabe: Nek Molerat", 15))
    r.check("Extra-Ausgabe kostet 10 Bits",
            s.wait_from(m, "Preis: 10 Bits", 8))
    r.check("Extra-Ausgabe ist kaufbar",
            s.wait_from(m, "2) Extra-Ausgabe kaufen", 8))
    s.send("2", 0.8)
    r.check("Extra-Ausgabe wird verkauft",
            s.wait_from(m, "[ Zeitung ] Extra-Ausgabe: Nek Molerat", 15))
    r.check("Kauf kostet 10 Bits",
            s.wait_from(m, "[ Bits ] -10 Bits", 8))
    s.send(b"\r", 0.8)                    # Kauf-Pause schließen
    r.check("Kastenmenü erscheint erneut",
            s.wait_from(m, "3) Nichts tun", 10))
    s.send("3", 0.8)                      # Nichts tun
    s.send(b"\r", 0.8)                    # Dialog schließen
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ========================================= §4 Tracey verkauft Extra
with start("extra_tracey", {
        "CWD": OST, "BITS": 20, "ZEITUNG_EDITION": "bezirke",
        "TRACEY_FOUND": 0, "TRACEY_GIVEN": 0, "TRACEY_DONE": 0,
        "JIMMY_FIRST_SALE": 0, **extra_on()}) as s:
    r = Report("4) Tracey Briggs: Extra-Ausgabe für 10 Bits")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch TraceyBriggs")
    r.check("Tracey erwähnt den Nachruf",
            s.wait_from(m, "Die Extra-Ausgabe mit Neks Nachruf", 15))
    r.check("Extra-Ausgabe ist wählbar",
            s.wait_from(m, "2) Extra-Ausgabe kaufen (10 Bits)", 8))
    s.send("2", 0.8)
    r.check("Tracey verkauft die Extra-Ausgabe",
            s.wait_from(m, "[ Zeitung ] Extra-Ausgabe: Nek Molerat", 15))
    r.check("Kauf kostet 10 Bits",
            s.wait_from(m, "[ Bits ] -10 Bits", 8))
    s.send(b"\r", 0.8)                    # Kauf-Pause schließen
    r.check("Verkaufsmenü erscheint erneut",
            s.wait_from(m, "3) Nichts weiter.", 10))
    s.send("3", 0.8)                      # Nichts weiter
    s.send(b"\r", 0.8)                    # Dialog schließen
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ================================ §5 Jimmy verhandelt die Extra-Ausgabe
with start("extra_jimmy", {
        "CWD": JIMMY, "BITS": 0, "LEVEL": 0, "EXP": 0,
        "SKILL_POINTS": 0, "ZEITUNG_EDITION": "bezirke",
        "JIMMY_GIVEN": 1, "JIMMY_TRACEY_DONE": 1,
        "JIMMY_INTRO_DONE": 1, "JIMMY_LAST_SOLD": "",
        "JIMMY_FIRST_SALE": 0}, inv=["extraausgabe"]) as s:
    r = Report("5) Jimmy: Extra-Ausgabe, 50 Bits -> 250 EXP")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch JimmyPage")
    r.check("Jimmy erkennt die Extra-Ausgabe",
            s.wait_from(m, "Hast du die Extra-Ausgabe? Die mit Neks Nachruf?",
                        15))
    s.send("1", 0.8)                      # verkaufen
    r.check("Jimmy verhandelt den Preis",
            s.wait_from(m, "Also – was willst du dafür?", 10))
    r.check("drei Preise wie bei der Sperrzone",
            s.wait_from(m, "3) 100 Bits.", 8))
    r.check("erster Preis ist 50 Bits",
            s.wait_from(m, "1) 50 Bits.", 8))
    s.send("1", 0.8)                      # 50 Bits
    r.check("Jimmy zahlt 50 Bits",
            s.wait_from(m, "[ Bits ] +50 Bits", 10))
    r.check("Jimmy gibt 250 EXP",
            s.wait_from(m, "[ EXP ] +250", 10))
    r.check("Jimmy bietet cal kostenpflichtig an",
            s.wait_from(m, "cal lernen (2 Skillpunkte, 50 Bits)", 10))
    s.send("2", 0.8)                      # ablehnen
    s.send(b"\r", 0.8)                    # Dialog schließen

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    s.drain(0.8)
    sv = save_text("extra_jimmy")
    r.check("Jimmy hat die Extra-Ausgabe angenommen",
            "JIMMY_LAST_SOLD=extraausgabe" in sv)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

# ================================= §6 Jack Nullpunkt: cal kostet
JACK_LEARNED = LEARNED_ALL + ["clear", "trade"]
with start("extra_jack_cal", {
        "CWD": VERLAG, "BITS": 100, "SKILL_POINTS": 2,
        "ZEITUNG_DONE": 1, "BARACKE_SCENE_DONE": 1,
        "PIXI_DESKTOP_DONE": 1, "PIXI_GATE_DONE": 1,
        "PIXI_HALL_DONE": 1, "VERLAG_DONE": 1,
        "PIXI_GUIDE_DONE": 1}, learned=JACK_LEARNED) as s:
    r = Report("6) Jack Nullpunkt: cal für 2 Skillpunkte + 50 Bits")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Jack begrüßt im Verlag",
            s.wait_from(m, "Was möchtest du?", 15))
    r.check("Lernangebot ist sichtbar",
            s.wait_from(m, "1) Befehl lernen", 8))
    s.send("1", 0.8)
    r.check("cal kostet 2 Skillpunkte und 50 Bits",
            s.wait_from(m, "1) cal Befehl lernen (2 Skillpunkte, 50 Bits)",
                        10))
    s.send("1", 0.8)
    r.check("cal wird gelernt",
            s.wait_from(m, "Neuer Befehl erlernt: cal", 10))
    r.check("Kosten werden abgezogen",
            s.wait_from(m, "[ Skillpunkte ] -2 · [ Bits ] -50 Bits", 10))
    m2 = s.mark()
    s.send(b"\r", 0.8)                    # Lern-Pause schließen
    r.check("Hauptmenü erscheint nach dem Lernen",
            s.wait_from(m2, "Nichts weiter.", 10))
    s.send("2", 0.8)                      # Hauptmenü: Nichts weiter.
    s.send(b"\r", 0.8)                    # Dialog schließen

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    s.drain(0.8)
    sv = save_text("extra_jack_cal")
    learned_block = sv.split("LEARNED=(", 1)[-1].split(")", 1)[0]
    r.check("cal steht im Spielstand",
            bool(re.search(r"(^|\s)(\[\d+\]=)?cal(\s|$)", learned_block)))
    r.check("Skillpunkte sind verbraucht", "SKILL_POINTS=0" in sv)
    r.check("Bits sind verbraucht", "BITS=50" in sv)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()

sys.exit(1 if fails else 0)
