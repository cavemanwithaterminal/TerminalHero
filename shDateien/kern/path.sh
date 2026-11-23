# ============================================================
#  TerminalHero - Pfad-Auflösung & Sperrzonen
#
#  »~« expandieren, Pfade normalisieren und den Zugriff außerhalb von ~
#  abweisen (Sperrzone). Wird von (fast) jedem Befehl genutzt.
# ============================================================

resolve_path() {   # $1 = Pfad, $2 = Basis (i. d. R. $CWD)
    local p="$1"
    case "$p" in
        "~")   p="$HOME_DIR" ;;
        "~/")  p="$HOME_DIR" ;;
        "~/"*) p="$HOME_DIR/${p:2}" ;;
    esac
    normalize_path "$p" "$2"
}
outside_home() {
    [ "$1" = "$HOME_DIR" ] && return 1
    [[ "$1" == "$HOME_DIR/"* ]] && return 1
    return 0
}
zone_denied() {
    outside_home "$3" || return 1
    play_sound error
    OUT+=("$1: $2: Zugriff verweigert.")
    OUT+=("[ SPERRZONE ] Hinter ~/ ist die Welt noch abgeriegelt – dieser Teil kommt später.")
    return 0
}
