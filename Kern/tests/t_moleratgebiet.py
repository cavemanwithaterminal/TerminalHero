#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Brachland/Steppe: Moleratgebiete (PTY)
# ------------------------------------------------------------
#  Prüft:
#    1) Brachland enthält Friedhof und Steppe, aber keinen Canyon
#       mehr; die Steppe enthält Canyon und Moleratgebiet.
#    2) Das Moleratgebiet und seine sechs Untergebiete sind per
#       cd/ls erreichbar; 1.2 liegt in 1.1, 2.2 in 2.1 und 3.2
#       in 3.1.
#    3) Im Basislager stehen zwei, in jedem Untergebiet drei
#       Molerats.
#    4) Ein Kill im Basislager wird im Spielstand als eigener
#       Gebietszähler gesichert und lässt die Höhlen-Bitmaske
#       unberührt.
#    5) Ein fälliger 24-Stunden-Respawn kommt beim Laden genau
#       einmal; ein noch nicht fälliger Timer bleibt untätig.
#    6) Farmland/Farm mit der Familie Molerat und die Canyon-
#       Tunnelkette sind erreichbar; jeder Tunnel hält genau ein
#       Molerat und respawnt nach 24 Stunden höchstens eines.
#
#  Aufruf:  python3 Kern/tests/t_moleratgebiet.py
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
BL = DESK + "/Brachland"
STEPPE = BL + "/Steppe"
GEBIET = STEPPE + "/Moleratgebiet"
G11 = GEBIET + "/Moleratgebiet1.1"
G12 = G11 + "/Moleratgebiet1.2"
G21 = GEBIET + "/Moleratgebiet2.1"
G22 = G21 + "/Moleratgebiet2.2"
G31 = GEBIET + "/Moleratgebiet3.1"
G32 = G31 + "/Moleratgebiet3.2"
FARMLAND = STEPPE + "/Farmland"
FARM = FARMLAND + "/Farm"
HOLE = STEPPE + "/Canyon/Höhleneingang"
T1 = HOLE + "/Höhlentunnel1"
T2 = T1 + "/Höhlentunnel2"
T3 = T2 + "/Höhlentunnel3"
KAMMER = T3 + "/GroßeHöhlenkammer"


def add_molerat_state(name, dead=0, nxt=0):
    """Ergänzt den Teststand um die per-Gebiet-Zustände (assoc arrays)."""
    path = os.path.join(TMP, name, "manual1.save")
    with open(path, "a", encoding="utf-8") as fh:
        fh.write("declare -g -A MOLERAT_AREA_DEAD=([Moleratgebiet]=%d)\n" % dead)
        fh.write("declare -g -A MOLERAT_AREA_NEXT=([Moleratgebiet]=%d)\n" % nxt)


def add_area_state(name, key, dead=0, nxt=0):
    """Ergänzt den Teststand um den Zustand eines einzelnen Gebiets."""
    path = os.path.join(TMP, name, "manual1.save")
    with open(path, "a", encoding="utf-8") as fh:
        fh.write("declare -g -A MOLERAT_AREA_DEAD=([%s]=%d)\n" % (key, dead))
        fh.write("declare -g -A MOLERAT_AREA_NEXT=([%s]=%d)\n" % (key, nxt))


def start(name, cwd, scalars=None, learned=None, inv=None, equip=None,
          mol_dead=None, mol_next=None, area=None, env=None):
    d = os.path.join(TMP, name)
    sv = {
        "CWD": cwd, "OLDPWD": DESK, "VIEW_DIR": cwd,
        "SHOW_PATH": 1, "SHOW_LS": 1,
        "HOME_FIRST_VISIT": 1, "TUT_DONE": 1, "TORWAEHTER_DONE": 1,
        "README_DONE": 1, "SAVE_LEARNED": 1,
        "PIXI_DESKTOP_DONE": 1, "PIXI_GATE_DONE": 1,
        "PIXI_HALL_DONE": 1, "PIXI_GUIDE_DONE": 1, "PIXI_LETTER_DONE": 1,
        "TOKENS_CUR": 1000, "TOKENS_MAX": 1000,
        # Die Höhlen-Story und andere Szenen sollen hier nicht dazwischenfunken.
        "MOLERATS_DEAD": 7,
        "GUY_SUS_MET": 1, "GUY_SUS_GONE": 1,
        "GUY_SUS_CAVE_DONE": 1, "GUY_SUS_OUTSIDE_DONE": 1,
        "WORLD_SECS": 0, "WORLD_STARTED": 1,
    }
    sv.update(scalars or {})
    write_save(os.path.join(d, "manual1.save"), scalars=sv,
               learned=learned or LEARNED_ALL, inv=inv, equip=equip)
    if mol_dead is not None or mol_next is not None:
        add_molerat_state(name, mol_dead or 0, mol_next or 0)
    if area:
        for key, (dead, nxt) in area.items():
            add_area_state(name, key, dead, nxt)

    e = {
        "TERMINALHERO_LOAD": "manual",
        "TH_SAY_SECS": "0.01",
        "TH_TOKEN_REGEN_SECS": "3600",
    }
    e.update(env or {})
    return Sim(env=e, saves=d, rows=40, cols=120)


