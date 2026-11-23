#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Achievements (PTY)
# ------------------------------------------------------------
#    1) Vor dem ersten Besuch der Downloads ist »achievements« gesperrt.
#    2) Beim Wechsel in den Downloads-Ordner wird der Befehl gelernt und
#       »Kompass Geeicht« erscheint samt 50-EXP-Belohnung im Dialog.
#    3) Das Fenster zeigt Titel, Text, ASCII-Kompass und Rahmen.
#    4) Das Achievement wird nur einmal vergeben und gespeichert.
#
#  Aufruf:  python3 Kern/tests/t_achievements.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL,
                     Screen, ESC)

reset_tmp()
fails = 0
H = "/home/benutzer"
AGENT = H + "/Downloads/Neugier"
DOWNLOADS = H + "/Downloads"
LEARNED_NO_ACH = [c for c in LEARNED_ALL if c != "achievements"]


def start(name, scalars, learn=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=learn or LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


with start("achievements",
           {"CWD": AGENT, "OLDPWD": H, "VIEW_DIR": AGENT,
            "SHOW_PATH": 1, "SHOW_LS": 1, "README_DONE": 1,
            "TUT_DONE": 1, "SAVE_LEARNED": 1},
           learn=LEARNED_NO_ACH) as s:
    r = Report("Achievements: Kompass Geeicht")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    # --- Vor dem ersten Downloads-Besuch: Befehl gesperrt --------------
    m = s.mark()
    s.cmd("achievements")
    r.check("achievements ist vor den Downloads gesperrt",
            s.wait_from(m, "Diesen Befehl hat der Virus mir genommen", 15))
    r.check("gesperrter Befehl öffnet kein Fenster",
            "ACHIEVEMENTS" not in s.since(m))
    r.check("keine Skriptfehler im gesperrten Zustand",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))

    # --- Auslöser: Agenten-Ordner -> Downloads -------------------------
    m = s.mark()
    s.cmd("cd ..")
    r.check("achievements wird beim ersten Downloads-Besuch gelernt",
            s.wait_from(m, "Neuer Befehl erlernt: achievements", 15))
    r.check("Achievement-Meldung im Dialog",
            s.wait_from(m, "Achievement erhalten", 15))
    r.check("Titel in der Meldung", s.wait_from(m, "Kompass Geeicht", 15))
    r.check("kurzer Text in der Meldung",
            s.wait_from(m, "Jetzt weiß ich worum es hier geht", 15))
    r.check("Achievement-Belohnung im Dialog",
            s.wait_from(m, "Belohnung: 50 EXP", 15))
    r.check("keine Skriptfehler beim Freischalten",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))

    # --- Fenster mit dem freigeschalteten Eintrag ----------------------
    m = s.mark()
    s.cmd("achievements")
    r.check("Fenster zeigt Titel", s.wait_from(m, "◈ Kompass Geeicht", 15))
    r.check("Fenster zeigt den kurzen Text",
            s.wait_from(m, "Jetzt weiß ich worum es hier geht", 15))
    r.check("Fenster zeigt den ASCII-Kompass", s.wait_from(m, "W + E", 15))
    r.check("Eintrag ist umrahmt",
            s.wait_from(m, "╡ ◈ Kompass Geeicht ╞", 15))
    r.check("Fenster zählt den Eintrag", s.wait_from(m, "1 von 1", 15))
    # --- Layout: Zähler dürfen die Eckzeichen nicht berühren -----------
    sc = Screen(40, 110)
    sc.feed(bytes(s.buf[m:]))
    lines = sc.lines()
    top = next((ln for ln in lines if "ACHIEVEMENTS" in ln), "")
    bot = next((ln for ln in lines if "zurück zur Shell" in ln), "")
    r.check("kein doppelter Zähler oben", "◈ 1" not in top,
            "  [" + top.strip() + "]")
    r.check("Ecke oben rechts ist frei", "◢" in top and "1◢" not in top,
            "  [" + top.strip() + "]")
    r.check("Zähler unten lässt die Ecke frei", "1 von 1 ◣" in bot,
            "  [" + bot.strip() + "]")
    r.check("keine Skriptfehler im Achievement-Fenster",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))
    s.send(ESC, 0.8)

    # --- Nur einmal vergeben ------------------------------------------
    s.cmd("cd Neugier")
    s.cmd("cd ..")
    s.drain(1.2)

    # --- Speichern -----------------------------------------------------
    m = s.mark()
    s.cmd("save")
    r.check("Spielstand gespeichert",
            s.wait_from(m, "Spielstand in Slot", 15))
    save_path = os.path.join(TMP, "achievements", "manual1.save")
    saved = open(save_path, encoding="utf-8").read()
    r.check("Achievement wird nur einmal vergeben",
            saved.count("ACHIEVEMENT") == 1)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

save_text = open(os.path.join(TMP, "achievements", "manual1.save"),
                 encoding="utf-8").read()
print("OK   Save enthält das Achievement"
      if "[kompass_geeicht]=1" in save_text
      else "FAIL Save enthält das Achievement")
if "[kompass_geeicht]=1" not in save_text:
    fails += 1

# Nach dem Laden muss das Achievement weiterhin freigeschaltet sein.
with Sim(env={"TERMINALHERO_LOAD": "manual"},
         saves=os.path.join(TMP, "achievements")) as s:
    r = Report("Achievements: Spielstand laden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("achievements")
    r.check("Achievement bleibt nach dem Laden freigeschaltet",
            s.wait_from(m, "◈ Kompass Geeicht", 15))
    r.check("keine Skriptfehler nach dem Laden",
            "command not found" not in s.since(m)
            and "bad array subscript" not in s.since(m))
    s.send(ESC, 0.8)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print("\nACHIEVEMENT-TESTS: %d Fehler" % fails)
sys.exit(1 if fails else 0)
