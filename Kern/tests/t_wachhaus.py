#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Wachhaus, Simon Guard & Nek Molerat (PTY)
# ------------------------------------------------------------
#  Prüft die neue Inhaltskette:
#    1) Simon Guard (Torwache) bietet mit der Hauptquest
#       »Vermisste Bewohner« die Option »Vermisste Bewohner?« an.
#       Er erzählt von Nek Molerat und vergibt die Nebenquest
#       »Wo ist Nek Molerat?«.
#    2) Ohne die Hauptquest fehlt die Option.
#    3) Simple Jon steht im Wachhaus (Haupteingang), hat den
#       Standard-Dialog und mit der Nek-Quest die Option
#       »Nek Molerat?«. Sein Wissen landet im Nek-Questlog.
#    4) Ohne Nek-Quest fehlt Jons Option.
#
#  Aufruf:  python3 Kern/tests/t_wachhaus.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity"
BASE = CITY + "/Haupteingang"
WACHHAUS = BASE + "/Wachhaus"


def start(name, scalars):
    d = os.path.join(TMP, name)
    write_save(os.path.join(d, "manual1.save"), scalars=scalars,
               learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=d, rows=40, cols=120)


# ================================================== §1 Simon Guard: Nek
with start("wach_simon_nek", {
        "CWD": BASE, "OLDPWD": CITY, "VIEW_DIR": BASE,
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "PIXI_GATE_DONE": 1, "PIXI_HALL_DONE": 1,
        "TORWAEHTER_DONE": 1,
        "VERMISSTE_GIVEN": 1,
        "SIMON_NEK_INFO": 0, "NEK_GIVEN": 0, "JON_NEK_INFO": 0,
}) as s:
    r = Report("1) Simon Guard: Vermisste Bewohner & Nek Molerat")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon Guard begrüßt den Agenten",
            s.wait_from(m, "Bisher kein Ärger", 20))
    r.check("die Option Vermisste Bewohner erscheint",
            s.wait_from(m, "1) Vermisste Bewohner?", 15))
    r.check("Nek wird erst nach der Auswahl genannt",
            "Nek Molerat" not in s.since(m))

    s.send("1", 0.8)
    r.check("Simon nennt seinen Freund",
            s.wait_from(m, "Nek Molerat. Ja. Er ist einer von uns.", 20))
    r.check("Simon sagt, dass Nek seit Tagen fehlt",
            s.wait_from(m, "seit Tagen nicht aufgetaucht", 20))
    r.check("Simon bittet um Bericht",
            s.wait_from(m, "sag mir Bescheid", 20))
    r.check("der Agent stimmt zu",
            s.wait_from(m, "Ich halte die Augen offen", 20))
    r.check("die Nek-Quest wird vergeben",
            s.wait_from(m, "»Wo ist Nek Molerat?« erhalten", 20))
    r.check("der Questlog nennt die neue Spur",
            s.wait_from(m, "Neue Spur: Simon Guard: Nek Molerat", 20))
    r.check("der Hinweis führt ins Wachhaus",
            s.wait_from(m, "Simple Jon im Wachhaus", 20))

    s.send(b"\r", 1.0)
    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    save = open(os.path.join(TMP, "wach_simon_nek", "manual1.save"),
                encoding="utf-8").read()
    r.check("NEK_GIVEN ist gesichert", "NEK_GIVEN=1" in save)
    r.check("SIMON_NEK_INFO ist gesichert", "SIMON_NEK_INFO=1" in save)
    r.check("Jon wurde noch nicht gefragt", "JON_NEK_INFO=0" in save)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §2 Simon Guard: Gating
