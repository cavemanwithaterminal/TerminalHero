# ============================================================
#  TerminalHero - Lesefenster
#
#  Öffnet einen vollflächigen Textbetrachter für Items, die mit
#  item_readable <id> "<text>" angemeldet wurden. Der Einstieg
#  läuft über das Inventar: Item wählen -> Enter/e -> »benutzen«.
#
#  Das Fenster ist scrollbar (↑/↓, Bild↑/Bild↓, Pos1/Ende) und
#  schließt mit Esc oder Q. Die Spiel-GUI wird währenddessen
#  vollständig überdeckt; danach baut das Inventar sein Fenster
#  neu auf.
#
#  Der Text wird wortweise auf die Innenbreite umgebrochen. Leere
#  Zeilen im Artikel bleiben als Absätze erhalten.
#
#  Nur Funktionsdefinitionen; Zeichenprimitive aus kern/ui.sh.
# ============================================================

# Artikeltext in sichtbare Zeilen umbrechen.
#   lesen_build_lines <item-id> <breite>
# Ergebnis: LESEN_LINES (global).
lesen_build_lines() {
    local id="$1" width="$2" text line wrapped
    LESEN_LINES=()
    [ "$width" -lt 8 ] && width=8
    text="$(item_read_text "$id")"
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            LESEN_LINES+=("")
            continue
        fi
        while IFS= read -r wrapped; do
            LESEN_LINES+=("$wrapped")
        done < <(wrap_line "$line" "$width")
    done <<< "$text"
    [ "${#LESEN_LINES[@]}" -gt 0 ] || LESEN_LINES=("(Dieser Text ist leer.)")
}

# Lesefenster zeichnen. $1 = Offset (erste sichtbare Zeile)
lesen_paint() {
    local off="${1:-0}"
    overlay_geom

    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER"
    local ix=$(( px + 1 ))
    local cw=$(( inner - 4 )); [ "$cw" -lt 8 ] && cw=8
    local cx=$(( px + 3 ))

    clear_region "$((py + 1))" "$ix" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"

    # Kopf: Fenstertitel, Itemname, Trennlinie.
    put_text "$((py + 1))" "$ix" "$inner" \
        "$(center_text '◤  LESEN  ◢' "$inner")" "$TITLE$BOLD"
    put_text "$((py + 2))" "$ix" "$inner" \
        "$(center_text "— $(item_name "$LESEN_ID") —" "$inner")" "$ACCENT$BOLD"
    put_text "$((py + 3))" "$ix" "$inner" "$(repeat '─' "$inner")" "$FRAME"

    # Sichtbarer Textbereich: py+4 bis py+ph-3.
    local cap=$(( ph - 6 )); [ "$cap" -lt 1 ] && cap=1
    local total=${#LESEN_LINES[@]}
    local maxoff=$(( total - cap )); [ "$maxoff" -lt 0 ] && maxoff=0
    [ "$off" -gt "$maxoff" ] && off="$maxoff"
    [ "$off" -lt 0 ] && off=0

    local row=$(( py + 4 )) i line
    for ((i = off; i < total && i < off + cap; i++)); do
        line="${LESEN_LINES[i]}"
        put_text "$row" "$cx" "$cw" "$line" "$FG"
        ((row++))
    done

    # Fußzeile: Bedienung mittig, Positionsanzeige rechts (wenn Platz).
    local hint='↑/↓ · Bild↑/↓ · Pos1/Ende · Esc/Q schließen'
    if [ "$inner" -lt 72 ]; then
        hint='↑/↓ · Esc/Q'
    fi
    put_text "$((py + ph - 2))" "$ix" "$inner" \
        "$(center_text "$hint" "$inner")" "$MENU_C"

    local status="" end
    end=$(( off + cap )); [ "$end" -gt "$total" ] && end="$total"
    status=" $((off + 1))-$end/$total "
    if [ "$inner" -ge 86 ] && [ "$total" -gt "$cap" ]; then
        put_right "$((py + ph - 2))" "$ix" "$inner" "$status" "$MUTED"
    fi

    LESEN_CAP=$cap
    LESEN_MAXOFF=$maxoff
    LESEN_OFF=$off
}

# Lesefenster öffnen. $1 = Item-id
lesen_screen() {
    local id="$1"
    item_is_readable "$id" || return 1

    play_sound select
    printf '%s' "$UI_BG"
    clear

    LESEN_ID="$id"
    overlay_geom
    lesen_build_lines "$id" "$(( OV_INNER - 4 ))"

    local off=0
    while true; do
        lesen_paint "$off"
        read_key_t "" || break
        off="$LESEN_OFF"
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') [ "$off" -gt 0 ] && off=$(( off - 1 )) ;;
            $'\x1b[B'|$'\x1bOB') [ "$off" -lt "$LESEN_MAXOFF" ] && off=$(( off + 1 )) ;;
            $'\x1b[5~')          off=$(( off - LESEN_CAP )); [ "$off" -lt 0 ] && off=0 ;;
            $'\x1b[6~')          off=$(( off + LESEN_CAP ))
                                 [ "$off" -gt "$LESEN_MAXOFF" ] && off="$LESEN_MAXOFF" ;;
            $'\x1b[H'|$'\x1bOH') off=0 ;;
            $'\x1b[F'|$'\x1bOF') off="$LESEN_MAXOFF" ;;
            $'\x1b'|q|Q)         break ;;
        esac
    done

    # Optionaler Haken nach dem Lesen: item_on_read_<id>. Er läuft nach
    # dem Schließen des Fensters, damit Quest-/Log-Meldungen nicht von
    # der Vollbildansicht verdeckt werden.
    local read_hook="item_on_read_${id}"
    if declare -F "$read_hook" >/dev/null 2>&1; then
        "$read_hook"
    fi

    FIRST_RENDER=1
    return 0
}
