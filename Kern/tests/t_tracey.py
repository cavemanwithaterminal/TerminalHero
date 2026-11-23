#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Tracey Briggs & Jimmys Zeitungsbote (PTY)
# ------------------------------------------------------------
#  Prüft die neue Inhaltskette:
#    1) Tracey steht vor Rachels Quest im Ostdistrikt, stellt sich vor
#       und verkauft die aktuelle DailyPulse-Ausgabe für 10 Bits.
#    2) Rachel vergibt nach der Baracken-Szene ohne Ablehnungsoption
#       »Finde Tracey« und aktualisiert »Vermisste Bewohner«.
#    3) Tracey wird vor Jimmys Haus gefunden, sagt, dass sie Jimmy
#       gerade die Ausgabe für 100 Bits verkauft hat, und wechselt
#       in den DailyPulse-Verlag.
#    4) Jimmy beschwert sich über Tracey und vergibt »Jimmys
#       Zeitungsbote«; danach kauft er eine Ausgabe für 50 Bits.
#    5) Rachel bedankt sich, Tracey meldet sich zu Wort und die
#       Quest endet mit 100 EXP.
#    6) Jimmy hat auch vor der Quest einen Standarddialog.
#
#  Aufruf:  python3 Kern/tests/t_tracey.py
# ============================================================
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL)

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
SUED = CITY + "/Süddistrikt"
OST = CITY + "/Ostdistrikt"
VERLAG = SUED + "/DailyPulse"
JIMMY = OST + "/JimmysHaus"


def start(name, scalars, inv=None):
    d = os.path.join(TMP, name)
    write_save(os.path.join(d, "manual1.save"), scalars=scalars,
               learned=LEARNED_ALL, inv=inv)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=d)


# ============================================================ A) Standard Tracey
with start("tracey_a", {"CWD": OST, "OLDPWD": CITY, "VIEW_DIR": OST,
                        "SHOW_PATH": 1, "SHOW_LS": 1, "BITS": 30,
                        "README_DONE": 1, "TUT_DONE": 1}) as s:
    r = Report("A) Tracey vor Rachels Quest")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark(); s.cmd("ls")
    r.check("Tracey steht im Ostdistrikt", s.wait_from(m, "TraceyBriggs", 15))

    m = s.mark(); s.cmd("touch TraceyBriggs")
    r.check("Tracey stellt sich vor",
            s.wait_from(m, "Tracey Briggs. Ich trag die DailyPulse aus", 30))
    r.check("Kaufangebot ist da", s.wait_from(m, "Exemplar kaufen", 20))
    r.check("kein Ablehnen im Standardgespräch",
            "Ablehnen" not in s.since(m))
    s.send("1", 0.8)
    r.check("aktuelle Ausgabe gekauft",
            s.wait_from(m, "[ Zeitung ]", 20))
    r.check("Kauf kostet 10 Bits",
            s.wait_from(m, "-10 Bits", 20))
    r.check("Kauf wird bestätigt",
            s.wait_from(m, "Bitte sehr", 20))
    m2 = s.mark()
    s.send(b"\r", 1)
    r.check("nach dem Kauf erscheint das Menü erneut",
            s.wait_from(m2, "Nichts weiter.", 10))
    s.send("2", 0.8)                        # Menü: Nichts weiter.
    s.send(b"\r", 0.8)                      # Abschieds-pause

    s.cmd("exit")
    s.drain(2)
    r.check("Spiel beendet", s.eof)
    fails += r.done()

