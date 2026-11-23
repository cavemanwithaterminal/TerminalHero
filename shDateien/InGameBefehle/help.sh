# ============================================================
#  TerminalHero - Hilfe
#
#  Zeigt das Hilfe-Fenster (Befehl »help«): ein eigenes, vollflächiges
#  Fenster - bewusst NICHT in die 4-Fenster-Spiel-GUI geladen.
#
#  Die Befehle stehen in ZWEI REITERN (oben, UMSCHALTEN mit ←/→ bzw. Tab):
#     ▸ Terminal-Befehle   echte Shell-Befehle (pwd, ls, cd, cat, touch,
#                          grep, file, clear, cal)
#     ▸ Spiel-Befehle      reine Spiel-Befehle (achievements, character,
#                          exit, questlog, inventar, statistics, use, trade,
#                          save, help)
#  Über der Liste steht ein Hinweis zur Tab-Vervollständigung auf der
#  Kommandozeile.
#  Jeder Reiter zeigt nur seine eigene Gruppe, alphabetisch nach Befehl.
#  Die Liste ist mit ↑/↓ (und Bild↑/Bild↓, Pos1/Ende) scrollbar - sie
#  wird im Lauf der Zeit lang.
#
#  Angezeigt wird nur, was der Agent kennt:
#     "gelernt" -> erst nach dem Erlernen (weiß der Virus genommen)
#     "immer"   -> von Anfang an benutzbar (Menü-Befehle wie character)
#
#  Neue Einträge (z. B. ein Befehl aus einem Stadtteil) melden sich an mit:
#     help_define <cmd> terminal|ingame immer|gelernt "<aufruf>" "<beschreibung>"
#  Optional kann die Beschreibung dynamisch sein:
#     help_desc_<cmd>() { printf '...'; }
#
#  Eingang für den Dispatch in TerminalShell.sh:
#     help_handles <cmd> && continue
#  (enthält auch die Erlernungs-Sperre: erst »help« zurückerobern)
#
#  Nur Funktionsdefinitionen + Register; Zeichenprimitive (put_text,
#  draw_box, clear_region, center_text, put_right, repeat, tab_row,
#  overlay_geom) aus ui.sh.
# ============================================================

# ============================================================
#  Register
# ============================================================
declare -ga HELP_TERM=()     # IDs der Terminal-Befehle (alphabetisch sortiert)
declare -ga HELP_GAME=()     # IDs der Spiel-Befehle (alphabetisch sortiert)
declare -gA HELP_USAGE=()    # id -> Aufruf (z. B. "ls")
declare -gA HELP_DESC=()     # id -> Beschreibung
declare -gA HELP_AVAIL=()    # id -> "gelernt" | "immer"

HELP_TABS=("Terminal-Befehle" "Spiel-Befehle")   # Reiterbeschriftungen
HELP_OFF=(0 0)               # Scrollstand je Reiter (0=Terminal, 1=Spiel)
HELP_ROWS=()                 # sichtbare Einträge des aktuellen Reiters
HELP_CAP=0                   # sichtbare Zeilen (help_draw)
HELP_MAXOFF=0                # maximaler Scroll-Offset (help_draw)

# Befehl anmelden (idempotent):
#   help_define <cmd> <terminal|ingame> <immer|gelernt> "<aufruf>" "<beschreibung>"
help_define() {
    local id="$1" grp="$2" avail="$3" usage="$4" desc="$5"
    [ -n "${HELP_AVAIL[$id]:-}" ] && return 0
    HELP_AVAIL["$id"]="$avail"
    HELP_USAGE["$id"]="$usage"
    HELP_DESC["$id"]="$desc"
    if [ "$grp" = "terminal" ]; then
        HELP_TERM+=("$id")
    else
        HELP_GAME+=("$id")
    fi
}

# Kennt der Agent diesen Befehl? (0 = ja, also im Fenster anzeigen)
help_is_known() {
    case "${HELP_AVAIL[$1]:-}" in
        immer) return 0 ;;
    esac
    knows "$1"
}

