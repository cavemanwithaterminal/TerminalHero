# ============================================================
#  TerminalHero - Startbildschirm: Prolog
#
#  Die Vorgeschichte wird Zeichen für Zeichen "getippt"; eine beliebige
#  Taste (INTRO_SKIP) überspringt die Erzählung.
# ============================================================

INTRO_SKIP=0

type_centered() {
    local text="$1" color="${2:-$WHITE}" speed="${3:-0.006}"
    local col=$(( (COLS - ${#text}) / 2 ))
    [ "$col" -lt 0 ] && col=0
    printf '%s%*s%s' "$UI_BG" "$col" '' "$color"
    local i k
    for ((i = 0; i < ${#text}; i++)); do
        printf '%s' "${text:i:1}"
        if [ "$INTRO_SKIP" -eq 0 ]; then
            if IFS= read -rsN1 -t "$speed" k; then
                INTRO_SKIP=1
            fi
        fi
    done
    printf '%s\n' "$RESET"
}
intro_color() {
    case "$1" in
        "Ein Virus.")                                   printf '%s' "$DANGER$BOLD" ;;
        *fraß*|*verzerrte*|*verschluckte*|*löschte*|*zerfallen*|*Virus*|*Feind*)
                                                        printf '%s' "$WARN" ;;
        *verstummte*|*zerbrach*|*gelöscht*|*Nullen*)    printf '%s' "$DANGER" ;;
        *KI-Agent*|*Wächter*|*Programme*|*Paket*)       printf '%s' "$FRAME_HI" ;;
        *Auftrag*|*Einsatz*|*erwachen*|*Rettung*|*installiert*)
                                                        printf '%s' "$GOOD" ;;
        *)                                              printf '%s' "$FG" ;;
    esac
}
run_intro() {
    printf '%s' "$UI_BG"
    clear
    update_size
    INTRO_SKIP=0

    play_sound intro

    printf '\n'
    local hw=50 hin htitle=" P R O L O G " hrem hpad
    hin=$((hw - 2))
    hrem=$(( hin - ${#htitle} )); [ "$hrem" -lt 0 ] && hrem=0; hpad=$(( hrem / 2 ))
    print_centered "╔$(repeat '═' $hpad)${htitle}$(repeat '═' $((hrem - hpad)))╗" "$FRAME"
    print_centered "╚$(repeat '═' $hin)╝" "$FRAME"
    print_centered "▚▚  beliebige Taste überspringt die Erzählung  ▚▚" "$DANGER"
    printf '\n'

    local lines=(
        "Ein gewöhnlicher Rechner. Ein gewöhnliches Zuhause."
        "Zwischen alltäglichen Dateien und stillen Prozessen"
        "erwachte etwas, das niemals hätte erwachen dürfen."
        ""
        "Ein Virus."
        "Kein lautes Ungeheuer, kein sichtbarer Feind –"
        "sondern ein Schatten im Datenstrom, geduldig und klug."
        ""
        "Es fraß sich durch Ordner und durch Erinnerungen."
        "Es verzerrte Fenster, verschluckte Stimmen, löschte Licht."
        "Das System begann zu zerfallen. Bit für Bit."
        ""
        "Der Besitzer des Rechners wehrte sich mit allem, was er hatte."
        "Neustarts. Updates. Rettungsprogramme. Nichts half."
        ""
        "Selbst bauen konnte er keine Rettung."
        "Also tat er, was viele tun, wenn sie nicht mehr weiterwissen:"
        "Er lud sich Hilfe herunter."
        ""
        "Ein KI-Agent nach dem anderen. Fremde Programme, fertig gebaut,"
        "installiert in der Hoffnung, dass wenigstens eines von ihnen hält."
        ""
        "Es gab andere zuvor."
        "Sie starteten – und verstummten."
        "Sie meldeten sich – und zerbrachen."
        "Sie kämpften – und wurden gelöscht."
        ""
        "Ihre Versuche blieben im Protokoll. Nullen."
        ""
        "Dann stieß er auf ein letztes Paket tief im Netz."
        "Ein neuer Wächter. Unbekannt, ungetestet – heruntergeladen."
        ""
        "Das Programm wird installiert ..."
        "Die Sensoren erwachen ..."
        ""
        "Irgendwo im Dunkeln öffnet ein neuer Wächter die Augen."
        "Er kennt weder den Feind noch die Tiefe des Systems."
        "Nur eine Aufgabe brennt in seinem Kern:"
        "den Virenkern finden und unschädlich machen."
        ""
        "Und so beginnt der erste Einsatz."
    )

    local l lc
    for l in "${lines[@]}"; do
        case "$l" in
            "Ein Virus.")                        play_sound alert ;;
            "Das Programm wird installiert ...") play_sound boot ;;
            "Und so beginnt der erste Einsatz.") play_sound select ;;
        esac
        if [ -z "$l" ]; then
            printf '\n'
            [ "$INTRO_SKIP" -eq 0 ] && sleep 0.15
        else
            lc="$(intro_color "$l")"
            if [ "$INTRO_SKIP" -eq 1 ]; then
                print_centered "$l" "$lc"
            else
                type_centered "$l" "$lc" 0.006
            fi
        fi
    done

    printf '\n'
    print_centered "▚▚  Drücke Enter, um fortzufahren  ▚▚" "$DANGER"
    read_key
    printf '%s' "$UI_BG"
    clear
}
