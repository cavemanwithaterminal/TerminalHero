# ============================================================
#  TerminalHero - Spiel-Befehl: save
#
#  Öffnet ein Speicherfenster zur Auswahl von Slot 1-3.
#  Autosave/Quicksave ist hier nicht wählbar.
# ============================================================

save_slot_label() {   # $1 = manual1|manual2|manual3
    case "$1" in
        manual1) printf 'Slot 1' ;;
        manual2) printf 'Slot 2' ;;
        manual3) printf 'Slot 3' ;;
        *) printf '%s' "$1" ;;
    esac
}

save_draw_menu() {   # $1 = ausgewählter Index (0..2)
    local sel="${1:-0}"
    overlay_geom
    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER" ix=$((px+1))
    local slots=(manual1 manual2 manual3)
    local i slot label info when who ag status line col marker

    clear_region "$((py + 1))" "$ix" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"

    # Text/Elemente an exakt berechneter Spalte zentrieren (innerhalb des Kastens).
    local txt sep tcol slen
    txt='◤  SPIELSTAND SPEICHERN  ◢'
    tcol=$(( ix + (inner - ${#txt}) / 2 )); [ "$tcol" -lt "$ix" ] && tcol="$ix"
    put_text "$((py + 2))" "$tcol" "${#txt}" "$txt" "$TITLE$BOLD"

    sep="$(repeat '─' $((inner - 8)))"
    [ "${#sep}" -lt 10 ] && sep="$(repeat '─' $((inner - 2)))"
    tcol=$(( ix + (inner - ${#sep}) / 2 )); [ "$tcol" -lt "$ix" ] && tcol="$ix"
    put_text "$((py + 3))" "$tcol" "${#sep}" "$sep" "$FRAME"

    txt='Wähle einen Speicherplatz (Autosave nicht wählbar).'
    if [ "${#txt}" -gt "$inner" ]; then txt="${txt:0:$inner}"; fi
    tcol=$(( ix + (inner - ${#txt}) / 2 )); [ "$tcol" -lt "$ix" ] && tcol="$ix"
    put_text "$((py + 5))" "$tcol" "${#txt}" "$txt" "$MUTED"

    local row=$((py + 7))
    for i in 0 1 2; do
        slot="${slots[$i]}"
        label="$(save_slot_label "$slot")"
        status="– leer –"; when=""; who=""; ag=""
        if th_have_save "$slot"; then
            info="$(th_save_info "$slot" 2>/dev/null || true)"
            when="${info%%|*}"; info="${info#*|}"; who="${info%%|*}"; ag="${info#*|}"; ag="${ag%%|*}"
            when="${when%:*}"
            status="${when} · ${who} · ${ag}"
        fi
        # Einheitlicher Einzug, damit "Slot X" immer an gleicher Stelle steht.
        if [ "$i" -eq "$sel" ]; then
            col="$ACCENT$BOLD"; marker="▸ ${label}"
        else
            col="$FG"; marker="  ${label}"
        fi
        tcol=$(( ix + (inner - ${#marker}) / 2 )); [ "$tcol" -lt "$ix" ] && tcol="$ix"
        put_text "$row" "$tcol" "${#marker}" "$marker" "$col"
        if [ "${#status}" -gt "$inner" ]; then status="${status:0:$inner}"; fi
        tcol=$(( ix + (inner - ${#status}) / 2 )); [ "$tcol" -lt "$ix" ] && tcol="$ix"
        put_text "$((row + 1))" "$tcol" "${#status}" "$status" "$MUTED"
        row=$((row + 3))
    done

    txt='↑/↓ wählen  ·  Enter speichern  ·  Esc/Q abbrechen'
    if [ "${#txt}" -gt "$inner" ]; then txt="${txt:0:$inner}"; fi
    tcol=$(( ix + (inner - ${#txt}) / 2 )); [ "$tcol" -lt "$ix" ] && tcol="$ix"
    put_text "$((py + ph - 2))" "$tcol" "${#txt}" "$txt" "$MENU_C"

    # Seitenränder des Rahmens sicher nachziehen (saubere Linien).
    local br
    for ((br = py + 1; br < py + ph - 1; br++)); do
        put_text "$br" "$px" 1 "║" "$FRAME_HI"
        put_text "$br" "$((px + pw - 1))" 1 "║" "$FRAME_HI"
    done
}

save_screen() {
    play_sound select
    printf '%s' "$UI_BG"; clear
    local sel=0
    local slots=(manual1 manual2 manual3)
    local chosen=""
    while true; do
        save_draw_menu "$sel"
        read_key_t "" || { chosen=""; break; }
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') sel=$((sel - 1)); [ "$sel" -lt 0 ] && sel=2 ;;
            $'\x1b[B'|$'\x1bOB') sel=$((sel + 1)); [ "$sel" -gt 2 ] && sel=0 ;;
            $'\n'|$'\r'|'')
                chosen="${slots[$sel]}"
                break ;;
            $'\x1b'|q|Q)
                chosen=""
                break ;;
        esac
    done

    FIRST_RENDER=1
    if [ -z "$chosen" ]; then
        OUT+=("Speichern abgebrochen.")
        return 0
    fi
    if th_save "$chosen"; then
        play_sound select
        OUT+=("")
        OUT+=("» Spielstand in $(save_slot_label "$chosen") gesichert  [$(date '+%H:%M:%S')]")
    else
        play_sound error
        OUT+=("» Speichern fehlgeschlagen – kein Schreibzugriff auf den Speicher?")
    fi
}

builtin_save() {
    if ! knows save; then
        play_sound error
        OUT+=("»save« …? Auch diesen Befehl hat der Virus mir genommen. Noch.")
        return
    fi
    save_screen
}
