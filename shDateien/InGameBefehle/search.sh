# ============================================================
#  TerminalHero - Spiel-Befehl: search
#
#  »search <objekt>« DURCHSUCHT ein Objekt in der Welt. Anders als
#  »grep« (etwas herausziehen) und »use« (etwas benutzen) geht es hier
#  um den Inhalt: Eine Leiche kann Loot tragen, ein Schrank etwas
#  verbergen. Welche Objekte durchsuchbar sind, steht im Register
#  kern/search.sh (search_define); die Ausführung übernimmt die dort
#  angemeldete Funktion.
#
#  Zu Spielbeginn GESPERRT (Amnesie): Der Virus hat auch diesen Befehl
#  mitgenommen. Einen Lernpfad gibt es noch nicht - wer ihn im
#  Spielstand hat, kann ihn benutzen.
#
#  Aufruf:  search <objekt>
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
# ============================================================

builtin_search() {
    if ! knows search; then
        play_sound error
        OUT+=("»search« …? Diesen Befehl kenne ich nicht mehr.")
        OUT+=("Der Virus hat ihn mir genommen – wie so vieles. Noch.")
        return
    fi
    if [ -z "$1" ]; then
        play_sound error
        OUT+=("search: Was soll ich durchsuchen?")
        OUT+=("Verwendung: search <objekt>")
        return
    fi

    local arg="$1" np fn
    np="$(resolve_path "$arg" "$CWD")"
    zone_denied search "$arg" "$np" && return
    district_ensure "$np"          # Stadtteil bei Bedarf laden

    if [ -z "${TYPE[$np]:-}" ]; then
        play_sound error
        OUT+=("search: $arg: Datei oder Verzeichnis nicht gefunden")
        return
    fi
    if [ "${TYPE[$np]}" = "d" ]; then
        play_sound error
        OUT+=("search: $arg: Das ist ein Verzeichnis. Da gibt es nichts zu durchsuchen.")
        return
    fi

    fn="$(search_fn_of "$np")"
    if [ -z "$fn" ]; then
        play_sound error
        OUT+=("search: $arg: Hier gibt es nichts zu durchsuchen.")
        return
    fi

    th_source_if_fn "$fn"          # Suchmodul bei Bedarf laden
    play_sound cmd_touch
    "$fn" "$np"
}
