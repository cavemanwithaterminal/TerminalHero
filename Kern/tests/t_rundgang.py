#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Pixis Stadtrundgang (PTY)
# ------------------------------------------------------------
#  Prüft die Kette nach »Großer Ermittler« und Jacks Zeitungsquest:
#    1) Artikel fertig, Papier fehlt -> noch kein Rundgang.
#    2) Beide Quests fertig, aber 15:00 -> nur Termin-Hinweis.
#    3) 06:00: Rundgang ueber alle fuenf Distrikte, automatische
#       Ortswechsel, pwd/ls ohne Tokenkosten, 1000 EXP und Abschluss.
#    4) Nach dem Rundgang bietet Pixi ihn nicht erneut an.
#
#  Aufruf:  python3 Kern/tests/t_rundgang.py
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
VERLAG = SUED + "/DailyPulse"


def start(name, scalars, env=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=LEARNED_ALL)
    e = {
        "TERMINALHERO_LOAD": "manual",
        "TH_SAY_SECS": "0.02",
        "TH_SLEEP_SECS": "0.2",
        "TH_SIT_SECS": "0.2",
    }
    e.update(env or {})
    return Sim(env=e, saves=os.path.join(TMP, name))


def publisher(**extra):
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
        "TOKENS_CUR": 1000,
        "WORLD_STARTED": 1,
        "WORLD_SECS": 0,
    }
    vals.update(extra)
    return vals


