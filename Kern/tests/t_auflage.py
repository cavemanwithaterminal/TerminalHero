#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Die neueste Auflage: Sperrzone (PTY)
# ------------------------------------------------------------
#  Prüft die Kette nach Pixis Stadtrundgang:
#    1) Rachel bietet »Neuste Auflage« an, vergibt die Hauptquest
#       ohne Ablehnung, gibt fünf Bündel und den Schlüssel. Tracey
#       verschwindet aus dem Verlag und verkauft auf ihrer Stadttour
#       (Tourstart im Süddistrikt).
#    2) Alle fünf Zeitungskästen werden je einmal befüllt; danach
#       verkaufen sie die Sperrzone-Ausgabe. Rachel nimmt den Bericht
#       entgegen (50 Bits, ein Exemplar, 500 EXP), Pixi kommentiert,
#       und der Jimmy-Hinweis erscheint.
#    3) Jimmy verhandelt die Sperrzone-Ausgabe: 50 Bits -> 250 EXP.
#    4) Jimmy verhandelt sie für 100 Bits: 0 EXP, dafür 100 Bits.
#
#  Aufruf:  python3 Kern/tests/t_auflage.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
SUED = CITY + "/Süddistrikt"
ZENTRUM = CITY + "/Zentrum"
OST = CITY + "/Ostdistrikt"
NORD = CITY + "/Norddistrikt"
WEST = CITY + "/Westdistrikt"
VERLAG = SUED + "/DailyPulse"
JIMMY = OST + "/JimmysHaus"


def start(name, scalars, inv=None, inv_counts=None):
    d = os.path.join(TMP, name)
    write_save(os.path.join(d, "manual1.save"), scalars=scalars,
               learned=LEARNED_ALL, inv=inv, inv_counts=inv_counts)
    return Sim(env={
        "TERMINALHERO_LOAD": "manual",
        "TH_SAY_SECS": "0.02",
        "TH_SLEEP_SECS": "0.2",
        "TH_SIT_SECS": "0.2",
    }, saves=d)


def after_tour(**extra):
    vals = {
        "CWD": VERLAG,
        "PIXI_DESKTOP_DONE": 1,
        "PIXI_GATE_DONE": 1,
        "PIXI_HALL_DONE": 1,
        "VERLAG_DONE": 1,
        "PIXI_GUIDE_DONE": 1,
        "BARACKE_SCENE_DONE": 1,
        "PIXI_LETTER_DONE": 1,
        "SHERLOCK_BRIEF": 1,
        "SHERLOCK_DONE": 1,
        "SHERLOCK_HUNT": 1,
        "SHERLOCK_NORD": 1,
        "ERMITTLER_DONE": 1,
        "ZEITUNG_GIVEN": 1,
        "ZEITUNG_DONE": 1,
        "RUNDGANG_GIVEN": 1,
        "RUNDGANG_DONE": 1,
        "ZEITUNG_EDITION": "sperrzone",
        "ZEITUNG_EMPTIED": 31,
        "TRACEY_GIVEN": 1,
        "TRACEY_FOUND": 1,
        "TRACEY_DONE": 1,
        "JIMMY_INTRO_DONE": 1,
        "JIMMY_TRACEY_DONE": 1,
        "JIMMY_GIVEN": 1,
        "AUFLAGE_GIVEN": 0,
        "AUFLAGE_DONE": 0,
        "TOKENS_CUR": 1000,
        "WORLD_STARTED": 1,
        "WORLD_SECS": 0,
    }
    vals.update(extra)
    return vals


def publisher(**extra):
    return after_tour(**extra)