# Beschreibung eines Befehls - dynamisch, wenn help_desc_<id> existiert.
help_desc_of() {
    local fn="help_desc_$1"
    if declare -F "$fn" >/dev/null 2>&1; then
        "$fn"
        return 0
    fi
    printf '%s' "${HELP_DESC[$1]}"
}

# Einträge eines Reiters einsammeln: $1 = 0 Terminal / 1 Spiel.
help_build_rows() {
    local tab="${1:-0}"
    local ids=() known=() id
    HELP_ROWS=()
    if [ "$tab" = "1" ]; then ids=("${HELP_GAME[@]}"); else ids=("${HELP_TERM[@]}"); fi
    for id in "${ids[@]}"; do
        help_is_known "$id" || continue
        known+=("$id")
    done
    # Anzeige immer alphabetisch - unabhängig davon, in welcher Reihenfolge
    # Module ihre Befehle per help_define anmelden.
    if [ "${#known[@]}" -gt 1 ]; then
        while IFS= read -r id; do HELP_ROWS+=("$id"); done \
            < <(printf '%s\n' "${known[@]}" | LC_ALL=C sort)
    else
        HELP_ROWS=("${known[@]}")
    fi
}

# Wie viele Befehle dieses Reiters kennt der Agent noch nicht? ("verloren")
help_lost_count() {
    local tab="${1:-0}" ids=() id n=0
    if [ "$tab" = "1" ]; then ids=("${HELP_GAME[@]}"); else ids=("${HELP_TERM[@]}"); fi
    for id in "${ids[@]}"; do
        [ "${HELP_AVAIL[$id]}" = "immer" ] && continue
        help_is_known "$id" || n=$(( n + 1 ))
    done
    printf '%s' "$n"
}

# ============================================================
#  Befehls-Eingang (Verdrahtung für TerminalShell.sh)
# ============================================================
# Ist <wort> der Hilfe-Befehl? (help / hilfe, Groß-/Kleinschreibung egal)
help_is_command() {
    case "${1,,}" in
        help|hilfe) return 0 ;;
    esac
    return 1
}

# Gemauerter Eingang für den Dispatch in TerminalShell.sh:
#      help_handles <cmd> && continue
# Rückgabe 1 = kein Hilfe-Befehl (Zeile läuft normal weiter),
# Rückgabe 0 = behandelt (Fenster geöffnet oder Absage ausgegeben).
# Die Absage (»help« noch nicht wiedererlangt) gehört mit ins Modul.
help_handles() {
    help_is_command "$1" || return 1
    if knows help; then
        help_screen
    else
        play_sound error
        OUT+=("»help« …? Nein. Diesen Befehl hat der Virus mir genommen. Noch.")
    fi
    return 0
}

