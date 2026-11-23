#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Neks Amulett, Schmuck & Simon-Abschluss (PTY)
# ------------------------------------------------------------
#  Prüft die Erweiterung rund um Neks Leiche:
#    1) In der Molerathöhle liegt ein Bits-Haufen (11 Bits, »grep Bits«).
#    2) Neks Amulett landet im Schmuck-Reiter, lässt sich ausrüsten
#       (+50 Max-Tokens), wird mit ♦ markiert und wieder abgelegt.
#       Die Beschreibung nennt die Werte und zeigt kein literales \n.
#    3) Ausrüstung überlebt Speichern/Laden.
#    4) Simon: kein Loot -> zurück zum Durchsuchen.
#    5) Simon: Amulett verkaufen (150 Bits) / behalten (500 EXP).
#    6) Simon: Leiche bringen -> er durchsucht sie (150 Bits/750 EXP).
#       Danach ist die Leiche aus dem Dateisystem und dem Save verschwunden.
#    7) Simon: Leiche + Amulett -> Verkaufsgespräch.
#    8) Varianten: »da war nichts«, Bestätigung »doch verkaufen«.
#    9) Handel: Schmuck-Reiter, Verkauf für 150 Bits.
#
#  Aufruf:  python3 Kern/tests/t_nekschmuck.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL, RIGHT, DOWN

reset_tmp()
fails = 0
H = "/home/benutzer"
DESK = H + "/Schreibtisch"
HOEHLE = DESK + "/Höhleneingang/Molerathöhle"
BASE = H + "/Schreibtisch/DesktopCity/Haupteingang"
CORPSE = BASE + "/NeksLeiche"


def start(name, cwd, scalars=None, inv=None, equip=None, dyn_type=None,
          saves=None, rows=40, cols=120, learn=None):
    d = saves or os.path.join(TMP, name)
    sv = {"CWD": cwd, "OLDPWD": DESK, "VIEW_DIR": cwd,
          "SHOW_PATH": 1, "SHOW_LS": 1, "HOME_FIRST_VISIT": 1,
          "TUT_DONE": 1, "TORWAEHTER_DONE": 1,
          # Nek-Test: Molerats/Guy sind eigene Tests und sollen hier
          # weder Tokens abziehen noch eine Szene starten.
          "MOLERATS_DEAD": 7, "GUY_SUS_MET": 1,
          "GUY_SUS_GONE": 1, "GUY_SUS_CAVE_DONE": 1}
    sv.update(scalars or {})
    write_save(os.path.join(d, "manual1.save"), scalars=sv,
               learned=learn or LEARNED_ALL, inv=inv, equip=equip,
               dyn_type=dyn_type)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=d,
               rows=rows, cols=cols)


def save_text(name, saves=None):
    d = saves or os.path.join(TMP, name)
    return open(os.path.join(d, "manual1.save"), encoding="utf-8").read()


def dismiss_family_question(s, timeout=10):
    """Nach dem Nek-Abschluss fragt Simon optional nach dem Nachnamen."""
    s.wait("Warum heißt Nek", timeout)
    s.send("2"); s.drain(0.7)
    s.send(b"\r"); s.drain(0.8)


