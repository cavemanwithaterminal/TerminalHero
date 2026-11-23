#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Guy Sus, Molerats & Kampfbefehl rm (PTY)
# ------------------------------------------------------------
#  Prüft:
#    1) Guy Sus spricht beim ersten Betreten des Höhleneingangs
#       automatisch, erklärt Molerats/Molerate und lehrt »search«
#       für 2 Skillpunkte + 25 Bits.
#    2) Die Molerathöhle kündigt die drei Molerats mit »Oink, Oink«
#       an; nach 3 Sekunden ziehen sie Tokens ab. Außerhalb der
#       Höhle greift niemand mehr an.
#    3) »rm« braucht eine ausgerüstete Waffe.
#    4) »rm Molerat1 Molerat2 Molerat3« kostet 200 Tokens, gibt
#       40 EXP (1 EXP je 5 Tokens inkl. Gegnerkosten), lässt drei
#       MoleratCode fallen und startet Guys Höhlen-Szene nach dem Sieg.
#    5) Liegt Neks Leiche im Höhleneingang, spricht Guy draußen;
#       nach dem Abschied ist seine Datei verschwunden.
#
#  Aufruf:  python3 Kern/tests/t_guy.py
# ============================================================
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
DESK = H + "/Schreibtisch"
ENTRY = DESK + "/Höhleneingang"
CAVE = ENTRY + "/Molerathöhle"

LEARNED_NO_SEARCH = [c for c in LEARNED_ALL if c != "search"]


def start(name, cwd, scalars=None, learned=None, inv=None, equip=None,
          tokens=1000, extra_env=None):
    """Startet eine Sitzung mit ruhigen Story-Flags und ohne Regen."""
    d = os.path.join(TMP, name)
    sv = {
        "CWD": cwd, "OLDPWD": DESK, "VIEW_DIR": cwd,
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "HOME_FIRST_VISIT": 1, "TUT_DONE": 1, "TORWAEHTER_DONE": 1,
        "README_DONE": 1, "SAVE_LEARNED": 1,
        "PIXI_DESKTOP_DONE": 1, "PIXI_GATE_DONE": 1,
        "PIXI_HALL_DONE": 1, "PIXI_GUIDE_DONE": 1, "PIXI_LETTER_DONE": 1,
        "TOKENS_CUR": tokens, "TOKENS_MAX": 1000,
        # Standard: Guy ist bereits weg, damit fremde Szenen nicht stören.
        "GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
        "GUY_SUS_CAVE_DONE": 1, "GUY_SUS_OUTSIDE_DONE": 0,
        "MOLERATS_DEAD": 0,
    }
    sv.update(scalars or {})
    write_save(os.path.join(d, "manual1.save"), scalars=sv,
               learned=learned or LEARNED_ALL, inv=inv, equip=equip)
    env = {
        "TERMINALHERO_LOAD": "manual",
        "TH_SAY_SECS": "0.01",
        "TH_TOKEN_REGEN_SECS": "3600",
        "TH_FAINT_SECS": "0.01",
        "TH_DEATH_SECS": "0.01",
    }
    env.update(extra_env or {})
    return Sim(env=env, saves=d, rows=40, cols=120)


def read_save(name):
    return open(os.path.join(TMP, name, "manual1.save"),
                encoding="utf-8").read()


def field(sv, key):
    m = re.search(r"^%s=(.*)$" % re.escape(key), sv, re.M)
    if not m:
        return None
    return m.group(1).strip().strip("'\"")


def learned_names(sv):
    m = re.search(r"^LEARNED=\((.*)\)$", sv, re.M)
    if not m:
        return []
    return [v for _, v in re.findall(
        r"\[[0-9]+\]=(['\"]?)([^'\"\s)\]]+)", m.group(1))]


def inv_count(sv, item):
    m = re.search(r"^INV_COUNT=\((.*)\)$", sv, re.M)
    if not m:
        return 0
    hit = re.search(r"\[%s\]=([0-9]+)" % re.escape(item), m.group(1))
    return int(hit.group(1)) if hit else 0


