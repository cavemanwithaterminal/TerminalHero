#!/usr/bin/env python3
# ============================================================
#  TerminalHero - Kalender-Befehl »cal« (PTY)
# ------------------------------------------------------------
#    1) Vor dem Erlernen: Virus-Absage, keine Tokens, kein Datum.
#    2) Nach dem Erlernen: 50 Tokens, 10 EXP, Datum mittig auf der
#       oberen Linie des PFAD-Fensters; Hilfe nennt »cal«.
#    3) Das Datum bleibt 24 Spielstunden sichtbar und verschwindet
#       danach wieder; ein erneutes »cal« blendet es wieder ein.
#
#  Aufruf:  python3 Kern/tests/t_cal.py
# ============================================================
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pty_lib import (Sim, Report, reset_tmp, TMP, write_save, LEARNED_ALL,
                     Screen, ESC)

reset_tmp()
fails = 0
H = "/home/benutzer"
COLS = 110


def start(name, scalars, learn=None):
    sv = os.path.join(TMP, name, "manual1.save")
    write_save(sv, scalars=scalars, learned=learn or LEARNED_ALL)
    return Sim(env={"TERMINALHERO_LOAD": "manual"}, saves=os.path.join(TMP, name))


def top_line(s):
    """Die obere Linie des PFAD-Fensters aus dem kompletten Bildstrom."""
    sc = Screen(40, COLS)
    sc.feed(bytes(s.buf))
    return next((ln for ln in sc.lines() if "SYS://PFAD" in ln), "")


BASE = {
    "CWD": H, "OLDPWD": H, "VIEW_DIR": H,
    "SHOW_PATH": 1, "SHOW_LS": 1,
    "README_DONE": 1, "TUT_DONE": 1, "SAVE_LEARNED": 1,
    "WORLD_SECS": 0, "WORLD_STARTED": 1,
    "CAL_UNTIL_MIN": 0, "TOKENS_CUR": 1000, "EXP": 0, "LEVEL": 0,
}

# ================================================== §1 nicht gelernt
with start("cal_unlearned", BASE, learn=LEARNED_ALL) as s:
    r = Report("1) cal vor dem Erlernen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("vor cal ist kein Datum im PFAD-Fenster",
            "25.01.240" not in top_line(s))

    m = s.mark()
    s.cmd("cal")
    r.check("cal ist vor dem Erlernen gesperrt",
            s.wait_from(m, "»cal« …? Diesen Befehl kenne ich nicht mehr.", 12))
    r.check("die Virus-Absage nennt keinen Kalender",
            "Kalender:" not in s.since(m))
    r.check("cal kostet vor dem Erlernen nichts",
            "1000 / 1000" in s.text() and "950 / 1000" not in s.since(m))
    r.check("kein Datum nach der Absage", "25.01.240" not in s.since(m))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

# ================================================== §2 gelernt
with start("cal_learned", BASE, learn=LEARNED_ALL + ["cal"]) as s:
    r = Report("2) cal nach dem Erlernen")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("vor cal ist kein Datum im PFAD-Fenster",
            "25.01.240" not in top_line(s))

    m = s.mark()
    s.cmd("cal")
    r.check("cal nennt das Startdatum",
            s.wait_from(m, "Kalender: 25.01.240", 12))
    r.check("cal kostet 50 Tokens (-> 950)",
            s.wait_from(m, "950 / 1000", 8))
    r.check("cal nennt die 24 Spielstunden",
            s.wait_from(m, "24 Spielstunden", 5))

    top = top_line(s)
    token = "╡ ◷ 25.01.240 ╞"
    r.check("Datum steht auf der oberen PFAD-Linie", token in top,
            "  [" + top.strip() + "]")
    r.check("Datum ist mittig auf der PFAD-Linie",
            top.find(token) == (COLS - len(token)) // 2,
            "  Spalte %d, erwartet %d" % (top.find(token),
                                          (COLS - len(token)) // 2))

    # Hilfe: cal ist ein Terminal-Befehl und jetzt sichtbar.
    m = s.mark()
    s.cmd("help")
    r.check("Hilfe öffnet sich", s.wait_from(m, "HILFE", 12))
    r.check("Hilfe nennt cal", s.wait_from(m, "In-Game-Kalender anzeigen", 8))
    s.send(ESC, 0.6)
    r.check("Datum bleibt nach dem Schließen der Hilfe sichtbar",
            token in top_line(s))

    # Spielstand: Tokens, EXP und Anzeigedauer werden gesichert.
    m = s.mark()
    s.cmd("save")
    r.check("Spielstand gespeichert",
            s.wait_from(m, "Spielstand in Slot", 12))
    saved = open(os.path.join(TMP, "cal_learned", "manual1.save"),
                 encoding="utf-8").read()
    r.check("Save: cal + help + save kosten 60 Tokens",
            "TOKENS_CUR=940" in saved)
    r.check("Save: cal 10 EXP + help 1 + save 1", "EXP=12" in saved)
    # Die Uhr kann zwischen Laden und Eingabe eine Spielminute weiter sein;
    # entscheidend ist, dass die 24 Spielstunden (mind. 1440) gesichert sind.
    cal_saved = next((ln for ln in saved.splitlines()
                      if ln.startswith("CAL_UNTIL_MIN=")), "")
    cal_until = int(cal_saved.split("=", 1)[1]) if cal_saved else -1
    r.check("Save: Anzeigedauer ist gesichert (>= 1440 Spielminuten)",
            cal_until >= 1440, "  CAL_UNTIL_MIN=%d" % cal_until)

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

# ================================================== §3 Ablauf & erneut
# Kurz vor Ablauf laden: Das Datum ist noch da (26.01.240, weil der
# Starttag um 06:00 beginnt und inzwischen Mitternacht vorbei ist).
scalars = dict(BASE)
scalars["WORLD_SECS"] = 3597
scalars["CAL_UNTIL_MIN"] = 1440
with start("cal_expiry", scalars, learn=LEARNED_ALL + ["cal"]) as s:
    r = Report("3) Ablauf nach 24 Spielstunden")
    r.check("Spielstand geladen", s.wait("Spielstand geladen", 20))
    r.check("aktives Datum wird beim Laden gezeigt",
            "26.01.240" in top_line(s))

    # Die Uhr tickt im Leerlauf; nach wenigen echten Sekunden ist die
    # 24. Spielstunde erreicht und das Datum muss verschwinden.
    s.drain(5.0)
    r.check("Datum verschwindet nach 24 Spielstunden",
            "26.01.240" not in top_line(s))

    m = s.mark()
    s.cmd("cal")
    r.check("erneutes cal zeigt das Datum wieder",
            s.wait_from(m, "Kalender: 26.01.240", 12))
    r.check("erneutes cal kostet wieder 50 Tokens",
            s.wait_from(m, "950 / 1000", 8))
    r.check("erneutes cal setzt die Anzeige wieder auf der PFAD-Linie",
            "╡ ◷ 26.01.240 ╞" in top_line(s))

    s.cmd("exit"); s.drain(1.2)
    fails += r.done()

print("\nKalender gesamt:", "OK" if fails == 0 else "%d Fehler" % fails)
sys.exit(1 if fails else 0)