def read_save(name):
    return open(os.path.join(TMP, name, "manual1.save"),
                encoding="utf-8").read()


def assoc_value(sv, name, key):
    m = re.search(r"^%s=\((.*)\)$" % re.escape(name), sv, re.M)
    if not m:
        return None
    hit = re.search(r"\[%s\]=([^ ]+)" % re.escape(key), m.group(1))
    return hit.group(1) if hit else None


# ================================================== §1 Karte & Erreichbarkeit
with start("mg_nav", BL) as s:
    r = Report("1) Brachland, Steppe & Moleratgebiete")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("ls")
    r.check("Brachland zeigt Friedhof", s.wait_from(m, "Friedhof", 10))
    r.check("Brachland zeigt Steppe", s.wait_from(m, "Steppe", 10))
    r.check("Brachland zeigt keinen Canyon mehr",
            "Canyon" not in s.since(m))

    m = s.mark()
    s.cmd("cd Steppe")
    s.cmd("pwd")
    r.check("cd betritt die Steppe", s.wait_from(m, STEPPE, 10))

    m = s.mark()
    s.cmd("ls")
    r.check("Steppe zeigt Canyon", s.wait_from(m, "Canyon", 10))
    r.check("Steppe zeigt Moleratgebiet", s.wait_from(m, "Moleratgebiet", 10))

    m = s.mark()
    s.cmd("cd Moleratgebiet")
    s.cmd("pwd")
    r.check("cd betritt das Moleratgebiet", s.wait_from(m, GEBIET, 10))

    m = s.mark()
    s.cmd("ls")
    r.check("Basislager zeigt Molerat1", s.wait_from(m, "Molerat1", 10))
    r.check("Basislager zeigt Molerat2", s.wait_from(m, "Molerat2", 10))
    r.check("Basislager zeigt 1.1", s.wait_from(m, "Moleratgebiet1.1", 10))
    r.check("Basislager zeigt 2.1", s.wait_from(m, "Moleratgebiet2.1", 10))
    r.check("Basislager zeigt 3.1", s.wait_from(m, "Moleratgebiet3.1", 10))

    for path, inner in ((G11, "Moleratgebiet1.2"),
                        (G12, None),
                        (G21, "Moleratgebiet2.2"),
                        (G22, None),
                        (G31, "Moleratgebiet3.2"),
                        (G32, None)):
        m = s.mark()
        s.cmd("cd " + path)
        s.cmd("pwd")
        r.check("%s ist erreichbar" % path.rsplit("/", 1)[-1],
                s.wait_from(m, path, 10))
        m = s.mark()
        s.cmd("ls")
        r.check("%s zeigt drei Molerats" % path.rsplit("/", 1)[-1],
                s.wait_from(m, "Molerat1", 10)
                and s.wait_from(m, "Molerat2", 10)
                and s.wait_from(m, "Molerat3", 10))
        if inner:
            r.check("%s liegt in %s" % (inner, path.rsplit("/", 1)[-1]),
                    s.wait_from(m, inner, 10))

    # Farmland/Farm mit der Familie Molerat.
    m = s.mark()
    s.cmd("cd " + FARMLAND)
    s.cmd("pwd")
    r.check("Farmland ist erreichbar", s.wait_from(m, FARMLAND, 10))
    m = s.mark()
    s.cmd("ls")
    r.check("Farmland zeigt die Farm", s.wait_from(m, "Farm", 10))
    m = s.mark()
    s.cmd("cd Farm")
    s.cmd("pwd")
    r.check("Farm ist erreichbar", s.wait_from(m, FARM, 10))
    m = s.mark()
    s.cmd("ls")
    r.check("Farm zeigt das Anwesen", s.wait_from(m, "Anwesen", 10))
    # Die Familie wohnt im Erdgeschoss des Anwesens.
    m = s.mark()
    s.cmd("cd Anwesen/Haupteingang/Erdgeschoss")
    s.cmd("pwd")
    r.check("Erdgeschoss ist erreichbar", s.wait_from(m, "Erdgeschoss", 10))
    m = s.mark()
    s.cmd("ls")
    for name in ("GregorMolerat", "MarleneMolerat", "ChantalMolerat"):
        r.check("Erdgeschoss zeigt %s" % name, s.wait_from(m, name, 10))

    # Canyon-Höhleneingang und die drei verschachtelten Tunnel.
    m = s.mark()
    s.cmd("cd " + STEPPE)
    s.cmd("cd Canyon")
    s.cmd("pwd")
    r.check("Canyon ist erreichbar", s.wait_from(m, STEPPE + "/Canyon", 10))
    m = s.mark()
    s.cmd("ls")
    r.check("Canyon zeigt den Höhleneingang",
            s.wait_from(m, "Höhleneingang", 10))

    for path, inner in ((HOLE, "Höhlentunnel1"), (T1, "Höhlentunnel2"),
                        (T2, "Höhlentunnel3"), (T3, "GroßeHöhlenkammer")):
        m = s.mark()
        s.cmd("cd " + path)
        s.cmd("pwd")
        r.check("%s ist erreichbar" % path.rsplit("/", 1)[-1],
                s.wait_from(m, path, 10))
        m = s.mark()
        s.cmd("ls")
        if inner:
            r.check("%s enthält %s" % (path.rsplit("/", 1)[-1], inner),
                    s.wait_from(m, inner, 10))
        if path in (T1, T2, T3):
            # Das Maximum von genau einem Molerat prüfen die Unit-Tests
            # und der frische Respawn-Test in §5. Hier genügt, dass der
            # Tunnel erreichbar ist und sein Molerat zeigt.
            r.check("%s zeigt seinen Molerat" % path.rsplit("/", 1)[-1],
                    s.wait_from(m, "Molerat1", 10))

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §2 Kill im Basislager
with start("mg_kill", GEBIET, learned=LEARNED_ALL + ["rm"],
           inv=["trainingsklinge"],
           equip={"linke_hand": "trainingsklinge"}) as s:
    r = Report("2) Kill im Basislager & eigener Gebietszustand")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("rm Molerat1", wait="Molerat1 wurde gelöscht", timeout=12)
    r.check("Molerat1 wurde im Basislager gelöscht",
            "Molerat1 wurde gelöscht" in s.since(m))

    m = s.mark()
    s.cmd("ls")
    r.check("Molerat2 lebt weiter", s.wait_from(m, "Molerat2", 10))

    s.cmd("save", wait="Spielstand in Slot", timeout=12)
    sv = read_save("mg_kill")
    r.check("Gebiets-Todeszähler ist gespeichert",
            assoc_value(sv, "MOLERAT_AREA_DEAD", "Moleratgebiet") == "1")
    r.check("Gebiets-Timer ist gespeichert",
            (assoc_value(sv, "MOLERAT_AREA_NEXT", "Moleratgebiet") or "0") != "0")
    r.check("Höhlen-Bitmaske bleibt unberührt",
            re.search(r"^MOLERATS_DEAD=7$", sv, re.M) is not None)

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §3 Respawn beim Laden
with start("mg_respawn", GEBIET, mol_dead=1, mol_next=100,
           scalars={"WORLD_SECS": 1000}) as s:
    r = Report("3) Fälliger 24-Stunden-Respawn beim Laden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Tick meldet den Nachspawn",
            s.wait("Ein Molerat ist im Gebiet nachgekommen", 12))

    m = s.mark()
    s.cmd("ls")
    r.check("nach dem Nachspawn leben wieder zwei Molerats",
            s.wait_from(m, "Molerat1", 10)
            and s.wait_from(m, "Molerat2", 10))

    s.cmd("save", wait="Spielstand in Slot", timeout=12)
    sv = read_save("mg_respawn")
    r.check("Todeszähler ist nach dem Spawn leer",
            assoc_value(sv, "MOLERAT_AREA_DEAD", "Moleratgebiet") == "0")
    r.check("Respawn-Timer ist nach dem Spawn aus",
            assoc_value(sv, "MOLERAT_AREA_NEXT", "Moleratgebiet") == "0")

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §4 Timer noch nicht fällig
with start("mg_wait", GEBIET, mol_dead=1, mol_next=500000,
           scalars={"WORLD_SECS": 1000}) as s:
    r = Report("4) Noch nicht fälliger Respawn bleibt untätig")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("kein vorzeitiger Nachspawn",
            s.no_wait("Ein Molerat ist im Gebiet nachgekommen", 1.5))

    m = s.mark()
    s.cmd("ls")
    r.check("nur ein Molerat lebt noch", s.wait_from(m, "Molerat1", 10))
    r.check("der zweite Molerat fehlt weiterhin",
            "Molerat2" not in s.since(m))

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

