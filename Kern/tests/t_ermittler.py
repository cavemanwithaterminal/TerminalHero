#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Kettentest (PTY)
# ------------------------------------------------------------
#  Die Story-Kette »Großer Ermittler« und ihre Mechanik, in vier
#  Abschnitten. Weil in der Nacht ganz andere Dinge passieren als
#  am Tag und ein Durchspielen sehr lang wäre, startet jeder
#  Abschnitt aus einem passend gepatchten Spielstand
#  (pty_lib.write_save) - so prüft jeder Abschnitt genau eine
#  Stufe der Kette.
#
#    1) Sherlocks Tagesablauf: nachts da, tagsüber nicht
#    2) Baracke: Fundorte (grep Bits), Armbanduhr, Matratze/Schlafen
#    3) Börty Smiles: Holmes-Auskunft gegen Bits (arm & reich)
#    4) Detektei -> Pixi: Briefübergabe (100 EXP) und Abschluss (200 EXP)
#
#  Aufruf:  python3 Kern/tests/t_ermittler.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
KNEIPE = CITY + "/Ostdistrikt/KneipeZumGoldenenLächeln"
DETEKTEI = CITY + "/Ostdistrikt/DetekteiHolmes"
BARACKE = CITY + "/Süddistrikt/EingestürzteBaracke"
SUED = CITY + "/Süddistrikt"
DAILYPULSE = CITY + "/Süddistrikt/DailyPulse"
LEARNED_NO_STATS = [c for c in LEARNED_ALL if c != "statistics"]


def start(name, scalars, learned=None, inv=None, env=None):
    """Session aus einem gepatchten Spielstand starten."""
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=learned or LEARNED_ALL, inv=inv)
    e = {"TERMINALHERO_LOAD": "manual"}
    e.update(env or {})
    return Sim(env=e, saves=os.path.join(TMP, name))


# =========================================================== §1 Tagesablauf
with start("nacht", {"CWD": CITY + "/Ostdistrikt", "WORLD_SECS": 2400}) as s:
    r = Report("1) Sherlock: Tagesablauf")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("ls")
    r.check("nachts (22:00): Sherlock steht im Ostdistrikt",
            s.wait_from(m, "Sherlock", 10))
    s.cmd("cat Sherlock")
    r.check("cat zeigt sein Profil", s.wait("Nachts im Bezirk unterwegs", 10))
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