# ============================================================ B) Questkette
with start("tracey_b", {
        "CWD": VERLAG, "OLDPWD": SUED, "VIEW_DIR": VERLAG,
        "SHOW_PATH": 1, "SHOW_LS": 1, "BITS": 40, "SKILL_POINTS": 3,
        "README_DONE": 1, "TUT_DONE": 1, "SAVE_LEARNED": 1,
        "VERLAG_DONE": 1, "PIXI_DESKTOP_DONE": 1, "PIXI_GATE_DONE": 1,
        "PIXI_HALL_DONE": 1, "PIXI_GUIDE_DONE": 1, "BARACKE_SCENE_DONE": 1,
    }, inv=["bezirke", "bezirke"]) as s:
    r = Report("B) Rachel, Tracey, Jimmy & Abschluss")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark(); s.cmd("touch Rachel")
    r.check("Rachel fragt nach Tracey",
            s.wait_from(m, "Ich bestehe darauf", 40))
    r.check("Rachels Quest ist nicht ablehnbar",
            "Ablehnen" not in s.since(m))
    r.check("Vermisste Bewohner wird aktualisiert",
            s.wait_from(m, "»Vermisste Bewohner« erhalten", 20))
    r.check("Finde Tracey wird vergeben",
            s.wait_from(m, "»Finde Tracey« erhalten", 20))
    r.check("Questlog nennt den Suchort",
            s.wait_from(m, "Rachel sucht Tracey Briggs", 20))
    s.send(b"\r", 1)

    # Im Ostdistrikt: Jimmys Haus und Tracey davor.
    m = s.mark(); s.cmd("cd Ostdistrikt"); s.cmd("pwd")
    r.check("Ostdistrikt betreten", s.wait_from(m, "/Ostdistrikt", 15))
    m = s.mark(); s.cmd("cd JimmysHaus"); s.cmd("pwd")
    r.check("Jimmys Haus betreten", s.wait_from(m, "/JimmysHaus", 15))
    m = s.mark(); s.cmd("ls")
    r.check("JimmyPage liegt in JimmysHaus", s.wait_from(m, "JimmyPage", 15))
    m = s.mark(); s.cmd("cd .."); s.cmd("pwd")
    r.check("zurück im Ostdistrikt", s.wait_from(m, "/Ostdistrikt", 15))
    m = s.mark(); s.cmd("ls")
    r.check("Tracey steht vor Jimmys Haus", s.wait_from(m, "TraceyBriggs", 15))

    m = s.mark(); s.cmd("touch TraceyBriggs")
    r.check("Tracey ist bei Jimmy fertig",
            s.wait_from(m, "Ja, bin hier fertig", 30))
    r.check("Tracey nennt die 100 Bits",
            s.wait_from(m, "100 Bits", 20))
    r.check("Vermisste Bewohner: Hab Tracey gefunden",
            s.wait_from(m, "Hab Tracey gefunden", 20))
    s.send(b"\r", 1)
    m = s.mark(); s.cmd("ls")
    r.check("Tracey ist aus dem Ostdistrikt verschwunden",
            not s.wait_from(m, "◆ TraceyBriggs", 4))

    # Jimmy: Ärger über Tracey, neue Quest, danach Ankauf.
    m = s.mark(); s.cmd("cd JimmysHaus")
    r.check("Jimmys Haus wieder betreten", s.wait_from(m, "JimmysHaus", 15))
    m = s.mark(); s.cmd("touch JimmyPage")
    r.check("Jimmy regt sich über Tracey auf",
            s.wait_from(m, "Diese Tracey", 35))
    r.check("Jimmy nennt den überhöhten Preis",
            s.wait_from(m, "100 Bits", 20))
    r.check("Jimmy bietet 50 Bits pro Ausgabe",
            s.wait_from(m, "50 Bits pro neuer Ausgabe", 20))
    r.check("Jimmys Zeitungsbote wird vergeben",
            s.wait_from(m, "»Jimmys Zeitungsbote« erhalten", 20))
    s.send(b"\r", 1)

    m = s.mark(); s.cmd("touch JimmyPage")
    r.check("Jimmy kauft eine Ausgabe an",
            s.wait_from(m, "Zeitungsausgabe verkaufen", 30))
    s.send("1", 0.8)
    r.check("Verkauf bringt 50 Bits",
            s.wait_from(m, "+50", 20))
    r.check("Jimmy bedankt sich", s.wait_from(m, "Endlich. Danke.", 20))
    r.check("Jimmy kauft dieselbe Edition nicht erneut",
            s.wait_from(m, "Diese Ausgabe habe ich schon", 20))
    r.check("Dialog bietet den Ausstieg",
            s.wait_from(m, "Nichts weiter.", 20))
    s.send("1", 0.8)
    r.check("nach dem ersten Verkauf bietet Jimmy cal an",
            s.wait_from(m, "1) cal lernen (2 Skillpunkte, 50 Bits)", 20))
    s.send("1", 0.8)
    r.check("Jimmy lehrt cal kostenpflichtig",
            s.wait_from(m, "Neuer Befehl erlernt: cal", 20))
    r.check("cal kostet 2 Skillpunkte",
            s.wait_from(m, "[ Skillpunkte ] -2", 20))
    s.send(b"\r", 1)

    # Traceys einmalige Konkurrenz-Szene: Jimmy hat jetzt einen Käufer,
    # also ist der Agent für sie Konkurrenz.
    m = s.mark(); s.cmd("cd Süddistrikt/DailyPulse")
    s.cmd("pwd")
    r.check("zurück im DailyPulse", s.wait_from(m, "/DailyPulse", 15))
    m = s.mark(); s.cmd("touch TraceyBriggs")
    r.check("Tracey erkennt die Konkurrenz",
            s.wait_from(m, "Aha! Du bist jetzt also meine Konkurrenz!", 25))
    r.check("Tracey sagt den vollen Satz",
            s.wait_from(m, "Wie du willst!", 10))
    s.send(b"\r", 1)

    # Zweites Gespräch: Der Konkurrenz-Dialog erscheint nicht erneut.
    m = s.mark(); s.cmd("touch TraceyBriggs")
    r.check("normales Tracey-Gespräch danach",
            s.wait_from(m, "Ich bin schon da. Rachel wartet wohl schon.", 25))
    s.send("2", 0.8)                        # Nichts weiter.
    s.send(b"\r", 1)

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    saved = open(os.path.join(TMP, "tracey_b", "manual1.save"),
                 encoding="utf-8").read()
    r.check("JIMMY_FIRST_SALE ist gesichert", "JIMMY_FIRST_SALE=1" in saved)
    r.check("TRACEY_RIVAL_SEEN ist gesichert", "TRACEY_RIVAL_SEEN=1" in saved)
    r.check("cal ist erlernt und gesichert",
            bool(re.search(r"^LEARNED=\(.*\bcal\b.*\)$", saved, re.M)))

    # Zurück zu Rachel: Abschluss mit 100 EXP und Traceys Kommentar.
    m = s.mark(); s.cmd("touch Rachel")
    r.check("Rachel bedankt sich",
            s.wait_from(m, "Du hast sie gefunden. Danke.", 35))
    r.check("Tracey hat den letzten Satz",
            s.wait_from(m, "keiner mit mir anlegt", 20))
    r.check("Rachel kennt die verkauften Ausgaben",
            s.wait_from(m, "alle Ausgaben losgeworden", 20))
    r.check("Rachel hätte es lieber anders gesehen",
            s.wait_from(m, "lieber gewesen", 20))
    r.check("Rachel ist vom Verkauf überrascht",
            s.wait_from(m, "Überraschend", 20))
    r.check("Rachel fragt nach Jimmys Geld",
            s.wait_from(m, "Hast bestimmt wieder bei Jimmy abkassiert?", 20))
    r.check("Tracey bleibt diskret",
            s.wait_from(m, "Betriebsgeheimnis.", 20))
    r.check("Rachel missbilligt die hohen Summen",
            s.wait_from(m, "nicht in Ordnung, so hohe Summen", 20))
    r.check("Rachel kennt Traceys Tagelöhner-Lage",
            s.wait_from(m, "als Tagelöhnerin nicht viel verdienst", 20))
    r.check("Abschluss bringt 100 EXP",
            s.wait_from(m, "Questbelohnung: 100 EXP", 20))
    r.check("Finde Tracey ist abgeschlossen",
            s.wait_from(m, "»Finde Tracey«", 20))
    s.send(b"\r", 1)
    m = s.mark(); s.cmd("ls")
    r.check("Tracey ist nach der Quest aus dem Verlag verschwunden",
            not s.wait_from(m, "TraceyBriggs", 6))

    s.cmd("exit")
    s.drain(2)
    r.check("Spiel beendet", s.eof)
    fails += r.done()

