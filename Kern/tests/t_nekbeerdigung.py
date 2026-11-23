#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Neks Beerdigung & Neks Familie (PTY)
# ------------------------------------------------------------
#  Prüft die getimte Folgequest:
#    1) Gemunkel beim Betreten eines Stadtteils (Höhlen-Variante).
#    2) Gemunkel bei zurückgelassener Leiche (»vergammeln lassen«).
#    3) Trauergäste und Standarddialoge vor 16:00 auf dem Friedhof.
#    4) Beerdigung am fünften Spieltag ab 16:00 auf dem Friedhof
#       (1000 EXP, Quest abgeschlossen), danach Nachgespräche bis
#       Mitternacht.
#    5) Verpasster Termin -> Quest gescheitert.
#    6) Nach dem Nek-Abschluss fragt Simon nach dem Nachnamen und
#       vergibt die Folgequest »Neks Familie«.
#
#  Aufruf:  python3 Kern/tests/t_nekbeerdigung.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL,
                     RIGHT, DOWN)

reset_tmp()
fails = 0
H = "/home/benutzer"
DESK = H + "/Schreibtisch"
BASE = DESK + "/DesktopCity/Haupteingang"
CEMETERY = DESK + "/Brachland/Friedhof"

DAY5_1000 = 18600   # 5 Spieltage + 10 h ab Start 06:00 (vor 16:00)
DAY5_1600 = 19500   # 5 Spieltage + 16 h ab Start 06:00
DAY6_0600 = 21600   # Beginn des Folgetags
DAY7_1000 = 25800   # 7 Spieltage + 10 h (lost-Variante)


def start(name, cwd, scalars=None, dyn_type=None):
    d = os.path.join(TMP, name)
    sv = {"CWD": cwd, "OLDPWD": DESK, "VIEW_DIR": cwd,
          "SHOW_PATH": 1, "SHOW_LS": 1, "HOME_FIRST_VISIT": 1,
          "TUT_DONE": 1, "TORWAEHTER_DONE": 1, "WORLD_STARTED": 1}
    sv.update(scalars or {})
    write_save(os.path.join(d, "manual1.save"), scalars=sv,
               learned=LEARNED_ALL, dyn_type=dyn_type)
    return Sim(env={"TERMINALHERO_LOAD": "manual", "TH_SAY_SECS": "0.02"},
               saves=d)


def save_text(name):
    return open(os.path.join(TMP, name, "manual1.save"), encoding="utf-8").read()


# ================================================== §1 Gemunkel
with start("nek_geruecht_cave", BASE,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0}) as s:
    r = Report("1) Gemunkel im Stadtteil (Leiche in der Höhle)")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("cd Süddistrikt")
    r.check("Gemunkel erscheint beim Betreten",
            s.wait_from(m, "Du hörst jemand sagen", 20))
    r.check("Gemunkel nennt Nek", s.wait_from(m, "Nek wurde gefunden", 8))
    r.check("Gemunkel nennt das Datum",
            s.wait_from(m, "30.01.240", 8))
    r.check("Gemunkel nennt 16 Uhr", s.wait_from(m, "16 Uhr", 8))
    r.check("keine Vergammeln-Variante",
            not s.since(m).lower().count("vergammeln"))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §2 Lost-Gemunkel
with start("nek_geruecht_lost", BASE,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "lost",
            "NEK_FUNERAL_DAY": 7, "NEK_FUNERAL_DISCOVERY_DAY": 2,
            "NEK_FUNERAL_FOUND": 1, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0}) as s:
    r = Report("2) Gemunkel bei zurückgelassener Leiche")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("cd Westdistrikt")
    r.check("Gemunkel erscheint beim Betreten",
            s.wait_from(m, "Du hörst jemand sagen", 20))
    r.check("Gemunkel nennt das spätere Datum",
            s.wait_from(m, "01.02.240", 8))
    r.check("Gemunkel nennt das Vergammeln",
            s.wait_from(m, "vergammeln lassen", 8))
    r.check("Gemunkel nennt den Spieler",
            s.wait_from(m, "der Spieler", 8))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §3 Gäste vor 16:00