with start("tag", {"CWD": CITY + "/Ostdistrikt", "WORLD_SECS": 0}) as s:
    r = Report("1) Sherlock: Tagesablauf (Tag)")
    s.wait("Spielstand geladen", 20)
    m = s.mark()
    s.cmd("ls")
    r.check("tagsüber (06:00) fehlt er im Ordner",
            s.wait_from(m, "DetekteiHolmes", 10) and "Sherlock" not in s.since(m))
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# =========================================================== §2 Baracke
with start("baracke",
           {"CWD": BARACKE, "BARACKE_SCENE_DONE": 1, "PIXI_GUIDE_DONE": 1,
            "VERLAG_DONE": 1, "TOKENS_CUR": 100, "BITS": 0},
           env={"TH_SIT_SECS": "2"}) as s:
    r = Report("2) Baracke: Fundorte, grep, Schlafen, Sitzen")
    s.wait("Spielstand geladen", 20)

    m = s.mark()
    s.cmd("ls")
    for ding in ("Matratze", "Bits", "Armbanduhr"):
        r.check("%s liegt in der Baracke" % ding, s.wait_from(m, ding, 10))

    # --- grep: den Bits-Haufen herausziehen (10 Tokens, 2 EXP) ------
    m = s.mark()
    s.cmd("grep Bits")
    r.check("grep zieht den Bits-Haufen heraus",
            s.wait_from(m, "10 Bits aufgesammelt", 10))
    r.check("Kontostand wird gemeldet", "Stand: 10 Bits" in s.since(m))
    r.check("grep kostet 10 Tokens (100 -5 für ls -10 = 85)",
            s.wait_from(m, "85 / 1000", 10))

    # --- use Matratze: Schlafffenster, 8 Stunden, +20 Tokens je Stunde
    m = s.mark()
    s.cmd("use Matratze")
    r.check("use Matratze öffnet das Schlafffenster",
            s.wait_from(m, "◤ Matratze ◢", 12))
    r.check("Schlafffenster zeigt die aktuelle Uhrzeit",
            "Uhrzeit" in s.since(m) and "06:00" in s.since(m))
    s.send(b"\r", 1.0)                       # Vorgabe: 8 Stunden (schwarzer Bildschirm)
    r.check("acht Stunden geschlafen",
            s.wait("Du hast 8 Stunden geschlafen", 15))
    r.check("use kostet 5; Schlafen regeneriert +160 (80 -> 240)",
            "Tokens regeneriert: +160" in s.text() and s.wait("240 / 1000", 10))

    # Zweites Schlafen am selben Tag: nur noch der Rest des Budgets (4 h)
    m = s.mark()
    s.cmd("use Matratze")
    r.check("zweites Fenster öffnet sich", s.wait_from(m, "◤ Matratze ◢", 12))
    s.send(b"\r", 1.0)
    r.check("vier weitere Stunden (Tagesgrenze 12)",
            s.wait("Du hast 4 Stunden geschlafen", 15))

    # Drittes Schlafen am selben Tag: abgelehnt
    m = s.mark()
    s.cmd("use Matratze")
    r.check("mehr als 12 Stunden am Tag wird abgelehnt",
            s.wait_from(m, "Mehr geht erst an einem neuen Tag", 12))

    # --- use Stuhl: eigenes Sitz-Fenster, 5 Tokens je Stunde ----------
    # Sitzen ist vom Schlafen getrennt: Das Schlafbudget ist bereits voll,
    # der Stuhl funktioniert trotzdem.
    m = s.mark()
    s.cmd("use Stuhl")
    r.check("use Stuhl öffnet das Sitzfenster",
            s.wait_from(m, "◤ Stuhl ◢", 12))
    r.check("Sitzfenster zeigt die aktuelle Uhrzeit",
            "Uhrzeit" in s.since(m))
    s.send(b"\r", 1.0)                       # Vorgabe: 1 Stunde
    r.check("schwarzer Bildschirm sagt »Du sitzt«",
            s.wait("Du sitzt", 10))
    r.check("eine Stunde gesessen",
            s.wait("Du hast eine Stunde gesessen", 10))
    r.check("Sitzen regeneriert +5 Tokens",
            "Tokens regeneriert: +5" in s.text())

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ==================================================== §2b Baracken-Szene
with start("baracke_statistics",
           {"CWD": SUED, "BARACKE_SCENE_DONE": 0, "PIXI_GUIDE_DONE": 1,
            "VERLAG_DONE": 1, "TOKENS_CUR": 100, "BITS": 0},
           learned=LEARNED_NO_STATS) as s:
    r = Report("2b) Baracke: statistics lernen")
    s.wait("Spielstand geladen", 20)

    # Vor der Szene ist statistics noch gesperrt.
    m = s.mark()
    s.cmd("statistics")
    r.check("statistics ist vor der Baracke gesperrt",
            s.wait_from(m, "Diesen Befehl hat der Virus mir genommen", 12))
    r.check("gesperrtes statistics öffnet kein Fenster",
            "◈ STATISTICS ◈" not in s.since(m))

    # Betreten der Baracke startet Pixis letzte Szene.
    m = s.mark()
    s.cmd("cd EingestürzteBaracke")
    r.check("Baracken-Szene startet beim Betreten",
            s.wait_from(m, "EINGESTÜRZTE BARACKE", 20))
    r.check("Pixi erklärt statistics",
            s.wait_from(m, "Spielzeit, Quests, Zeitungen", 40))
    r.check("statistics wird am Ende gelernt",
            s.wait_from(m, "Neuer Befehl erlernt: statistics", 40))
    r.check("Szene endet mit dem Hinweis auf Pixi",
            s.wait_from(m, "Ich sollte noch mal mit Pixi sprechen.", 20))
    m = s.mark()
    s.send(b"\r")
    r.check("Eingabezeile ist nach der Szene zurück",
            s.wait_from(m, "benutzer@testhost$", 15))
    s.drain(2.5)                              # Dialog sicher geschlossen

    m = s.mark()
    s.cmd("statistics")
    r.check("Statistics-Fenster öffnet nach dem Lernen",
            s.wait_from(m, "◈ STATISTICS ◈", 20))
    s.esc()
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# =========================================================== §3 Börty
BASE3 = {"CWD": KNEIPE, "PIXI_LETTER_DONE": 1, "AMANDA_DONE": 1,
         "SHERLOCK_DONE": 0, "BOERTY_INFO": 0, "BOERTY_SH_DONE": 0, "BITS": 0}