# ================================================== §1 Guy intro & search
with start("guy_intro", DESK,
           scalars={"SKILL_POINTS": 2, "BITS": 25,
                    "GUY_SUS_MET": 0, "GUY_SUS_GONE": 0,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0},
           learned=LEARNED_NO_SEARCH) as s:
    r = Report("1) Guy Sus: automatische Begrüßung & »search« lernen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("cd Höhleneingang")
    r.check("Guy begrüßt automatisch",
            s.wait_from(m, "Hey. Pssst. Vorsicht.", 12))
    r.check("Guy nennt die Molerats",
            s.wait_from(m, "Molerats ... oder Molerate", 12))
    r.check("Antwortoption »Molerats?«", s.wait_from(m, "1) Molerats?", 12))
    r.check("Antwortoption »Molerate?«", s.wait_from(m, "2) Molerate?", 12))

    s.send("1")
    r.check("beide Schreibweisen führen zur Erklärung",
            s.wait("große, angriffslustige Schweine", 12))
    r.check("Guy nennt die Leiche", s.wait("In der Höhle liegt eine Leiche", 12))
    r.check("Guy nennt das glänzende Objekt",
            s.wait("glänzendes Objekt", 12))
    r.check("Guy bietet Plündern an", s.wait("Plündern lernen", 12))
    r.check("Guy bietet auch Später an", s.wait("Später.", 12))

    s.send("1")
    r.check("Lernpreis wird genannt",
            s.wait("Das kostet 2 Skillpunkte und 25 Bits.", 12))
    r.check("Guy fragt vor dem Lernen nach",
            s.wait("Willst du es wirklich lernen?", 12))
    r.check("Guy bietet die Bestätigung an",
            s.wait("1) Ja, bring es mir bei.", 12))
    s.send("1")
    r.check("search wird gelernt",
            s.wait("[ Neuer Befehl erlernt: search ]", 12))
    r.check("Guy entlässt den Agenten",
            s.wait("nichts wie rein", 12))

    s.cmd("save", wait="Spielstand in Slot", timeout=12)
    sv = read_save("guy_intro")
    r.check("2 Skillpunkte bezahlt", field(sv, "SKILL_POINTS") == "0")
    r.check("25 Bits bezahlt", field(sv, "BITS") == "0")
    r.check("search steht im Spielstand", "search" in learned_names(sv))
    r.check("Guy gilt als getroffen", field(sv, "GUY_SUS_MET") == "1")
    r.check("Guy ist noch nicht verschwunden",
            field(sv, "GUY_SUS_GONE") == "0")
    fails += r.done()

# ================================================== §2 Molerate-Variante
with start("guy_molerate", DESK,
           scalars={"GUY_SUS_MET": 0, "GUY_SUS_GONE": 0,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0},
           learned=LEARNED_NO_SEARCH) as s:
    r = Report("2) Guy Sus: Variante »Molerate?«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("cd Höhleneingang")
    r.check("Guy begrüßt automatisch",
            s.wait_from(m, "Hey. Pssst. Vorsicht.", 12))
    s.send("2")
    r.check("Molerate führt zur selben Erklärung",
            s.wait("große, angriffslustige Schweine", 12))
    r.check("auch hier folgt die Leiche",
            s.wait("In der Höhle liegt eine Leiche", 12))
    s.send("2")   # Später
    r.check("Später beendet das Gespräch",
            s.wait("Dann pass auf dich auf", 12))
    fails += r.done()

# ================================================== §3 Oink & Schaden
# CAVE_DONE=1 würde laut Migration alle Molerats als tot markieren -
# für diesen Test müssen sie leben, Guy darf aber verschwunden sein.
with start("guy_oink", CAVE,
           scalars={"GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0,
                    "MOLERATS_DEAD": 0}) as s:
    r = Report("3) Molerathöhle: Oink, Oink & automatischer Schaden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Betreten kündigt Oink, Oink an", s.wait("Oink, Oink", 12))
    r.check("drei Molerats werden genannt",
            s.wait("3 Gegner: Molerat1, Molerat2, Molerat3.", 12))
    r.check("Angriff nach 3 Sekunden angekündigt",
            s.wait("Angriff nach 3s", 12))
    r.check("Molerats ziehen 30 Tokens pro Sekunde",
            s.wait("Molerat1, Molerat2, Molerat3: -30 Tokens", 10))

    # Raus aus der Höhle: dort darf kein weiterer Schaden entstehen.
    s.cmd("cd ..", wait="Höhleneingang", timeout=10)
    m = s.mark()
    s.cmd("save")
    s.wait_from(m, "Spielstand in Slot", 12)
    before = field(read_save("guy_oink"), "TOKENS_CUR")
    s.drain(3.0)
    m = s.mark()
    s.cmd("save")
    s.wait_from(m, "Spielstand in Slot", 12)
    after = field(read_save("guy_oink"), "TOKENS_CUR")
    r.check("außerhalb der Höhle kein weiterer Schaden (nur save -5)",
            after == str(int(before) - 5))
    r.check("der Agent lebt noch", int(after) > 0)
    fails += r.done()

# ================================================== §4 rm ohne Waffe
with start("guy_rm_noweapon", CAVE,
           scalars={"GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0,
                    "MOLERATS_DEAD": 0},
           learned=LEARNED_ALL + ["rm"]) as s:
    r = Report("4) rm ohne ausgerüstete Waffe")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("rm Molerat1")
    r.check("rm verlangt eine Waffe",
            s.wait_from(m, "Ich brauche eine ausgerüstete Waffe", 10))
    r.check("kein Molerat wurde gelöscht",
            "wurde gelöscht" not in s.since(m))
    fails += r.done()

# ================================================== §5 rm tötet alle drei
with start("guy_rm_all", CAVE,
           scalars={"GUY_SUS_MET": 1, "GUY_SUS_GONE": 0,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0,
                    "MOLERATS_DEAD": 0, "NEKS_LEICHE_SEARCHED": 1},
           learned=LEARNED_ALL + ["rm"],
           inv=["trainingsklinge"],
           equip={"linke_hand": "trainingsklinge"}) as s:
    r = Report("5) rm Molerat1 Molerat2 Molerat3: Sieg, Loot & Guy")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("rm Molerat1 Molerat2 Molerat3",
          wait="Wow. Das war große Klasse.", timeout=20)
    r.check("Guy erscheint nach dem Sieg",
            "Wow. Das war große Klasse. Den Biestern hast du es gezeigt."
            in s.since(m))
    r.check("Guy fragt nach der Leiche",
            s.wait("Hast du die Leiche schon durchsucht?", 12))

    s.send("1")
    r.check("Agent bekennt sich zum Amulett",
            s.wait("Ja. Hab ein Amulett gefunden", 12))
    r.check("Guy nimmt Abschied",
            s.wait("vielleicht sieht man sich wieder. Die Welt ist klein", 12))
    r.check("Guy verschwindet",
            s.wait("und ist im nächsten Augenblick verschwunden", 12))
    s.send(b"\r")   # dialog_pause am Ende

    # Erst speichern, bevor »ls« (5 Tokens, 1 EXP) die Werte verändert.
    s.cmd("save", wait="Spielstand in Slot", timeout=12)
    sv = read_save("guy_rm_all")
    r.check("alle drei Molerats sind tot", field(sv, "MOLERATS_DEAD") == "7")
    r.check("Höhlen-Szene ist abgeschlossen",
            field(sv, "GUY_SUS_CAVE_DONE") == "1")
    r.check("Guy ist verschwunden", field(sv, "GUY_SUS_GONE") == "1")
    r.check("sechs MoleratCodes im Inventar (2 je Molerat)",
            inv_count(sv, "moleratcode") == 6)
    r.check("rm kostet 200 Tokens, save 5 (795)",
            field(sv, "TOKENS_CUR") == "795")
    r.check("rm gibt 40 EXP, save 1 (41)",
            field(sv, "EXP") == "41")

    m2 = s.mark()
    s.cmd("ls")
    r.check("keine Molerats mehr im ls", "Molerat" not in s.since(m2))
    fails += r.done()

# ================================================== §6 Guy draußen
# Faithful setup: Die Leiche liegt noch in der Höhle, die Molerats leben.
# Der Agent greift sie und zieht sie in den Höhleneingang - erst dort
# taucht Guy auf. So bleibt die Höhlen-Szene aus.
with start("guy_outside", CAVE,
           scalars={"GUY_SUS_MET": 1, "GUY_SUS_GONE": 0,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0,
                    "MOLERATS_DEAD": 0, "NEKS_LEICHE_SEARCHED": 1}) as s:
    r = Report("6) Leiche in den Höhleneingang ziehen: Guys Außen-Szene")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("grep NeksLeiche", wait="Du ziehst jetzt eine Leiche", timeout=12)
    r.check("Leiche wird gezogen",
            "Du ziehst jetzt eine Leiche" in s.since(m))
    m = s.mark()
    s.cmd("cd ..")
    r.check("Leiche folgt in den Höhleneingang", s.wait_from(
        m, "Guy Sus wartet draußen", 12))
    r.check("Guy spricht draußen",
            s.wait_from(m,
                        "Puh, da bist du aber glimpflich davon gekommen. "
                        "Den Molerats bist du entkommen.", 12))
    r.check("Guy fragt nach der Leiche",
            s.wait_from(m, "Hast du die Leiche schon durchsucht?", 12))

    s.send("1")
    r.check("Agent bekennt sich zum Amulett",
            s.wait_from(m, "Ja. Hab ein Amulett gefunden", 12))
    r.check("Guy nimmt Abschied",
            s.wait_from(m, "vielleicht sieht man sich wieder. Die Welt ist klein",
                        12))
    r.check("Guy verschwindet",
            s.wait_from(m, "und ist im nächsten Augenblick verschwunden", 12))
    s.send(b"\r")

    m2 = s.mark()
    s.cmd("ls")
    r.check("GuySus ist aus dem Ordner verschwunden",
            "GuySus" not in s.since(m2))
    s.cmd("save", wait="Spielstand in Slot", timeout=12)
    sv = read_save("guy_outside")
    r.check("Außen-Szene ist abgeschlossen",
            field(sv, "GUY_SUS_OUTSIDE_DONE") == "1")
    r.check("Guy ist verschwunden", field(sv, "GUY_SUS_GONE") == "1")
    r.check("Guy gilt als getroffen", field(sv, "GUY_SUS_MET") == "1")
    fails += r.done()

# ================================================== §7 Ohnmacht ohne Kampf
with start("guy_faint", DESK, tokens=5,
           scalars={"WORLD_STARTED": 1, "WORLD_SECS": 0}) as s:
    r = Report("7) 0 Tokens ohne Kampf: Ohnmacht, 6 Stunden, 15 % Tokens")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    # »cd ..« würde den Ordner wechseln - durch die Ohnmacht darf es das nicht.
    s.cmd("cd ..")
    r.check("schwarzer Bildschirm meldet Ohnmacht",
            s.wait_from(m, "Du bist Ohnmächtig", 10))
    r.check("sechs Ingame-Stunden vergehen",
            s.wait_from(m, "Sechs Stunden später wachst du wieder auf.", 10))
    r.check("der Agent ist nicht tot", not s.eof)
    r.check("15 % Max-Tokens nach dem Aufwachen",
            s.wait_from(m, "150 / 1000", 10))

    s.cmd("save", wait="Spielstand in Slot", timeout=12)
    sv = read_save("guy_faint")
    r.check("Ohnmacht: 150 Tokens, save kostet 5 (145)",
            field(sv, "TOKENS_CUR") == "145")
    r.check("der auslösende Befehl wurde abgebrochen",
            field(sv, "CWD") == DESK)
    world = int(field(sv, "WORLD_SECS"))
    r.check("Ohnmacht: 6 Spielstunden (900 s) vergangen",
            900 <= world <= 902)
    fails += r.done()

# ================================================== §8 Tod durch Befehl
with start("guy_death_cmd", CAVE, tokens=5,
           scalars={"GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0,
                    "MOLERATS_DEAD": 0},
           # Zeitanker fest: Die Molerats sollen vor dem Befehl nicht angreifen.
           extra_env={"TH_GEGNER_NOW": "1000000000"}) as s:
    r = Report("8) 0 Tokens im Kampf durch einen Befehl: Tod")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Molerats sind aktiv", s.wait("Oink, Oink", 12))

    m = s.mark()
    s.cmd("pwd")
    r.check("Tod wird gemeldet", s.wait_from(m, "Du bist tot", 10))
    s.drain(1.0)
    r.check("Spiel-Shell endet nach dem Tod", s.eof)
    fails += r.done()

# ================================================== §9 Tod durch Gegner
with start("guy_death_hit", CAVE, tokens=10,
           scalars={"GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
                    "GUY_SUS_CAVE_DONE": 0, "GUY_SUS_OUTSIDE_DONE": 0,
                    "MOLERATS_DEAD": 0}) as s:
    r = Report("9) 0 Tokens durch Gegnerschaden: Tod")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Molerats sind aktiv", s.wait("Oink, Oink", 12))
    r.check("Gegnerschaden tötet den Agenten",
            s.wait("Du bist tot", 12))
    s.drain(1.0)
    r.check("Spiel-Shell endet nach dem Tod", s.eof)
    fails += r.done()

sys.exit(1 if fails else 0)
