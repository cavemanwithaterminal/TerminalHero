# ============================================================
#  TerminalHero - Rendern (die 4-Fenster-Oberfläche)
#
#  Zeichnet Kopfzeile, Pfad-, Ausgabe-/Dialog- und Ordnerfenster, die
#  Token-Leiste, den Verlauf und die Kommandozeile. Der Umbruch-Cache
#  hält das Blättern flüssig. Zustand kommt aus kern/state.sh, die
#  Zeichenprimitive aus kern/ui.sh.
# ============================================================

line_color() {
    local l="$1"
    case "$l" in
        "")                        printf '%s' "$FG" ;;
        "═════"*)                  printf '%s' "$ACCENT$BOLD" ;;
        "Ziel:"*)                  printf '%s' "$MUTED" ;;
        "──"*"getrennt"*)          printf '%s' "$DANGER" ;;
        "──"*)                     printf '%s' "$MUTED" ;;
        "[ TOKENS ]"*)             printf '%s' "$DANGER" ;;
        "   ▲ LEVEL UP"*)          printf '%s' "$GOOD$BOLD" ;;
        "   Max. Tokens"*)         printf '%s' "$MUTED" ;;
        "   [ Neuer Befehl"*)      printf '%s' "$GOOD$BOLD" ;;
        "   "*)                    printf '%s' "$MENU_C" ;;
        "${AGENT_NAME}:"*)         printf '%s' "$AGENT_C" ;;
        "README:"*)                printf '%s' "$GENERAL_C" ;;
        "Pixi:"*)                  printf '%s' "$PIXI_C" ;;
        "Rachel:"*)                printf '%s' "$RACHEL_C" ;;
        "Jack:"*)                  printf '%s' "$JACK_C" ;;
        "Amanda:"*)                printf '%s' "$AMANDA_C" ;;
        "Börty:"*)                 printf '%s' "$BOERTY_C" ;;
        "Sherlock:"*)              printf '%s' "$SHERLOCK_C" ;;
        "Michael:"*)               printf '%s' "$MICHAEL_C" ;;
        "Tracey:"*)                printf '%s' "$TRACEY_C" ;;
        "Jimmy:"*)                 printf '%s' "$JIMMY_C" ;;
        "Guy Sus:"*)               printf '%s' "$GUY_C" ;;
        "[ GEGNER ]"*|"[GEGNER]"*|"Oink, Oink"*) printf '%s' "$DANGER" ;;
        "[ NEUE QUEST ]"*|"[ QUEST ABGESCHLOSSEN ]"*|"[ QUEST GESCHEITERT ]"*|"[ QUESTLOG ]"*|"[ NEUES ZIEL ]"*) printf '%s' "$DANGER" ;;
        "[ KAMPF ]"*)              printf '%s' "$WARN" ;;
        "[ LOOT ]"*)               printf '%s' "$GOOD" ;;
        "Torwächter:"*)            printf '%s' "$TORW_C" ;;
        "Simon Guard:"*)           printf '%s' "$TORW_C" ;;
        "Simple Jon:"*)            printf '%s' "$JON_C" ;;
        "Kriegsrat:"*)             printf '%s' "$RAT_C" ;;
        "Ermittler:"*)             printf '%s' "$ERM_C" ;;
        "cd:"*|"ls:"*|"cat:"*|"touch:"*|"pwd:"*|"use:"*|"search:"*|"rm:"*) printf '%s' "$DANGER" ;;
        "Nein."*|*"genommen"*|*"kenne ich nicht"*|*"verlassen"*) printf '%s' "$DANGER" ;;
        *:*)
            # Jeder registrierte Sprecher bekommt seine eigene, nicht-graue
            # Farbe. Neue Charaktere werden in kern/theme.sh (SPEAKER_COLOR)
            # eingetragen; unbekannte Sprecher bleiben beim neutralen FG.
            local _speaker="${l%%:*}"
            if [ -n "${SPEAKER_COLOR[$_speaker]:-}" ]; then
                printf '%s' "${SPEAKER_COLOR[$_speaker]}"
            else
                printf '%s' "$FG"
            fi
            ;;
        *)                         printf '%s' "$FG" ;;
    esac
}
# Rang für die Ordner-Sortierung (aufsteigend):
#   1 Ordner · 2 Datei/Figur · 3 benutzbares Objekt (use) · 4 Sammelbares
folder_rank_set() {   # setzt FOLDER_RANK
    local path="$1" id
    FOLDER_RANK=2
    if [ "${TYPE[$path]:-f}" = "d" ]; then
        FOLDER_RANK=1
    elif [ -n "${WORLD_ITEM[$path]:-}" ]; then
        FOLDER_RANK=4
    else
        id="${INTERIOR_AT[$path]:-}"
        if [ -n "$id" ] && [ -n "${INTERIOR_USE[$id]:-}" ]; then
            FOLDER_RANK=3
        fi
    fi
}

