# ============================================================
#  TerminalHero - Dialog-Grundlagen
#
#  say  <sprecher> <text> [pause]  –  eine Zeile ins Ausgabefenster, mit
#                                     kurzer Pause ("-" = Erzählstimme).
#  ask  <opt1> <opt2> ...           –  Auswahl abfragen (Ergebnis in CHOICE).
#  Wird von allen Charakter-Dialogen und den Pixi-Szenen genutzt.
# ============================================================

say() {
    # TH_SAY_SECS ist ein reiner Testhaken (wie TH_SLEEP_SECS): Ohne den
    # Wert bleibt die Erzählpause bei 0,55 s; Tests können sie verkürzen.
    local who="$1" text="$2" delay="${3:-${TH_SAY_SECS:-0.55}}"
    if [ "$who" = "-" ]; then OUT+=("$text"); else OUT+=("${who}: ${text}"); fi
    SCROLL=0
    render
    sleep "$delay"
}
ask() {
    local n=$# i
    local opts=("$@")
    SCROLL=0
    for ((i = 0; i < n; i++)); do OUT+=("   $((i + 1))) ${opts[i]}"); done
    DIALOG_HINT="   Wähle 1-$n   ·   ↑/↓ blättern > "
    render
    while true; do
        read_key2 || return
        # Im Menü wird NUR mit den Pfeiltasten geblättert - Bild↑/Bild↓
        # gehören dem ORDNER-Fenster und werden hier bewusst ignoriert.
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') SCROLL=$(( SCROLL + 1 )); render; continue ;;
            $'\x1b[B'|$'\x1bOB') SCROLL=$(( SCROLL - 1 )); render; continue ;;
        esac
        case "$LAST_KEY" in
            [1-9])
                if [ "$LAST_KEY" -ge 1 ] && [ "$LAST_KEY" -le "$n" ]; then
                    CHOICE="$LAST_KEY"
                    OUT+=("   » ${opts[$((LAST_KEY - 1))]}")
                    play_sound select
                    render
                    return
                fi ;;
            *) : ;;
        esac
    done
}
