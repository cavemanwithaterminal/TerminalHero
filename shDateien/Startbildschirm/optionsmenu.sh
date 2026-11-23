# ============================================================
#  TerminalHero - Startbildschirm: Optionsmenü
# ============================================================

OPTIONS_MENU_OPTS=("Startbildschirm" "Zurück")
OPTIONS_MENU_SEL=0
OPTIONS_MENU_STYLE=0

options_menu_draw_bg() {
    local r c
    for ((r = 1; r <= ROWS; r++)); do
        printf '\033[%d;1H' "$r"
        for ((c = 1; c <= COLS; c++)); do
            local val=$(( ((r + c) * 7919) % 23 ))
            case $val in
                0) printf '%s░' "$MUTED" ;;
                1) printf '%s▒' "$FRAME" ;;
                2) printf '%s▓' "$FRAME_HI" ;;
                3) printf '%s.' "$MUTED" ;;
                4) printf '%s:' "$FRAME" ;;
                5) printf '%s+' "$MUTED" ;;
                6) printf '%s*' "$FRAME" ;;
                *) printf ' ' ;;
            esac
        done
    done
    printf '%s' "$RESET"
}
draw_word_opt() {
    local word="$1" top="$2" fcol="$3" frame_w="$4"; shift 4
    local pal=("$@")
    local n=${#word}; local w=$((5 * n + n - 1)); local sc=$(( fcol + (frame_w - w) / 2 ))
    local r j ch glyph
    for ((r = 0; r < 8; r++)); do
        printf '\033[%d;%dH%s' "$((top + r))" "$sc" "$UI_BG"
        for ((j = 0; j < n; j++)); do
            ch="${word:j:1}"; glyph=$(font_row "$ch" "$r"); printf '%s%s' "${pal[j % ${#pal[@]}]}" "$glyph"; (( j < n - 1 )) && printf ' '
        done
        printf '%s' "$RESET"
        printf '\033[%d;%dH%s║%s' "$((top + r))" "$fcol" "$UI_BG$FRAME" "$RESET"
        printf '\033[%d;%dH%s║%s' "$((top + r))" "$((fcol + frame_w - 1))" "$UI_BG$FRAME" "$RESET"
    done
}
options_menu_orig_header() {
    local word1="TERMINAL" word2="HERO"
    local fcol=$(( (COLS - 60) / 2 )); [ "$fcol" -lt 1 ] && fcol=1
    local r_top=2
    local frame_w=60 frame_h=$((2 + 8 + 8))
    local notch="╡ ▓ TERMINAL·HERO ▓ ╞"
    local rem=$((58 - ${#notch})); [ "$rem" -lt 0 ] && rem=0
    printf '\033[%d;%dH%s%s%s%s' "$r_top" "$fcol" "$UI_BG$FRAME" "╔${notch}$(repeat '═' "$rem")╗" "$RESET"
    printf '\033[%d;%dH%s%s%s%s' "$((r_top + frame_h - 1))" "$fcol" "$UI_BG$FRAME" "╚$(repeat '═' 58)╝" "$RESET"
    local pal1=("$FRAME" "$FRAME" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI")
    local pal2=("$TITLE" "$WARN" "$WARN" "$DANGER")
    draw_word_opt "$word1" "$((r_top + 1))" "$fcol" "$frame_w" "${pal1[@]}"
    draw_word_opt "$word2" "$((r_top + 1 + 8))" "$fcol" "$frame_w" "${pal2[@]}"
    local sub="« E I N   T E R M I N A L - A B E N T E U E R »"
    local ucol=$(( (COLS - ${#sub}) / 2 )); [ "$ucol" -lt 1 ] && ucol=1
    printf '\033[%d;%dH%s%s%s%s' "$((r_top + frame_h + 1))" "$ucol" "$UI_BG$TITLE" "$sub" "$RESET"
}

options_menu_load_style() {
    local cfg="${PROJ_DIR:-.}/saves/.startscreen_style"
    [ -f "$cfg" ] && read -r STARTSCREEN_STYLE < "$cfg" 2>/dev/null
    case "${STARTSCREEN_STYLE:-0}" in
        0|1|2) : ;;
        *) STARTSCREEN_STYLE=0 ;;
    esac
    OPTIONS_MENU_STYLE=$STARTSCREEN_STYLE
}
options_menu_save_style() {
    local cfg="${PROJ_DIR:-.}/saves/.startscreen_style"
    mkdir -p "$(dirname "$cfg")" 2>/dev/null
    printf '%s\n' "${STARTSCREEN_STYLE:-0}" > "$cfg" 2>/dev/null
}
options_menu() {
    local styles=( "Original" "Elaboriert" "Elaboriert mit Hintergrund" )
    options_menu_load_style
    OPTIONS_MENU_STYLE=${STARTSCREEN_STYLE:-0}
    [ "$OPTIONS_MENU_STYLE" -lt 0 ] && OPTIONS_MENU_STYLE=0
    [ "$OPTIONS_MENU_STYLE" -gt 2 ] && OPTIONS_MENU_STYLE=2

    while true; do
        printf '%s' "$UI_BG"
        if [ "${STARTSCREEN_STYLE:-2}" = "0" ]; then clear
        elif [ "${STARTSCREEN_STYLE:-2}" = "1" ]; then clear
        else clear; options_menu_draw_bg; fi
        update_size

        local start_row=2
        if [ "${STARTSCREEN_STYLE:-2}" = "0" ]; then
            options_menu_orig_header
            start_row=24
        else
            local art=(
"████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗         ██╗  ██╗███████╗██████╗  ██████╗ "
"╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║         ██║  ██║██╔════╝██╔══██╗██╔═══██╗"
"   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║         ███████║█████╗  ██████╔╝██║   ██║"
"   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║         ██╔══██║██╔══╝  ██╔══██╗██║   ██║"
"   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗    ██║  ██║███████╗██║  ██║╚██████╔╝"
"   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ "
            )
            local art_rows=${#art[@]}
            start_row=2
            local dec1="╔$(repeat '═' 100)╗"
            local dec2="╚$(repeat '═' 100)╝"
            local dcol=$(( (COLS - ${#dec1}) / 2 )); [ "$dcol" -lt 1 ] && dcol=1
            printf '\033[%d;%dH%s%s%s%s' "$start_row" "$dcol" "$UI_BG$FRAME" "$dec1" "$RESET"; start_row=$((start_row + 1))
            local r
            for r in "${!art[@]}"; do
                local line="${art[$r]}"; local acol=$(( (COLS - ${#line}) / 2 )); [ "$acol" -lt 1 ] && acol=1
                if [ $r -le 1 ]; then printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$DANGER" "$line" "$RESET"
                elif [ $r -le 3 ]; then printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$WARN" "$line" "$RESET"
                elif [ $r -eq 4 ]; then printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$TITLE" "$line" "$RESET"
                else printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$ACCENT" "$line" "$RESET"; fi
            done
            start_row=$((start_row + art_rows))
            printf '\033[%d;%dH%s%s%s%s' "$start_row" "$dcol" "$UI_BG$FRAME" "$dec2" "$RESET"; start_row=$((start_row + 2))
            local sub="▓▒░  O P T I O N E N   ░▒▓"; local scol=$(( (COLS - ${#sub}) / 2 )); [ "$scol" -lt 1 ] && scol=1
            printf '\033[%d;%dH%s%s%s%s' "$start_row" "$scol" "$UI_BG$TITLE$BOLD" "$sub" "$RESET"; start_row=$((start_row + 3))
        fi

        local row=$((start_row))
        if [ "${OPTIONS_MENU_SEL}" -eq 0 ]; then
            local line="╔══[ Startbildschirm:  ◄ ${styles[$OPTIONS_MENU_STYLE]} ► ]════════════════════════════════════════╗"
            local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$DANGER$BOLD" "$line" "$RESET"
        else
            local line="    Startbildschirm:        ${styles[$OPTIONS_MENU_STYLE]}        "
            local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$MUTED" "$line" "$RESET"
        fi
        row=$((row + 2))
        if [ "${OPTIONS_MENU_SEL}" -eq 1 ]; then
            local line="╔══[ ▸ Zurück ◂ ]═══════════════════════════════════════════════════════════════════════╗"
            local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$DANGER$BOLD" "$line" "$RESET"
        else
            local line="    [ Zurück ]"
            local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$MUTED" "$line" "$RESET"
        fi

        local hint="↑/↓ Navigieren   ·   ←/→ Ändern   ·   Enter/ESC Zurück"
        printf '\033[%d;%dH%s%s%s%s' "$((ROWS - 1))" "$(( (COLS - ${#hint}) / 2 ))" "$UI_BG$MUTED" "$hint" "$RESET"

        read_key
        local key="$LAST_KEY"
        case "$key" in
            $'\x1b[A'|$'\x1bOA') OPTIONS_MENU_SEL=$(( (OPTIONS_MENU_SEL - 1 + 2) % 2 )); play_sound move ;;
            $'\x1b[B'|$'\x1bOB') OPTIONS_MENU_SEL=$(( (OPTIONS_MENU_SEL + 1) % 2 )); play_sound move ;;
            $'\x1b[D'|$'\x1bOD')
                if [ "${OPTIONS_MENU_SEL}" -eq 0 ]; then
                    OPTIONS_MENU_STYLE=$(( (OPTIONS_MENU_STYLE - 1 + 3) % 3 ))
                    STARTSCREEN_STYLE=$OPTIONS_MENU_STYLE
                    options_menu_save_style
                    play_sound move
                fi ;;
            $'\x1b[C'|$'\x1bOC')
                if [ "${OPTIONS_MENU_SEL}" -eq 0 ]; then
                    OPTIONS_MENU_STYLE=$(( (OPTIONS_MENU_STYLE + 1) % 3 ))
                    STARTSCREEN_STYLE=$OPTIONS_MENU_STYLE
                    options_menu_save_style
                    play_sound move
                fi ;;
            $'\n'|$'\r')
                if [ "${OPTIONS_MENU_SEL}" -eq 1 ]; then return 0; fi ;;
            'q'|'Q'|$'\x1b') return 0 ;;
        esac
    done
}
