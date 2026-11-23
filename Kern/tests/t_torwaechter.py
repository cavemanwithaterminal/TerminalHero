#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Torwächter: Erstkontakt & Standard-Dialog (PTY)
# ------------------------------------------------------------
#  Der Torwächter am Haupttor hat zwei Zustände:
#
#    1) Erstkontakt (TORWAEHTER_DONE=0): das ausführliche Gespräch
#       (»Ich hoffe, ich bereue es nicht …«).
#    2) Nach dem Tor (TORWAEHTER_DONE=1): der kurze Standard-Dialog
#       (»Bisher kein Ärger …«).
#
#  Geprüft wird beides – und dass das Wortgefecht am Tor
#  (pixi_gate_scene) den Torwächter in den Standard-Zustand setzt,
#  damit sich der Erstkontakt hinter dem Tor nicht wiederholt.
#
#  Aufruf:  python3 Kern/tests/t_torwaechter.py
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


def start(name, scalars):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name),
               rows=40, cols=120)


# ================================================== §1 Standard-Dialog
with start("tw_standard",
           {"CWD": BASE, "PIXI_GATE_DONE": 1, "TORWAEHTER_DONE": 1}) as s:
    r = Report("1) Torwächter: Standard-Dialog nach dem Tor")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("neuer Standard-Dialog", s.wait_from(m, "Bisher kein Ärger", 15))
    r.check("nennt seinen Posten",
            s.wait_from(m, "weißt du, wo ich stehe", 5))
    r.check("kein Erstkontakt mehr",
            not s.wait_from(m, "Ich hoffe, ich bereue es nicht", 2))

    s.send(b"\r"); s.drain(1.0)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §2 Erstkontakt
# Noch kein Tor-Durchgang: der Torwächter spricht den Agenten ausführlich an.
with start("tw_erstkontakt",
           {"CWD": BASE, "PIXI_DESKTOP_DONE": 0, "PIXI_GATE_DONE": 0,
            "TORWAEHTER_DONE": 0}) as s:
    r = Report("2) Torwächter: ausführlicher Erstkontakt")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Erstkontakt beginnt",
            s.wait_from(m, "Ich hoffe, ich bereue es nicht", 15))
    r.check("richtet den Agenten ernsthaft ein",
            s.wait_from(m, "Bevor es jemand merkt", 15))
    r.check("nicht schon der Standard-Dialog",
            not s.wait_from(m, "Bisher kein Ärger", 2))

    s.send(b"\r"); s.drain(1.0)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


# ================================================== §3 Durchs Tor
# Der komplette Tor-Durchgang: Wortgefecht -> danach Standard-Dialog.
with start("tw_gate",
           {"CWD": CITY, "PIXI_DESKTOP_DONE": 1, "PIXI_GATE_DONE": 0,
            "PIXI_HALL_DONE": 1, "TORWAEHTER_DONE": 0}) as s:
    r = Report("3) Durchs Tor: Torwächter danach im Standard-Dialog")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    # Ein Befehl stößt die Torsszene an (pixi_maybe_gate).
    s.cmd("ls")
    r.check("das Wortgefecht am Tor beginnt",
            s.wait("Statt mit mir zu streiten", 25))
    s.wait("1) Pixi hat recht", 10)
    s.send("1")
    s.wait("Abgemacht. Wir halten uns daran", 25)
    s.send("1")
    r.check("das Tor öffnet sich",
            s.wait("Folge Pixi in die Stadt", 25))
    s.send(b"\r")                       # dialog_pause schließt die Szene
    r.check("zurück in der Spiel-GUI", s.wait("◈ TOKENS", 15))

    m = s.mark()
    s.cmd("cd Haupteingang")
    s.cmd("ls")
    r.check("im Haupteingang", s.wait_from(m, "ORDNER: Haupteingang", 10))
    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("danach nur noch der Standard-Dialog",
            s.wait_from(m, "Bisher kein Ärger", 15))
    r.check("der Erstkontakt wiederholt sich nicht",
            not s.wait_from(m, "Ich hoffe, ich bereue es nicht", 2))

    s.send(b"\r"); s.drain(1.0)
    s.cmd("exit"); s.drain(1.0)
    fails += r.done()


print("\nTORWÄCHTER-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