with start("nek_beerdigung_vor16", CEMETERY,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY5_1000}) as s:
    r = Report("3) Trauergäste und Standarddialoge vor 16:00")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    for name in ("FrancescoDellamorte", "Pixi", "Jack", "Rachel",
                 "SherlockHolmes", "Torwächter", "SimpleJon", "Börty",
                 "GregorMolerat", "MarleneMolerat", "ChantalMolerat"):
        r.check("Gast %s ist da" % name, s.wait_from(m, name, 10))

    dialogues = [
        ("FrancescoDellamorte", "Ah. Du bist früh.", "Francesco"),
        ("Pixi", "Ich schreibe seinen Namen auf", "Pixi"),
        ("Jack", "Ich habe ein Foto von ihm", "Jack"),
        ("Rachel", "Keine Tränen auf Seite eins", "Rachel"),
        ("SherlockHolmes", "Es gibt keinen Fall", "Sherlock"),
        ("Torwächter", "Nek war mein Freund", "Torwächter"),
        ("SimpleJon", "Sein Stuhl im Wachhaus", "Simple Jon"),
        ("Börty", "Nek hat immer pünktlich gezahlt", "Börty"),
        ("GregorMolerat", "Wir beerdigen meinen Sohn", "Vater"),
        ("MarleneMolerat", "Ich habe seine Uniform gebügelt", "Mutter"),
        ("ChantalMolerat", "Wie lange dauert das?", "Schwester"),
    ]
    for name, key, label in dialogues:
        m = s.mark()
        s.cmd("touch %s" % name)
        r.check("%s hat einen Standarddialog" % label,
                s.wait_from(m, key, 10))
        s.send(b"\r"); s.drain(0.25)

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_beerdigung_vor16")
    r.check("vor 16:00 noch nicht abgeschlossen",
            "NEK_FUNERAL_DONE=0" in sv)
    r.check("vor 16:00 noch kein Aufstieg",
            "LEVEL=0" in sv and "BITS=0" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §3b Lost vor 16:00
with start("nek_beerdigung_lost_vor16", CEMETERY,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "lost",
            "NEK_FUNERAL_DAY": 7, "NEK_FUNERAL_DISCOVERY_DAY": 2,
            "NEK_FUNERAL_FOUND": 1, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY7_1000}) as s:
    r = Report("3b) Empörung, wenn Nek liegen gelassen wurde")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Torwächter macht Vorwürfe",
            s.wait_from(m, "Du hast ihn gefunden und bist gegangen", 10))
    s.send(b"\r"); s.drain(0.25)

    m = s.mark()
    s.cmd("touch GregorMolerat")
    r.check("Vater macht Vorwürfe",
            s.wait_from(m, "Du hast meinen Sohn liegen lassen", 10))
    s.send(b"\r"); s.drain(0.25)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §4 Beerdigung
with start("nek_beerdigung", CEMETERY,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY5_1600}) as s:
    r = Report("4) Beerdigung am 30.01.240 um 16:00")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Beerdigung beginnt",
            s.wait("FRIEDHOF · NEKS BEERDIGUNG", 30))
    r.check("Nek wird beerdigt",
            s.wait("Nek Molerat ist nicht allein geblieben", 30))
    r.check("1000 EXP Belohnung",
            s.wait("Questbelohnung: 1000 EXP", 30))

    for key, label in (
            ("Die Toten beschweren sich nie", "Francesco-Rede"),
            ("Du warst mein Freund", "Torwächter"),
            ("Sein Stuhl im Wachhaus", "Simple Jon"),
            ("Nek war mein Sohn", "Vater"),
            ("Mein Junge. Mein Nek.", "Mutter"),
            ("Ich hasse Beerdigungen", "Schwester"),
            ("Heute Abend gebe ich einen aus", "Börty"),
            ("Es wird ein Nachruf", "Pixi"),
            ("Jack Nullpunkt", "Jack"),
            ("Ein Nachruf, keine Sensation", "Rachel"),
            ("Es gibt keinen Fall", "Sherlock"),
            ("+8 Bits", "Bits pro Levelup")):
        r.check("%s kommt vor" % label, s.wait(key, 10))

    # Die Feier endet mit einem Lesepunkt; danach bleiben die Gäste
    # bis Mitternacht für die Nachgespräche am Grab.
    s.send(b"\r"); s.drain(0.4)
    m = s.mark(); s.cmd("ls")
    r.check("Pixi bleibt nach der Feier", s.wait_from(m, "Pixi", 10))
    r.check("Chantal bleibt nach der Feier",
            s.wait_from(m, "ChantalMolerat", 10))

    m = s.mark(); s.cmd("touch Pixi")
    r.check("Pixi hat ein Nachgespräch",
            s.wait_from(m, "Der Nachruf steht", 10))
    s.send(b"\r"); s.drain(0.25)

    m = s.mark(); s.cmd("touch FrancescoDellamorte")
    r.check("Francesco hat ein Nachgespräch",
            s.wait_from(m, "Die Erde ist geschlossen", 10))
    s.send(b"\r"); s.drain(0.25)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_beerdigung")
    r.check("Beerdigung ist abgeschlossen", "NEK_FUNERAL_DONE=1" in sv)
    r.check("Beerdigung ist nicht gescheitert", "NEK_FUNERAL_FAILED=0" in sv)
    r.check("1000 EXP als Aufstiege verbucht", "LEVEL=4" in sv)
    r.check("vier Aufstiege geben 32 Bits", "BITS=32" in sv)
    r.check("vier Aufstiege erhöhen MaxTokens", "TOKENS_MAX=1004" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §5 Mitternacht
with start("nek_beerdigung_mitternacht", CEMETERY,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 1,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY6_0600},
           dyn_type={CEMETERY + "/Pixi": "f",
                     CEMETERY + "/ChantalMolerat": "f"}) as s:
    r = Report("5) Nach Mitternacht sind die Gäste fort")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark(); s.cmd("ls")
    r.check("Pixi ist nicht mehr im Friedhof",
            not s.wait_from(m, "Pixi", 2))
    r.check("Chantal ist nicht mehr im Friedhof",
            not s.wait_from(m, "ChantalMolerat", 2))
    r.check("Francesco bleibt im Friedhof",
            s.wait_from(m, "FrancescoDellamorte", 10))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §6 Verpasst
