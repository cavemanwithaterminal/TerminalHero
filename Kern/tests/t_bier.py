#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Bierlieferung: Ersatz, Frist und Scheitern (PTY)
# ------------------------------------------------------------
#  Prüft die Regeln rund um die Bierkiste:
#
#    1) Ist die Kiste verloren, gibt Samy für 250 Bits Ersatz.
#       Eine zweite Kiste gibt es nicht, solange eine im Inventar liegt.
#    2) Nach 24 Spielstunden ohne Kiste rechnet Börty ab:
#       »Du hast meine Kiste nicht geliefert!« / »Wo ist mein Geld?«
#       Die Quest steht danach auf »gescheitert«.
#    3) Vor Ablauf der Frist gibt es noch kein Scheitern-Event.
#    4) Nach Ablauf gibt Samy keinen Ersatz mehr.
#
#  Aufruf:  python3 Kern/tests/t_bier.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity/Haupteingang"
LAGER = CITY + "/Zentrum/Marktplatz/Lager"
KNEIPE = CITY + "/Ostdistrikt/KneipeZumGoldenenLächeln"


def start(name, scalars, inv=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=LEARNED_ALL, inv=inv)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


# ============================================= §1 Ersatzkiste bei Samy
with start("bier_ersatz", {"CWD": LAGER, "SAMY_INTRO_DONE": 1,
                           "ERMITTLER_DONE": 1, "BIER_GIVEN": 1,
                           "BIER_TAKEN": 1, "BIER_DONE": 0,
                           "BIER_FAILED": 0, "BIER_LOST_AT": 0,
                           "BITS": 300}) as s:
    r = Report("1) Samy: Ersatzkiste für 250 Bits")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    r.check("die Quest-Option steht da",
            s.wait_from(m, "Bier für Börty.", 20))
    s.send("1", 0.6)
    r.check("Samy erkennt den Verlust",
            s.wait("Deine Kiste ist weg?", 20))
    r.check("Ersatz kostet wieder 250 Bits",
            s.wait("Ersatz gibt es. Kostet wieder 250 Bits.", 20))
    s.send(b"\r", 1.5)
    r.check("die Ersatzkiste wandert ins Inventar",
            s.wait("[ Ersatzkiste ]", 20))
    r.check("250 Bits werden abgebucht",
            s.wait("-250 Bits an Samy Cage", 20))
    s.send(b"\r", 1.2)

    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    s.drain(1.0)
    s.send("1", 0.6)
    r.check("keine zweite Kiste bei vorhandener Kiste",
            s.wait("Du hast deine Kiste doch noch.", 20))
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §2 Scheitern nach 24 Spielstunden
with start("bier_gescheitert", {"CWD": KNEIPE, "BOERTY_INTRO_DONE": 1,
                                "ERMITTLER_DONE": 1, "BOERTY_FAVOR_DONE": 1,
                                "VERMISSTE_GIVEN": 1, "BIER_GIVEN": 1,
                                "BIER_TAKEN": 1, "BIER_DONE": 0,
                                "BIER_FAILED": 0, "BIER_LOST_AT": 0,
                                "WORLD_SECS": 3600}) as s:
    r = Report("2) Börty: Scheitern nach 24 Spielstunden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Börty")
    r.check("Börty rechnet ab",
            s.wait_from(m, "Du hast meine Kiste nicht geliefert!", 25))
    r.check("und fragt nach seinem Geld",
            s.wait("Wo ist mein Geld?", 20))
    r.check("die Quest ist gescheitert",
            s.wait("QUEST GESCHEITERT", 20))
    r.check("»Bier für Börty« wird genannt",
            s.wait("Bier für Börty", 20))
    s.send(b"\r", 1.2)

    m = s.mark()
    s.cmd("touch Börty")
    s.wait_from(m, "Was darf sein?", 20)
    s.drain(1.0)
    r.check("keine Bitte-Option mehr", "behilflich" not in s.since(m))
    s.send("5", 0.6)
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §3 Noch kein Event vor der Frist
with start("bier_frist", {"CWD": KNEIPE, "BOERTY_INTRO_DONE": 1,
                          "ERMITTLER_DONE": 1, "BOERTY_FAVOR_DONE": 1,
                          "VERMISSTE_GIVEN": 1, "BIER_GIVEN": 1,
                          "BIER_TAKEN": 1, "BIER_DONE": 0,
                          "BIER_FAILED": 0, "BIER_LOST_AT": 0,
                          "WORLD_SECS": 3500}) as s:
    r = Report("3) Börty: vor Ablauf der 24 Stunden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Börty")
    r.check("normales Standardgespräch",
            s.wait_from(m, "Was darf sein?", 25))
    r.check("noch kein Scheitern-Event",
            "Du hast meine Kiste nicht geliefert!" not in s.since(m))
    s.send("6", 0.6)              # Abschied (nach Bitte + Vermisste)
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================= §4 Nach der Frist kein Ersatz mehr
with start("bier_zu_spaet", {"CWD": LAGER, "SAMY_INTRO_DONE": 1,
                             "ERMITTLER_DONE": 1, "BIER_GIVEN": 1,
                             "BIER_TAKEN": 1, "BIER_DONE": 0,
                             "BIER_FAILED": 0, "BIER_LOST_AT": 0,
                             "WORLD_SECS": 3600, "BITS": 300}) as s:
    r = Report("4) Samy: nach 24 Stunden kein Ersatz")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch SamyCage")
    s.wait_from(m, "Du schon wieder", 20)
    s.drain(1.2)
    s.send("1", 0.6)
    r.check("Samy schickt zum Wirt", s.wait("Zu spät.", 20))
    r.check("keine Ersatzkiste", "[ Ersatzkiste ]" not in s.since(m))
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print()
if fails:
    print("BIER-TEST: %d Fehler" % fails)
else:
    print("BIER-TEST: 0 Fehler")
sys.exit(1 if fails else 0)
