#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Bits-Fundorte & direkte Stadtteilwechsel (PTY)
# ------------------------------------------------------------
#  Prüft die Aufgaben aus dem Stand vom 19.10.2026:
#
#    1) Bits-Haufen mit »grep« einsammeln - an sechs Orten:
#         ~                         15 Bits
#         ~/Schreibtisch             7 Bits
#         ~/Schreibtisch/DesktopCity 11 Bits
#         .../Haupteingang           9 Bits
#         .../Süddistrikt            3 Bits
#         .../Ostdistrikt           12 Bits
#       »grep« muss erlernt sein; »use« darf diese Haufen NICHT
#       einsammeln (Bits sind ausdrücklich grep-Fundorte).
#
#    2) Aus JEDEM Stadtteil direkt in jeden anderen: »cd Ostdistrikt«
#       und »cd Westdistrikt« funktionieren auch aus einem anderen
#       Stadtteil - ohne Umweg über den Haupteingang.
#
#  Aufruf:  python3 Kern/tests/t_aufgaben.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL

reset_tmp()
fails = 0
H = "/home/benutzer"
CITY = H + "/Schreibtisch/DesktopCity"
HALL = CITY + "/Haupteingang"
SCHMIEDE = HALL + "/Zentrum/Schmiede"
FRIEDHOF = H + "/Schreibtisch/Brachland/Friedhof"