# ================================================== §5 Tunnel-Respawn
with start("mg_tunnel_respawn", T1,
           area={"Hoehlentunnel1": (1, 100)},
           scalars={"WORLD_SECS": 1000}) as s:
    r = Report("5) Höhlentunnel: ein Molerat & 24-Stunden-Respawn")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("Tunnel meldet den Nachspawn",
            s.wait("Ein Molerat ist im Gebiet nachgekommen", 12))

    m = s.mark()
    s.cmd("ls")
    r.check("Höhlentunnel1 ist wieder besetzt",
            s.wait_from(m, "Molerat1", 10))
    r.check("es kommt höchstens ein Molerat nach",
            "Molerat2" not in s.since(m))

    s.cmd("save", wait="Spielstand in Slot", timeout=12)
    sv = read_save("mg_tunnel_respawn")
    r.check("Tunnel-Todeszähler ist leer",
            assoc_value(sv, "MOLERAT_AREA_DEAD", "Hoehlentunnel1") == "0")
    r.check("Tunnel-Respawn-Timer ist aus",
            assoc_value(sv, "MOLERAT_AREA_NEXT", "Hoehlentunnel1") == "0")

    s.cmd("exit")
    s.drain(1.0)
    fails += r.done()

print("\nMOLERATGEBIET-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
