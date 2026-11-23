#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Tutorial (PTY)
# ------------------------------------------------------------
#  Frischer Start MIT Tutorial: Der Agent erwacht blind.
#  Geprüft wird die ganze Kette
#     pwd -> ls -> cat README -> touch README
#  samt Tutorial-Sperre (nur der erwartete Befehl zählt, und
#  sperrige Eingaben kosten nichts), General-Gespräch, dem
#  Erlernen der vier Menü-Befehle, der Quest-Belohnung und dem
#  späteren Freischalten von »save«.
#
#  Aufruf:  python3 Kern/tests/t_tutorial.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP

reset_tmp()
r = Report("Tutorial")

with Sim(saves=os.path.join(TMP, "tut")) as s:      # ohne TH_TUTORIAL -> Tutorial an
    # --- Erwachen -------------------------------------------------
    r.check("Intro läuft (Agent erwacht blind)", s.wait("Ein System bootet", 15))

    # --- Stufe 1: nur »pwd« ist erlaubt ---------------------------
    m = s.mark()
    s.cmd("ls")
    r.check("Stufe 1 sperrt alles außer pwd",
            s.wait_from(m, "Mein Kopf lässt gerade nur eine Sache zu", 10))
    r.check("gesperrter Befehl kostet keine Tokens",
            "995 / 1000" not in s.since(m))

    s.cmd("pwd")
    r.check("pwd lässt das PFAD-Fenster erwachen",
            s.wait("Der PFAD-Bildschirm erwacht", 10))
    r.check("pwd kostet 5 Tokens (-> 995)", s.wait("995 / 1000"))

    # --- Stufe 2: ls ----------------------------------------------
    m = s.mark()
    s.cmd("cat README")
    r.check("Stufe 2 sperrt cat", s.wait_from(m, "Nur »ls« hilft mir gerade", 10))
    r.check("auch hier kostenlos", "990 / 1000" not in s.since(m))

    s.cmd("ls")
    r.check("ls lässt das ORDNER-Fenster erwachen",
            s.wait("Der ORDNER-Bildschirm füllt sich", 10))

    # --- Stufe 3: cat README --------------------------------------
    s.cmd("cat README")
    r.check("cat README sickert Erinnerung zurück (Anti-Virus-Agent)",
            s.wait("Ich bin also ein Anti-Virus-Agent", 10))

    # --- Stufe 4: touch README -> General-Gespräch -----------------
    s.cmd("touch README")
    r.check("touch README öffnet die Funkverbindung zum General",
            s.wait("FUNKVERBINDUNG GEÖFFNET", 15))

    s.wait("für die man dich gebaut hat", 20)
    s.send("1")                                  # Frage 1
    s.wait("Erste Entscheidung, Soldat", 20)
    s.send("1")                                  # Frage 2
    s.wait("Zweite und letzte Entscheidung", 20)
    s.send("1")                                  # Frage 3
    r.check("General-Gespräch läuft bis zum Ende",
            s.wait("Funkverbindung getrennt", 40))
    r.check("General erklärt den Rückweg mit »cd ..«",
            "»cd ..«" in s.text()
            and "Agenten-Ordner" in s.text()
            and "Downloads-Ordner" in s.text())

    # dialog_pause: erst der Tastendruck schließt das Gespräch ab – DANACH
    # läuft tutorial_after_touch (Quest-Belohnung, Tutorial-Ende).
    s.send(b"\r", 1.0)
    r.check("Hauptquest abgeschlossen",
            s.wait("»Aller Anfang ist schwer«", 10))

    # --- Auswertung -------------------------------------------------
    for c in ("help", "character", "questlog", "inventar"):
        r.check("Befehl erlernt: %s" % c,
                "[ Neuer Befehl erlernt: %s ]" % c in s.text())
    r.check("Questbelohnung 50 EXP", "Questbelohnung: 50 EXP" in s.text())
    r.check("Tutorial-Befehle kosteten 4×5 Tokens (-> 980)",
            s.wait("980 / 1000", 10))

    # --- Die vier Fenster sind jetzt benutzbar ----------------------
    m = s.mark(); s.cmd("help")
    r.check("help-Fenster nach dem Erlernen", s.wait_from(m, "HILFE", 12))
    s.esc(); s.wait_from(m, "◈ TOKENS", 8)

    m = s.mark(); s.cmd("character")
    r.check("character-Fenster nach dem Erlernen", s.wait_from(m, "CHARAKTERBOGEN", 12))
    # 4 Tutorial-Befehle + help + character (je 1 EXP) + 50 aus der Quest
    r.check("Charakterbogen zeigt EXP 56 / 100", "56 / 100" in s.since(m))
    s.esc(); s.wait_from(m, "◈ TOKENS", 8)

    # --- Ausgang nur über »cd ..« -----------------------------------
    # Ein direkter Sprung in einen Downloads-Unterordner würde den ersten
    # Downloads-Besuch (save/achievements/Kompass) umgehen.
    m = s.mark()
    s.cmd("cd ../DetektivConan")
    r.check("Tutorial-Ausgang führt nur über »cd ..«",
            s.wait_from(m, "nur »cd ..« in den Downloads-Ordner", 12))
    r.check("kein direkter Sprung in einen Downloads-Unterordner",
            "Neuer Befehl erlernt: save" not in s.since(m))

    # --- save kehrt im Downloads-Bereich zurück ---------------------
    m = s.mark()
    s.cmd("cd ..")
    r.check("cd .. schaltet »save« frei",
            s.wait_from(m, "Neuer Befehl erlernt: save", 12))

    s.cmd("exit")
    s.drain(2.0)
    r.check("exit beendet das Spiel", s.eof)

fails = r.done()
print("\nTutorial gesamt:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