def start(name, scalars, learn=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=learn or LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


def cd_to(s, r, district, path):
    """»cd <Stadtteil>« und mit pwd prüfen, wo der Agent gelandet ist."""
    m = s.mark()
    s.cmd("cd %s" % district)
    s.cmd("pwd")
    return s.wait_from(m, path, 12)


# ============================================= §1 Bits mit »grep«
with start("auf_bits", {"CWD": H, "BITS": 0}) as s:
    r = Report("1) Bits-Haufen: einsammeln mit »grep«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("cat Bits")
    r.check("der Fundort nennt »grep Bits«", s.wait_from(m, "»grep Bits«", 10))

    # use darf einen Bits-Haufen nicht einsammeln.
    m = s.mark()
    s.cmd("use Bits")
    r.check("use verweigert den Bits-Haufen",
            s.wait_from(m, "Das muss ich herausziehen", 10))
    r.check("use hat nichts aufgesammelt", "aufgesammelt" not in s.since(m))

    m = s.mark()
    s.cmd("grep Bits")
    r.check("~: 15 Bits", s.wait_from(m, "15 Bits aufgesammelt", 10))

    s.cmd("cd Schreibtisch")
    m = s.mark()
    s.cmd("grep Bits")
    r.check("~/Schreibtisch: 7 Bits", s.wait_from(m, "7 Bits aufgesammelt", 10))

    s.cmd("cd DesktopCity")
    m = s.mark()
    s.cmd("grep Bits")
    r.check("DesktopCity: 11 Bits", s.wait_from(m, "11 Bits aufgesammelt", 10))

    s.cmd("cd Haupteingang")
    m = s.mark()
    s.cmd("grep Bits")
    r.check("Haupteingang: 9 Bits", s.wait_from(m, "9 Bits aufgesammelt", 10))

    m = s.mark()
    s.cmd("cd Süddistrikt")
    r.check("im Süddistrikt", s.wait_from(m, "Süddistrikt", 10))
    m = s.mark()
    s.cmd("grep 3x Bits")
    r.check("Süddistrikt: 3 Bits (Schreibweise wie im Ordner)",
            s.wait_from(m, "3 Bits aufgesammelt", 10))

    # Direkt von Süddistrikt nach Ostdistrikt - ohne Haupteingang.
    r.check("aus Süddistrikt direkt nach Ostdistrikt",
            cd_to(s, r, "Ostdistrikt", HALL + "/Ostdistrikt"))
    m = s.mark()
    s.cmd("grep Bits")
    r.check("Ostdistrikt: 12 Bits", s.wait_from(m, "12 Bits aufgesammelt", 10))

    # Gesamtkontostand: 15+7+11+9+3+12 = 57.
    m = s.mark()
    s.cmd("inventar")
    r.check("Kontostand 57 Bits", s.wait_from(m, "57 Bits", 12))
    s.esc()
    s.drain(0.6)
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ============================= §2 aus jedem Stadtteil in jeden anderen
with start("auf_cd", {"CWD": HALL + "/Süddistrikt"}) as s:
    r = Report("2) Direkte Stadtteilwechsel mit »cd«")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    for d in ("Ostdistrikt", "Westdistrikt", "Norddistrikt",
              "Zentrum", "Süddistrikt", "Ostdistrikt"):
        r.check("cd %s (aus dem vorigen Stadtteil)" % d,
                cd_to(s, r, d, HALL + "/" + d))

    r.check("aus dem Bezirk direkt zum Haupteingang",
            cd_to(s, r, "Haupteingang", HALL))
    r.check("vom Haupteingang direkt in einen Bezirk",
            cd_to(s, r, "Ostdistrikt", HALL + "/Ostdistrikt"))

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ============================= §3 ohne »grep« bleibt der Haufen liegen
LEARNED_NO_GREP = [x for x in LEARNED_ALL if x != "grep"]
with start("auf_ohne_grep", {"CWD": H, "BITS": 0}, learn=LEARNED_NO_GREP) as s:
    r = Report("3) Ohne erlerntes »grep« kein Einsammeln")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    m = s.mark()
    s.cmd("grep Bits")
    r.check("»grep« ist noch unbekannt",
            s.wait_from(m, "Diesen Befehl hat der Virus mir genommen", 10))
    r.check("grep hat nichts aufgesammelt", "aufgesammelt" not in s.since(m))
    r.check("gesperrtes grep kostet keine Tokens",
            s.no_wait("995 / 1000", 0.7))
    m = s.mark()
    s.cmd("cat Bits")
    r.check("der Fundort nennt weiterhin »grep Bits«",
            s.wait_from(m, "»grep Bits«", 10))
    m = s.mark()
    s.cmd("use Bits")
    r.check("use zieht den Haufen nicht heraus",
            s.wait_from(m, "Das muss ich herausziehen", 10))
    r.check("use hat nichts aufgesammelt", "aufgesammelt" not in s.since(m))
    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

# ============================= §4 Brunos Amboss lässt sich nicht greppen
with start("auf_amboss", {"CWD": SCHMIEDE, "BITS": 0}) as s:
    r = Report("4) Amboss: kein grep-Fundort")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("grep Amboss")
    r.check("grep verweigert den Amboss",
            s.wait_from(m, "Der Amboss gehört nicht mir, den kann ich nicht mit nehmen", 10))
    r.check("kein Fundort im Inventar",
            "aufgenommen" not in s.since(m)
            and "Amboss" not in " ".join(s.since(m).split("GEGENSTAND")[1:]))

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()


# ============================= §5 Stadtwechsel nur innerhalb der Stadt
with start("auf_cd_aussen", {"CWD": FRIEDHOF}) as s:
    r = Report("5) Von außerhalb kein direkter Stadtteilwechsel")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))

    m = s.mark()
    s.cmd("cd Ostdistrikt")
    r.check("Sprung vom Friedhof wird abgewiesen",
            s.wait_from(m, "Von außerhalb der Stadt kann ich nicht direkt in einen Stadtteil wechseln", 10))
    m = s.mark()
    s.cmd("pwd")
    r.check("der Agent bleibt auf dem Friedhof",
            s.wait_from(m, "Brachland/Friedhof", 10))

    # Erst in die Stadt, dann ist der direkte Wechsel wieder erlaubt.
    m = s.mark()
    s.cmd("cd %s" % HALL)
    s.cmd("pwd")
    r.check("Haupteingang betreten", s.wait_from(m, HALL, 12))
    r.check("aus der Stadt direkt nach Ostdistrikt",
            cd_to(s, r, "Ostdistrikt", HALL + "/Ostdistrikt"))

    s.cmd("exit")
    s.drain(1.5)
    fails += r.done()

print("\nAUFGABEN-TEST:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
