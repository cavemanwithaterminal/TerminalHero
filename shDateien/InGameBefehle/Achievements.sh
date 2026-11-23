# ============================================================
#  TerminalHero - Ingame-Befehl: achievements (Errungenschaften)
# ------------------------------------------------------------
#  »achievements« öffnet ein eigenes, vollflächiges Fenster - bewusst
#  NICHT in die 4-Fenster-GUI geladen.
#
#  Angezeigt werden nur bereits freigeschaltete Achievements. Jeder
#  Eintrag hat:
#     - einen Titel
#     - einen kurzen Text
#     - ein kleines ASCII-Bild
#  Die Einträge stehen als kleine, gerahmte Karten im Raster: immer
#  ZWEI nebeneinander, mehrere Reihen passen in das Fenster. Bei mehr
#  Einträgen blättert man mit ↑/↓ seitenweise.
#
#  Neue Achievements melden sich in Achievements/<Name>.sh an:
#     achievement_define <id> "<Titel>" "<Text>" '<ASCII-Bild>'
#     achievement_reward_exp <id> <exp>        (optional)
#     achievement_check_register <prüffunktion>
#  Die Prüffunktion bekommt beim Verlassen eines Ordners zwei Argumente:
#     <alter Pfad> <neuer Pfad>
#  und ruft bei Bedarf achievement_unlock <id> auf.
#
#  Der Befehl wird beim ersten Betreten des Downloads-Ordners gelernt
#  und kostet keine Tokens.
# ============================================================

# ============================================================
#  Register
# ============================================================
declare -ga ACH_ORDER=()          # IDs in Anmelde-Reihenfolge
declare -gA ACH_TITLE=()          # id -> Titel
declare -gA ACH_TEXT=()           # id -> kurzer Text
declare -gA ACH_ART=()            # id -> ASCII-Bild (mehrzeilig)
declare -gA ACH_EXP=()            # id -> EXP-Belohnung beim Freischalten
declare -gA ACH_UNLOCKED=()       # id -> 1, wenn freigeschaltet
declare -ga ACH_DIR_CHECKS=()     # Prüffunktionen für Ordnerwechsel
declare -ga ACH_SHOWN=()          # freigeschaltete IDs (für das Fenster)
ACH_PAGE=0                        # aktuelle Seite im Raster

# Achievement anlegen (idempotent).
achievement_define() {   # $1=id $2=Titel $3=Text $4=ASCII-Bild
    local id="$1"
    [ -n "${ACH_TITLE[$id]:-}" ] && return 0
    ACH_TITLE["$id"]="$2"
    ACH_TEXT["$id"]="$3"
    ACH_ART["$id"]="$4"
    ACH_ORDER+=("$id")
}

# Belohnung in EXP anmelden: achievement_reward_exp <id> <exp>
achievement_reward_exp() {   # $1=id $2=EXP
    [ -n "${1:-}" ] || return 1
    ACH_EXP["$1"]="${2:-0}"
}

# Ist das Achievement freigeschaltet? (0 = ja)
achievement_has() {
    [ "${ACH_UNLOCKED[$1]:-0}" = "1" ]
}

# Alle Errungenschaften für einen neuen Durchlauf zurücksetzen.
# Die Definitionen selbst bleiben registriert.
achievements_reset() {
    ACH_UNLOCKED=()
    ACH_PAGE=0
}

# Prüffunktion für Ordnerwechsel anmelden.
achievement_check_register() {
    [ -n "${1:-}" ] || return 1
    ACH_DIR_CHECKS+=("$1")
}

# Wird von builtin_cd nach einem erfolgreichen Wechsel aufgerufen.
achievements_on_dir_change() {   # $1=alter Pfad $2=neuer Pfad
    local from="$1" to="$2" fn
    # Der Befehl »achievements« wird beim ersten Betreten des
    # Downloads-Ordners gelernt - genau wie »save« ein Stück weiter.
    if [ "$to" = "$HOME_DIR/Downloads" ] \
       && declare -F knows >/dev/null 2>&1 && ! knows achievements; then
        learn_cmd achievements
    fi
    for fn in "${ACH_DIR_CHECKS[@]}"; do
        declare -F "$fn" >/dev/null 2>&1 && "$fn" "$from" "$to"
    done
}

# Achievement freischalten (nur einmal). Die Meldung landet im Dialogfenster.
# Rückgabe 0 = neu freigeschaltet, 1 = unbekannt oder schon vorhanden.
achievement_unlock() {   # $1=id
    local id="$1"
    local exp="${ACH_EXP[$id]:-0}"
    [ -n "${ACH_TITLE[$id]:-}" ] || return 1
    achievement_has "$id" && return 1

    ACH_UNLOCKED["$id"]=1
    declare -F play_sound >/dev/null 2>&1 && play_sound online
    OUT+=("")
    OUT+=("[ ACHIEVEMENT ]  Achievement erhalten: »${ACH_TITLE[$id]}«")
    OUT+=("   ${ACH_TEXT[$id]}")
    if [ "$exp" -gt 0 ] 2>/dev/null; then
        OUT+=("   Belohnung: ${exp} EXP")
        declare -F char_gain_exp >/dev/null 2>&1 && char_gain_exp "$exp"
    fi
    return 0
}

