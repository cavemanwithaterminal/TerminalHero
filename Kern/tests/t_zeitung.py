#!/usr/bin/env python3
# ============================================================
#  TerminalHero - DailyPulse-Zeitungskästen & Jacks Rückholquest (PTY)
# ------------------------------------------------------------
#  Prüft die komplette Kette:
#    1) Kauf am Kasten: 10 Bits, mehrfach möglich, Item im Inventar.
#    2) Jack: »Kann ich dir irgendwie helfen?«, Rachel/Pixi-Kommentare,
#       Ablehnung (Quest bleibt offen), Annahme + Schlüssel.
#    3) Kasten mit Schlüssel leeren: genau einmal, ein Zeitungsbündel.
#    4) Fünf Bündel bei Jack: 3 Stunden später, 200 EXP, »clear« danach
#       für 1 Skillpunkt (ohne 50 Bits).
#    5) Vor dem Questabschluss: »clear« für 1 Skillpunkt + 50 Bits.
#
#  Aufruf:  python3 Kern/tests/t_zeitung.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL,
                     LEARNED_TUT, ESC, RIGHT)

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
SUED = CITY + "/Süddistrikt"
OST = CITY + "/Ostdistrikt"
VERLAG = SUED + "/DailyPulse"


def start(name, scalars, inv=None, inv_counts=None, learned=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=learned or LEARNED_ALL, inv=inv,
               inv_counts=inv_counts)
    return Sim(env={"TERMINALHERO_LOAD": "manual",
                    "TH_ZEITUNG_BLACK_SECS": "0.2"},
               saves=os.path.join(TMP, name))


def publisher_scalars(**extra):
    vals = {
        "CWD": VERLAG,
        "PIXI_DESKTOP_DONE": 1,
        "PIXI_GATE_DONE": 1,
        "PIXI_HALL_DONE": 1,
        "VERLAG_DONE": 1,
        "PIXI_GUIDE_DONE": 1,
        "BARACKE_SCENE_DONE": 1,
    }
    vals.update(extra)
    return vals


