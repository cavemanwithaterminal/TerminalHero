#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Archiv & Save-Slots (PTY)
# ------------------------------------------------------------
#  Prüft die neuen Archiv-/Speicherfunktionen:
#    1) »archive« öffnet das Archivfenster (Kapitel/Orte/Zurück)
#    2) »save« öffnet die Slot-Auswahl (Slot 1-3) und speichert
#       in den gewählten Slot (ohne Autosave-Auswahl)
#
#  Aufruf:  python3 Kern/tests/t_archive.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL, DOWN, ESC

reset_tmp()
fails = 0
H = "/home/benutzer"

# ================================================== 1) Archiv-Fenster
sv = os.path.join(TMP, "archive_ui", "manual1.save")
write_save(sv,
           scalars={"CWD": H, "VIEW_DIR": H, "OLDPWD": H,
                    "ARCHIVE_KAP1": 1, "ARCHIVE_ORT_DESKTOPCITY": 1},
           learned=LEARNED_ALL + ["archive"])
with Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, "archive_ui")) as s:
    r = Report("1) Archiv: Fenster & Navigation")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("archive")
    r.check("Archiv öffnet sich", s.wait_from(m, "A R C H I V", 12))
    txt = s.since(m)
    r.check("Menü zeigt Kapitel", "Kapitel" in txt)
    r.check("Menü zeigt Orte", "Orte" in txt)
    r.check("Menü zeigt Zurück", "Zurück" in txt)

    # Kapitel öffnen -> interaktive Bildansicht (mit Schließen-Hinweis), schließen
    s.send(b"\r", 0.6)
    r.check("Kapitelansicht öffnet sich (Schließen-Hinweis)",
            s.wait("ESC / Q", 12) or s.wait("Schließen", 12))
    s.send(b"q", 0.6)
    r.check("zurück in Kapitelübersicht", s.wait("ARCHIV · KAPITEL", 12) or s.wait("Kapitel", 12))
    s.esc(pause=0.6)
    r.check("zurück ins Archiv-Hauptmenü", s.wait("A R C H I V", 10))

    s.esc(pause=0.6)
    r.check("Esc schließt Archiv", s.wait("◈ TOKENS", 10))
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ================================================== 2) Save-Slot-Auswahl
saves_dir = os.path.join(TMP, "save_slots")
sv = os.path.join(saves_dir, "manual1.save")
write_save(sv,
           scalars={"CWD": H, "VIEW_DIR": H, "OLDPWD": H},
           learned=LEARNED_ALL)
with Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=saves_dir) as s:
    r = Report("2) Save: Slot-Auswahl & Speichern")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    # Quicksave-Datei darf NICHT als wählbare Option erscheinen
    open(os.path.join(saves_dir, "quicksave.save"), "w").close()
    m = s.mark()
    s.cmd("save")
    r.check("Save-Fenster öffnet sich", s.wait_from(m, "SPIELSTAND SPEICHERN", 12))
    txt = s.since(m)
    r.check("Slot 1 sichtbar", "Slot 1" in txt)
    r.check("Slot 2 sichtbar", "Slot 2" in txt)
    r.check("Slot 3 sichtbar", "Slot 3" in txt)
    r.check("Autosave/Quicksave nicht wählbar",
            "Autosave nicht wählbar" in txt and "Autosave" not in txt.replace("Autosave nicht wählbar", ""))

    # Slot 2 wählen (↓) und speichern
    s.send(DOWN, 0.4)
    s.send(b"\r", 0.8)
    r.check("Bestätigung für Slot 2", s.wait("Slot 2 gesichert", 12) or s.wait("Spielstand in Slot 2", 12))
    s.drain(0.6)
    r.check("Datei manual2.save wurde erstellt",
            os.path.exists(os.path.join(saves_dir, "manual2.save")))

    # Nochmals öffnen, Slot 3 speichern
    m = s.mark()
    s.cmd("save")
    r.check("Save-Fenster erneut offen", s.wait_from(m, "SPIELSTAND SPEICHERN", 12))
    s.send(DOWN, 0.3); s.send(DOWN, 0.3)
    s.send(b"\r", 0.8)
    r.check("Bestätigung für Slot 3", s.wait("Slot 3 gesichert", 12) or s.wait("Spielstand in Slot 3", 12))
    s.drain(0.6)
    r.check("Datei manual3.save wurde erstellt",
            os.path.exists(os.path.join(saves_dir, "manual3.save")))

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print("\nARCHIV/SAVE-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