# Freigeschaltete Achievements in Anmelde-Reihenfolge einsammeln.
achievements_build_shown() {
    ACH_SHOWN=()
    local id
    for id in "${ACH_ORDER[@]}"; do
        achievement_has "$id" && ACH_SHOWN+=("$id")
    done
}

# ============================================================
#  Befehls-Eingang (Verdrahtung für TerminalShell.sh)
# ============================================================
achievements_is_command() {
    case "${1,,}" in
        achievements) return 0 ;;
    esac
    return 1
}

achievements_handles() {
    achievements_is_command "$1" || return 1
    if knows achievements; then
        achievements_screen
    else
        play_sound error
        OUT+=("»achievements« …? Nein. Diesen Befehl hat der Virus mir genommen. Noch.")
    fi
    return 0
}

# ============================================================
#  Fenster
# ============================================================
# Eine kleine Achievement-Karte: Titel im Rahmen, links das ASCII-Bild,
# rechts der kurze Text. Die Höhe bleibt am Bild orientiert.
achievements_card() {   # $1=id $2=x $3=y $4=Breite $5=Höhe
    local id="$1" x="$2" y="$3" w="$4" h="$5"
    draw_box "$x" "$y" "$w" "$h" "◈ ${ACH_TITLE[$id]}" "$FRAME"

    local artw=14
    local maxart=$(( w - 2 - 8 ))
    [ "$artw" -gt "$maxart" ] && artw="$maxart"
    [ "$artw" -lt 6 ] && artw=6
    local tx=$(( x + 2 + artw + 2 ))
    local tw=$(( w - 2 - artw - 3 ))
    [ "$tw" -lt 5 ] && tw=5

    # --- Trennlinie zwischen Bild und Text ---
    local sep_x=$(( x + 2 + artw )) sy
    for ((sy = y + 1; sy <= y + h - 2; sy++)); do
        put_text "$sy" "$sep_x" 1 "│" "$FRAME"
    done

    # --- links: ASCII-Bild, vertikal zentriert ---
    local -a art_lines=()
    local line
    while IFS= read -r line; do art_lines+=("$line"); done <<< "${ACH_ART[$id]}"
    local an=${#art_lines[@]} ay=$(( y + 1 ))
    [ "$an" -lt $(( h - 2 )) ] && ay=$(( y + 1 + ((h - 2 - an) / 2) ))
    local a
    for a in "${!art_lines[@]}"; do
        [ "$ay" -gt $(( y + h - 2 )) ] && break
        put_text "$ay" "$(( x + 2 ))" "$artw" "${art_lines[a]}" "$GOOD$BOLD"
        ((ay++))
    done

    # --- rechts: kurzer Text, ebenfalls zentriert ---
    local -a text_lines=()
    while IFS= read -r line; do text_lines+=("$line"); done \
        < <(wrap_line "${ACH_TEXT[$id]}" "$tw")
    local tn=${#text_lines[@]} ty=$(( y + 1 ))
    [ "$tn" -lt $(( h - 2 )) ] && ty=$(( y + 1 + ((h - 2 - tn) / 2) ))
    local t
    for t in "${!text_lines[@]}"; do
        [ "$ty" -gt $(( y + h - 2 )) ] && break
        put_text "$ty" "$tx" "$tw" "${text_lines[t]}" "$FG"
        ((ty++))
    done
}

achievements_paint() {
    overlay_geom
    achievements_build_shown

    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER"
    local ix=$(( px + 1 )) total=${#ACH_SHOWN[@]}

    clear_region "$((py + 1))" "$ix" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
    put_text "$((py + 1))" "$ix" "$inner" \
        "$(center_text '◈  ACHIEVEMENTS  ◈' "$inner")" "$TITLE$BOLD"
    put_text "$((py + 2))" "$ix" "$inner" \
        "$(center_text 'Errungenschaften des Agenten' "$inner")" "$ACCENT"
    put_text "$((py + 3))" "$ix" "$inner" "$(repeat '─' "$inner")" "$FRAME"

    if [ "$total" -eq 0 ]; then
        ACH_PAGE=0
        put_text "$((py + 5))" "$ix" "$inner" \
            "$(center_text '◇       ◇       ◇' "$inner")" "$FRAME"
        put_text "$((py + 7))" "$ix" "$inner" \
            "$(center_text 'Noch keine Achievements erhalten.' "$inner")" "$MUTED"
        put_text "$((py + 9))" "$ix" "$inner" \
            "$(center_text 'Die Stadt hält einige Geschichten bereit.' "$inner")" "$FRAME_HI"
        put_text "$((py + ph - 2))" "$ix" "$inner" \
            "$(center_text 'Esc / Q   ·   zurück zur Shell' "$inner")" "$MENU_C"
        ui_corners "$px" "$py" "$pw" "$ph" "$TITLE" "$FRAME_HI"
        return 0
    fi

    # --- Raster: zwei Karten nebeneinander ---------------------------------
    local area_top=$(( py + 4 ))
    local area_bottom=$(( py + ph - 3 ))
    local area_h=$(( area_bottom - area_top + 1 ))
    local grid_x=$(( px + 2 ))
    local grid_w=$(( inner - 2 ))
    local gap=2
    local cw=$(( (grid_w - gap) / 2 ))
    [ "$cw" -lt 22 ] && cw=22

    # Kartenhöhe: an ASCII-Bild und Text ausrichten, aber bewusst klein
    # halten (nicht die ganze Fensterhöhe ausfüllen).
    local artw=14
    local maxart=$(( cw - 2 - 8 ))
    [ "$artw" -gt "$maxart" ] && artw="$maxart"
    [ "$artw" -lt 6 ] && artw=6
    local tw=$(( cw - 2 - artw - 3 ))
    [ "$tw" -lt 5 ] && tw=5
    local maxlines=5 id line n artn
    for id in "${ACH_SHOWN[@]}"; do
        artn=0
        while IFS= read -r line; do artn=$(( artn + 1 )); done <<< "${ACH_ART[$id]}"
        [ "$artn" -gt "$maxlines" ] && maxlines=$artn
        n=0
        while IFS= read -r line; do n=$(( n + 1 )); done \
            < <(wrap_line "${ACH_TEXT[$id]}" "$tw")
        [ "$n" -gt "$maxlines" ] && maxlines=$n
    done
    local ch=$(( maxlines + 2 ))
    [ "$ch" -lt 7 ]  && ch=7
    [ "$ch" -gt 10 ] && ch=10

    local row_gap=1
    local rows=$(( (area_h + row_gap) / (ch + row_gap) ))
    [ "$rows" -lt 1 ] && rows=1
    local per_page=$(( rows * 2 ))
    local pages=$(( (total + per_page - 1) / per_page ))
    [ "$pages" -lt 1 ] && pages=1
    [ "$ACH_PAGE" -ge "$pages" ] && ACH_PAGE=$(( pages - 1 ))
    [ "$ACH_PAGE" -lt 0 ] && ACH_PAGE=0

    local start=$(( ACH_PAGE * per_page ))
    local end=$(( start + per_page - 1 ))
    [ "$end" -ge "$total" ] && end=$(( total - 1 ))
    local idx col row cx cy
    for (( idx = start; idx <= end; idx++ )); do
        col=$(( (idx - start) % 2 ))
        row=$(( (idx - start) / 2 ))
        cx=$(( grid_x + col * (cw + gap) ))
        cy=$(( area_top + row * (ch + row_gap) ))
        achievements_card "${ACH_SHOWN[idx]}" "$cx" "$cy" "$cw" "$ch"
    done

    # --- Fußzeile: Blättern (falls nötig) und Zähler ----------------------
    local hint='Esc / Q   ·   zurück zur Shell'
    [ "$pages" -gt 1 ] && hint='↑/↓ blättern   ·   Esc/Q zurück'
    put_text "$((py + ph - 2))" "$ix" "$inner" \
        "$(center_text "$hint" "$inner")" "$MENU_C"

    local status
    if [ "$total" -eq 1 ]; then
        status=" ◈ 1 von 1 "
    else
        status=" ◈ $(( start + 1 ))-$(( end + 1 )) von ${total} "
    fi
    put_right "$((py + ph - 2))" "$ix" "$((inner - 1))" "$status" "$ACCENT"
    ui_corners "$px" "$py" "$pw" "$ph" "$TITLE" "$FRAME_HI"
}

achievements_screen() {
    play_sound select
    printf '%s' "$UI_BG"
    clear

    ACH_PAGE=0
    while true; do
        achievements_paint
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA'|$'\x1b[5~')
                [ "$ACH_PAGE" -gt 0 ] && ACH_PAGE=$(( ACH_PAGE - 1 )) ;;
            $'\x1b[B'|$'\x1bOB'|$'\x1b[6~')
                ACH_PAGE=$(( ACH_PAGE + 1 )) ;;
            $'\x1b[H'|$'\x1bOH') ACH_PAGE=0 ;;
            $'\x1b[F'|$'\x1bOF') ACH_PAGE=9999 ;;
            $'\x1b'|q|Q) break ;;
        esac
    done

    FIRST_RENDER=1
    return 0
}
