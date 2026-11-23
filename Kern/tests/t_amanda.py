#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Unterstützung für Amanda (PTY)
# ------------------------------------------------------------
#  Prüft die neue Nebenquest nach »Großer Ermittler«:
#    1) Amanda bietet die Option »Kann ich dir helfen?« erst nach
#       abgeschlossener Hauptquest an.
#    2) Das ausgebaute Gespräch vergibt »Unterstützung für Amanda«,
#       ohne einen Kandidaten zu nennen.
#    3) Jack bietet »Amanda helfen« an, vertröstet aber, solange seine
#       eigene Zeitungsquest offen ist.
#    4) Nach Jacks Zeitungsquest stimmt er zu; Rachel kommentiert,
#       Jack zieht in die Detektei um und hat dort einen neuen Dialog.
#    5) Amanda bedankt sich, gibt 200 EXP und hat danach den neuen
#       Standard-Dialog.
#
#  Aufruf:  python3 Kern/tests/t_amanda.py
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
OST = CITY + "/Ostdistrikt"
DETEKTEI = OST + "/DetekteiHolmes"

# Jacks Queststand und die Familienszenen sind für diese Tests bereits
# abgeschlossen; der Fokus liegt auf dem Amanda-Gespräch.
BASE = {
    "PIXI_DESKTOP_DONE": 1,
    "PIXI_GATE_DONE": 1,
    "PIXI_HALL_DONE": 1,
    "VERLAG_DONE": 1,
    "PIXI_GUIDE_DONE": 1,
    "BARACKE_SCENE_DONE": 1,
    "SHERLOCK_DONE": 1,
    "SHERLOCK_BRIEF": 1,
    "AMANDA_DONE": 1,
    "AMANDA_INTRO_DONE": 1,
    "ERMITTLER_DONE": 1,
}


def start(name, scalars):
    d = os.path.join(TMP, name)
    write_save(os.path.join(d, "manual1.save"), scalars=scalars,
               learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=d)


def save_text(name):
    with open(os.path.join(TMP, name, "manual1.save"), encoding="utf-8") as fh:
        return fh.read()


# ======================================= §1 Vor der Hauptquest
with start("amanda_vorher", dict(BASE, CWD=DETEKTEI, ERMITTLER_DONE=0,
                                 SHERLOCK_BRIEF=0, AMANDA_DONE=0,
                                 AMANDA_INTRO_DONE=0)) as s:
    r = Report("1) Amanda vor »Großer Ermittler«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Amanda")
    r.check("normales Bürogespräch",
            s.wait_from(m, "Mr. Holmes ist nicht zu sprechen.", 20))
    s.drain(0.6)
    r.check("keine Hilfe-Option", "Kann ich dir helfen?" not in s.since(m))
    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ======================================= §2 Angebot & Questvergabe
with start("amanda_angebot", dict(BASE, CWD=DETEKTEI)) as s:
    r = Report("2) Amanda: Hilfe anbieten, Quest erhalten")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Amanda")
    r.check("Option »Kann ich dir helfen?«",
            s.wait_from(m, "Kann ich dir helfen?", 20))
    r.check("Abschiedsoption ist da",
            s.wait_from(m, "Nichts weiter.", 20))
    s.send("1", 0.8)
    r.check("Amanda erklärt ihre Arbeit",
            s.wait_from(m, "Diese Arbeit ist nicht für jeden", 25))
    r.check("der Stapel wächst",
            s.wait_from(m, "mehr Arbeit als morgens", 25))
    r.check("der Agent schlägt eine zweite Hand vor",
            s.wait_from(m, "zweite Hand", 25))
    r.check("Amanda fragt nach einem Kandidaten",
            s.wait_from(m, "wer kommt dafür in Frage", 25))
    r.check("der Agent hält die Augen offen",
            s.wait_from(m, "Ich halte die Augen offen", 25))
    r.check("kein Kandidatenname im Gespräch",
            "Jack" not in s.since(m) and "Nullpunkt" not in s.since(m))
    r.check("Quest »Unterstützung für Amanda« erhalten",
            s.wait_from(m, "»Unterstützung für Amanda« erhalten", 25))
    r.check("neues Ziel wird angezeigt",
            s.wait_from(m, "[ NEUES ZIEL ]", 20))

    # Nach dem Gespräch bleibt das Menü offen; mit der Abschiedsoption
    # beenden.
    s.send(b"\r", 1.0)
    r.check("das Menü ist wieder da",
            s.wait_from(m, "Worum ging es noch?", 15))
    s.send("2", 0.8)
    s.send(b"\r", 0.8)

    s.cmd("save")
    s.wait("Spielstand in Slot", 10)
    sv = save_text("amanda_angebot")
    r.check("AMANDA_HELP_GIVEN wird gespeichert",
            "AMANDA_HELP_GIVEN=1" in sv)
    r.check("Jack ist noch nicht umgezogen",
            "AMANDA_HELP_JACK=0" in sv)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ======================================= §3 Jack vertröstet