# ORDNER-Fenster seitenweise blättern (Bild↑ = -1, Bild↓ = +1).
folder_scroll_page() {
    [ "${FOLDER_VISIBLE:-0}" = "1" ] || return 1
    local page="${FOLDER_CAP:-1}"
    [ "$page" -lt 1 ] && page=1
    FOLDER_SCROLL=$(( FOLDER_SCROLL + $1 * page ))
    [ "$FOLDER_SCROLL" -lt 0 ] && FOLDER_SCROLL=0
    [ "$FOLDER_SCROLL" -gt "${FOLDER_SCROLL_MAX:-0}" ] && FOLDER_SCROLL="${FOLDER_SCROLL_MAX:-0}"
    render
    return 0
}

render() {
    geom
    if [ "$FIRST_RENDER" = "1" ] || [ "$COLS" != "$PREV_COLS" ] || [ "$ROWS" != "$PREV_ROWS" ]; then
        printf '%s' "$UI_BG"     # Grundfarbe aktivieren - "clear" füllt damit
        clear
        FIRST_RENDER=0
        PREV_COLS=$COLS
        PREV_ROWS=$ROWS
    fi

    # --- Kopfzeile: Systemkennung & Telemetrie ---
    clrline "$HEADER_ROW"
    local h_r="◤ SYS://${AGENT_NAME} ◢   ● LINK   ${USERNAME_}@${HOSTNAME_} "
    put_text "$HEADER_ROW" 2 "$((COLS - ${#h_r} - 3))" "▓▒░ TERMINAL·HERO" "$ACCENT$BOLD"
    put_right "$HEADER_ROW" 1 "$((COLS - 1))" "$h_r" "$FRAME"

    # --- oberes Fenster: Pfad (bleibt "???" bis "pwd" benutzt wurde) ---
    draw_box 1 "$PATH_TOP" "$COLS" "$PATH_H" "SYS://PFAD" "$FRAME"
    local cwd_disp="$(short_path "$CWD")" path_col="$TITLE"
    if [ "$SHOW_PATH" != "1" ]; then cwd_disp="???"; path_col="$MUTED"; fi
    local sp_l="○ PFAD VERBORGEN" sp_c="$MUTED"
    [ "$SHOW_PATH" = "1" ] && { sp_l="● PFAD AKTIV"; sp_c="$GOOD"; }
    clear_region "$((PATH_TOP + 1))" 2 "$((COLS - 2))" 1
    put_text "$((PATH_TOP + 1))" 3 "$((COLS - 4))" "▸ ${USERNAME_}@${HOSTNAME_}:${cwd_disp}" "$path_col"
    put_right "$((PATH_TOP + 1))" 3 "$((COLS - 4))" "${sp_l} " "$sp_c"

    # --- Kalender: Datum mittig auf der oberen Linie des PFAD-Fensters ---
    # Nur nach »cal« und nur für 24 Spielstunden (kern/kalender.sh).
    declare -F cal_draw >/dev/null 2>&1 && cal_draw

    # --- Uhrzeit: Notch in der Trennlinie PFAD-/Ordner-Fenster (nur mit Armbanduhr) ---
    uhrzeit_draw

    # --- mittleres linkes Fenster: Ausgabe / Dialog ---
    local lcolor="$FRAME" ltag="● RX"
    [ "$DIALOG_ACTIVE" = "1" ] && { lcolor="$ACCENT"; ltag="◉ FUNK"; }
    local ltitle="AUSGABE / DIALOG"
    [ "$SCROLL" -gt 0 ] && ltitle="AUSGABE / DIALOG  ▲ $SCROLL"
    draw_box "$LEFT_X" "$MAIN_TOP" "$LEFT_W" "$MAIN_H" "$ltitle" "$lcolor"
    [ "$LEFT_W" -ge 36 ] && put_right "$MAIN_TOP" "$LEFT_X" "$((LEFT_W - 1))" "[ ${ltag} ] " "$lcolor"

    # --- rechtes Fenster: Ordnerinhalt (Titel bleibt "???" bis "ls" benutzt wurde) ---
    # Die Fackel zeigt den Ordnerinhalt automatisch - ohne »ls«. Sie
    # ersetzt die manuelle Ansicht nicht: »ls -a« zeigt weiterhin auch
    # versteckte Dateien, die Fackel selbst nie.
    local torch=0 ls_on=0
    if declare -F fackel_active >/dev/null 2>&1 && fackel_active; then torch=1; fi
    { [ "$SHOW_LS" = "1" ] || [ "$torch" = "1" ]; } && ls_on=1

    local vd="$VIEW_DIR"
    # Automatisch (nur Fackel) immer den AKTUELLEN Ordner zeigen - nicht
    # ein eventuell älteres manuelles »ls«-Ziel. Nach einem geladenen
    # Spielstand kann VIEW_DIR sonst woanders stehen.
    if [ "$torch" = "1" ] && [ "$SHOW_LS" != "1" ]; then vd="$CWD"; fi
    [ -z "${TYPE[$vd]}" ] && vd="$CWD"
    local -a names=() e
    if [ "$ls_on" = "1" ]; then
        while IFS= read -r e; do
            [ -n "$e" ] || continue
            # Automatisch (nur Fackel) niemals versteckte Einträge.
            if { [ "$SHOW_LS" != "1" ] || [ "$LS_SHOW_ALL" = "0" ]; } \
               && [[ "$e" == .* ]]; then continue; fi
            names+=("$e")
        done <<< "${CHILDREN[$vd]}"
    fi

    # Offsets beim Ordnerwechsel zurücksetzen.
    if [ "${FOLDER_LAST_DIR:-}" != "$vd" ]; then
        FOLDER_SCROLL=0
        FOLDER_LAST_DIR="$vd"
    fi

    # Reihenfolge: 1 Ordner, 2 Dateien/Figuren, 3 benutzbare Objekte (use),
    # 4 sammelbare Weltgegenstände. Innerhalb jeder Gruppe alphabetisch.
    local -a fshown=()
    if [ "$ls_on" = "1" ] && [ "${#names[@]}" -gt 0 ]; then
        while IFS= read -r e; do
            fshown+=("$e")
        done < <(
            for e in "${names[@]}"; do
                folder_rank_set "$vd/$e"
                printf '%s\t%s\n' "$FOLDER_RANK" "$e"
            done | sort -t$'\t' -k1,1n -k2,2 | cut -f2-
        )
    fi
    # Anzeigezeilen: vor jeder nicht-leeren Gruppe steht eine Überschrift.
    # Das \x01-Präfix markiert eine Überschrift (Dateinamen enthalten es nie).
    local -a fdisp=()
    local rank=0
    for e in "${fshown[@]}"; do
        folder_rank_set "$vd/$e"
        if [ "$FOLDER_RANK" != "$rank" ]; then
            case "$FOLDER_RANK" in
                1) fdisp+=($'\x01---Orte---') ;;
                2) fdisp+=($'\x01---Charaktere---') ;;
                3) fdisp+=($'\x01---Interaktiv---') ;;
                4) fdisp+=($'\x01---Sammelbar---') ;;
            esac
            rank="$FOLDER_RANK"
        fi
        fdisp+=("$e")
    done

    local fcap=$(( MAIN_H - 2 ))
    [ "$fcap" -lt 1 ] && fcap=1
    FOLDER_VISIBLE="$ls_on"
    FOLDER_CAP="$fcap"
    FOLDER_SCROLL_MAX=$(( ${#fdisp[@]} - fcap ))
    [ "$FOLDER_SCROLL_MAX" -lt 0 ] && FOLDER_SCROLL_MAX=0
    [ "$FOLDER_SCROLL" -gt "$FOLDER_SCROLL_MAX" ] && FOLDER_SCROLL="$FOLDER_SCROLL_MAX"
    [ "$FOLDER_SCROLL" -lt 0 ] && FOLDER_SCROLL=0

    local rtitle rcolor="$FRAME"
    if [ "$ls_on" = "1" ]; then
        local vname
        if [ "$vd" = "$HOME_DIR" ]; then vname="~"; else vname="${vd##*/}"; fi
        if [ "$RIGHT_W" -ge 30 ]; then
            rtitle="ORDNER: ${vname} [${#names[@]}]"
        else
            rtitle="ORDNER: ${vname}"
        fi
        if [ "$FOLDER_SCROLL_MAX" -gt 0 ]; then
            [ "$FOLDER_SCROLL" -gt 0 ] && rtitle+=" ▲${FOLDER_SCROLL}"
            [ "$FOLDER_SCROLL" -lt "$FOLDER_SCROLL_MAX" ] && rtitle+=" ▼"
        fi
        if [ "$torch" = "1" ] && [ "$SHOW_LS" != "1" ]; then
            rcolor="$WARN"
        else
            rcolor="$GOOD"
        fi
    else
        rtitle="ORDNER: ???"
        rcolor="$MUTED"
    fi
    draw_box "$RIGHT_X" "$MAIN_TOP" "$RIGHT_W" "$MAIN_H" "$rtitle" "$rcolor"
    [ "$RIGHT_W" -ge 36 ] && put_right "$MAIN_TOP" "$RIGHT_X" "$((RIGHT_W - 1))" "[ ▚▚ ] " "$rcolor"

    # --- Inhalte der beiden Mittelfenster leeren ---
    clear_region "$((MAIN_TOP + 1))" "$((LEFT_X + 1))" "$((LEFT_W - 2))" "$((MAIN_H - 2))"
    clear_region "$((MAIN_TOP + 1))" "$((RIGHT_X + 1))" "$((RIGHT_W - 2))" "$((MAIN_H - 2))"

    # --- Dialog-/Ausgabetext (wortweise umgebrochen, farbig, unten ausgerichtet) ---
    # Umbruch+Farbe nur neu berechnen, wenn sich die Ausgabe oder die Geometrie
    # geändert hat - das hält das Blättern flüssig.
    local inner=$((LEFT_W - 2)) cap=$((MAIN_H - 2))
    local wk="${#OUT[@]}|${inner}|${cap}"
    if [ "$WRAP_KEY" != "$wk" ]; then
        WRAPPED=(); WCOL=()
        local ln x lc
        for ln in "${OUT[@]}"; do
            lc="$(line_color "$ln")"
            while IFS= read -r x; do WRAPPED+=("$x"); WCOL+=("$lc"); done < <(wrap_line "$ln" "$inner")
        done
        WRAP_KEY="$wk"
    fi
    local total=${#WRAPPED[@]} start=0
    SCROLL_MAX=$(( total - cap )); [ "$SCROLL_MAX" -lt 0 ] && SCROLL_MAX=0
    [ "$SCROLL" -gt "$SCROLL_MAX" ] && SCROLL=$SCROLL_MAX
    [ "$SCROLL" -lt 0 ] && SCROLL=0
    start=$(( total - cap - SCROLL )); [ "$start" -lt 0 ] && start=0
    local end=$(( start + cap )); [ "$end" -gt "$total" ] && end=$total
    local row=$(( MAIN_TOP + 1 )) i
    for ((i = start; i < end; i++)); do
        put_text "$row" "$((LEFT_X + 1))" "$inner" "${WRAPPED[i]}" "${WCOL[i]}"
        ((row++))
    done

    # --- Ordnerinhalt ---
    local fcol=$((RIGHT_X + 1)) finner=$((RIGHT_W - 2))
    local frow=$((MAIN_TOP + 1)) fmax=$((MAIN_BOT - 1))
    if [ "$ls_on" != "1" ]; then
        put_text "$frow" "$fcol" "$finner" "[ nur Schwärze ]" "$MUTED"
    elif [ "${#names[@]}" -eq 0 ]; then
        put_text "$frow" "$fcol" "$finner" "(leer)" "$MUTED"
    else
        local fi
        for ((fi = FOLDER_SCROLL; fi < ${#fdisp[@]} && frow <= fmax; fi++)); do
            e="${fdisp[fi]}"
            if [[ "$e" == $'\x01'* ]]; then
                put_text "$frow" "$fcol" "$finner" \
                    "$(center_text "${e:1}" "$finner")" "$MUTED"
            else
                put_file "$frow" "$fcol" "$finner" "$e" "${TYPE[$vd/$e]:-f}" "$vd/$e"
            fi
            ((frow++))
        done
    fi

    # --- Token-Leiste (zwischen Dialog- und Kommandozeile) ---
    # Zeigt das LS-Fenster Inhalt, steht der Scroll-Hinweis mittig darunter
    # und die Token-Leiste hält bis zu seinem Anfang Platz frei.
    local fhint="Bild↑/↓ blättern" fhx=0
    TOKEN_BAR_RIGHT=0
    if [ "$FOLDER_VISIBLE" = "1" ]; then
        fhx=$(( RIGHT_X + (RIGHT_W - ${#fhint}) / 2 ))
        [ "$fhx" -lt 1 ] && fhx=1
        TOKEN_BAR_RIGHT=$(( COLS - fhx + 2 ))
    fi
    draw_token_bar
    [ "$FOLDER_VISIBLE" = "1" ] && \
        put_text "$TOKEN_ROW" "$fhx" "${#fhint}" "$fhint" "$MUTED"

    # --- Verlauf (letzte 3 Befehle) ---
    local r
    for ((r = HIST_TOP; r < ROWS; r++)); do clrline "$r"; done
    local n=${#CMD_HIST[@]}
    for ((i = 0; i < n; i++)); do
        r=$(( HIST_TOP + (3 - n) + i ))
        local hc="$MUTED"; [ "$i" -eq "$((n - 1))" ] && hc="$FRAME_HI"
        pos "$r" 2
        printf '%s%s▸%s %s%s%s%s' "$UI_BG" "$FRAME" "$RESET" "$UI_BG" "$hc" "${CMD_HIST[i]}" "$RESET"
    done

    # --- Kommandozeile ---
    draw_prompt
}
draw_prompt() {
    clrline "$PROMPT_ROW"
    if [ "$DIALOG_ACTIVE" = "1" ]; then
        printf '%s%s▶ %s%s' "$UI_BG" "$ACCENT$BOLD" "${DIALOG_HINT:-Dialog läuft ...}" "$RESET"
        hide_cursor
    else
        # Nur Benutzer@Rechner: der Pfad steht oben im PFAD-Fenster. Stünde er
        # hier noch einmal, würde er bei tiefen Pfaden die ganze Kommandozeile
        # füllen (z. B. »~//Schreibtisch/DesktopCity/.../EingestürzteBaracke«).
        printf '%s%s▌ %s' "$UI_BG" "$ACCENT$BOLD" "$RESET"
        printf '%s%s%s@%s%s' "$UI_BG" "$GOOD" "$USERNAME_" "$HOSTNAME_" "$RESET"
        printf '%s%s$ %s' "$UI_BG" "$GOOD$BOLD" "$RESET"
        printf '%s%s%s' "$FG" "$CMD_BUFFER" "$RESET"
        show_cursor
    fi
}