# ============================================================ C) Standard Jimmy
with start("tracey_c", {"CWD": JIMMY, "OLDPWD": OST, "VIEW_DIR": JIMMY,
                        "SHOW_PATH": 1, "SHOW_LS": 1,
                        "README_DONE": 1, "TUT_DONE": 1,
                        "JIMMY_GIVEN": 0, "TRACEY_GIVEN": 0,
                        "TRACEY_FOUND": 0}) as s:
    r = Report("C) Jimmy vor der Quest")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark(); s.cmd("ls")
    r.check("JimmyPage ist zu sehen", s.wait_from(m, "JimmyPage", 15))
    m = s.mark(); s.cmd("touch JimmyPage")
    r.check("Jimmy stellt sich vor",
            s.wait_from(m, "Jimmy Page. Und nein, ich gehe nicht raus", 30))
    r.check("Jimmy erwähnt den Rollstuhl",
            s.wait_from(m, "Rollstuhl", 20))
    r.check("Jimmy ist Zeitungssammler",
            s.wait_from(m, "Zeitungen sind meine Fenster", 20))
    r.check("Jimmy kauft seltene Ausgaben",
            s.wait_from(m, "seltene Ausgabe", 20))
    r.check("noch kein 50-Bits-Angebot vor der Quest",
            "50 Bits" not in s.since(m))
    s.send(b"\r", 1)

    s.cmd("exit")
    s.drain(2)
    r.check("Spiel beendet", s.eof)
    fails += r.done()

# ============================================================ D) Stadttour
with start("tracey_d", {
        "CWD": CITY + "/Süddistrikt", "OLDPWD": CITY,
        "VIEW_DIR": CITY + "/Süddistrikt",
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "README_DONE": 1, "TUT_DONE": 1,
        "TRACEY_GIVEN": 1, "TRACEY_FOUND": 1, "TRACEY_DONE": 1,
        "WORLD_SECS": 0, "WORLD_STARTED": 1,
    }) as s:
    r = Report("D) Tracey auf Stadttour nach ihrer Quest")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark(); s.cmd("ls")
    r.check("Tracey beginnt die Tour im Süddistrikt",
            s.wait_from(m, "TraceyBriggs", 15))
    m = s.mark(); s.cmd("cat TraceyBriggs")
    r.check("Tracey-Notiz nennt die Stadttour",
            s.wait_from(m, "auf Stadttour", 10))
    r.check("Tracey-Notiz nennt den 4-Stunden-Rhythmus",
            s.wait_from(m, "alle 4 Spielstunden", 10))

    s.cmd("exit")
    s.drain(2)
    r.check("Spiel beendet", s.eof)
    fails += r.done()

print("\nTracey/Jimmy-Test gesamt:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