# ================================================ §1 Rachel & Tracey
with start("auflage_rachel", publisher(BITS=0)) as s:
    r = Report("1) Rachel: Neuste Auflage, fünf Bündel, Schlüssel")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Rachel")
    r.check("Rachel bietet die neue Auflage an",
            s.wait_from(m, "Neuste Auflage.", 20))
    s.send("1", 0.6)
    r.check("Rachel nennt die Sperrzone-Ausgabe",
            s.wait_from(m, "Die neue Ausgabe. Die über die Sperrzone.", 20))
    r.check("Rachel verlangt fünf Kästen",
            s.wait_from(m, "Fünf Bündel, fünf Zeitungskästen", 20))
    r.check("Rachel lässt keine Ablehnung zu",
            s.wait_from(m, "Nein, du kannst nicht ablehnen", 20))
    r.check("die Hauptquest wird vergeben",
            s.wait_from(m, "»Die neueste Auflage: Sperrzone« erhalten", 20))
    r.check("der Schlüssel kommt mit",
            s.wait_from(m, "[ Zeitungskastenschlüssel ]", 20))
    r.check("fünf Bündel kommen mit",
            s.wait_from(m, "[ Sperrzone-Bündel ] +5", 20))
    r.check("das Ziel nennt den Kasten-Befehl",
            s.wait_from(m, "use Zeitungskasten", 20))
    s.send(b"\r", 1.0)

    m = s.mark()
    s.cmd("inventar")
    s.wait_from(m, "Quest", 20)
    s.send(b"\x1b[C", 0.8)                  # Reiter: Quest
    r.check("fünf Sperrzone-Bündel im Inventar",
            s.wait_from(m, "Sperrzone-Bündel ×5", 20))
    r.check("Schlüssel im Inventar",
            s.wait_from(m, "Zeitungskastenschlüssel", 20))
    s.send(b"\x1b", 0.8)

    # Mit Rachels Bündeln bleibt Tracey auf ihrer Stadttour. Der Tourstart
    # liegt beim Laden bei WORLD_SECS=0, also steht sie im Süddistrikt;
    # dort verkauft sie die neue Ausgabe.
    m = s.mark()
    s.cmd("ls")
    r.check("Tracey ist aus dem DailyPulse verschwunden",
            not s.wait_from(m, "TraceyBriggs", 4))

    s.cmd("cd Süddistrikt")
    s.drain(0.6)
    m = s.mark()
    s.cmd("ls")
    r.check("Tracey beginnt die Tour im Süddistrikt",
            s.wait_from(m, "TraceyBriggs", 15))

    m = s.mark()
    s.cmd("touch TraceyBriggs")
    r.check("Tracey-Gespräch nennt die Stadttour",
            s.wait_from(m, "SÜDDISTRIKT · STADTTOUR", 20))
    r.check("Tracey hat die Sperrzone-Ausgabe",
            s.wait_from(m, "Die Sperrzone-Ausgabe? Ja, ich hab ein paar dabei.", 20))
    r.check("Tracey nennt den aktuellen Titel",
            s.wait_from(m, "Aktuelle Ausgabe: »Die Sperrzone«", 20))
    s.send("2", 0.8)                        # Nichts weiter.
    s.send(b"\r", 0.8)

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    s.drain(0.8)
    save = open(os.path.join(TMP, "auflage_rachel", "manual1.save"),
                encoding="utf-8").read()
    r.check("AUFLAGE_GIVEN ist gesichert", "AUFLAGE_GIVEN=1" in save)
    r.check("die neue Edition ist gesichert",
            "ZEITUNG_EDITION=sperrzone" in save)
    r.check("alle fünf Kästen warten leer", "ZEITUNG_EMPTIED=31" in save)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================================ §2 Kästen & Abschluss
