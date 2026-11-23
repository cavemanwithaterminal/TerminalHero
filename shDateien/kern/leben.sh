# ============================================================
#  TerminalHero - Ohnmacht & Tod
# ------------------------------------------------------------
#  Fällt der Agent auf 0 Tokens, entscheidet der Kampfzustand:
#
#    * NICHT im Kampf -> Ohnmacht. Der Bildschirm wird drei
#      Sekunden schwarz (»Du bist Ohnmächtig«), ingame vergehen
#      sechs Stunden, danach wacht der Agent mit einem Teil seiner
#      Tokens wieder auf.
#    * IM KAMPF -> Tod. Egal ob der letzte Token durch Gegnerschaden
#      oder durch die Kosten eines eingegebenen Befehls verloren geht:
#      Der Bildschirm wird drei Sekunden schwarz (»Du bist tot«),
#      danach endet die Spiel-Shell und der Startbildschirm erscheint.
#
#  »Im Kampf« heißt: Es gibt eine aktive Gegner-Begegnung im aktuellen
#  Ordner. Die Entscheidung liegt zentral hier, damit Tokens-Kosten
#  (TerminalShell.sh) und Gegnerschaden (kern/gegner.sh) gleich
#  behandelt werden.
#
#  Test-Haken:
#    TH_FAINT_SECS       Dauer des schwarzen Ohnmachts-Bildschirms
#    TH_DEATH_SECS       Dauer des schwarzen Todes-Bildschirms
#    TH_LEBEN_NO_SCREEN  1 = keinen Vollbildschirm zeichnen, nur Text
# ============================================================

LEBEN_BLACK_SECS=3            # Standarddauer des schwarzen Bildschirms
LEBEN_FAINT_HOURS=6           # so viele Ingame-Stunden vergehen bei Ohnmacht
LEBEN_FAINT_REGEN_PCT=15      # danach 15 % der Maximal-Tokens (6 h Regen)

# Ist der Agent gerade in einer aktiven Gegner-Begegnung?
leben_in_combat() {
    [ -n "${GEGNER_ACTIVE_CWD:-}" ] || return 1
    [ "${CWD:-}" = "${GEGNER_ACTIVE_CWD:-}" ] || return 1
    declare -F gegner_count_current >/dev/null 2>&1 || return 1
    [ "$(gegner_count_current)" -gt 0 ]
}

# Schwarzer Vollbildschirm mit einer zentrierten Zeile.
leben_black() {   # $1 = Text, $2 = Sekunden
    local msg="$1" secs="${2:-$LEBEN_BLACK_SECS}"
    if [ "${TH_LEBEN_NO_SCREEN:-0}" = "1" ]; then
        printf '%s\n' "$msg"
        sleep "$secs"
        return 0
    fi

    geom
    printf '\033[48;5;16m\033[38;5;250m'   # schwarzer Grund, heller Text
    clear
    local rr=$(( ROWS / 2 ))
    local cc=$(( (COLS - ${#msg}) / 2 + 1 )); [ "$cc" -lt 1 ] && cc=1
    pos "$rr" "$cc"
    printf '%s' "$msg"
    sleep "$secs"
}

# Ohnmacht: schwarz, sechs Ingame-Stunden, dann mit 15 % Tokens aufwachen.
leben_faint() {
    local wake
    leben_black "Du bist Ohnmächtig" "${TH_FAINT_SECS:-$LEBEN_BLACK_SECS}"

    declare -F uhrzeit_advance_hours >/dev/null 2>&1 \
        && uhrzeit_advance_hours "$LEBEN_FAINT_HOURS"

    wake=$(( ${TOKENS_MAX:-0} * LEBEN_FAINT_REGEN_PCT / 100 ))
    [ "$wake" -lt 1 ] && wake=1
    [ "$wake" -gt "${TOKENS_MAX:-0}" ] && wake="${TOKENS_MAX:-0}"
    TOKENS_CUR="$wake"

    OUT+=("")
    OUT+=("── Du bist ohnmächtig geworden. ──")
    OUT+=("   Sechs Stunden später wachst du wieder auf.")
    OUT+=("   Tokens: ${TOKENS_CUR} / ${TOKENS_MAX}")
    play_sound online

    # Zurück in die normale Spiel-GUI; die Hauptschleife zeichnet neu.
    printf '%s' "$UI_BG"
    FIRST_RENDER=1
    return 0
}

# Tod: schwarz, dann Spiel-Shell beenden. Der Startbildschirm läuft weiter,
# weil TerminalHero.sh die Shell als eigenen Prozess gestartet hat.
leben_die() {
    leben_black "Du bist tot" "${TH_DEATH_SECS:-$LEBEN_BLACK_SECS}"
    play_sound error
    exit 0
}

# Zentrale Weiche für »Tokens sind auf 0 gefallen«.
leben_token_zero() {
    if leben_in_combat; then
        OUT+=("")
        OUT+=("[ KAMPF ] Deine Energie ist aufgebraucht. Du stirbst.")
        leben_die
    fi
    leben_faint
}