# ============================================================
#  Fenster
# ============================================================
help_draw() {   # $1 = Reiter (0|1)  (Scrollstand steht in HELP_OFF[$1])
    local tab="${1:-0}"
    overlay_geom
    help_build_rows "$tab"

    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER"
    local ix=$(( px + 1 ))

    clear_region "$((py + 1))" "$ix" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
    put_text "$((py + 1))" "$ix" "$inner" \
        "$(center_text '◤  HILFE  ◢' "$inner")" "$TITLE$BOLD"

    # --- Reiter ---
    tab_row "$((py + 2))" "$((ix + 2))" "$tab" "${HELP_TABS[@]}"
    put_text "$((py + 3))" "$ix" "$inner" "$(repeat '─' "$inner")" "$FRAME"
    put_text "$((py + 4))" "$((ix + 3))" "$((inner - 4))" \
        "Tipp: Tab vervollständigt Befehle und Pfade." "$MUTED"

    # Spaltenbreite für den Aufruf aus allen Einträgen (stabile Ausrichtung).
    local colw=0 e u
    for e in "${HELP_ROWS[@]}"; do
        u="${HELP_USAGE[$e]}"
        [ "${#u}" -gt "$colw" ] && colw="${#u}"
    done
    colw=$(( colw + 4 )); [ "$colw" -gt 28 ] && colw=28; [ "$colw" -lt 12 ] && colw=12

    # Sichtbarer Bereich (ggf. blättern)
    local total=${#HELP_ROWS[@]}
    local cap=$(( ph - 8 )); [ "$cap" -lt 1 ] && cap=1
    local maxoff=$(( total - cap )); [ "$maxoff" -lt 0 ] && maxoff=0
    local off="${HELP_OFF[$tab]:-0}"
    [ "$off" -gt "$maxoff" ] && off="$maxoff"; [ "$off" -lt 0 ] && off=0
    HELP_OFF[$tab]="$off"

    local row=$(( py + 5 )) i id
    if [ "$total" -eq 0 ]; then
        put_text "$row" "$((ix + 3))" "$((inner - 4))" \
            "(in dieser Gruppe noch kein Befehl freigeschaltet)" "$MUTED"
    else
        for ((i = off; i < total && i < off + cap; i++)); do
            id="${HELP_ROWS[i]}"
            put_text "$row" "$((ix + 3))" "$colw" "  ${HELP_USAGE[$id]}" "$FRAME_HI"
            put_text "$row" "$((ix + 3 + colw))" "$(( inner - colw - 4 ))" \
                "$(help_desc_of "$id")" "$FG"
            ((row++))
        done
    fi

    # --- Fußzeile: Bedienung mittig, Zähler rechts ---
    local lost; lost="$(help_lost_count "$tab")"
    local status="bekannt: ${total}"
    [ "$lost" -gt 0 ] && status="bekannt: ${total}  ·  verloren: ${lost}"
    local status_txt=" ${status} "

    local hint
    if [ "$maxoff" -gt 0 ]; then
        hint='←/→ Reiter  ·  ↑/↓ scrollen  ·  Esc/Q zu'
    else
        hint='←/→ Reiter  ·  Esc/Q zurück'
    fi
    local avail=$(( inner - 2 * ${#status_txt} - 2 ))
    if [ "${#hint}" -gt "$avail" ]; then
        hint='←/→ · ↑/↓ · Esc'
        [ "${#hint}" -gt "$avail" ] && { status_txt=""; hint='←/→ · Esc'; }
    fi
    [ "${#hint}" -gt "$inner" ] && hint=''

    put_text "$((py + ph - 2))" "$ix" "$inner" "$(center_text "$hint" "$inner")" "$MENU_C"
    [ -n "$status_txt" ] && put_right "$((py + ph - 2))" "$ix" "$inner" "$status_txt" "$MUTED"

    HELP_CAP=$cap
    HELP_MAXOFF=$maxoff
}

help_screen() {
    play_sound select

    # Eigener Bildschirm: Spiel-GUI komplett überdecken.
    printf '%s' "$UI_BG"
    clear

    local tab=0
    HELP_OFF[0]=0; HELP_OFF[1]=0
    while true; do
        help_draw "$tab"
        read_key_t "" || break
        local off="${HELP_OFF[$tab]:-0}"
        case "$LAST_KEY" in
            $'\x1b[D'|$'\x1bOD') [ "$tab" -gt 0 ] && tab=$(( tab - 1 )) ;;                 # ← Reiter links
            $'\x1b[C'|$'\x1bOC') [ "$tab" -lt $(( ${#HELP_TABS[@]} - 1 )) ] && tab=$(( tab + 1 )) ;;  # → Reiter rechts
            $'\t')               tab=$(( (tab + 1) % ${#HELP_TABS[@]} )) ;;                # Tab weiterschalten
            $'\x1b[A'|$'\x1bOA') [ "$off" -gt 0 ] && off=$(( off - 1 )) ;;                  # hoch
            $'\x1b[B'|$'\x1bOB') [ "$off" -lt "$HELP_MAXOFF" ] && off=$(( off + 1 )) ;;      # runter
            $'\x1b[5~')          off=$(( off - HELP_CAP )); [ "$off" -lt 0 ] && off=0 ;;     # Bild hoch
            $'\x1b[6~')          off=$(( off + HELP_CAP ))                                   # Bild runter
                                 [ "$off" -gt "$HELP_MAXOFF" ] && off="$HELP_MAXOFF" ;;
            $'\x1b[H'|$'\x1bOH') off=0 ;;                                                    # Anfang
            $'\x1b[F'|$'\x1bOF') off="$HELP_MAXOFF" ;;                                       # Ende
            $'\x1b'|q|Q) break ;;                                                            # schließen (Esc oder Q)
        esac
        HELP_OFF[$tab]="$off"
    done

    # Danach die Spiel-GUI vollständig neu aufbauen (Hilfe-Fenster weg).
    FIRST_RENDER=1
    return 0
}

# ============================================================
#  Die Befehle dieser Welt
# ============================================================
help_init() {
    # --- echte Terminal-Befehle (alphabetisch) -------------------------
    help_define cal      terminal gelernt "cal"                   "In-Game-Kalender anzeigen (24 Spielstunden)"
    help_define cat      terminal gelernt "cat <datei>"           "Dateiinhalt anzeigen"
    help_define cd       terminal gelernt "cd .. | cd <pfad>"     "Verzeichnis wechseln"
    help_define clear    terminal gelernt "clear"                 "Bildschirm leeren"
    help_define file     terminal gelernt "file <datei>"          "Metadaten einer Datei anzeigen"
    help_define grep     terminal gelernt "grep <muster> [datei]" "etwas finden – und herausziehen"
    help_define ls       terminal gelernt "ls"                    "Ordnerinhalt rechts anzeigen"
    help_define pwd      terminal gelernt "pwd"                   "Aktuellen Pfad anzeigen"
    help_define rm       terminal gelernt "rm <gegner> [...]"     "Gegner löschen (Kampfbefehl; Waffe nötig)"
    help_define touch    terminal gelernt "touch <datei>"         "mit einer beseelten Datei SPRECHEN"

    # --- reine Spiel-Befehle (alphabetisch) -----------------------------
    # character/questlog/inventar/help bringt der General im Tutorial bei -> "gelernt".
    # »achievements« lernt man beim ersten Betreten der Downloads, »statistics«
    # am Ende der Baracken-Szene bei Pixi.
    help_define achievements ingame gelernt "achievements"         "Errungenschaften anzeigen"
    help_define archive   ingame gelernt "archive"                "Archiv freigeschalteter Kapitelbilder öffnen"
    help_define character ingame gelernt "character"              "Charakterbogen öffnen (Level, EXP, Tokens)"
    help_define exit      ingame immer   "exit"                   "Agent herunterfahren (Spiel verlassen)"
    help_define help      ingame gelernt "help"                   "Diese Hilfe"
    help_define inventar  ingame gelernt "inventar | inventory"   "Inventar öffnen (6 Reiter)"
    help_define questlog  ingame gelernt "questlog"               "Questlog öffnen (Haupt-/Nebenquests)"
    help_define save      ingame gelernt "save"                   "Spielstand manuell speichern"
    help_define search    ingame gelernt "search <objekt>"       "Objekt durchsuchen (z. B. eine Leiche)"
    help_define statistics ingame gelernt "statistics | statistik"  "Spielstatistiken anzeigen"
    help_define trade     ingame gelernt "trade <händler>"        "Handeln (nur mit jemandem im selben Ordner)"
    help_define use       ingame gelernt "use <objekt>"           "Objekt benutzen (z. B. schlafen oder sitzen)"
}

# »touch« spricht Gegenstände an und kann erst nach dem Erlernen auch
# Dateien anlegen.
help_desc_touch() {
    if [ "${TOUCH_CREATE_KNOWN:-0}" = "1" ]; then
        printf 'Datei anlegen – oder mit ihr SPRECHEN'
    else
        printf 'beseelte Datei/Gegenstand ansprechen'
    fi
}

help_init
