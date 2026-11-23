# ============================================================
#  TerminalHero - Startbildschirm: Lade-Untermenü
# ============================================================

LOAD_BW=64
LOAD_CHOICE=""
LOAD_LABELS=("Quicksave" "Spielstand 1" "Spielstand 2" "Spielstand 3")
LOAD_KINDS=("quick" "manual1" "manual2" "manual3")

init_screen() {   # $1 = Kopfzeile, $2 = Statuszeile
    printf '%s' "$UI_BG"; clear
    printf '\n'
    print_centered "$1" "$ACCENT"
    print_centered "$2" "$TITLE"
    local i
    for i in 1 2 3; do
        print_centered "▓▒░" "$GOOD"
        sleep 0.35
    done
    play_sound online
    sleep 0.4
    printf '\033[0m'
    clear
}
menu_box_line() {   # $1 = sichtbarer Inhalt (ohne Rahmen), $2 = Farbe
    local text="$1" color="${2:-$FG}"
    local inner=$((LOAD_BW - 2)) len=${#text}
    [ "$len" -gt "$inner" ] && { text="${text:0:$inner}"; len=$inner; }
    print_centered "║${text}$(repeat ' ' $((inner - len)))║" "$color"
}
draw_load_menu_bg() {
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
draw_word_load() {
    local word="$1" top="$2" fcol="$3" frame_w="$4"; shift 4
    local pal=("$@")
    local n=${#word}; local w=$((5 * n + n - 1)); local sc=$(( fcol + (frame_w - w) / 2 ))
    local r j ch glyph
    for ((r = 0; r < FONT_ROWS; r++)); do
        printf '\033[%d;%dH%s' "$((top + r))" "$sc" "$UI_BG"
        for ((j = 0; j < n; j++)); do
            ch="${word:j:1}"; glyph=$(font_row "$ch" "$r"); printf '%s%s' "${pal[j % ${#pal[@]}]}" "$glyph"; (( j < n - 1 )) && printf ' '
        done
        printf '%s' "$RESET"
        printf '\033[%d;%dH%s║%s' "$((top + r))" "$fcol" "$UI_BG$FRAME" "$RESET"
        printf '\033[%d;%dH%s║%s' "$((top + r))" "$((fcol + frame_w - 1))" "$UI_BG$FRAME" "$RESET"
    done
}
draw_load_menu_orig_header() {
    local word1="TERMINAL" word2="HERO"
    local fcol=$(( (COLS - 60) / 2 )); [ "$fcol" -lt 1 ] && fcol=1
    local r_top=2
    local frame_w=60 frame_h=$((2 + FONT_ROWS + FONT_ROWS))
    local notch="╡ ▓ TERMINAL·HERO ▓ ╞"
    local rem=$((58 - ${#notch})); [ "$rem" -lt 0 ] && rem=0
    printf '\033[%d;%dH%s%s%s%s' "$r_top" "$fcol" "$UI_BG$FRAME" "╔${notch}$(repeat '═' "$rem")╗" "$RESET"
    printf '\033[%d;%dH%s%s%s%s' "$((r_top + frame_h - 1))" "$fcol" "$UI_BG$FRAME" "╚$(repeat '═' 58)╝" "$RESET"
    local pal1=("$FRAME" "$FRAME" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI")
    local pal2=("$TITLE" "$WARN" "$WARN" "$DANGER")
    draw_word_load "$word1" "$((r_top + 1))" "$fcol" "$frame_w" "${pal1[@]}"
    draw_word_load "$word2" "$((r_top + 1 + FONT_ROWS))" "$fcol" "$frame_w" "${pal2[@]}"
    local sub="« E I N   T E R M I N A L - A B E N T E U E R »"
    local ucol=$(( (COLS - ${#sub}) / 2 )); [ "$ucol" -lt 1 ] && ucol=1
    printf '\033[%d;%dH%s%s%s%s' "$((r_top + frame_h + 1))" "$ucol" "$UI_BG$TITLE" "$sub" "$RESET"
}
draw_load_menu() {   # $1 = ausgewählter Index
    local sel="$1"
    local st="${STARTSCREEN_STYLE:-2}"
    printf '%s' "$UI_BG"
    if [ "$st" = "0" ]; then
        clear
    elif [ "$st" = "1" ]; then
        clear
    else
        clear
        draw_load_menu_bg
    fi
    update_size

    local art_rows=0
    if [ "$st" = "0" ]; then
        draw_load_menu_orig_header
        art_rows=20
    elif [ "$st" != "0" ]; then
        local art=(
"████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗         ██╗  ██╗███████╗██████╗  ██████╗ "
"╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║         ██║  ██║██╔════╝██╔══██╗██╔═══██╗"
"   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║         ███████║█████╗  ██████╔╝██║   ██║"
"   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║         ██╔══██║██╔══╝  ██╔══██╗██║   ██║"
"   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗    ██║  ██║███████╗██║  ██║╚██████╔╝"
"   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ "
        )
        art_rows=${#art[@]}
        local start_row=$(( 2 ))
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
        printf '\033[%d;%dH%s%s%s%s' "$start_row" "$dcol" "$UI_BG$FRAME" "$dec2" "$RESET"
    fi

    # Die Spielstand-Box sitzt in allen Stilen auf derselben Höhe wie im
    # Original (Zeile 24) - nicht direkt unter dem Artwork.
    local menu_start=24
    local title=" S P I E L   L A D E N "
    local rem=$(( (LOAD_BW - 2) - ${#title} ))
    local l rr
    l=$((rem / 2)); rr=$((rem - l))
    printf '\033[%d;%dH%s%s%s%s' "$menu_start" "$(( (COLS - LOAD_BW) / 2 ))" "$UI_BG$FRAME" "╔$(repeat '═' $l)${title}$(repeat '═' $rr)╗" "$RESET"
    menu_start=$((menu_start + 1))
    local row i kind label info when who ag avail
    menu_box_line_at() { local rt="$1" text="$2" color="${3:-$FG}"; local inner=$((LOAD_BW - 2)) len=${#text}; [ "$len" -gt "$inner" ] && { text="${text:0:$inner}"; len=$inner; }; printf '\033[%d;%dH%s%s%s%s' "$rt" "$(( (COLS - LOAD_BW) / 2 ))" "$UI_BG$FRAME" "║${text}$(repeat ' ' $((inner - len)))║" "$RESET"; }
    row="$menu_start"; menu_box_line_at "$row" "" "$FRAME"; row=$((row+1))
    for i in 0 1 2 3; do
        kind="${LOAD_KINDS[i]}"; label="${LOAD_LABELS[i]}"
        if th_have_save "$kind"; then
            info="$(th_save_info "$kind")"; when="${info%%|*}"; info="${info#*|}"; who="${info%%|*}"; ag="${info#*|}"; ag="${ag%%|*}"; when="${when%:*}"; avail=1
        else
            when=""; who=""; ag=""; avail=0
        fi
        if [ "$i" -eq "$sel" ] && [ "$avail" = "1" ]; then
            menu_box_line_at "$row" "   ▐► ${label} ◄▌" "$FRAME_HI$BOLD"; row=$((row+1))
            menu_box_line_at "$row" "    ${when}   ·   ${who}   ·   ${ag}" "$FG"; row=$((row+1))
        elif [ "$i" -eq "$sel" ]; then
            menu_box_line_at "$row" "   ▐► ${label} ◄▌" "$FRAME_HI"; row=$((row+1))
            menu_box_line_at "$row" "      – noch kein Speicherstand –" "$MUTED"; row=$((row+1))
        else
            menu_box_line_at "$row" "      ${label}" "$MENU_C"; row=$((row+1))
            if [ "$avail" = "1" ]; then menu_box_line_at "$row" "    ${when}   ·   ${who}   ·   ${ag}" "$MUTED"; row=$((row+1))
            else menu_box_line_at "$row" "      – noch kein Speicherstand –" "$MUTED"; row=$((row+1)); fi
        fi
        menu_box_line_at "$row" "" "$FRAME"; row=$((row+1))
    done
    printf '\033[%d;%dH%s%s%s%s' "$row" "$(( (COLS - LOAD_BW) / 2 ))" "$UI_BG$FRAME" "╚$(repeat '═' $((LOAD_BW - 2)))╝" "$RESET"
    printf '\033[%d;%dH%s%s%s%s' "$((row + 1))" "$(( (COLS - 48) / 2 ))" "$UI_BG$TITLE" "↑/↓ Navigieren   ·   Enter Laden   ·   Q/Esc zurück" "$RESET"
}
load_menu() {
    LOAD_CHOICE=""
    local sel=0 kind
    while true; do
        draw_load_menu "$sel"
        read_key
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') ((sel--)); [ "$sel" -lt 0 ] && sel=3; play_sound move ;;
            $'\x1b[B'|$'\x1bOB') ((sel++)); [ "$sel" -gt 3 ] && sel=0; play_sound move ;;
            $'\n'|$'\r')
                kind="${LOAD_KINDS[sel]}"
                if th_have_save "$kind"; then
                    LOAD_CHOICE="$kind"
                    return 0
                fi
                play_sound error ;;
            'q'|'Q'|$'\x1b') LOAD_CHOICE=""; return 1 ;;
        esac
    done
}
