# ============================================================
#  TerminalHero - Startbildschirm: Setup
#
#  Fragt Benutzername, Hostname und Agentenname ab und zeigt die
#  Zusammenfassung. Rückgabe 0 = starten, 1 = zurück zum Menü.
# ============================================================

read_input() {
    local label="$1" def="$2" val
    local col=$(( (COLS - 48) / 2 ))
    [ "$col" -lt 0 ] && col=0
    printf '%s%*s%s%s%s%s %s[%s]%s: ' "$UI_BG" "$col" '' "$BOLD$CYAN" "$label" "$RESET" "$DIM" "$def" "$RESET" >&2
    IFS= read -r val
    [ -z "$val" ] && val="$def"
    printf '%s' "$val"
}
run_setup() {
    printf '%s' "$UI_BG"
    clear
    update_size
    show_cursor

    printf '\n'
    local hw=50 hin htitle=" S Y S T E M · K O N F I G " hrem hpad
    hin=$((hw - 2))
    hrem=$(( hin - ${#htitle} )); [ "$hrem" -lt 0 ] && hrem=0; hpad=$(( hrem / 2 ))
    print_centered "╔$(repeat '═' $hpad)${htitle}$(repeat '═' $((hrem - hpad)))╗" "$FRAME"
    print_centered "╚$(repeat '═' $hin)╝" "$FRAME"
    printf '\n'
    print_centered "Der Agent benötigt Identität und Zielsystem." "$MUTED"
    printf '\n'

    # Benutzername
    while true; do
        USERNAME="$(read_input "Benutzername" "benutzer")"
        if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]]; then break; fi
        play_sound error
        print_centered "Ungültig: nur Kleinbuchstaben, Ziffern, - und _ (Start mit Buchstabe)." "$RED"
    done

    # Hostname
    while true; do
        HOSTNAME_="$(read_input "Hostname" "pc")"
        if [[ "$HOSTNAME_" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,30}[A-Za-z0-9])?$ ]]; then break; fi
        play_sound error
        print_centered "Ungültig: Buchstaben, Ziffern und - (kein - am Rand)." "$RED"
    done

    # Agentenname
    while true; do
        AGENT="$(read_input "Agentenname" "Sentinel")"
        if [[ "$AGENT" =~ ^[A-Za-z0-9._-]{1,24}$ ]]; then break; fi
        play_sound error
        print_centered "Ungültig: 1–24 Zeichen, keine Leerzeichen." "$RED"
    done

    play_sound select
    printf '\n'

    local bw=48
    local iw=$((bw - 4))
    local l1="System   : ${USERNAME}@${HOSTNAME_}"
    local l2="KI-Agent : ${AGENT}"
    local pad1 pad2
    pad1=$(repeat ' ' $(( iw - ${#l1} ))); [ "$(( iw - ${#l1} ))" -lt 0 ] && pad1=""
    pad2=$(repeat ' ' $(( iw - ${#l2} ))); [ "$(( iw - ${#l2} ))" -lt 0 ] && pad2=""

    print_centered "╔$(repeat '═' $((bw - 2)))╗" "$GOOD"
    print_centered "║ ${l1}${pad1} ║" "$FG"
    print_centered "║ ${l2}${pad2} ║" "$GOOD$BOLD"
    print_centered "╚$(repeat '═' $((bw - 2)))╝" "$GOOD"
    printf '\n'
    print_centered "▸ Enter: Agent starten        ▸ Q/Esc: zurück" "$TITLE"

    while true; do
        read_key
        case "$LAST_KEY" in
            $'\n'|$'\r')       return 0 ;;
            'q'|'Q'|$'\x1b')   return 1 ;;
        esac
    done
}
