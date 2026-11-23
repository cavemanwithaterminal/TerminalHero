# ============================================================
#  TerminalHero - Ingame-Befehl: statistics (Spielstatistiken)
# ------------------------------------------------------------
#  »statistics« (Alias: statistik) öffnet ein eigenes,
#  vollflächiges Fenster - bewusst NICHT in die 4-Fenster-GUI geladen.
#
#  Angezeigt werden die ersten Spielstatistiken:
#     - Spielzeit als ECHTE Zeit (nicht In-Game-Zeit)
#     - Hauptquests: erledigt / gescheitert / gesamt
#     - Nebenquests: erledigt / gescheitert / gesamt
#     - Zeitungen: im Besitz / gesamt (Ausgaben, nicht Exemplare)
#     - gesammelte/verdiente Bits (BITS_EARNED, nicht der Kontostand)
#
#  Der Befehl wird am Ende der Baracken-Szene bei Pixi gelernt und
#  kostet keine Tokens.
#  Das Fenster aktualisiert die Spielzeit einmal pro Sekunde.
# ============================================================

# Welche Items zählen als Zeitungs-Ausgaben? Neue Editionen hier ergänzen.
# "Im Besitz" zählt Ausgaben (einmal), nicht gekaufte Exemplare.
declare -ga STATISTICS_NEWSPAPERS=(bezirke sperrzone extraausgabe)

statistics_is_command() {
    case "${1,,}" in
        statistics|statistik) return 0 ;;
    esac
    return 1
}

# Questzahlen für eine Gruppe: $1 = haupt|neben
# Setzt STAT_DONE, STAT_FAILED, STAT_TOTAL (keine Subshell).
statistics_count_quests() {
    local typ="${1:-haupt}" id ids=()
    STAT_DONE=0; STAT_FAILED=0; STAT_TOTAL=0
    if [ "$typ" = "neben" ]; then ids=("${QL_NEBEN[@]}"); else ids=("${QL_HAUPT[@]}"); fi
    STAT_TOTAL=${#ids[@]}
    questlog_refresh
    for id in "${ids[@]}"; do
        case "${QL_STATUS[$id]:-verborgen}" in
            abgeschlossen) STAT_DONE=$(( STAT_DONE + 1 )) ;;
            gescheitert)   STAT_FAILED=$(( STAT_FAILED + 1 )) ;;
        esac
    done
}

statistics_newspapers_owned() {
    local id n=0
    for id in "${STATISTICS_NEWSPAPERS[@]}"; do
        inv_has "$id" && n=$(( n + 1 ))
    done
    printf '%s' "$n"
}

statistics_newspapers_total() {
    printf '%s' "${#STATISTICS_NEWSPAPERS[@]}"
}

# ============================================================
#  Fenster
# ============================================================
statistics_paint() {
    overlay_geom
    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER"
    local ix=$(( px + 1 )) row=$(( py + 3 ))
    local hdone hfail htotal ndone nfail ntotal secs sp=2 hcol ncol
    # Bei sehr niedrigem Fenster (Mindesthöhe 16) die Leerzeilen sparen,
    # damit die Fußzeile nicht auf die letzte Zeile rutscht.
    [ "$ph" -lt 18 ] && sp=1

    statistics_count_quests haupt
    hdone=$STAT_DONE; hfail=$STAT_FAILED; htotal=$STAT_TOTAL
    statistics_count_quests neben
    ndone=$STAT_DONE; nfail=$STAT_FAILED; ntotal=$STAT_TOTAL
    secs="$(playtime_seconds)"
    hcol="$FG"; ncol="$FG"
    [ "$hfail" -gt 0 ] && hcol="$WARN"
    [ "$nfail" -gt 0 ] && ncol="$WARN"
    [ "$hfail" -eq 0 ] && [ "$hdone" -gt 0 ] && hcol="$GOOD"
    [ "$nfail" -eq 0 ] && [ "$ndone" -gt 0 ] && ncol="$GOOD"

    clear_region "$((py + 1))" "$ix" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
    put_text "$((py + 1))" "$ix" "$inner" \
        "$(center_text '◈  STATISTICS  ◈' "$inner")" "$TITLE$BOLD"
    put_right "$((py + 1))" "$ix" "$((inner - 1))" "◈ LIVE " "$MUTED"
    put_text "$((py + 2))" "$ix" "$inner" "$(repeat '─' "$inner")" "$FRAME"

    put_text "$row" "$ix" "$inner" "  ◈ SPIELZEIT" "$TITLE$BOLD"; ((row++))
    put_text "$row" "$ix" "$inner" \
        "    Echtzeit gesamt   $(playtime_text "$secs")" "$FRAME_HI$BOLD"; ((row += sp))

    put_text "$row" "$ix" "$inner" "  ◆ QUESTS" "$TITLE$BOLD"; ((row++))
    put_text "$row" "$ix" "$inner" \
        "  Hauptquests  erledigt ${hdone} · gescheitert ${hfail} · gesamt ${htotal}" "$hcol"; ((row++))
    put_text "$row" "$ix" "$inner" \
        "  Nebenquests  erledigt ${ndone} · gescheitert ${nfail} · gesamt ${ntotal}" "$ncol"; ((row += sp))

    put_text "$row" "$ix" "$inner" "  ▤ DAILYPULSE" "$TITLE$BOLD"; ((row++))
    put_text "$row" "$ix" "$inner" \
        "  Zeitungen    im Besitz $(statistics_newspapers_owned) · gesamt $(statistics_newspapers_total)" "$FRAME_HI"; ((row += sp))

    put_text "$row" "$ix" "$inner" "  ● BITS" "$TITLE$BOLD"; ((row++))
    put_text "$row" "$ix" "$inner" \
        "  Gesammelt    $(bits_total_earned) Bits" "$GOOD$BOLD"

    put_text "$((py + ph - 2))" "$ix" "$inner" \
        "$(center_text 'Esc / Q   ·   zurück zur Shell' "$inner")" "$MENU_C"
    ui_corners "$px" "$py" "$pw" "$ph" "$TITLE" "$FRAME_HI"
}

statistics_screen() {
    play_sound select
    printf '%s' "$UI_BG"
    clear

    while true; do
        statistics_paint
        # 1 s Timeout: die echte Spielzeit läuft sichtbar weiter.
        if ! read_key_t 1; then
            [ "$LAST_KEY_RC" = "2" ] && break      # EOF
            tokens_tick || true
            continue
        fi
        case "$LAST_KEY" in
            $'\x1b'|q|Q) break ;;
        esac
    done

    FIRST_RENDER=1
    return 0
}

statistics_handles() {
    statistics_is_command "$1" || return 1
    if knows statistics; then
        statistics_screen
    else
        play_sound error
        OUT+=("»statistics« …? Nein. Diesen Befehl hat der Virus mir genommen. Noch.")
    fi
    return 0
}