with start("auflage_verteilung",
           publisher(CWD=SUED, AUFLAGE_GIVEN=1, AUFLAGE_DONE=0,
                     BITS=0, JIMMY_GIVEN=1),
           inv=["zeitungsschluessel"],
           inv_counts={"sperrzonebuendel": 5}) as s:
    r = Report("2) Fünf Kästen befüllen, Rachels Bericht, Pixi & Jimmy")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    boxes = [
        ("Süddistrikt", SUED),
        ("Zentrum", ZENTRUM),
        ("Ostdistrikt", OST),
        ("Norddistrikt", NORD),
        ("Westdistrikt", WEST),
    ]
    for idx, (name, path) in enumerate(boxes, 1):
        s.cmd("cd %s" % path)
        s.drain(0.6)
        m = s.mark()
        s.cmd("use Zeitungskasten")
        r.check("%s: Befüllen wird angeboten" % name,
                s.wait_from(m, "Zeitungskasten befüllen.", 20))
        s.send("1", 0.6)
        r.check("%s: Fortschritt %d/5" % (name, idx),
                s.wait_from(m, "Zeitungskasten befüllt: %d/5" % idx, 20))
        s.send(b"\r", 0.8)

    # Der zuletzt befüllte Kasten verkauft jetzt die neue Ausgabe.
    m = s.mark()
    s.cmd("use Zeitungskasten")
    r.check("befüllter Kasten verkauft die Sperrzone",
            s.wait_from(m, "Exemplar kaufen", 20))
    r.check("die neue Ausgabe liegt im Kasten",
            s.wait_from(m, "Die Sperrzone", 20))
    s.send("2", 0.8)                        # Nichts tun.
    s.send(b"\r", 0.8)

    s.cmd("save")
    s.wait("Spielstand in Slot", 20)
    s.drain(0.8)
    save = open(os.path.join(TMP, "auflage_verteilung", "manual1.save"),
                encoding="utf-8").read()
    r.check("alle Kästen sind voll", "ZEITUNG_EMPTIED=0" in save)
    r.check("die Auflage läuft noch", "AUFLAGE_GIVEN=1" in save)
    r.check("noch kein Abschluss", "AUFLAGE_DONE=0" in save)
    r.check("keine Bündel mehr", "sperrzonebuendel" not in save)

    # Zurück zu Rachel: Bericht erstatten.
    s.cmd("cd %s" % VERLAG)
    s.drain(0.6)
    m = s.mark()
    s.cmd("touch Rachel")
    r.check("Rachel fragt nach dem Fortschritt",
            s.wait_from(m, "Alle fünf? Dann her mit dem Bericht.", 20))
    s.send("1", 0.6)
    r.check("Rachel bedankt sich",
            s.wait_from(m, "Alle fünf. Gut.", 20))
    r.check("50 Bits werden ausgezahlt",
            s.wait_from(m, "[ Bits ] +50", 20))
    r.check("der Agent bekommt ein Exemplar",
            s.wait_from(m, "[ Zeitung ] Die Sperrzone", 20))
    r.check("Rachel verlangt den Kastenschlüssel zurück",
            s.wait_from(m, "Den Zeitungskastenschlüssel brauche ich zurück.", 20))
    r.check("der Kastenschlüssel wird abgegeben",
            s.wait_from(m, "[ Zeitungskastenschlüssel ] -1", 20))
    r.check("Pixi ist physisch da und kommentiert",
            s.wait_from(m, "Und ich erst!", 20))
    r.check("Pixi nennt die Reaktion der Leute",
            s.wait_from(m, "Die werden ihren Augen nicht trauen!", 20))
    r.check("500 EXP werden gutgeschrieben",
            s.wait_from(m, "Questbelohnung: 500 EXP", 20))
    r.check("die Quest ist abgeschlossen",
            s.wait_from(m, "»Die neueste Auflage: Sperrzone«", 20))
    r.check("der Jimmy-Hinweis erscheint",
            s.wait_from(m, "Ich sollte Jimmy ein Exemplar bringen.", 20))
    s.send(b"\r", 1.0)

    # Rachel und Pixi haben neue Standardgespräche.
    m = s.mark()
    s.cmd("touch Rachel")
    r.check("Rachels neuer Standard nennt die volle Stadt",
            s.wait_from(m, "Die Sperrzone-Ausgabe liegt in allen fünf Kästen.", 20))
    s.send(b"\r", 0.8)

    m = s.mark()
    s.cmd("touch Pixi")
    r.check("Pixis neuer Standard nennt die Ausgabe",
            s.wait_from(m, "Die Sperrzone-Ausgabe ist raus.", 20))
    r.check("Pixi freut sich auf die Reaktionen",
            s.wait_from(m, "Die werden ihren Augen nicht trauen!", 20))
    s.send(b"\r", 0.8)

    s.cmd("save")
    s.wait("Spielstand in Slot", 20)
    s.drain(0.8)
    save = open(os.path.join(TMP, "auflage_verteilung", "manual1.save"),
                encoding="utf-8").read()
    r.check("AUFLAGE_DONE ist gesichert", "AUFLAGE_DONE=1" in save)
    r.check("66 Bits sind gesichert (50 + 16 aus Aufstiegen)",
            "BITS=66" in save)
    r.check("ein Sperrzone-Exemplar ist gesichert", "[sperrzone]=1" in save)
    r.check("der Kastenschlüssel ist zurückgegeben",
            "zeitungsschluessel" not in save)
    r.check("alle Kästen bleiben voll", "ZEITUNG_EMPTIED=0" in save)

    # Auch nach dem Abschluss verkauft ein Kasten die neue Ausgabe.
    s.cmd("cd %s" % SUED)
    s.drain(0.6)
    m = s.mark()
    s.cmd("use Zeitungskasten")
    r.check("Kasten verkauft weiter die Sperrzone",
            s.wait_from(m, "Die Sperrzone", 20))
    r.check("Kaufoption ist vorhanden",
            s.wait_from(m, "Exemplar kaufen", 20))
    s.send("2", 0.8)
    s.send(b"\r", 0.8)

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================================ §3 Jimmy: 50 Bits
with start("auflage_jimmy_50",
           after_tour(CWD=JIMMY, AUFLAGE_GIVEN=1, AUFLAGE_DONE=1,
                      ZEITUNG_EMPTIED=0, BITS=0, EXP=0, LEVEL=0,
                      JIMMY_GIVEN=1, JIMMY_LAST_SOLD=""),
           inv=["sperrzone"]) as s:
    r = Report("3) Jimmy: Sperrzone für 50 Bits, 250 EXP")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch JimmyPage")
    r.check("Jimmy fragt nach der neuen Ausgabe",
            s.wait_from(m, "Hast du die neue Ausgabe? Die über die Sperrzone?", 20))
    r.check("Jimmy bietet die Option »Neuste Ausgabe«",
            s.wait_from(m, "Neuste Ausgabe.", 20))
    s.send("1", 0.6)
    r.check("Jimmy fragt nach dem Preis",
            s.wait_from(m, "Also – was willst du dafür?", 20))
    r.check("Preisoption 50 Bits",
            s.wait_from(m, "50 Bits.", 20))
    r.check("Preisoption 75 Bits",
            s.wait_from(m, "75 Bits.", 20))
    r.check("Preisoption 100 Bits",
            s.wait_from(m, "100 Bits.", 20))
    r.check("Option zum Behalten",
            s.wait_from(m, "Doch nicht verkaufen.", 20))
    s.send("1", 0.6)
    r.check("Jimmy dankt für den fairen Preis",
            s.wait_from(m, "50 Bits? Das ist fair.", 20))
    r.check("50 Bits werden gutgeschrieben",
            s.wait_from(m, "[ Bits ] +50", 20))
    r.check("250 EXP werden gutgeschrieben",
            s.wait_from(m, "[ EXP ] +250", 20))
    r.check("Jimmy nimmt die Ausgabe",
            s.wait_from(m, "Ab damit in die Sammlung.", 20))
    r.check("Jimmy bietet cal kostenpflichtig an",
            s.wait_from(m, "cal lernen (2 Skillpunkte, 50 Bits)", 20))
    s.send("2", 0.8)                        # cal-Angebot ablehnen
    r.check("Jimmy lässt das Angebot stehen",
            s.wait_from(m, "Deine Entscheidung", 20))
    s.send(b"\r", 1.0)                      # Dialog schließen

    m = s.mark()
    s.cmd("touch JimmyPage")
    r.check("Jimmy hat die Ausgabe gelesen",
            s.wait_from(m, "Die Sperrzone-Ausgabe. Ich habe sie gelesen. Zweimal.", 20))
    r.check("kein zweiter Verkauf derselben Ausgabe",
            "Neuste Ausgabe." not in s.since(m))
    s.send("1", 0.6)                        # Nichts weiter.
    r.check("cal wird erneut angeboten",
            s.wait_from(m, "cal lernen (2 Skillpunkte, 50 Bits)", 20))
    s.send("2", 0.6)                        # Nichts weiter.
    s.send(b"\r", 0.8)                      # Dialog schließen

    s.cmd("save")
    s.wait("Spielstand in Slot", 20)
    s.drain(0.8)
    save = open(os.path.join(TMP, "auflage_jimmy_50", "manual1.save"),
                encoding="utf-8").read()
    r.check("JIMMY_LAST_SOLD ist gesichert",
            "JIMMY_LAST_SOLD=sperrzone" in save)
    r.check("58 Bits sind gesichert (50 + 8 aus Aufstieg)",
            "BITS=58" in save)
    r.check("die Ausgabe ist aus dem Inventar", "INV_COUNT=()" in save)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================================ §4 Jimmy: 100 Bits