with start("boerty_arm", BASE3) as s:
    r = Report("3) Börty: ohne Bits")
    s.wait("Spielstand geladen", 20)
    m = s.mark()
    s.cmd("touch Börty")
    r.check("Börty nennt seinen Preis",
            s.wait_from(m, "Was Genaueres kostet 10 Bits", 20))
    s.send("1", 0.5)                          # »Bezahlen« wählen
    r.check("ohne Geld keine Auskunft", s.wait("Du hast nicht genug Bits", 15))
    s.send(b"\r", 0.8)                        # dialog_pause
    s.send("4", 0.6); s.send(b"\r", 0.8)      # Menü: Abschied
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

with start("boerty_reich", dict(BASE3, BITS=25)) as s:
    r = Report("3) Börty: mit Bits")
    s.wait("Spielstand geladen", 20)
    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "Was Genaueres kostet 10 Bits", 20)
    s.send("1", 0.5)
    r.check("Bezahlen wird bestätigt", s.wait("Gut. 10 Bits", 15))
    r.check("Börty verrät die Nachtzeit",
            s.wait("Holmes ist ein Nachttier", 15))
    m2 = s.mark()
    s.send(b"\r", 1.0)
    r.check("nach dem Bezahlen kommt das Standardmenü",
            s.wait_from(m2, "Was darf sein?", 10))
    s.send("4", 0.6); s.send(b"\r", 0.8)      # Menü: Abschied
    m = s.mark()
    s.cmd("inventar")
    r.check("10 Bits wurden abgebucht (25 -> 15)",
            s.wait_from(m, "15 Bits", 12))
    s.esc(); s.wait_from(m, "◈ TOKENS", 10)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# =========================================================== §4 Ermittler
BASE4 = {"CWD": DETEKTEI, "PIXI_LETTER_DONE": 1, "AMANDA_DONE": 1,
         "BOERTY_INFO": 1, "SHERLOCK_HUNT": 1, "SHERLOCK_NORD": 1,
         "SHERLOCK_BRIEF": 0, "SHERLOCK_DONE": 1, "ERMITTLER_DONE": 0,
         "VERLAG_DONE": 1, "PIXI_GUIDE_DONE": 1, "BARACKE_SCENE_DONE": 1,
         "PIXI_HALL_DONE": 1, "TOKENS_CUR": 500}

