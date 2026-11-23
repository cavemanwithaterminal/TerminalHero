# ============================================================
#  TerminalHero - InGame-Befehl: trade (Handeln)
#
#     trade              – wen kann ich handeln lassen?
#     trade <Händler>    – das Handelsfenster mit ihm öffnen
#
#  Der Befehl ist NICHT von Anfang an bekannt - er wird später von einem
#  Lehrer beigebracht (im Spielverlauf; aktuell lehrt ihn noch niemand).
#  Danach steht »trade« auch im help-Fenster (Reiter »Spiel-Befehle«).
#
#  HANDELN NUR VOR ORT: Ein Händler steht als beseelte Datei in einem
#  Ordner. »trade <Händler>« funktioniert nur, wenn genau dieser Ordner
#  der aktuelle ist (handel_here in Handelsfenster.sh). Wer nicht weiß,
#  wie der Befehl geht, kann trotzdem handeln: den Händler »touch«en -
#  sein Dialog bietet »Handeln.« an.
#
#  Das eigentliche Fenster und die Händler-Register stecken in
#  shDateien/Handelsfenster.sh - diese Datei ist nur die Verdrahtung
#  (wie InGameBefehle/Inventar.sh für »inventar«). Deshalb wird das
#  Handelsfenster hier auch erst NACHGELADEN, wenn es gebraucht wird.
#
#  Lazy geladen über require_gamecmd Trade (TerminalShell.sh).
# ============================================================

# Ist <wort> der Handels-Befehl? (Groß-/Kleinschreibung egal)
trade_is_command() {
    case "${1,,}" in
        trade) return 0 ;;
    esac
    return 1
}

# Alle Händler anmelden, die ein Lager bereitstellen. Konvention:
# die Charakter-Datei stellt handel_lager_<id> bereit (z. B.
# handel_lager_boerty in Charakter/BörtySmiles.sh). Der Funktionsindex
# kennt die Datei - geladen wird sie erst hier.
trade_merchants_load() {
    # Das Fenster-Modul selbst (handel_define & Co.) bei Bedarf laden.
    declare -F handel_define >/dev/null 2>&1 || th_source_if_fn handel_define
    declare -F handel_define >/dev/null 2>&1 || return 1
    th_build_fn_index
    local fn
    for fn in "${!TH_FN_FILE[@]}"; do
        case "$fn" in
            handel_lager_*) th_source_if_fn "$fn" ;;
        esac
    done
    return 0
}

# Öffnet den Handel, wenn <wort> der Befehl ist – aber nur, wenn der
# Befehl schon gelernt wurde (aktuell lernt ihn noch niemand) und der
# Händler in genau dem Ordner steht, in dem der Agent ist.
# Rückgabe 0 = war der Handels-Befehl (Fenster bzw. Absage).
# Rückgabe 1 = kein Handels-Befehl (Zeile läuft normal weiter).
trade_handles() {
    local cmd="$1" rest="${2:-}"
    trade_is_command "$cmd" || return 1

    if ! knows trade; then
        play_sound error
        OUT+=("»trade« …? Nein. Wie das geht, weiß ich noch nicht – das hat mir keiner gesagt.")
        return 0
    fi

    trade_merchants_load

    # Ohne Namen: wer steht HIER im Ordner?
    if [ -z "$rest" ]; then
        local ids x
        ids="$(handel_here_ids)"
        if [ -z "$ids" ]; then
            OUT+=("In diesem Ordner handelt niemand.")
            return 0
        fi
        OUT+=("Mit wem soll ich handeln?")
        while IFS= read -r x; do
            [ -n "$x" ] && OUT+=("   trade $(handel_name "$x")")
        done <<< "$ids"
        return 0
    fi

    local id
    id="$(handel_find "$rest")"
    if [ -z "$id" ]; then
        play_sound error
        OUT+=("»${rest}« …? Mit der Person habe ich kein Geschäft.")
        return 0
    fi
    # Handeln geht nur vor Ort - der Händler muß in DIESEM Ordner stehen.
    if ! handel_here "$id"; then
        play_sound error
        OUT+=("»$(handel_name "$id")« ist nicht hier. Handeln kann ich nur mit jemandem, der im selben Ordner steht.")
        return 0
    fi
    handel_start "$id"
    return 0
}