# ================================================== §1 Höhlen-Bits
with start("nek_bits", HOEHLE) as s:
    r = Report("1) Molerathöhle: Bits-Haufen mit 11 Bits")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("ls zeigt den Bits-Haufen", s.wait_from(m, "Bits", 12))
    r.check("ls zeigt weiterhin NeksLeiche", s.wait_from(m, "NeksLeiche", 12))

    m = s.mark()
    s.cmd("grep Bits")
    r.check("grep sammelt 11 Bits ein",
            s.wait_from(m, "11 Bits aufgesammelt", 12))
    s.cmd("save")
    r.check("Spielstand in Slot",
            s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_bits")
    r.check("Save enthält 11 Bits", "BITS=11" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §2 Inventar/Schmuck
with start("nek_schmuck", BASE, inv=["neksamulett"],
           scalars={"NEK_GIVEN": 1}) as s:
    r = Report("2) Schmuck-Reiter: ausrüsten, tragen, abrüsten")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("inventar")
    r.check("Inventar öffnet", s.wait("INVENTAR", 15))
    for _ in range(3):
        s.send(RIGHT); s.drain(0.35)
    r.check("Schmuck-Reiter ist ausgewählt", s.wait("Schmuck", 8))
    txt = s.since(m)
    r.check("Beschreibung nennt die Werte", "Werte:" in txt)
    r.check("Beschreibung nennt +50 Max-Tokens",
            "+50 maximale Tokens" in txt)
    r.check("kein literales \\n in der Beschreibung", "\\n" not in txt)
    s.send(DOWN); s.drain(0.35)
    s.send(b"\r"); s.drain(0.5)
    r.check("Aktionsfenster öffnet", s.wait('Item "Neks Amulett" benutzen?', 8))
    r.check("Option 2 heißt ausrüsten", s.wait("2) ausrüsten", 5))
    r.check("vierte Option ist nichts tun", s.wait("4) nichts tun", 5))
    s.send("2"); s.drain(0.8)
    r.check("Inventar markiert getragenes Amulett",
            s.wait("Wird getragen", 8))
    r.check("getragenes Amulett trägt das ♦-Symbol", s.wait("♦", 8))

    s.send(b"\x1b"); s.drain(0.6)
    s.cmd("character")
    r.check("Charakterbogen öffnet", s.wait("CHARAKTERBOGEN", 15))
    r.check("Amulett-Slot ist gefüllt", s.wait("Neks Amulett", 8))
    r.check("Max-Tokens steigen auf 1050", s.wait("1050", 8))
    s.send(b"\x1b"); s.drain(0.6)

    s.cmd("inventar")
    r.check("Inventar erneut offen", s.wait("INVENTAR", 15))
    for _ in range(3):
        s.send(RIGHT); s.drain(0.35)
    s.send(DOWN); s.drain(0.35)
    s.send(b"\r"); s.drain(0.5)
    r.check("zweite Option ist jetzt abrüsten",
            s.wait("2) abrüsten", 8))
    s.send("2"); s.drain(0.8)
    s.send(b"\x1b"); s.drain(0.6)

    s.cmd("character")
    r.check("Charakterbogen nach Ablegen offen", s.wait("CHARAKTERBOGEN", 15))
    r.check("Max-Tokens wieder 1000", s.wait("1000", 8))
    r.check("Amulett-Slot ist wieder leer",
            s.wait("— leer —", 8))
    s.send(b"\x1b"); s.drain(0.6)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §3 Speichern/Laden
with start("nek_equip_save", BASE, inv=["neksamulett"],
           scalars={"NEK_GIVEN": 1}) as s:
    r = Report("3) Ausrüstung überlebt Speichern/Laden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    s.cmd("inventar")
    s.wait("INVENTAR", 15)
    for _ in range(3):
        s.send(RIGHT); s.drain(0.35)
    s.send(DOWN); s.drain(0.35)
    s.send(b"\r"); s.drain(0.5)
    s.wait("2) ausrüsten", 8)
    s.send("2"); s.drain(0.8)
    s.send(b"\x1b"); s.drain(0.6)
    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_equip_save")
    r.check("Save enthält den Amulett-Slot", "[amulett]=neksamulett" in sv)
    r.check("Save enthält 1050 Max-Tokens", "TOKENS_MAX=1050" in sv)
    s.cmd("exit"); s.drain(1.2)

with Sim(env={"TERMINALHERO_LOAD": "manual"},
         saves=os.path.join(TMP, "nek_equip_save"), rows=40, cols=120) as s:
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    s.cmd("character")
    r.check("Amulett nach dem Laden getragen", s.wait("Neks Amulett", 15))
    r.check("Max-Tokens nach dem Laden 1050", s.wait("1050", 8))
    s.send(b"\x1b"); s.drain(0.6)
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §4 Simon: kein Loot
with start("nek_simon_leer", BASE,
           scalars={"NEK_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                    "SIMON_NEK_INFO": 1, "NEK_FOUND": 1,
                    "NEK_REPORTED": 0}) as s:
    r = Report("4) Simon: ohne Leiche/Amulett zurück zum Suchen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon fragt nach dem Fund",
            s.wait_from(m, "Du hast Nek gefunden? Wo?", 20))
    r.check("Simon fragt nach Beute",
            s.wait_from(m, "Hast du etwas bei ihm gefunden?", 20))
    r.check("Option: Leiche nicht angefasst",
            s.wait_from(m, "Nein hab seine Leiche nicht angefasst.", 8))
    s.send("1"); s.drain(0.8)
    r.check("Simon schickt zurück",
            s.wait_from(m, "Geh zurück und durchsuch ihn. Komm dann wieder.", 20))
    s.send(b"\r"); s.drain(0.8)

    s.cmd("questlog")
    r.check("Questlog öffnet", s.wait("QUESTLOG", 15))
    s.send(RIGHT); s.drain(0.35)   # Nebenquest
    s.send(DOWN); s.drain(0.35)    # Status
    s.send(DOWN); s.drain(0.35)    # Liste
    r.check("Questlog nennt den Fund",
            s.wait("Hab Nek gefunden. Lag tot in einer Höhle", 8))
    r.check("Questziel führt zurück zur Leiche",
            s.wait("durchsuche Neks Leiche", 8))
    s.send(b"\x1b"); s.drain(0.6)
    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_simon_leer")
    r.check("Save merkt die Suchauflage", "NEK_MUST_SEARCH=1" in sv)
    r.check("Quest ist noch nicht abgeschlossen", "NEK_DONE=0" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §5 Simon: Amulett
with start("nek_simon_amulett", BASE, inv=["neksamulett"],
           scalars={"NEK_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                    "SIMON_NEK_INFO": 1, "NEK_FOUND": 1,
                    "NEK_REPORTED": 0}) as s:
    r = Report("5) Simon: Amulett verkaufen (150 Bits + 500 EXP)")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon fragt nach dem Fund",
            s.wait_from(m, "Hast du etwas bei ihm gefunden?", 20))
    r.check("Option: Amulett zeigen",
            s.wait_from(m, "Ja. Dieses Amulett", 8))
    s.send("1"); s.drain(0.8)
    r.check("Simon bietet 150 Bits",
            s.wait_from(m, "Ich gebe dir 150 Bits dafür.", 20))
    r.check("Option: verkaufen", s.wait_from(m, "Verkaufen (150 Bits).", 8))
    s.send("1"); s.drain(0.8)
    r.check("Simon bedankt sich",
            s.wait_from(m, "Danke. Wirklich.", 20))
    r.check("Quest abgeschlossen",
            s.wait_from(m, "QUEST ABGESCHLOSSEN", 20))
    r.check("500 EXP Belohnung",
            s.wait_from(m, "Questbelohnung: 500 EXP", 8))
    r.check("Beerdigung wird angesetzt",
            s.wait_from(m, "Neks Beerdigung", 8))
    r.check("Beerdigungsdatum steht im Log",
            s.wait_from(m, "30.01.240", 8))
    r.check("Simon schickt jemanden zur Leiche",
            s.wait_from(m, "Ich schicke jemanden in die Molerathöhle", 8))
    r.check("Simon bietet die Nachnamensfrage an",
            s.wait_from(m, "Warum heißt Nek", 8))
    s.send("1"); s.drain(0.8)
    r.check("Simon erklärt den Nachnamen",
            s.wait_from(m, "Ist halt sein Nachname", 8))
    r.check("Simon verweist auf die Familie",
            s.wait_from(m, "such die Familie auf", 8))
    r.check("Folgequest Neks Familie",
            s.wait_from(m, "Neks Familie", 8))
    s.send(b"\r"); s.drain(0.8)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_simon_amulett")
    r.check("166 Bits gutgeschrieben (150 + 16 aus Aufstiegen)",
            "BITS=166" in sv)
    r.check("500 EXP als Aufstiege verbucht", "LEVEL=2" in sv)
    r.check("Nek-Quest abgeschlossen", "NEK_DONE=1" in sv)
    r.check("Amulett verkauft", "NEK_AMULET_SOLD=1" in sv)
    r.check("Amulett ist aus dem Inventar", "[neksamulett]" not in sv)
    r.check("Beerdigung ist angesetzt", "NEK_FUNERAL_GIVEN=1" in sv)
    r.check("Leiche lag in der Höhle",
            "NEK_FUNERAL_DISPOSITION=cave" in sv)
    r.check("Beerdigung an Spieltag 5", "NEK_FUNERAL_DAY=5" in sv)
    r.check("Familienquest ist vergeben", "NEK_FAMILY_GIVEN=1" in sv)

    s.cmd("questlog")
    r.check("Questlog öffnet", s.wait("QUESTLOG", 15))
    s.send(RIGHT); s.drain(0.35)   # Nebenquest
    s.send(DOWN); s.drain(0.35)    # Status
    s.send(RIGHT); s.drain(0.35)   # Abgeschlossen
    s.send(DOWN); s.drain(0.35)    # Liste
    r.check("Nek-Quest ist abgeschlossen",
            s.wait("Status: abgeschlossen", 8))
    r.check("abgeschlossene Nek-Quest ist ausgewählt",
            s.wait("Wo ist Nek Molerat?", 8))
    s.send(b"\x1b"); s.drain(0.6)
    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §6 Simon: behalten
with start("nek_simon_behalten", BASE, inv=["neksamulett"],
           scalars={"NEK_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                    "SIMON_NEK_INFO": 1, "NEK_FOUND": 1,
                    "NEK_REPORTED": 0}) as s:
    r = Report("6) Simon: Amulett behalten (500 EXP, Bestätigung)")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon fragt nach dem Fund",
            s.wait_from(m, "Hast du etwas bei ihm gefunden?", 20))
    s.send("1"); s.drain(0.8)
    r.check("Simon bietet 150 Bits",
            s.wait_from(m, "Ich gebe dir 150 Bits dafür.", 20))
    s.send("2"); s.drain(0.8)
    r.check("Simon fragt nach Bestätigung",
            s.wait_from(m, "Verdammt. Bist du dir sicher?", 20))
    r.check("Option: behalten",
            s.wait_from(m, "Ja, ich behalte es.", 8))
    s.send("1"); s.drain(0.8)
    r.check("Simon akzeptiert",
            s.wait_from(m, "Ich akzeptiere es.", 20))
    r.check("500 EXP Belohnung",
            s.wait_from(m, "Questbelohnung: 500 EXP", 8))
    dismiss_family_question(s)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_simon_behalten")
    r.check("16 Bits aus zwei Aufstiegen", "BITS=16" in sv)
    r.check("500 EXP als Aufstiege verbucht", "LEVEL=2" in sv)
    r.check("Amulett behalten", "NEK_AMULET_KEPT=1" in sv)
    r.check("Amulett bleibt im Inventar", "[neksamulett]=1" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §6b Simon: "da war nichts"
with start("nek_simon_nichts", BASE, inv=["neksamulett"],
           scalars={"NEK_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                    "SIMON_NEK_INFO": 1, "NEK_FOUND": 1,
                    "NEK_REPORTED": 0}) as s:
    r = Report("6b) Simon: »Nein, da war nichts« (500 EXP, Amulett bleibt)")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon fragt nach dem Fund",
            s.wait_from(m, "Hast du etwas bei ihm gefunden?", 20))
    r.check("Option: nichts gefunden",
            s.wait_from(m, "Nein, da war nichts", 8))
    s.send("2"); s.drain(0.8)
    r.check("Simon akzeptiert die Antwort",
            s.wait_from(m, "Dann weiß ich jetzt wenigstens", 20))
    r.check("500 EXP Belohnung",
            s.wait_from(m, "Questbelohnung: 500 EXP", 8))
    dismiss_family_question(s)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_simon_nichts")
    r.check("16 Bits aus zwei Aufstiegen", "BITS=16" in sv)
    r.check("Amulett behalten", "NEK_AMULET_KEPT=1" in sv)
    r.check("Amulett bleibt im Inventar", "[neksamulett]=1" in sv)
    r.check("Quest abgeschlossen", "NEK_DONE=1" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §6c Simon: doch verkaufen
with start("nek_simon_doch", BASE, inv=["neksamulett"],
           scalars={"NEK_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                    "SIMON_NEK_INFO": 1, "NEK_FOUND": 1,
                    "NEK_REPORTED": 0}) as s:
    r = Report("6c) Simon: Bestätigung »doch verkaufen« (150 Bits)")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon fragt nach dem Fund",
            s.wait_from(m, "Hast du etwas bei ihm gefunden?", 20))
    s.send("1"); s.drain(0.8)
    r.check("Simon bietet 150 Bits",
            s.wait_from(m, "Ich gebe dir 150 Bits dafür.", 20))
    s.send("2"); s.drain(0.8)
    r.check("Simon fragt nach Bestätigung",
            s.wait_from(m, "Verdammt. Bist du dir sicher?", 20))
    r.check("Option: doch verkaufen",
            s.wait_from(m, "Nein, ich verkaufe es doch.", 8))
    s.send("2"); s.drain(0.8)
    r.check("Simon freut sich",
            s.wait_from(m, "Gut. Ich wusste doch", 20))
    dismiss_family_question(s)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_simon_doch")
    r.check("166 Bits gutgeschrieben (150 + 16 aus Aufstiegen)",
            "BITS=166" in sv)
    r.check("Amulett verkauft", "NEK_AMULET_SOLD=1" in sv)
    r.check("Amulett ist aus dem Inventar", "[neksamulett]" not in sv)
    r.check("Quest abgeschlossen", "NEK_DONE=1" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §7 Simon: Leiche
with start("nek_simon_leiche", BASE,
           scalars={"NEK_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                    "SIMON_NEK_INFO": 1, "NEK_FOUND": 1,
                    "NEK_REPORTED": 0,
                    "NEKS_LEICHE_PATH": CORPSE},
           dyn_type={CORPSE: "f"}) as s:
    r = Report("7) Simon: Leiche bringen, er durchsucht sie")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon ist schockiert",
            s.wait_from(m, "Heilige Scheiße! Was stimmt nicht mit dir!", 20))
    r.check("Simon fragt nach dem Durchsuchen",
            s.wait_from(m, "Hast du ihn durchsucht?", 20))
    r.check("Option: nicht angefasst",
            s.wait_from(m, "Nein, ich habe ihn nicht angefasst.", 8))
    s.send("1"); s.drain(0.8)
    r.check("Simon durchsucht die Leiche",
            s.wait_from(m, "Simon kniet neben seinem Freund", 20))
    r.check("Simon findet das Amulett",
            s.wait_from(m, "Da ist es. Sein Amulett.", 20))
    r.check("150 Bits Belohnung",
            s.wait_from(m, "150 Bits", 20))
    r.check("750 EXP Belohnung",
            s.wait_from(m, "Questbelohnung: 750 EXP", 8))
    dismiss_family_question(s)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_simon_leiche")
    r.check("174 Bits gutgeschrieben (150 + 24 aus Aufstiegen)",
            "BITS=174" in sv)
    r.check("750 EXP als Aufstiege verbucht", "LEVEL=3" in sv)
    r.check("Leiche wurde zu Simon gebracht", "NEK_CORPSE_BROUGHT=1" in sv)
    r.check("Simon hat sie durchsucht", "NEK_SIMON_SEARCHED=1" in sv)
    r.check("Suche ist vermerkt", "NEKS_LEICHE_SEARCHED=1" in sv)
    r.check("Quest abgeschlossen", "NEK_DONE=1" in sv)
    r.check("Leichenpfad ist geleert",
            "\nNEKS_LEICHE_PATH=''\n" in sv or "\nNEKS_LEICHE_PATH=\n" in sv)
    r.check("Ziehen ist beendet",
            "\nDRAGGED_CORPSE=''\n" in sv or "\nDRAGGED_CORPSE=\n" in sv)
    r.check("keine Leiche mehr im Save", "/NeksLeiche" not in sv)

    # Nach der Übergabe darf die Leiche weder im Ordner liegen noch
    # wieder hinter dem Agenten hergezogen werden.
    m = s.mark()
    s.cmd("ls")
    r.check("Leiche ist aus dem Tor-Ordner verschwunden",
            "NeksLeiche" not in s.since(m))
    m = s.mark()
    s.cmd("grep NeksLeiche")
    r.check("Leiche lässt sich nicht mehr ziehen",
            "Du ziehst" not in s.since(m))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §8 Simon: Leiche + Amulett
with start("nek_simon_beides", BASE, inv=["neksamulett"],
           scalars={"NEK_GIVEN": 1, "VERMISSTE_GIVEN": 1,
                    "SIMON_NEK_INFO": 1, "NEK_FOUND": 1,
                    "NEK_REPORTED": 0,
                    "NEKS_LEICHE_PATH": CORPSE,
                    "NEKS_LEICHE_SEARCHED": 1},
           dyn_type={CORPSE: "f"}) as s:
    r = Report("8) Simon: Leiche + Amulett -> Verkaufsgespräch")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("touch Torwächter")
    r.check("Simon ist schockiert",
            s.wait_from(m, "Heilige Scheiße! Was stimmt nicht mit dir!", 20))
    r.check("Simon erkennt das Amulett",
            s.wait_from(m, "Du hast ihn durchsucht. Und du hast sein Amulett.", 20))
    r.check("Simon bietet 150 Bits",
            s.wait_from(m, "Ich gebe dir 150 Bits dafür.", 20))
    s.send("1"); s.drain(0.8)
    r.check("Verkauf abgeschlossen",
            s.wait_from(m, "Danke. Wirklich.", 20))
    r.check("500 EXP Belohnung",
            s.wait_from(m, "Questbelohnung: 500 EXP", 8))
    dismiss_family_question(s)

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_simon_beides")
    r.check("166 Bits gutgeschrieben (150 + 16 aus Aufstiegen)",
            "BITS=166" in sv)
    r.check("500 EXP als Aufstiege verbucht", "LEVEL=2" in sv)
    r.check("Leiche wurde gebracht", "NEK_CORPSE_BROUGHT=1" in sv)
    r.check("Amulett verkauft", "NEK_AMULET_SOLD=1" in sv)
    r.check("Quest abgeschlossen", "NEK_DONE=1" in sv)
    r.check("Leiche ist auch hier entfernt", "/NeksLeiche" not in sv)
    r.check("auch hier ist der Pfad leer",
            "\nNEKS_LEICHE_PATH=''\n" in sv or "\nNEKS_LEICHE_PATH=\n" in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


# ================================================== §9 Handel: Schmuck
with start("nek_handel", BASE + "/Ostdistrikt/KneipeZumGoldenenLächeln",
           inv=["neksamulett"], scalars={"BITS": 0},
           learn=LEARNED_ALL + ["trade"]) as s:
    r = Report("9) Handel: Schmuck-Reiter verkauft das Amulett für 150 Bits")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    s.cmd("trade Börty")
    r.check("Handelsfenster öffnet", s.wait("TRADE TABLE", 15))
    s.send("d"); s.send("d"); s.send("d"); s.drain(0.7)
    r.check("Schmuck-Reiter ist erreichbar", s.wait("Schmuck", 8))
    r.check("Neks Amulett steht im Verkaufsinventar",
            s.wait("Neks Amulett", 8))
    r.check("Verkaufspreis ist 150 B", s.wait("150 B", 8))
    s.send("e"); s.drain(0.7)
    r.check("Händler zahlt 150 Bits",
            s.wait("zahlt dir 150 Bits", 8))
    s.send(b"\x1b"); s.drain(0.6)
    r.check("Abschlussfenster erscheint", s.wait("HANDEL ABSCHLIESSEN?", 8))
    s.send("1"); s.drain(0.9)
    r.check("Handel wird abgeschlossen", s.wait("[ HANDEL ]", 12))
    r.check("Bericht nennt 150 Bits", s.wait("verkauft: Neks Amulett ×1", 8))

    s.cmd("save")
    r.check("Spielstand in Slot", s.wait("Spielstand in Slot", 20))
    sv = save_text("nek_handel")
    r.check("150 Bits gutgeschrieben", "BITS=150" in sv)
    r.check("Amulett ist verkauft", "[neksamulett]" not in sv)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()


print("\nNEKS-SCHMUCK-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