with start("wach_simon_ohne", {
        "CWD": BASE, "OLDPWD": CITY, "VIEW_DIR": BASE,
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "PIXI_GATE_DONE": 1, "PIXI_HALL_DONE": 1,
        "TORWAEHTER_DONE": 1,
        "VERMISSTE_GIVEN": 0,
}) as s:
    r = Report("2) Simon Guard: keine Option ohne Hauptquest")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Standard-Dialog läuft",
            s.wait_from(m, "Bisher kein Ärger", 20))
    s.drain(2)
    r.check("keine Option Vermisste Bewohner",
            "Vermisste Bewohner?" not in s.since(m))
    s.send(b"\r", 1.0)
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §3 Simple Jon: Nek
with start("wach_jon_nek", {
        "CWD": WACHHAUS, "OLDPWD": BASE, "VIEW_DIR": WACHHAUS,
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "PIXI_GATE_DONE": 1, "PIXI_HALL_DONE": 1,
        "TORWAEHTER_DONE": 1, "VERMISSTE_GIVEN": 1,
        "SIMON_NEK_INFO": 1, "NEK_GIVEN": 1, "JON_NEK_INFO": 0,
}) as s:
    r = Report("3) Simple Jon im Wachhaus: Nek Molerat?")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("SimpleJon liegt im Wachhaus",
            s.wait_from(m, "SimpleJon", 15))
    r.check("das Bett steht im Wachhaus",
            s.wait_from(m, "Bett", 15))
    r.check("der Stuhl steht im Wachhaus",
            s.wait_from(m, "Stuhl", 15))

    m = s.mark()
    s.cmd("touch SimpleJon")
    r.check("Simple Jon stellt sich vor",
            s.wait_from(m, "Ich bin Simple Jon. Stadtwache.", 20))
    r.check("der trockene Standard-Dialog läuft",
            s.wait_from(m, "Der Kaffee ist älter als ich", 20))
    r.check("die Option Nek Molerat erscheint",
            s.wait_from(m, "1) Nek Molerat?", 15))

    s.send("1", 0.8)
    r.check("Jon nennt Nek einen Kollegen",
            s.wait_from(m, "Er ist einer von uns. Stadtwache.", 20))
    r.check("Jon nennt die Freundschaft zu Simon",
            s.wait_from(m, "Simon Guard sind befreundet", 20))
    r.check("Nek hat die Stadt verlassen",
            s.wait_from(m, "aus der Stadt gegangen, um etwas zu erledigen", 20))
    r.check("Nek ist nicht zurückgekommen",
            s.wait_from(m, "nicht wieder aufgetaucht", 20))
    r.check("Jon hat nicht nachgefragt",
            s.wait_from(m, "Ich habe nicht gefragt", 20))
    r.check("der Questlog nimmt Jons Spur auf",
            s.wait_from(m, "Neue Spur: Simple Jon: Nek hat die Stadt verlassen", 20))

    s.send(b"\r", 1.0)
    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    save = open(os.path.join(TMP, "wach_jon_nek", "manual1.save"),
                encoding="utf-8").read()
    r.check("JON_NEK_INFO ist gesichert", "JON_NEK_INFO=1" in save)
    r.check("die Nek-Quest bleibt aktiv", "NEK_GIVEN=1" in save)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §4 Simple Jon: Gating
with start("wach_jon_ohne", {
        "CWD": WACHHAUS, "OLDPWD": BASE, "VIEW_DIR": WACHHAUS,
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "PIXI_GATE_DONE": 1, "PIXI_HALL_DONE": 1,
        "TORWAEHTER_DONE": 1, "VERMISSTE_GIVEN": 0,
        "SIMON_NEK_INFO": 0, "NEK_GIVEN": 0, "JON_NEK_INFO": 0,
}) as s:
    r = Report("4) Simple Jon: keine Option ohne Nek-Quest")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch SimpleJon")
    r.check("Standard-Dialog läuft",
            s.wait_from(m, "Ich bin Simple Jon. Stadtwache.", 20))
    r.check("die trockene Begrüßung bleibt",
            s.wait_from(m, "Der Kaffee ist älter als ich", 20))
    s.drain(2)
    r.check("keine Option Nek Molerat",
            "Nek Molerat?" not in s.since(m))
    s.send(b"\r", 1.0)
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §5 Simple Jon: Fund
with start("wach_jon_fund", {
        "CWD": WACHHAUS, "OLDPWD": BASE, "VIEW_DIR": WACHHAUS,
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "PIXI_GATE_DONE": 1, "PIXI_HALL_DONE": 1,
        "TORWAEHTER_DONE": 1, "VERMISSTE_GIVEN": 1,
        "SIMON_NEK_INFO": 1, "NEK_GIVEN": 1, "JON_NEK_INFO": 1,
        "NEK_FOUND": 1, "JON_NEK_FOUND_INFO": 0,
}) as s:
    r = Report("5) Simple Jon reagiert einmalig auf Neks Fund")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch SimpleJon")
    r.check("Jon spricht den Fund an",
            s.wait_from(m, "Du hast ihn gefunden. Nek.", 20))
    r.check("Jon hat es am Gesicht erkannt",
            s.wait_from(m, "an deinem Gesicht gesehen", 20))
    r.check("Jon bittet um Nachricht an Simon",
            s.wait_from(m, "sag Simon, dass ich es weiß", 20))
    s.send("2", 0.8)                        # Sonst nichts.
    s.send(b"\r", 1.0)

    # Zweites Gespräch: Der Fund-Dialog ist einmalig.
    m = s.mark()
    s.cmd("touch SimpleJon")
    r.check("Standard-Dialog läuft wieder",
            s.wait_from(m, "Ich bin Simple Jon. Stadtwache.", 20))
    r.check("Fund-Dialog erscheint nicht erneut",
            "Du hast ihn gefunden. Nek." not in s.since(m))
    s.send("2", 0.8)
    s.send(b"\r", 1.0)

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    save = open(os.path.join(TMP, "wach_jon_fund", "manual1.save"),
                encoding="utf-8").read()
    r.check("JON_NEK_FOUND_INFO ist gesichert",
            "JON_NEK_FOUND_INFO=1" in save)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

print("\nWACHHAUS-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