# ======================================= §0 use ist noch nicht gelernt
with start("zeitung_gesperrt", {"CWD": SUED, "BITS": 30},
           learned=LEARNED_TUT) as s:
    r = Report("0) Zeitungskasten ohne erlerntes »use«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("use Zeitungskasten")
    r.check("use wird als unbekannt abgewiesen",
            s.wait_from(m, "Diesen Befehl kenne ich nicht mehr", 20))
    s.drain(1.0)
    r.check("kein Verkaufsdialog ohne use",
            "Exemplar kaufen" not in s.since(m))
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ======================================= §1 Kauf am Kasten (mehrfach)
with start("zeitung_kauf", {"CWD": SUED, "BITS": 30}) as s:
    r = Report("1) Zeitungskasten: 10 Bits, Mehrfachkauf")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("use Zeitungskasten")
    r.check("Kauf-Option steht bereit", s.wait_from(m, "Exemplar kaufen", 20))
    r.check("Rückzug-Option steht bereit", s.wait_from(m, "Nichts tun", 20))
    r.check("aktuelle Ausgabe wird genannt",
            s.wait_from(m, "Bezirke der Stadt", 20))
    s.drain(0.4)
    r.check("ohne Schlüssel kein Leeren",
            "Zeitungskasten leeren" not in s.since(m))
    s.send("1", 0.8)
    r.check("Zeitung wandert ins Inventar", s.wait_from(m, "[ Zeitung ]", 20))
    r.check("10 Bits werden abgezogen",
            s.wait_from(m, "-10 Bits", 20))
    m2 = s.mark()
    s.send(b"\r", 1.2)
    r.check("nach dem Kauf erscheint das Menü erneut",
            s.wait_from(m2, "Nichts tun", 10))
    s.send("2", 0.8)                        # Menü: Nichts tun

    m = s.mark()
    s.cmd("use Zeitungskasten")
    s.wait_from(m, "Exemplar kaufen", 20)
    s.send("1", 0.8)
    r.check("zweiter Kauf ist möglich", s.wait_from(m, "[ Zeitung ]", 20))
    r.check("wieder 10 Bits", s.wait_from(m, "-10 Bits", 20))
    s.send(b"\r", 1.2)
    s.send("2", 0.8)                        # Menü: Nichts tun

    m = s.mark()
    s.cmd("inventar")
    s.wait_from(m, "Quest 2", 20)
    s.send(RIGHT, 0.8)
    r.check("zwei Exemplare im Inventar",
            s.wait_from(m, "Bezirke der Stadt ×2", 20))
    s.send(ESC, 0.8)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §2 Jack: ablehnen, dann annehmen
with start("zeitung_jack", publisher_scalars(BITS=100, SKILL_POINTS=2)) as s:
    r = Report("2) Jack: Quest-Angebot, Kommentare, Ablehnung, Annahme")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Option »Befehl lernen« ist da",
            s.wait_from(m, "Befehl lernen", 20))
    r.check("Hilfe-Option ist da",
            s.wait_from(m, "Kann ich dir irgendwie helfen?", 20))
    s.send("2", 0.8)
    r.check("Rachel lästert über die Ausgabe",
            s.wait_from(m, "sieben Mal erklärt, wo Norden liegt", 25))
    r.check("Pixi hat sie zweimal gelesen",
            s.wait_from(m, "Ich hatte nichts verpasst", 25))
    r.check("Jack wehrt sich", s.wait_from(m, "Hey, lasst das!", 20))
    r.check("Jack fragt nach Hilfe", s.wait_from(m, "Hilfst du mir?", 20))
    s.send("2", 0.8)
    r.check("Ablehnung lässt Zeit",
            s.wait_from(m, "Noch hast du Zeit es dir zu überlegen.", 20))
    s.send(b"\r", 1.2)
    s.send("4", 0.8)                        # Menü: Nichts weiter.

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Quest bleibt später erhältlich",
            s.wait_from(m, "Kann ich dir irgendwie helfen?", 20))
    s.send("2", 0.8)
    s.wait_from(m, "Hilfst du mir?", 20)
    s.send("1", 0.8)
    r.check("Quest wird vergeben",
            s.wait_from(m, "»Die langweiligste Ausgabe« erhalten", 20))
    r.check("Schlüssel wird übergeben",
            s.wait_from(m, "[ Zeitungskastenschlüssel ]", 20))
    r.check("neues Ziel nennt den Befehl",
            s.wait_from(m, "use Zeitungskasten", 20))
    s.send(b"\r", 1.2)
    s.send("4", 0.8)                        # Menü: Nichts weiter.

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Fortschritts-Option nach Annahme",
            s.wait_from(m, "Wie komme ich voran?", 20))
    s.send("4", 0.8)       # Nichts weiter.
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §3 Kasten leeren (genau einmal)
with start("zeitung_leeren", {"CWD": OST, "ZEITUNG_GIVEN": 1,
                              "ZEITUNG_EMPTIED": 0, "BITS": 20},
           inv=["zeitungsschluessel"]) as s:
    r = Report("3) Zeitungskasten mit Schlüssel leeren")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("use Zeitungskasten")
    r.check("Leeren wird angeboten",
            s.wait_from(m, "Zeitungskasten leeren", 20))
    s.send("2", 0.8)
    r.check("ein Zeitungsbündel entsteht",
            s.wait_from(m, "[ Zeitungsbündel ]", 20))
    r.check("Fortschritt 1/5", s.wait_from(m, "Zeitungskasten geleert: 1/5", 20))
    s.send(b"\r", 1.2)

    m = s.mark()
    s.cmd("use Zeitungskasten")
    r.check("Kasten ist jetzt leer",
            s.wait_from(m, "Der Kasten ist leer", 20))
    s.drain(0.8)
    r.check("kein Kauf mehr am leeren Kasten",
            "Exemplar kaufen" not in s.since(m))
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §4 Fünf Bündel, 3 Stunden, 200 EXP
with start("zeitung_abschluss",
           publisher_scalars(ZEITUNG_GIVEN=1, ZEITUNG_EMPTIED=31,
                             BITS=0, SKILL_POINTS=1,
                             WORLD_STARTED=1, WORLD_SECS=0),
           inv=["zeitungsschluessel", "armbanduhr"],
           inv_counts={"zeitungsbuendel": 5}) as s:
    r = Report("4) Jack: fünf Bündel, 3 Stunden, 200 EXP, clear frei")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Uhr zeigt vorher 06:xx", s.wait("06:", 10))

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Abgabe-Option erscheint",
            s.wait_from(m, "Ich habe die Zeitungsbündel.", 20))
    s.send("2", 0.8)
    r.check("Jack nimmt alle fünf", s.wait_from(m, "Du hast sie. Alle fünf.", 25))
    r.check("Bildschirm: 3 Stunden später",
            s.wait_from(m, "3 Stunden später", 20))
    r.check("Quest abgeschlossen",
            s.wait_from(m, "QUEST ABGESCHLOSSEN", 20))
    r.check("Titel der Quest",
            s.wait_from(m, "Die langweiligste Ausgabe", 20))
    r.check("200 EXP Belohnung",
            s.wait_from(m, "Questbelohnung: 200 EXP", 20))
    r.check("Zeit ist um drei Stunden vorgerückt",
            s.wait_from(m, "09:", 20))
    r.check("Jack nimmt den Zeitungskastenschlüssel zurück",
            s.wait_from(m, "[ Zeitungskastenschlüssel ] -1", 20))
    r.check("clear jetzt nur noch 1 Skillpunkt",
            s.wait_from(m, "nur noch einen Skillpunkt", 20))
    s.send(b"\r", 1.2)

    m = s.mark()
    s.send("1", 0.6)       # Menü: Befehl lernen
    r.check("clear kostet nach der Quest keine Bits",
            s.wait_from(m, "clear Befehl lernen (Kosten 1 Skillpunkt)", 20))
    s.drain(0.4)
    r.check("der alte 50-Bit-Preis ist verschwunden",
            "clear Befehl lernen (Kosten 1 Skillpunkt, 50 Bits)" not in s.since(m))
    s.send("1", 0.8)
    r.check("clear wird gelernt",
            s.wait_from(m, "Neuer Befehl erlernt: clear", 20))
    s.send(b"\r", 1.0)
    s.send("3", 0.8)       # Menü: Nichts weiter. (1 = Lernen, 2 = Handeln.)

    m = s.mark()
    s.cmd("inventar")
    s.wait_from(m, "Quest", 20)
    s.drain(0.6)
    r.check("Schlüssel ist nicht mehr im Inventar",
            "Zeitungskastenschlüssel" not in s.since(m))
    s.send(ESC, 0.8)

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §5 clear vor der Quest: 50 Bits
with start("zeitung_clear_vorher",
           {"CWD": VERLAG, "VERLAG_DONE": 1, "PIXI_DESKTOP_DONE": 1,
            "PIXI_GATE_DONE": 1, "PIXI_HALL_DONE": 1,
            "BARACKE_SCENE_DONE": 0, "BITS": 50, "SKILL_POINTS": 1}) as s:
    r = Report("5) Jack: clear vor der Quest für 1 Skillpunkt + 50 Bits")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Befehl lernen ist da", s.wait_from(m, "Befehl lernen", 20))
    s.send("1", 0.8)
    r.check("Preis nennt Skillpunkt und 50 Bits",
            s.wait_from(m, "clear Befehl lernen (Kosten 1 Skillpunkt, 50 Bits)", 20))
    s.send("1", 0.8)
    r.check("clear wird gelernt",
            s.wait_from(m, "Neuer Befehl erlernt: clear", 20))
    r.check("Tipp: bei Performance-Problemen clear anwenden",
            s.wait_from(m, "Bei Performance-Problemen", 10))
    r.check("ein Skillpunkt wird abgezogen",
            s.wait_from(m, "[ Skillpunkte ]", 20))
    r.check("50 Bits werden abgezogen",
            s.wait_from(m, "-50 Bits", 20))

    m2 = s.mark()
    s.send(b"\r", 1.4)       # Dialog-Pause schließen -> Hauptmenü neu
    r.check("cal bleibt als Lernangebot sichtbar",
            s.wait_from(m2, "Befehl lernen", 20))
    s.send("3", 0.8)         # Nichts weiter. (1 = Lernen, 2 = Handeln.)

    m3 = s.mark()
    s.cmd("touch Jack")
    r.check("neuer Jack-Dialog bietet weiterhin Lernen",
            s.wait_from(m3, "Was möchtest du?", 20))
    r.check("»Befehl lernen« bleibt für cal",
            s.wait_from(m3, "Befehl lernen", 10))
    s.send("1", 0.6)         # Befehl lernen
    r.check("cal kostet 2 Skillpunkte und 50 Bits",
            s.wait_from(m3, "cal Befehl lernen (2 Skillpunkte, 50 Bits)", 12))
    s.drain(0.4)
    r.check("clear wird nicht mehr angeboten",
            "clear Befehl lernen" not in s.since(m3))
    s.send("2", 0.6)         # Nichts weiter. -> Dialog-Pause
    s.send(b"\r", 0.8)
    s.send("3", 0.6)         # Hauptmenü: Nichts weiter.
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print("\nZEITUNG-TESTS: %d Fehler" % fails)
sys.exit(1 if fails else 0)
