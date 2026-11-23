#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Nutzbare Items: Schlafsack & Fackel (PTY)
# ------------------------------------------------------------
#  Prüft die neuen Gegenstände aus shDateien/NutzbareItems/:
#
#    1) Inventar -> Enter/e öffnet das kleine Aktionsfenster
#       (benutzen / ablegen / nichts tun). »nichts tun« schließt
#       nur; »benutzen« legt beim Schlafsack genau ein Exemplar in
#       den aktuellen Ordner, »grep« hebt es wieder auf.
#    2) Die Fackel wird mit »benutzen« angezündet (3 Spielstunden).
#       Solange sie brennt, zeigt das Ordner-Fenster den Inhalt
#       automatisch - ohne »ls«, aber ohne versteckte Dateien.
#
#  Aufruf:  python3 Kern/tests/t_nutzitems.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL, ESC, RIGHT, DOWN

reset_tmp()
fails = 0
H = "/home/benutzer"


def start(name, scalars, inv=None, inv_counts=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=LEARNED_ALL,
               inv=inv, inv_counts=inv_counts)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


def open_plunder(s):
    """Inventar öffnen, auf den Plunder-Reiter und in die Item-Liste."""
    s.cmd("inventar", wait="INVENTAR", timeout=15)
    s.send(RIGHT); s.drain(0.25)
    s.send(RIGHT); s.drain(0.25)
    s.send(DOWN);  s.drain(0.25)


# ================================================== §1 Schlafsack
with start("ni_schlafsack",
           {"CWD": H, "SHOW_LS": 0, "TORCH_UNTIL_MIN": 0},
           inv_counts={"einfacherschlafsack": 2}) as s:
    r = Report("1) Schlafsack: Aktion, Ablegen, grep")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    open_plunder(s)
    m = s.mark()
    s.send("e"); s.drain(0.7)
    r.check("Enter/e öffnet das Item-Fenster",
            s.wait_from(m, 'Item "Einfacher Schlafsack" benutzen?', 8))
    r.check("Option 1: benutzen", s.wait_from(m, "1) benutzen", 3))
    r.check("Option 2: ablegen", s.wait_from(m, "2) ablegen", 3))
    r.check("Option 3: nichts tun", s.wait_from(m, "3) nichts tun", 3))

    # »nichts tun« schließt nur - das Item bleibt im Inventar.
    m = s.mark()
    s.send("3"); s.drain(0.8)
    r.check("»nichts tun« legt nichts ab", "abgelegt" not in s.since(m))
    r.check("Schlafsack ist noch im Inventar", "Einfacher Schlafsack" in s.since(m))

    # Noch einmal öffnen; 1 wählt »benutzen« (Schlafsack = ablegen).
    s.send("e"); s.drain(0.5)
    m = s.mark()
    s.send("1"); s.drain(0.8)
    s.send(ESC); s.drain(1.0)
    r.check("Benutzen meldet das Ablegen",
            s.wait_from(m, "Einfacher Schlafsack abgelegt", 8))
    r.check("danach wieder die Spiel-GUI", s.wait_from(m, "◈ TOKENS", 8))

    # Das abgelegte Item liegt im aktuellen Ordner.
    m = s.mark()
    s.cmd("ls")
    r.check("ls zeigt den abgelegten Schlafsack",
            s.wait_from(m, "EinfacherSchlafsack", 8))
    m = s.mark()
    s.cmd("cat EinfacherSchlafsack")
    r.check("cat erkennt den Fundort",
            s.wait_from(m, "GEGENSTAND", 8))
    r.check("cat nennt den grep-Weg",
            s.wait_from(m, "grep EinfacherSchlafsack", 5))

    # grep hebt ihn wieder auf; von den zwei Exemplaren ist noch eins da.
    m = s.mark()
    s.cmd("grep EinfacherSchlafsack")
    r.check("grep hebt den Schlafsack auf",
            s.wait_from(m, "Einfacher Schlafsack aufgenommen", 10))

    m = s.mark()
    s.cmd("inventar", wait="INVENTAR", timeout=15)
    s.send(RIGHT); s.drain(0.2)
    s.send(RIGHT); s.drain(0.2)
    r.check("Inventar zeigt wieder beide Schlafsäcke",
            s.wait_from(m, "Einfacher Schlafsack ×2", 8))
    s.send(ESC); s.drain(0.6)
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §2 Fackel
with start("ni_fackel",
           {"CWD": H, "SHOW_LS": 0, "TORCH_UNTIL_MIN": 0},
           inv=["fackel"]) as s:
    r = Report("2) Fackel: anzünden und automatische Ordneransicht")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    open_plunder(s)
    m = s.mark()
    s.send("e"); s.drain(0.7)
    r.check("Item-Fenster zeigt die Fackel",
            s.wait_from(m, 'Item "Einfache Fackel" benutzen?', 8))
    m = s.mark()
    s.send(b"\r"); s.drain(0.7)
    s.send(ESC); s.drain(1.0)
    r.check("Benutzen meldet »Fackel angezündet«",
            s.wait_from(m, "Fackel angezündet", 8))
    r.check("Fackel nennt die drei Spielstunden",
            s.wait_from(m, "3 Spielstunden", 5))

    # Ohne »ls«: Der Ordnerinhalt erscheint trotzdem, aber ohne
    # versteckte Einträge wie .bashrc.
    r.check("Ordner-Fenster ist automatisch sichtbar",
            s.wait("ORDNER: ~", 8))
    r.check("kein »ORDNER: ???« mehr", "ORDNER: ???" not in s.since(m))
    r.check("versteckte Dateien bleiben verborgen",
            ".bashrc" not in s.since(m))
    r.check("normale Ordner werden gezeigt", "Dokumente" in s.since(m))

    # Auch ein Ordnerwechsel zeigt den neuen Inhalt ohne »ls«.
    m = s.mark()
    s.cmd("cd Dokumente")
    r.check("cd zeigt den neuen Ordner automatisch",
            s.wait_from(m, "ORDNER: Dokumente", 8))
    r.check("der neue Ordnerinhalt ist da",
            s.wait_from(m, "Steuer", 5))
    r.check("kein »ORDNER: ???« nach cd", "ORDNER: ???" not in s.since(m))

    # Die benutzte Fackel ist verbraucht: Im Inventar ist sie weg.
    s.send(ESC); s.drain(0.5)
    m = s.mark()
    s.cmd("inventar", wait="INVENTAR", timeout=15)
    s.send(RIGHT); s.drain(0.25)
    s.send(RIGHT); s.drain(0.25)
    r.check("benutzte Fackel ist aus dem Inventar verschwunden",
            not s.wait_from(m, "Einfache Fackel", 1.5))
    s.send(ESC); s.drain(0.5)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

