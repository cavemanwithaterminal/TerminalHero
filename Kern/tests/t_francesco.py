#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Francesco Dellamorte (PTY)
# ------------------------------------------------------------
#  Prüft den Totengräber im Brachland-Friedhof:
#    1) Die beseelte Datei liegt im Friedhof und lässt sich lesen.
#    2) Das erste Treffen ist lang, mysteriös und hat schwarzen
#       Humor; es setzt FRANCESCO_MET.
#    3) Danach kommt nur noch der kurze Standard-Dialog.
#    4) Das Geheimnis (die Rückkehr der Toten) wird im Spiel
#       nirgends ausgesprochen.
#
#  Aufruf:  python3 Kern/tests/t_francesco.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
DESK = H + "/Schreibtisch"
CEMETERY = DESK + "/Brachland/Friedhof"

SECRET_WORDS = ("zombie", "untot", "wieder auf", "aufersteh")


def no_secret(text):
    low = text.lower()
    return not any(w in low for w in SECRET_WORDS)


def start(name, scalars=None):
    d = os.path.join(TMP, name)
    sv = {"CWD": CEMETERY, "OLDPWD": DESK, "VIEW_DIR": CEMETERY,
          "SHOW_PATH": 1, "SHOW_LS": 1, "HOME_FIRST_VISIT": 1,
          "TUT_DONE": 1, "TORWAEHTER_DONE": 1,
          "PIXI_DESKTOP_DONE": 1, "PIXI_GATE_DONE": 1,
          "PIXI_HALL_DONE": 1,
          # Nek/Gegner sind eigene Tests und sollen hier nicht stören.
          "NEK_FUNERAL_GIVEN": 0, "MOLERATS_DEAD": 7,
          "GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
          "GUY_SUS_CAVE_DONE": 1, "FRANCESCO_MET": 0}
    sv.update(scalars or {})
    write_save(os.path.join(d, "manual1.save"), scalars=sv, learned=LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=d, rows=40, cols=120)


# ================================================== §1 Erstes Treffen
with start("francesco_intro") as s:
    r = Report("1) Friedhof: erster Besuch bei Francesco Dellamorte")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("FrancescoDellamorte liegt im Friedhof",
            s.wait_from(m, "FrancescoDellamorte", 12))

    m = s.mark()
    s.cmd("cat FrancescoDellamorte")
    r.check("cat nennt seinen Namen",
            s.wait_from(m, "Francesco Dellamorte", 12))
    r.check("cat nennt seine Herkunft",
            s.wait_from(m, "Italien", 8))
    r.check("cat nennt seinen Beruf",
            s.wait_from(m, "Totengräber", 8))
    r.check("cat verrät das Geheimnis nicht", no_secret(s.since(m)))

    m = s.mark()
    s.cmd("touch FrancescoDellamorte")
    r.check("Francesco stellt sich vor",
            s.wait_from(m, "Francesco Dellamorte. Totengräber.", 25))
    r.check("das Gespräch bietet die erste Frage",
            s.wait_from(m, "1) Du sprichst mit den Gräbern?", 15))
    r.check("das erste Treffen ist länger",
            s.wait_from(m, "Meine Kunden beschweren sich nie", 15))
    r.check("das erste Treffen hat schwarzen Humor",
            s.wait_from(m, "Der andere ist die frische Luft", 15))

    s.send("2", 0.8)
    r.check("die Antwort ist unheimlich-gelassen",
            s.wait_from(m, "Die hier sind ruhig. Höflich.", 20))
    r.check("die Ordnungs-Pointe kommt",
            s.wait_from(m, "Ordnung ist eine Form von Respekt", 20))
    r.check("der Kaffee wird angeboten",
            s.wait_from(m, "1) Ja, danke.", 15))

    s.send("1", 0.8)
    r.check("der Kaffee ist stark",
            s.wait_from(m, "Nicht gut. Aber stark.", 20))
    r.check("der Abschied ist typisch Francesco",
            s.wait_from(m, "Grüß die Steine", 20))
    r.check("das Gespräch verrät das Geheimnis nicht",
            no_secret(s.since(m)))

    s.send(b"\r", 1.0)
    r.check("zurück in der Spiel-GUI", s.wait("◈ TOKENS", 15))

    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    save = open(os.path.join(TMP, "francesco_intro", "manual1.save"),
                encoding="utf-8").read()
    r.check("FRANCESCO_MET ist gesichert", "FRANCESCO_MET=1" in save)

    # ============================================== §2 Standard-Dialog
    m = s.mark()
    s.cmd("touch FrancescoDellamorte")
    r.check("danach kommt der Standard-Dialog",
            s.wait_from(m, "Zu ruhig, sagen die Leute", 20))
    r.check("das erste Treffen wiederholt sich nicht",
            not s.wait_from(m, "Francesco Dellamorte. Totengräber.", 2))
    r.check("der Standard-Dialog bleibt kurz",
            s.wait_from(m, "Der Kaffee ist noch warm", 15))
    r.check("auch der Standard-Dialog schweigt über das Geheimnis",
            no_secret(s.since(m)))

    s.send(b"\r", 1.0)
    s.cmd("exit")
    s.drain(1.2)
    fails += r.done()

print("\nFRANCESCO-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