with start("nek_beerdigung_verpasst", BASE,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0, "WORLD_SECS": DAY6_0600}) as s:
    r = Report("6) Verpasster Beerdigungstag")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Quest wird als gescheitert gemeldet",
            s.wait("QUEST GESCHEITERT", 20))
    r.check("Meldung nennt die Beerdigung",
            s.wait("Neks Beerdigung", 8))

    s.cmd("questlog")
    r.check("Questlog öffnet", s.wait("QUESTLOG", 15))
    s.send(RIGHT); s.drain(0.35)   # Nebenquest
    s.send(DOWN); s.drain(0.35)    # Status
    s.send(RIGHT); s.drain(0.35)   # Abgeschlossen
    s.send(RIGHT); s.drain(0.35)   # Gescheitert
    s.send(DOWN); s.drain(0.35)    # Liste
    r.check("Status ist gescheitert",
            s.wait("Status: gescheitert", 8))
    r.check("Quest heißt Neks Beerdigung",
            s.wait("Neks Beerdigung", 8))
    s.send(b"\x1b"); s.drain(0.6)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_beerdigung_verpasst")
    r.check("Fehlschlag ist gespeichert", "NEK_FUNERAL_FAILED=1" in sv)
    r.check("nicht als abgeschlossen gespeichert", "NEK_FUNERAL_DONE=0" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §7 Familie
with start("nek_familie", BASE,
           {"NEK_GIVEN": 1, "NEK_DONE": 1, "NEK_FOUND": 1,
            "NEK_REPORTED": 1, "VERMISSTE_GIVEN": 1,
            "SIMON_NEK_INFO": 1, "NEK_AMULET_KEPT": 1,
            "NEK_FUNERAL_GIVEN": 1, "NEK_FUNERAL_DISPOSITION": "cave",
            "NEK_FUNERAL_DAY": 5, "NEK_FUNERAL_DISCOVERY_DAY": -1,
            "NEK_FUNERAL_FOUND": 0, "NEK_FUNERAL_DONE": 0,
            "NEK_FUNERAL_FAILED": 0}) as s:
    r = Report("7) Simon: Nachname, Familie & Folgequest")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Hauptmenü bietet Vermisste",
            s.wait_from(m, "Vermisste Bewohner?", 20))
    s.send("1"); s.drain(0.8)
    r.check("Simon erinnert an Nek",
            s.wait_from(m, "Nek. Du hast ihn gefunden", 20))
    r.check("Simon bietet die Nachnamensfrage an",
            s.wait_from(m, "Warum heißt Nek", 12))
    s.send("1"); s.drain(0.8)
    r.check("Simon erklärt den Nachnamen",
            s.wait_from(m, "Ist halt sein Nachname", 12))
    r.check("Simon verweist auf die Familie",
            s.wait_from(m, "such die Familie auf", 8))
    r.check("Simon nennt Fleischerei/Metzgerei",
            s.wait_from(m, "Fleischerei und Metzgerei", 8))
    r.check("Folgequest wird vergeben",
            s.wait_from(m, "Neks Familie", 8))
    s.send(b"\r"); s.drain(0.8)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_familie")
    r.check("Familienquest ist vergeben", "NEK_FAMILY_GIVEN=1" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


print("\nNEKS-BEERDIGUNG-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