# ================================================== §2b Fackel (groß)
with start("ni_fackel2",
           {"CWD": H, "SHOW_LS": 0, "TORCH_UNTIL_MIN": 0},
           inv=["fackel2"]) as s:
    r = Report("2b) Fackel: acht Spielstunden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    open_plunder(s)
    m = s.mark()
    s.send("e"); s.drain(0.7)
    r.check("Item-Fenster zeigt die Fackel",
            s.wait_from(m, 'Item "Fackel" benutzen?', 8))
    m = s.mark()
    s.send(b"\r"); s.drain(0.7)
    s.send(ESC); s.drain(1.0)
    r.check("Benutzen meldet »Fackel angezündet«",
            s.wait_from(m, "Fackel angezündet", 8))
    r.check("Fackel nennt die acht Spielstunden",
            s.wait_from(m, "8 Spielstunden", 5))
    r.check("Ordner-Fenster ist automatisch sichtbar",
            s.wait("ORDNER: ~", 8))
    r.check("kein »ORDNER: ???« mehr", "ORDNER: ???" not in s.since(m))

    s.send(ESC); s.drain(0.5)
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

# ================================================== §4 MoleratCode essen
with start("ni_moleratcode",
           {"CWD": H, "SHOW_LS": 0, "TOKENS_CUR": 900, "TOKENS_MAX": 1000},
           inv_counts={"moleratcode": 2}) as s:
    r = Report("4) MoleratCode: essen regeneriert 25 Tokens")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    open_plunder(s)
    m = s.mark()
    s.send("e"); s.drain(0.7)
    r.check("Item-Fenster zeigt MoleratCode",
            s.wait_from(m, 'Item "MoleratCode" benutzen?', 8))
    m = s.mark()
    s.send(b"\r"); s.drain(0.8)
    r.check("ein Stück wurde verbraucht",
            s.wait_from(m, "Stückzahl: 1", 5))
    s.send(ESC); s.drain(0.8)
    r.check("Essen regeneriert 25 Tokens",
            s.wait_from(m, "+25 Tokens", 8))
    r.check("Tokenstand ist 920/1000",
            s.wait_from(m, "920 / 1000", 5))
    s.send(ESC); s.drain(0.5)
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

# ================================================== §3 Speichern/Laden
# Abgelegte Items und die brennende Fackel müssen im Spielstand bleiben.
SAVE_DIR = os.path.join(TMP, "ni_persist")
sv = os.path.join(SAVE_DIR, "manual1.save")
write_save(sv, scalars={"CWD": H, "SHOW_LS": 0, "TORCH_UNTIL_MIN": 0},
           learned=LEARNED_ALL, inv=["fackel", "einfacherschlafsack"])
with Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.dirname(sv)) as s:
    r = Report("3) Spielstand: abgelegtes Item & brennende Fackel bleiben")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    open_plunder(s)
    # Die Fackel steht alphabetisch vor dem Schlafsack: ↓ wählt den
    # Schlafsack, Enter legt ihn ab.
    s.send(DOWN); s.drain(0.2)
    s.send("e"); s.drain(0.6)
    s.send(b"\r"); s.drain(0.8)
    # Jetzt ist die Fackel das einzige Plunder-Item; wieder öffnen.
    s.send("e"); s.drain(0.6)
    s.send(b"\r"); s.drain(0.8)
    s.send(ESC); s.drain(1.0)
    r.check("Fackel brennt vor dem Speichern",
            s.wait("Fackel angezündet", 8))
    m = s.mark()
    s.cmd("save")
    r.check("Spielstand gespeichert",
            s.wait_from(m, "Spielstand in Slot", 12))
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

with Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=SAVE_DIR) as s:
    r = Report("3b) Reload: Welt-Gegenstand & Fackellicht sind zurück")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("cat EinfacherSchlafsack")
    r.check("abgelegter Schlafsack liegt nach dem Laden wieder da",
            s.wait_from(m, "GEGENSTAND", 8))
    r.check("Fundort nennt weiterhin grep",
            s.wait_from(m, "grep EinfacherSchlafsack", 5))
    r.check("Fackel leuchtet nach dem Laden weiter",
            s.wait("ORDNER: ~", 8))
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

print("\nNUTZBARE-ITEMS-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