with start("ermittler", BASE4, inv=["pixisbrief"]) as s:
    r = Report("4) Ermittler: Detektei -> Pixi")
    s.wait("Spielstand geladen", 20)

    # Betreten der Detektei spielt die Szene automatisch ab.
    m = s.mark()
    s.cmd("ls")
    r.check("Detektei-Szene läuft beim Betreten",
            s.wait_from(m, "DETEKTEI HOLMES · VORZIMMER", 20))
    r.check("Briefübergabe bringt 100 EXP",
            s.wait("Belohnung ] 100 EXP", 40))
    r.check("Neues Ziel: Bericht an Pixi",
            s.wait("[ NEUES ZIEL ] Berichte Pixi", 10))
    s.send(b"\r", 1.0)                        # dialog_pause

    s.cmd("cd ../../Süddistrikt/DailyPulse", "DailyPulse")
    m = s.mark()
    s.cmd("touch Pixi")
    r.check("Bericht bei Pixi läuft",
            s.wait_from(m, "DAILYPULSE · BERICHT AUS DER NACHT", 20))
    r.check("Quest »Großer Ermittler« abgeschlossen",
            s.wait("»Großer Ermittler«", 30))
    r.check("Questbelohnung 200 EXP", "Questbelohnung: 200 EXP" in s.text())
    s.send(b"\r", 1.0)

    # 100 + 200 EXP: 0 -> 1 (100) -> 2 (200) -> Stufe 2, EXP 0
    m = s.mark()
    s.cmd("character")
    s.wait_from(m, "CHARAKTERBOGEN", 12)
    r.check("Stufe 2 durch 300 EXP", "LEVEL 2" in s.since(m))
    r.check("Max-Tokens je Aufstieg +1 (1000 -> 1002)",
            "1002" in s.since(m))
    s.esc(); s.wait_from(m, "◈ TOKENS", 10)

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ======================================= §5 Amanda nach Holmes' Rückkehr
with start("amanda_zurueck", {"CWD": DETEKTEI, "AMANDA_DONE": 1,
                              "SHERLOCK_NORD": 1, "SHERLOCK_BRIEF": 1}) as s:
    r = Report("5) Amanda nach Holmes' Rückkehr")
    s.wait("Spielstand geladen", 20)
    m = s.mark()
    s.cmd("touch Amanda")
    r.check("neuer Standarddialog (Holmes ist da)",
            s.wait_from(m, "Mr. Holmes ist im Büro", 20))
    r.check("das Katzen-Gespräch wird erwähnt",
            s.wait_from(m, "Die Katze", 20))
    r.check("nicht mehr »noch nicht zurück«",
            "noch nicht zurück" not in s.since(m))
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §6 Amanda vor der Sherlock-Quest
# Wer sie zufällig vor Pixis Brief anspricht, bekommt ein normales
# Bürogespräch ohne Holmes-Spur. AMANDA_DONE darf dabei NICHT gesetzt
# werden - sonst würde der spätere Quest-Hinweis übersprungen.
AMANDA_FRUEH_SAVE = os.path.join(TMP, "amanda_frueh", "manual1.save")
with start("amanda_frueh", {"CWD": DETEKTEI, "PIXI_LETTER_DONE": 0,
                            "AMANDA_DONE": 0, "AMANDA_INTRO_DONE": 0,
                            "SHERLOCK_DONE": 0, "SHERLOCK_BRIEF": 0}) as s:
    r = Report("6) Amanda vor der Sherlock-Quest")
    s.wait("Spielstand geladen", 20)
    m = s.mark()
    s.cmd("touch Amanda")
    r.check("sie stellt sich vor",
            s.wait_from(m, "Amanda Nox. Ich führe dieses Büro.", 20))
    r.check("der Standarddialog nennt Holmes' Büro",
            s.wait("Mr. Holmes ist nicht zu sprechen.", 20))
    r.check("keine Kneipen-Spur", "Zum Goldenen Lächeln" not in s.since(m))
    r.check("keine Börty-Spur", "Börty Smiles" not in s.since(m))
    r.check("keine Nacht-Spur", "nachts" not in s.since(m))
    s.send(b"\r", 1.0)

    m = s.mark()
    s.cmd("touch Amanda")
    r.check("beim zweiten Mal nur der kurze Standard",
            s.wait_from(m, "Bürozeiten sind Bürozeiten.", 20))
    s.send(b"\r", 1.0)

    s.cmd("save")
    s.wait("Spielstand in Slot", 10)
    with open(AMANDA_FRUEH_SAVE, encoding="utf-8") as fh:
        save = fh.read()
    r.check("früher Besuch setzt AMANDA_DONE nicht",
            "AMANDA_DONE=0" in save)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §7 Amanda mit laufender Sherlock-Quest
AMANDA_QUEST_SAVE = os.path.join(TMP, "amanda_quest", "manual1.save")
with start("amanda_quest", {"CWD": DETEKTEI, "PIXI_LETTER_DONE": 1,
                            "AMANDA_DONE": 0, "AMANDA_INTRO_DONE": 1,
                            "SHERLOCK_DONE": 0}) as s:
    r = Report("7) Amanda mit laufender Sherlock-Quest")
    s.wait("Spielstand geladen", 20)
    m = s.mark()
    s.cmd("touch Amanda")
    r.check("der Agent fragt nach Holmes",
            s.wait_from(m, "Ich suche Sherlock Holmes.", 20))
    r.check("Amanda nennt die Kneipe",
            s.wait("Zum Goldenen Lächeln", 20))
    r.check("und den Wirt",
            s.wait("Börty Smiles", 20))
    s.send(b"\r", 1.0)

    s.cmd("save")
    s.wait("Spielstand in Slot", 10)
    with open(AMANDA_QUEST_SAVE, encoding="utf-8") as fh:
        save = fh.read()
    r.check("Quest-Gespräch setzt AMANDA_DONE",
            "AMANDA_DONE=1" in save)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print("\nKettentest gesamt:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
