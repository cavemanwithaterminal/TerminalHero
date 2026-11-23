# ============================================================
#  TerminalHero - .sh-Dateien-Manager (Loader)
#
#  Lädt Spiel-Dateien BEDARFSGERECHT und IDEMPOTENT per "source"
#  (kein eigener Prozess). So bleibt jede Datei klein, und nichts
#  wird geladen, was gerade nicht gebraucht wird.
#
#  Wird von TerminalHero.sh (Startbildschirm) UND TerminalShell.sh
#  (In-Game-Shell) genutzt. Setzt voraus, dass SCRIPT_DIR = shDateien/
#  gesetzt ist; SONST wird es aus dem Speicherort dieser Datei
#  abgeleitet. Projektwurzel (assets/, saves/) = eine Ebene darüber.
#
#  Zentrale Aufrufe:
#    require_kern <name>       lädt kern/<name>.sh        (Engine)
#    require_termcmd <name>    lädt TerminalBefehle/<name>.sh
#    require_gamecmd <name>    lädt InGameBefehle/<name>.sh
#    require_char <name>       lädt Charakter/<name>.sh
#    require_ort <name>        lädt Orte/<name>.sh
#    require_quest <name>      lädt Quests/<name>.sh
#    require_gegner <name>     lädt Gegner/<name>.sh
#    require_tut <name>        lädt Tutorial/<name>.sh
#    require_start <name>      lädt Startbildschirm/<name>.sh
#    require_items             lädt Items/, NutzbareItems/ und GegnerLoot/
#    require_achievements      lädt alle Achievements/<Name>.sh
#    th_source_once <pfad>     lädt eine beliebige Datei genau einmal
#    th_source_if_fn <fn>      lädt die Datei, die <fn> bereitstellt
#    th_load_cmd <wort>        lädt die Datei eines Befehls (Aliase aufgelöst)
#    th_canon_cmd <wort>       kanonischer Befehlsname (Alias -> Name)
# ============================================================

TH_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# WICHTIG für alle nachzuladenden Dateien:
#   Variablen, die eine Datei auf oberster Ebene anlegt, MÜSSEN mit
#   "declare -g..." deklariert werden (z. B. declare -gA FONT=()).
#   Grund: th_source_once führt "source" INNERHALB einer Funktion aus.
#   Ein einfaches "declare -A X" wäre dort nur FUNKTIONS-LOKAL und nach
#   dem Laden wieder weg. "declare -g" erzwingt den globalen Namensraum.

# Schon geladene Dateien (Pfad -> 1).
declare -gA TH_SOURCED=()

# Lädt <pfad> genau einmal. Rückgabe 0 = geladen/vorhanden, 1 = fehlt.
th_source_once() {
    local f="$1"
    [ -n "${f:-}" ] || return 1
    [ -n "${TH_SOURCED[$f]:-}" ] && return 0
    [ -f "$f" ] || return 1
    # shellcheck disable=SC1090
    . "$f"
    TH_SOURCED["$f"]=1
    return 0
}

# Unterordner
th_dir_kern()    { printf '%s/kern' "$TH_DIR"; }
th_dir_termcmd() { printf '%s/TerminalBefehle' "$TH_DIR"; }
th_dir_gamecmd() { printf '%s/InGameBefehle' "$TH_DIR"; }
th_dir_char()    { printf '%s/Charakter' "$TH_DIR"; }
th_dir_ort()     { printf '%s/Orte' "$TH_DIR"; }
th_dir_quest()   { printf '%s/Quests' "$TH_DIR"; }
th_dir_gegner()  { printf '%s/Gegner' "$TH_DIR"; }
th_dir_tut()     { printf '%s/Tutorial' "$TH_DIR"; }
th_dir_start()   { printf '%s/Startbildschirm' "$TH_DIR"; }
th_dir_items()   { printf '%s/Items' "$TH_DIR"; }
th_dir_nutzitems(){ printf '%s/NutzbareItems' "$TH_DIR"; }
th_dir_gegnerloot(){ printf '%s/GegnerLoot' "$TH_DIR"; }
th_dir_interior(){ printf '%s/Interior' "$TH_DIR"; }
th_dir_ach()     { printf '%s/Achievements' "$TH_DIR"; }

require_kern()    { th_source_once "$(th_dir_kern)/$1.sh"; }
require_termcmd() { th_source_once "$(th_dir_termcmd)/$1.sh"; }
require_gamecmd() { th_source_once "$(th_dir_gamecmd)/$1.sh"; }
require_char()    { th_source_once "$(th_dir_char)/$1.sh"; }
require_ort()     { th_source_once "$(th_dir_ort)/$1.sh"; }
require_quest()   { th_source_once "$(th_dir_quest)/$1.sh"; }
require_gegner()  { th_source_once "$(th_dir_gegner)/$1.sh"; }
require_tut()     { th_source_once "$(th_dir_tut)/$1.sh"; }
require_start()   { th_source_once "$(th_dir_start)/$1.sh"; }