with start("amanda_jack_wartet",
           dict(BASE, CWD=VERLAG, AMANDA_HELP_GIVEN=1,
                AMANDA_HELP_ASKED=0, AMANDA_HELP_JACK=0,
                ZEITUNG_GIVEN=1, ZEITUNG_DONE=0)) as s:
    r = Report("3) Jack: Amanda helfen, aber Zeitung zuerst")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("touch Jack")
    r.check("Option »Amanda helfen« steht im Menü",
            s.wait_from(m, "Amanda helfen", 20))
    s.send("3", 0.8)
    r.check("Jack findet die Idee interessant",
            s.wait_from(m, "interessant", 20))
    r.check("Jack würde Amanda gern helfen",
            s.wait_from(m, "Ich würde ihr gern helfen", 20))
    r.check("die aktuelle Ausgabe muss zuerst weg",
            s.wait_from(m, "aus dem Verkehr", 20))
    r.check("Jack bittet um ein späteres Gespräch",
            s.wait_from(m, "Frag mich dann noch einmal.", 20))
    s.send(b"\r", 1.0)

    s.send("5", 0.8)                        # Menü: Nichts weiter.
    s.send(b"\r", 0.8)
    m = s.mark()
    s.cmd("ls")
    r.check("Jack bleibt im Verlag", s.wait_from(m, "Jack", 8))

    s.cmd("save")
    s.wait("Spielstand in Slot", 10)
    sv = save_text("amanda_jack_wartet")
    r.check("AMANDA_HELP_ASKED wird gespeichert",
            "AMANDA_HELP_ASKED=1" in sv)
    r.check("Jack ist noch nicht umgezogen",
            "AMANDA_HELP_JACK=0" in sv)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ======================================= §4 Umzug & Abschluss
with start("amanda_umzug",
           dict(BASE, CWD=VERLAG, AMANDA_HELP_GIVEN=1,
                AMANDA_HELP_ASKED=1, AMANDA_HELP_JACK=0,
                ZEITUNG_GIVEN=1, ZEITUNG_DONE=1)) as s:
    r = Report("4) Jack zieht um, Amanda bedankt sich")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Option »Amanda helfen« steht im Menü",
            s.wait_from(m, "Amanda helfen", 20))
    s.send("2", 0.8)                        # 1 = Befehl lernen
    r.check("Jack stimmt zu",
            s.wait_from(m, "Die Ausgabe ist aus dem Verkehr.", 25))
    r.check("Jack geht zu Amanda",
            s.wait_from(m, "Ich geh zu Amanda.", 20))
    r.check("Rachel will ihren Sohn nicht abwerben lassen",
            s.wait_from(m, "meinen Sohn abwerben", 20))
    r.check("Jack beruhigt seine Mutter",
            s.wait_from(m, "Keine Sorge", 20)
            and s.wait_from(m, "bald wieder zurück", 20))
    r.check("Jack verlässt den Verlag",
            s.wait_from(m, "Die Tür zum Vorzimmer fällt hinter ihm zu.", 20))
    s.send(b"\r", 1.0)

    m = s.mark()
    s.cmd("ls")
    r.check("Jack ist aus dem DailyPulse verschwunden",
            "Jack" not in s.since(m))

    # In die Detektei: Jack steht jetzt im Vorzimmer.
    s.cmd("cd ../..")
    s.cmd("cd Ostdistrikt")
    s.cmd("cd DetekteiHolmes")
    m = s.mark()
    s.cmd("ls")
    r.check("Jack steht in der Detektei",
            s.wait_from(m, "Jack", 10))
    r.check("Amanda ist ebenfalls da",
            s.wait_from(m, "Amanda", 10))

    m = s.mark()
    s.cmd("touch Jack")
    r.check("Jacks neuer Standard-Dialog",
            s.wait_from(m, "Gibt viel zu tun hier, macht aber auch irgendwie Spaß.", 20))
    r.check("er spricht über die Akten",
            s.wait_from(m, "Ablage", 20))
    s.send(b"\r", 1.0)

    m = s.mark()
    s.cmd("touch Amanda")
    r.check("Amanda dankt für Jack",
            s.wait_from(m, "Sie haben ihn wirklich hergebracht.", 20))
    r.check("Jack war eine gute Wahl",
            s.wait_from(m, "eine gute Wahl", 20))
    r.check("der Berg wird kleiner",
            s.wait_from(m, "Berg", 20))
    r.check("Quest abgeschlossen",
            s.wait_from(m, "QUEST ABGESCHLOSSEN", 20))
    r.check("200 EXP Belohnung",
            s.wait_from(m, "Questbelohnung: 200 EXP", 20))
    r.check("Questtitel im Abschluss",
            s.wait_from(m, "Unterstützung für Amanda", 20))
    s.send(b"\r", 1.0)

    m = s.mark()
    s.cmd("touch Amanda")
    r.check("neuer Standard-Dialog nach dem Abschluss",
            s.wait_from(m, "Wir kommen hier gut voran mit den Akten.", 20))
    s.send(b"\r", 1.0)

    s.cmd("save")
    s.wait("Spielstand in Slot", 10)
    sv = save_text("amanda_umzug")
    r.check("AMANDA_HELP_JACK wird gespeichert",
            "AMANDA_HELP_JACK=1" in sv)
    r.check("AMANDA_HELP_DONE wird gespeichert",
            "AMANDA_HELP_DONE=1" in sv)
    r.check("keine Skriptfehler im Gespräch",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print("\nAMANDA-TESTS: %d Fehler" % fails)
sys.exit(1 if fails else 0)
