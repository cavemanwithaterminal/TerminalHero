# ============================================================
#  TerminalHero - Startbildschirm: Hauptmenü-Zeichnung
# ============================================================

OPTIONS=("Spiel starten" "Spiel laden" "Optionen" "Beenden")
SELECTED=0

# Falls nicht gesetzt
[ -z "${STARTSCREEN_STYLE:-}" ] && STARTSCREEN_STYLE=0

draw_screen() {
    case "${STARTSCREEN_STYLE:-0}" in
        0) draw_screen_orig ;;
        1) draw_screen_elab ;;
        2) draw_screen_elab_bg ;;
        *) draw_screen_elab_bg ;;
    esac
}

draw_screen_orig() {
    printf '%s' "$UI_BG"
    clear
    update_size

    local word1="TERMINAL" word2="HERO"
    local w1=$((5 * ${#word1} + ${#word1} - 1))
    local w2=$((5 * ${#word2} + ${#word2} - 1))
    local nopt=${#OPTIONS[@]}
    local usable=$((ROWS - 2))

    local wmax=$w1 frame_w frame_h base menu_h total_h
    local boxed=1 small=0 stripe_on=1
    frame_w=$((wmax + 8)); frame_h=$((2 + FONT_ROWS + FONT_ROWS))
    base=$((frame_h + 3)); menu_h=$((nopt * 3))
    if [ $((base + menu_h)) -gt "$usable" ]; then
        boxed=0; menu_h=$((nopt * 2)); base=$((frame_h + 2))
    fi
    total_h=$((base + menu_h))
    if [ "$total_h" -gt "$usable" ]; then
        small=1; stripe_on=0; wmax=$w2
        frame_w=$((wmax + 8)); frame_h=$((2 + FONT_ROWS))
        base=$((frame_h + 2)); menu_h=$((nopt * 2))
        total_h=$((base + menu_h))
    fi

    local start_row=$(( (usable - total_h) / 2 + 1 ))
    [ "$start_row" -lt 1 ] && start_row=1

    local fcol=$(( (COLS - frame_w) / 2 + 1 ))
    [ "$fcol" -lt 1 ] && fcol=1

    local r_top=$start_row
    local r_bot=$((r_top + frame_h - 1))
    local inner=$((frame_w - 2))

    local notch="╡ ▓ TERMINAL·HERO ▓ ╞"
    local rem=$((inner - ${#notch}))
    [ "$rem" -lt 0 ] && { notch="${notch:0:inner}"; rem=0; }
    local top="╔${notch}$(repeat '═' "$rem")╗"
    local bot="╚$(repeat '═' "$inner")╝"
    printf '\033[%d;%dH%s%s%s%s' "$r_top" "$fcol" "$UI_BG$FRAME" "$top" "$RESET"
    printf '\033[%d;%dH%s%s%s%s' "$r_bot" "$fcol" "$UI_BG$FRAME" "$bot" "$RESET"

    local pal1=("$FRAME" "$FRAME" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI" "$FRAME_HI")
    local pal2=("$TITLE" "$WARN" "$WARN" "$DANGER")

    draw_word() {
        local word="$1" top="$2"; shift 2
        local pal=("$@")
        local n=${#word}
        local w=$((5 * n + n - 1))
        local sc=$(( fcol + (frame_w - w) / 2 ))
        local r j ch glyph
        for ((r = 0; r < FONT_ROWS; r++)); do
            printf '\033[%d;%dH%s' "$((top + r))" "$sc" "$UI_BG"
            for ((j = 0; j < n; j++)); do
                ch="${word:j:1}"
                glyph=$(font_row "$ch" "$r")
                printf '%s%s' "${pal[j % ${#pal[@]}]}" "$glyph"
                (( j < n - 1 )) && printf ' '
            done
            printf '%s' "$RESET"
            printf '\033[%d;%dH%s║%s' "$((top + r))" "$fcol" "$UI_BG$FRAME" "$RESET"
            printf '\033[%d;%dH%s║%s' "$((top + r))" "$((fcol + frame_w - 1))" "$UI_BG$FRAME" "$RESET"
        done
    }

    if [ "$small" = "0" ]; then
        draw_word "$word1" "$((r_top + 1))" "${pal1[@]}"
        draw_word "$word2" "$((r_top + 1 + FONT_ROWS))" "${pal2[@]}"
    else
        draw_word "$word2" "$((r_top + 1))" "${pal2[@]}"
    fi

    local sub_row=$((r_bot + 1))
    if [ "$stripe_on" = "1" ]; then
        local stripe="▚▚  SYSTEM BEFALLEN  ·  SICHERHEITSPROTOKOLL INAKTIV  ▚▚"
        local scol=$(( (COLS - ${#stripe}) / 2 )); [ "$scol" -lt 1 ] && scol=1
        printf '\033[%d;%dH%s%s%s%s' "$sub_row" "$scol" "$UI_BG" "$DANGER" "$stripe" "$RESET"
        sub_row=$((sub_row + 1))
    fi

    local sub="« E I N   T E R M I N A L - A B E N T E U E R »"
    local ucol=$(( (COLS - ${#sub}) / 2 )); [ "$ucol" -lt 1 ] && ucol=1
    printf '\033[%d;%dH%s%s%s%s' "$sub_row" "$ucol" "$UI_BG" "$TITLE" "$sub" "$RESET"

    local menu_start=$((sub_row + 1))
    local text i
    if [ "$boxed" = "1" ]; then
        local box_w=32 b_inner=$((32 - 2))
        for i in "${!OPTIONS[@]}"; do
            local row=$(( menu_start + i * 3 ))
            text="${OPTIONS[i]}"
            local bcol=$(( (COLS - box_w) / 2 )); [ "$bcol" -lt 1 ] && bcol=1
            if [ "$i" -eq "$SELECTED" ]; then
                local inner_text="▐► ${text} ◄▌"; local pad=$(( (b_inner - ${#inner_text}) / 2 ))
                printf '\033[%d;%dH%s%s%s%s' "$row" "$bcol" "$UI_BG$DANGER" "╔$(repeat '═' $b_inner)╗" "$RESET"
                printf '\033[%d;%dH%s%s%s%s' "$((row + 1))" "$bcol" "$UI_BG$TITLE" "║$(repeat ' ' $pad)${inner_text}$(repeat ' ' $((b_inner - ${#inner_text} - pad)))║" "$RESET"
                printf '\033[%d;%dH%s%s%s%s' "$((row + 2))" "$bcol" "$UI_BG$DANGER" "╚$(repeat '═' $b_inner)╝" "$RESET"
            else
                local pad=$(( (b_inner - ${#text}) / 2 ))
                printf '\033[%d;%dH%s%s%s%s' "$row" "$bcol" "$UI_BG$FRAME" "╭$(repeat '─' $b_inner)╮" "$RESET"
                printf '\033[%d;%dH%s%s%s%s' "$((row + 1))" "$bcol" "$UI_BG$FG" "│$(repeat ' ' $pad)${text}$(repeat ' ' $((b_inner - ${#text} - pad)))│" "$RESET"
                printf '\033[%d;%dH%s%s%s%s' "$((row + 2))" "$bcol" "$UI_BG$FRAME" "╰$(repeat '─' $b_inner)╯" "$RESET"
            fi
        done
    else
        for i in "${!OPTIONS[@]}"; do
            local row=$(( menu_start + i * 2 ))
            text="${OPTIONS[i]}"
            if [ "$i" -eq "$SELECTED" ]; then
                local line="▐►  ${text}  ◄▌"; local col=$(( (COLS - ${#line}) / 2 )); [ "$col" -lt 1 ] && col=1
                printf '\033[%d;%dH%s%s%s%s' "$row" "$col" "$UI_BG" "$DANGER$BOLD" "$line" "$RESET"
            else
                local line="·  ${text}"; local col=$(( (COLS - ${#line}) / 2 )); [ "$col" -lt 1 ] && col=1
                printf '\033[%d;%dH%s%s%s%s' "$row" "$col" "$UI_BG" "$MUTED" "$line" "$RESET"
            fi
        done
    fi

    local hint="↑/↓ Navigieren   ·   Enter Auswählen   ·   Q Beenden"
    printf '\033[%d;%dH%s%s%s%s' "$((ROWS - 1))" "$(( (COLS - ${#hint}) / 2 ))" "$UI_BG" "$MUTED" "$hint" "$RESET"
}

draw_screen_elab() {
    printf '%s' "$UI_BG"
    clear
    update_size

    local nopt=${#OPTIONS[@]}
    local usable=$((ROWS - 1))

    local art=(
"████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗         ██╗  ██╗███████╗██████╗  ██████╗ "
"╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║         ██║  ██║██╔════╝██╔══██╗██╔═══██╗"
"   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║         ███████║█████╗  ██████╔╝██║   ██║"
"   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║         ██╔══██║██╔══╝  ██╔══██╗██║   ██║"
"   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗    ██║  ██║███████╗██║  ██║╚██████╔╝"
"   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ "
    )

    local art_rows=${#art[@]}
    local start_row=$(( (usable - art_rows - 10) / 2 + 1 ))
    [ "$start_row" -lt 1 ] && start_row=1

    local dec1="╔$(repeat '═' 100)╗"
    local dec2="╚$(repeat '═' 100)╝"
    local dcol=$(( (COLS - ${#dec1}) / 2 )); [ "$dcol" -lt 1 ] && dcol=1
    printf '\033[%d;%dH%s%s%s%s' "$start_row" "$dcol" "$UI_BG$FRAME" "$dec1" "$RESET"
    start_row=$((start_row + 1))

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
    start_row=$((start_row + 2))

    local sub="▓▒░  E I N   T E R M I N A L - A B E N T E U E R   ░▒▓"
    local scol=$(( (COLS - ${#sub}) / 2 )); [ "$scol" -lt 1 ] && scol=1
    printf '\033[%d;%dH%s%s%s%s' "$start_row" "$scol" "$UI_BG$TITLE$BOLD" "$sub" "$RESET"
    start_row=$((start_row + 1))
    local sub2="[ INTRUSION DETECTED ]  ·  SYSTEM BEFALLEN  ·  SHELL ACCESS RESTORED"
    local scol2=$(( (COLS - ${#sub2}) / 2 )); [ "$scol2" -lt 1 ] && scol2=1
    printf '\033[%d;%dH%s%s%s%s' "$start_row" "$scol2" "$UI_BG$DANGER" "$sub2" "$RESET"
    start_row=$((start_row + 3))

    local i
    for i in "${!OPTIONS[@]}"; do
        local text="${OPTIONS[i]}"; local row=$((start_row + i * 2))
        if [ "$i" -eq "$SELECTED" ]; then
            local line="╔══[ ▸ ${text} ◂ ]═══════════════════════════════════════════════════════════╗"; local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$DANGER" "$line" "$RESET"
            printf '\033[%d;%dH%s%s%s%s' "$((row + 1))" "$lcol" "$UI_BG$DANGER" "╚$(repeat '═' $(( ${#line} - 2 )))╝" "$RESET"
        else
            local line="  [   ${text}   ]"; local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$MUTED" "$line" "$RESET"
        fi
    done
    local hint="↑/↓ Navigieren   ·   Enter Auswählen   ·   Q Beenden"
    printf '\033[%d;%dH%s%s%s%s' "$((ROWS - 1))" "$(( (COLS - ${#hint}) / 2 ))" "$UI_BG$MUTED" "$hint" "$RESET"
}

draw_screen_elab_bg() {
    printf '%s' "$UI_BG"
    clear
    update_size

    local nopt=${#OPTIONS[@]}
    local usable=$((ROWS - 1))

    local r c
    for ((r = 1; r <= ROWS; r++)); do
        printf '\033[%d;1H%s' "$r" "$UI_BG"
        for ((c = 1; c <= COLS; c++)); do
            local val=$(( ((r * 131542391) + (c * 1000000009)) % 17 ))
            if [ $val -eq 0 ]; then printf '%s░' "$MUTED"
            elif [ $val -eq 1 ]; then printf '%s▒' "$FRAME"
            elif [ $val -eq 2 ]; then printf '%s▓' "$FRAME_HI"
            elif [ $val -eq 3 ]; then printf '%s.' "$MUTED"
            elif [ $val -eq 4 ]; then printf '%s:' "$FRAME"
            elif [ $val -eq 5 ]; then printf '%s+' "$MUTED"
            elif [ $val -eq 6 ]; then printf '%s*' "$FRAME"
            elif [ $val -eq 7 ]; then printf '%s=' "$MUTED"
            elif [ $val -eq 8 ]; then printf '%s-' "$FRAME"
            else printf ' '; fi
        done
        printf '%s' "$RESET"
    done

    local decor_top="╔═══[ ROOT@TERMINALHERO:/START ]═══════════════════════════════════════════════════════════════════════════╗"
    local dtop=$(( (COLS - ${#decor_top}) / 2 )); [ "$dtop" -lt 1 ] && dtop=1
    printf '\033[%d;%dH%s%s%s%s' "1" "$dtop" "$UI_BG$DANGER" "$decor_top" "$RESET"
    local decor_bot="╚$(repeat '═' $(( ${#decor_top} - 2 )))╝"
    local dbot=$(( (COLS - ${#decor_bot}) / 2 )); [ "$dbot" -lt 1 ] && dbot=1
    printf '\033[%d;%dH%s%s%s%s' "$ROWS" "$dbot" "$UI_BG$DANGER" "$decor_bot" "$RESET"

    local sr
    for ((sr = 3; sr < ROWS-2; sr += 4)); do
        printf '\033[%d;2H%s%s%s%s' "$sr" "$UI_BG$ACCENT" "║[SYS]::KERNEL::LOADED" "$RESET"
        printf '\033[%d;%dH%s%s%s%s' "$sr" "$((COLS - 24))" "$UI_BG$ACCENT" "[MEM:OK][NET:SCAN]" "$RESET"
    done

    local art=(
"████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗         ██╗  ██╗███████╗██████╗  ██████╗ "
"╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║         ██║  ██║██╔════╝██╔══██╗██╔═══██╗"
"   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║         ███████║█████╗  ██████╔╝██║   ██║"
"   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║         ██╔══██║██╔══╝  ██╔══██╗██║   ██║"
"   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗    ██║  ██║███████╗██║  ██║╚██████╔╝"
"   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ "
    )

    local art_rows=${#art[@]}
    local start_row=$(( (usable - art_rows - 12) / 2 + 2 ))
    [ "$start_row" -lt 3 ] && start_row=3

    local dec1="╔$(repeat '═' 100)╗"
    local dec2="╚$(repeat '═' 100)╝"
    local dcol=$(( (COLS - ${#dec1}) / 2 )); [ "$dcol" -lt 1 ] && dcol=1
    printf '\033[%d;%dH%s%s%s%s' "$start_row" "$dcol" "$UI_BG$TITLE" "$dec1" "$RESET"
    start_row=$((start_row + 1))

    for r in "${!art[@]}"; do
        local line="${art[$r]}"; local acol=$(( (COLS - ${#line}) / 2 )); [ "$acol" -lt 1 ] && acol=1
        if [ $r -le 1 ]; then printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$DANGER$BOLD" "$line" "$RESET"
        elif [ $r -le 3 ]; then printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$WARN$BOLD" "$line" "$RESET"
        elif [ $r -eq 4 ]; then printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$TITLE$BOLD" "$line" "$RESET"
        else printf '\033[%d;%dH%s%s%s%s' "$((start_row + r))" "$acol" "$UI_BG$ACCENT$BOLD" "$line" "$RESET"; fi
    done
    start_row=$((start_row + art_rows))
    printf '\033[%d;%dH%s%s%s%s' "$start_row" "$dcol" "$UI_BG$TITLE" "$dec2" "$RESET"
    start_row=$((start_row + 2))

    local sub="▓▒░  TERMINAL ACCESS GRANTED // UNAUTHORIZED SESSION // PROCEED WITH CAUTION  ░▒▓"
    local scol=$(( (COLS - ${#sub}) / 2 )); [ "$scol" -lt 1 ] && scol=1
    printf '\033[%d;%dH%s%s%s%s' "$start_row" "$scol" "$UI_BG$GOOD$BOLD" "$sub" "$RESET"
    start_row=$((start_row + 3))

    for i in "${!OPTIONS[@]}"; do
        local text="${OPTIONS[i]}"; local row=$((start_row + i * 2))
        if [ "$i" -eq "$SELECTED" ]; then
            local line="╔══╣ ► ${text} ◄ ╠══════════════════════════════════════════════════════════╗"; local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$DANGER$BOLD" "$line" "$RESET"
            printf '\033[%d;%dH%s%s%s%s' "$((row + 1))" "$lcol" "$UI_BG$DANGER" "╚$(repeat '═' $(( ${#line} - 2 )))╝" "$RESET"
        else
            local line="    ╠══ ${text} ══╣"; local lcol=$(( (COLS - ${#line}) / 2 )); [ "$lcol" -lt 1 ] && lcol=1
            printf '\033[%d;%dH%s%s%s%s' "$row" "$lcol" "$UI_BG$MUTED" "$line" "$RESET"
        fi
    done

    local hint="┏━━[ ↑/↓ ] SELECT   [ ENTER ] CONFIRM   [ Q ] TERMINATE ━━┓"
    printf '\033[%d;%dH%s%s%s%s' "$((ROWS - 2))" "$(( (COLS - ${#hint}) / 2 ))" "$UI_BG$ACCENT" "$hint" "$RESET"
    local hint2="┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    printf '\033[%d;%dH%s%s%s%s' "$((ROWS - 1))" "$(( (COLS - ${#hint2}) / 2 ))" "$UI_BG$ACCENT" "$hint2" "$RESET"
}