# Alle Items der Welt laden: Items/<Kategorie>/<Item>.sh, die
# benutzbaren Gegenstände in NutzbareItems/**/*.sh und die Beute aus
# GegnerLoot/**/*.sh (alphabetisch, deterministisch; Unterordner wie
# NutzbareItems/Zeitungen/ sind erlaubt). Jede Datei meldet ihr Item per
# item_define an (siehe kern/items.sh). Genau einmal geladen (th_source_once).
require_items() {
    local d f
    for d in "$(th_dir_items)" "$(th_dir_nutzitems)" "$(th_dir_gegnerloot)"; do
        [ -d "$d" ] || continue
        while IFS= read -r f; do th_source_once "$f"; done \
            < <(find "$d" -name '*.sh' 2>/dev/null | sort)
    done
    return 0
}

# Alle Interior-Objekte der Welt laden: Interior/<Kategorie>/<Objekt>.sh
# (alphabetisch, deterministisch). Jede Datei meldet ihr Objekt per
# interior_define an (siehe kern/interior.sh). Genau einmal geladen.
require_interior() {
    local d f
    d="$(th_dir_interior)"
    [ -d "$d" ] || return 0
    while IFS= read -r f; do th_source_once "$f"; done \
        < <(find "$d" -name '*.sh' 2>/dev/null | sort)
    return 0
}

# Alle Achievements der Welt laden: Achievements/<Name>.sh
# (alphabetisch, deterministisch). Jede Datei meldet ihr Achievement per
# achievement_define an (siehe InGameBefehle/Achievements.sh). Genau einmal.
require_achievements() {
    local d f
    d="$(th_dir_ach)"
    [ -d "$d" ] || return 0
    while IFS= read -r f; do th_source_once "$f"; done \
        < <(find "$d" -name '*.sh' 2>/dev/null | sort)
    return 0
}

# ============================================================
#  Befehls-Auflösung (Lazy Loading für Terminal-/Spiel-Befehle)
# ------------------------------------------------------------
#  th_canon_cmd <wort>  ->  kanonischer Befehlsname (Aliase aufgelöst)
#  th_load_cmd  <wort>  ->  lädt TerminalBefehle/<cmd>.sh bzw.
#                           InGameBefehle/<cmd>.sh (genau einmal)
# ============================================================
th_canon_cmd() {
    case "${1,,}" in
        hilfe)               printf 'help' ;;
        charakter)           printf 'character' ;;
        quests)              printf 'questlog' ;;
        inventory|inv|inventur) printf 'inventar' ;;
        speichern)           printf 'save' ;;
        statistik)           printf 'statistics' ;;
        cd..|cd.)            printf 'cd' ;;
        quit|logout|beenden) printf 'exit' ;;
        *)                   printf '%s' "${1,,}" ;;
    esac
}

th_load_cmd() {
    local c
    c="$(th_canon_cmd "${1:-}")"
    [ -n "$c" ] || return 1
    th_source_once "$(th_dir_termcmd)/$c.sh" && return 0
    th_source_once "$(th_dir_gamecmd)/$c.sh" && return 0
    return 1
}

# ============================================================
#  Funktions-Index (Funktion -> Datei)
# ------------------------------------------------------------
#  Ermöglicht "lade die Datei, die <fn> bereitstellt", ohne dass
#  jede Zuordnung von Hand gepflegt werden muss. Der Index wird
#  beim ersten Bedarf einmalig aus allen .sh-Dateien gebaut.
# ============================================================
declare -gA TH_FN_FILE=()
TH_FN_INDEX_READY=0

th_build_fn_index() {
    [ "$TH_FN_INDEX_READY" = "1" ] && return 0
    TH_FN_INDEX_READY=1
    local f fn rel
    while IFS= read -r f; do
        rel="${f#"$TH_DIR"/}"
        # Nur Top-Level-Funktionsdefinitionen ("name() {" am Zeilenanfang).
        while IFS= read -r fn; do
            [ -n "$fn" ] && TH_FN_FILE["$fn"]="$rel"
        done < <(grep -oE '^[A-Za-z_][A-Za-z0-9_]*\(\)' "$f" 2>/dev/null | sed 's/()$//')
    done < <(find "$TH_DIR" -name '*.sh' -not -path '*/saves/*' 2>/dev/null)
    return 0
}

# Lädt die Datei, die <fn> bereitstellt (falls die Funktion noch fehlt).
th_source_if_fn() {
    local fn="$1"
    declare -F "$fn" >/dev/null 2>&1 && return 0
    th_build_fn_index
    local rel="${TH_FN_FILE[$fn]:-}"
    [ -n "$rel" ] || return 1
    th_source_once "$TH_DIR/$rel"
}