with start("auflage_jimmy_100",
           after_tour(CWD=JIMMY, AUFLAGE_GIVEN=1, AUFLAGE_DONE=1,
                      ZEITUNG_EMPTIED=0, BITS=0, EXP=0, LEVEL=0,
                      JIMMY_GIVEN=1, JIMMY_LAST_SOLD=""),
           inv=["sperrzone"]) as s:
    r = Report("4) Jimmy: Sperrzone für 100 Bits, 0 EXP")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch JimmyPage")
    s.wait_from(m, "Neuste Ausgabe.", 20)
    s.send("1", 0.6)
    s.wait_from(m, "Also – was willst du dafür?", 20)
    s.send("3", 0.6)
    r.check("Jimmy schimpft über den Preis",
            s.wait_from(m, "Halsabschneider wie Tracey", 20))
    r.check("100 Bits werden gutgeschrieben",
            s.wait_from(m, "[ Bits ] +100", 20))
    r.check("keine EXP für den Wucherpreis",
            s.wait_from(m, "[ EXP ] ±0", 20))
    r.check("Jimmy kauft trotzdem",
            s.wait_from(m, "Ab damit in die Sammlung.", 20))
    r.check("Jimmy bietet cal kostenpflichtig an",
            s.wait_from(m, "cal lernen (2 Skillpunkte, 50 Bits)", 20))
    s.send("2", 0.8)                        # cal-Angebot ablehnen
    s.send(b"\r", 1.0)                      # Dialog schließen

    s.cmd("save")
    s.wait("Spielstand in Slot", 20)
    s.drain(0.8)
    save = open(os.path.join(TMP, "auflage_jimmy_100", "manual1.save"),
                encoding="utf-8").read()
    r.check("JIMMY_LAST_SOLD ist gesichert",
            "JIMMY_LAST_SOLD=sperrzone" in save)
    r.check("100 Bits sind gesichert", "BITS=100" in save)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print("\nAUFLAGE-TESTS: %d Fehler" % fails)
sys.exit(1 if fails else 0)
