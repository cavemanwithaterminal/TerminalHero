#!/usr/bin/env bash
# ============================================================
#  TerminalHero - Unit-Tests der Spiel-Logik (ohne TUI/PTY)
# ------------------------------------------------------------
#  Lädt die echten Module aus shDateien/ und prüft die reinen
#  Funktionen: Tokens, Charakter/EXP, erlernte Befehle, Items &
#  Bits, Interior, Stadtteile, Pfade/Sperrzonen, Loader.
#
#  Der Lauf ist organisatorisch in unit/*.sh aufgeteilt. Die Teile
#  werden alphabetisch in DIESER Reihenfolge in derselben Shell
#  geladen; nur so bleiben Variablen, Funktionen und der
#  Fortschritt (PASS/FAIL) über alle Abschnitte erhalten.
# ============================================================
#  Aufruf:  bash Kern/tests/unit.sh
# ============================================================

HERE="$(cd "$(dirname "$0")" && pwd)"
for part in "$HERE"/unit/*.sh; do
    . "$part"
done