# ================================================ §1 Papier fehlt noch
with start("rundgang_papier", publisher(ZEITUNG_DONE=0)) as s:
    r = Report("1) Nach dem Artikel fehlt das Papier")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Pixi")
    r.check("Pixi nennt das fehlende Papier",
            s.wait_from(m, "Es fehlt nur noch das Papier", 15))
    r.check("Jack holt die letzte Ausgabe zurück",
            s.wait_from(m, "Jack muss dafür seine letzte Ausgabe aus den Kästen zurückholen", 15))
    r.check("noch keine Rundgang-Option",
            "Rundgang machen" not in s.since(m))
    s.send(b"\r", 0.5)
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================ §2 Falsche Tageszeit
with start("rundgang_zeit", publisher(ZEITUNG_DONE=1, WORLD_SECS=1350)) as s:
    r = Report("2) 15:00: kein Rundgang, nur Termin")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Pixi")
    r.check("Pixi nennt das Zeitfenster",
            s.wait_from(m, "zwischen 06:00 und 14:00", 15))
    r.check("Pixi schickt zum richtigen Zeitpunkt weg",
            s.wait_from(m, "Komm in diesem Zeitfenster wieder", 15))
    r.check("keine Rundgang-Option am Nachmittag",
            "Rundgang machen" not in s.since(m))
    s.send(b"\r", 0.5)
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================ §3 Kompletter Rundgang
with start("rundgang_tour", publisher(ZEITUNG_DONE=1, WORLD_SECS=0,
                                      BITS=0)) as s:
    r = Report("3) Rundgang: fünf Distrikte, pwd/ls, 1000 EXP")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Pixi")
    r.check("Standardgespräch bietet den Rundgang an",
            s.wait_from(m, "Rundgang machen.", 15))
    s.send("1", 0.5)
    r.check("Pixi fragt nach der Bereitschaft",
            s.wait("Bist du bereit?", 15))
    s.send("1", 0.5)

    r.check("Pixi erklärt direkte Stadtteilwechsel",
            s.wait("cd Ostdistrikt", 15)
            and s.wait("nicht erst mit »cd ..« bis zum Haupteingang", 15))
    r.check("Pixi nennt die direkte Schreibweise mehrerer Bezirke",
            s.wait("cd Westdistrikt", 15) and s.wait("cd Zentrum", 15))
    r.check("Süddistrikt wird angekündigt",
            s.wait("STADTRUNDGANG · SÜDDISTRIKT", 15))
    r.check("Ankunft im Süddistrikt wird genannt",
            s.wait("Im Süddistrikt angekommen", 15))
    r.check("Pfadfenster zeigt den Süddistrikt",
            "Süddistrikt" in s.since(m))
    r.check("Ordnerfenster zeigt den Verlag",
            "DailyPulse" in s.since(m))
    r.check("Ordnerfenster zeigt die Baracke",
            "EingestürzteBaracke" in s.since(m))
    r.check("nur touch kostet Tokens (1000 -> 995)",
            s.wait("995 / 1000", 15))

    # Jeder Distrikt endet mit einer ausdrücklichen Bestätigung.
    m = s.mark()
    r.check("Süden endet mit Bestätigung",
            s.wait_from(m, "Bereit für das Zentrum?", 15))
    s.send("1", 0.5)
    r.check("Zentrum wird angekündigt",
            s.wait("STADTRUNDGANG · ZENTRUM", 15))
    r.check("Marktplatz wird gezeigt",
            s.wait("Marktplatz", 15))
    r.check("Samy Cage wird erwähnt",
            s.wait("Samy Cage", 15))
    r.check("Schmiede wird erwähnt",
            s.wait("Schmiede von Bruno Amboss", 15))
    r.check("Bruno Amboss wird erwähnt",
            s.wait("Bruno repariert, was andere wegwerfen", 15))
    r.check("Kampfset wird erwähnt",
            s.wait("das Einfache Set und sein Kampfset", 15))

    m = s.mark()
    r.check("Zentrum endet mit Bestätigung",
            s.wait_from(m, "Bereit für den Ostdistrikt?", 15))
    s.send("1", 0.5)
    r.check("Ostdistrikt wird angekündigt",
            s.wait("STADTRUNDGANG · OSTDISTRIKT", 15))
    r.check("Detektei wird gezeigt",
            s.wait("DetekteiHolmes", 15))
    r.check("Pixi ist gespannt auf Sherlocks Meinung",
            s.wait("Ich bin gespannt, was Sherlock von meinem Artikel über die Sperrzone hält", 15))
    r.check("Kneipe wird gezeigt",
            s.wait("KneipeZumGoldenenLächeln", 15))
    r.check("Börty wird erwähnt",
            s.wait("Börty Smiles", 15))

    m = s.mark()
    r.check("Osten endet mit Bestätigung",
            s.wait_from(m, "Bereit für den Norddistrikt?", 15))
    s.send("1", 0.5)
    r.check("Norddistrikt wird angekündigt",
            s.wait("STADTRUNDGANG · NORDDISTRIKT", 15))
    r.check("Norddistrikt wird beschrieben",
            s.wait("Der stillste Teil der Stadt", 15))

    m = s.mark()
    r.check("Norden endet mit Bestätigung",
            s.wait_from(m, "Bereit für den Westdistrikt?", 15))
    s.send("1", 0.5)
    r.check("Westdistrikt wird angekündigt",
            s.wait("STADTRUNDGANG · WESTDISTRIKT", 15))
    r.check("Restaurant wird gezeigt",
            s.wait("Restaurant", 15))
    r.check("Michael Mitch wird erwähnt",
            s.wait("Michael Mitch", 15))

    m = s.mark()
    r.check("Westen endet mit Bestätigung",
            s.wait_from(m, "Bereit für den Rückweg zum DailyPulse?", 15))
    s.send("1", 0.5)
    r.check("Rückkehr in den Verlag wird angekündigt",
            s.wait("STADTRUNDGANG · ZURÜCK IM DAILYPULSE", 15))
    r.check("Pixi beendet den Rundgang",
            s.wait("So. Das war der Rundgang.", 15))
    r.check("Pixi nennt die wichtigsten Orte und Leute",
            s.wait("Jetzt kennst du die wichtigsten Orte", 15))
    r.check("Pixi erwähnt die fertig gedruckte neue Ausgabe",
            s.wait("Mama müsste die neue Ausgabe inzwischen fertig gedruckt haben", 15))
    r.check("Pixi nennt das Thema der neuen Ausgabe",
            s.wait("Die über die Sperrzone", 15))
    r.check("1000 EXP werden gutgeschrieben",
            s.wait("Questbelohnung: 1000 EXP", 20))
    r.check("Quest gilt als abgeschlossen",
            s.wait("QUEST ABGESCHLOSSEN", 15))
    r.check("Pfadfenster ist wieder im Verlag",
            "DailyPulse" in s.since(m))
    r.check("keine weiteren Tokenkosten während des Rundgangs",
            "995 / 1000" in s.text())

    # Dialog schließen, speichern und den gesicherten Zustand prüfen.
    s.send(b"\r", 0.5)
    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 15))
    save = os.path.join(TMP, "rundgang_tour", "manual1.save")
    with open(save, encoding="utf-8") as fh:
        data = fh.read()
    r.check("RUNDGANG_GIVEN ist gesichert", "RUNDGANG_GIVEN=1" in data)
    r.check("RUNDGANG_DONE ist gesichert", "RUNDGANG_DONE=1" in data)
    r.check("neue Ausgabe ist gesichert", "ZEITUNG_EDITION=sperrzone" in data)
    r.check("fünf leere Kästen warten auf die Verteilung",
            "ZEITUNG_EMPTIED=31" in data)
    r.check("save kostet 5 Tokens", "TOKENS_CUR=990" in data)

    # ============================================ §4 Kein zweiter Rundgang
    m = s.mark()
    s.cmd("touch Pixi")
    r.check("Pixi erinnert an den Rundgang",
            s.wait_from(m, "Der Rundgang war gut.", 15))
    r.check("kein zweiter Rundgang",
            "Rundgang machen" not in s.since(m))
    s.send(b"\r", 0.5)
    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

sys.exit(1 if fails else 0)
