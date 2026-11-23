#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Rauchtest (PTY)
# ------------------------------------------------------------
#  A) Start im Agenten-Ordner: Grundbefehle, Tokens, Sperrzonen,
#     unbekannte/gesperrte Befehle und die README-Einsperrung.
#  B) Entsperrt (TH_README_DONE=1): Stadt betreten, Tab-
#     Vervollständigung und die vier Menü-Fenster.
#
#  Aufruf:  python3 Kern/tests/t_smoke.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0

# ============================================================ A) eingesperrt
with Sim(env={"TH_TUTORIAL": "0"}, saves=os.path.join(TMP, "smoke_a")) as s:
    r = Report("A) Start & Sperren")
    r.check("Spiel startet und meldet sich", s.wait("TerminalHero gestartet"))
    r.check("Token-Leiste: voll (1000 / 1000)", s.wait("1000 / 1000"))

    s.cmd("pwd")
    r.check("pwd zeigt den Agenten-Ordner", s.wait("/home/benutzer/Downloads/Neugier"))
    r.check("pwd kostet 5 Tokens (-> 995)", s.wait("995 / 1000"))

    s.cmd("ls")
    r.check("ls zeigt den Ordnerinhalt (README)", s.wait("README"))
    r.check("ls kostet 5 Tokens (-> 990)", s.wait("990 / 1000"))

    s.cmd("cd ~/Schreibtisch")
    r.check("Agenten-Ordner ist gesperrt bis zum README-Gespräch",
            s.wait("Ich kann den Agenten-Ordner noch nicht verlassen"))
    r.check("auch der verweigerte cd kostet (-> 985)", s.wait("985 / 1000"))

    s.cmd("cat /etc/passwd")
    r.check("Sperrzone: Zugriff verweigert", s.wait("Zugriff verweigert"))
    r.check("Sperrzone wird benannt", "SPERRZONE" in s.text())
    r.check("gescheiterter Befehl kostet trotzdem (-> 980)", s.wait("980 / 1000"))

    s.cmd("frozzel")
    r.check("unbekannter Befehl wird abgewiesen", s.wait("kenne ich nicht mehr"))
    r.check("unbekannter Befehl kostet nichts", s.no_wait("975 / 1000", 0.6))

    s.cmd("file README")
    r.check("file ist ohne Erlernen gesperrt",
            s.wait("»file« …? Diesen Befehl kenne ich nicht mehr."))
    r.check("file kostet nichts (weiter 980)", s.no_wait("975 / 1000", 0.6))

    s.cmd("exit")
    s.drain(2.0)
    r.check("exit beendet das Spiel", s.eof)
    fails += r.done()

# ============================================================ B) entsperrt
# Bereits mitten im Spiel: im Downloads-Ordner, Pixi getroffen. So bleiben
# Tab-Vervollständigung und Menü-Fenster unabhängig von der Startsequenz
# testbar; der Tutorial-Ausgang selbst wird in t_tutorial.py geprüft.
H = "/home/benutzer"
DOWNLOADS = H + "/Downloads"
smoke_b = os.path.join(TMP, "smoke_b")
write_save(os.path.join(smoke_b, "manual1.save"),
           scalars={"CWD": DOWNLOADS, "OLDPWD": H, "VIEW_DIR": DOWNLOADS,
                    "SHOW_PATH": 1, "SHOW_LS": 1,
                    "README_DONE": 1, "TUT_DONE": 1, "SAVE_LEARNED": 1},
           learned=LEARNED_ALL)
with Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=smoke_b) as s:
    r = Report("B) Stadt, Tab, Menü-Fenster")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    # Tab-Vervollständigung: erst der Befehl (mit Leerzeichen), dann der
    # eindeutige Ordner (mit /). Ohne das Leerzeichen nach »cd« würde die
    # Pfadergänzung bündig am Befehl kleben und scheitern.
    s.send("cd")
    s.send(b"\t", 0.6)
    s.send("~/Schre")
    s.send(b"\t", 0.6)
    r.check("Tab ergänzt Befehl und danach eindeutigen Ordner (mit /)",
            s.wait("cd ~/Schreibtisch/", 6))
    s.send(b"\r", 0.6)
    s.cmd("pwd")
    r.check("cd nach Vervollständigung betritt ~/Schreibtisch",
            s.wait("/home/benutzer/Schreibtisch", 6))

    # Mehrdeutig: längster gemeinsamer Anfang + Trefferliste
    s.send("cd ~/D")               # nur tippen (kein Enter!)
    s.send(b"\t", 0.8)
    r.check("Tab listet mehrdeutige Treffer (⟂ … Treffer)",
            s.wait("Treffer:", 6))
    s.clear_line()

    for cmd, titel in (("help", "HILFE"), ("character", "CHARAKTERBOGEN"),
                       ("inventar", "INVENTAR"), ("questlog", "QUESTLOG")):
        m = s.mark()
        s.cmd(cmd)
        r.check("%s-Fenster öffnet sich" % cmd, s.wait_from(m, titel, 12))
        m = s.mark()
        s.esc()
        r.check("Esc schließt %s (zurück zur Shell)" % cmd,
                s.wait_from(m, "◈ TOKENS", 10) and titel not in s.since(m))

    # Hilfe: Hinweis auf Tab-Vervollständigung, Gruppierung von »use«
    # und der Inventar-Alias »inventory«.
    m = s.mark()
    s.cmd("help")
    r.check("Hilfe nennt die Tab-Vervollständigung",
            s.wait_from(m, "Tab vervollständigt Befehle und Pfade.", 12))
    r.check("use steht nicht bei den Terminal-Befehlen",
            "use <objekt>" not in s.since(m))
    r.check("exit steht nicht bei den Terminal-Befehlen",
            "Agent herunterfahren" not in s.since(m))
    s.send(b"\t", 0.8)
    r.check("exit steht bei den Spiel-Befehlen",
            s.wait("Agent herunterfahren", 10))
    r.check("Inventar nennt den Alias inventory",
            s.wait("inventar | inventory", 10))
    s.esc(); s.wait_from(m, "◈ TOKENS", 10)

    m = s.mark()
    s.cmd("inventory")
    r.check("inventory-Alias öffnet das Inventar",
            s.wait_from(m, "INVENTAR", 12))
    s.esc(); s.wait_from(m, "◈ TOKENS", 10)

    # cd (995) + pwd (990) und sechs Menü-Befehle (je 5) waren bezahlt:
    # 990 - 4*5 (Schleife) - 5 (help) - 5 (inventory) = 960.
    r.check("Menü-Fenster kosten je 5 Tokens (bleibt bei 960)",
            s.wait_from(m, "960 / 1000", 8))

    s.cmd("exit")
    s.drain(2.0)
    r.check("exit beendet das Spiel", s.eof)
    fails += r.done()

print("\nRauchtest gesamt:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
