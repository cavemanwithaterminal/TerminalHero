# ============================================================
#  TerminalHero - Terminal-Befehl: cat
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#  Datei lesen. Binärdateien und Ordner werden abgewiesen.
# ============================================================

builtin_cat() {
    LAST_CAT_OK=0
    LAST_CAT_PATH=""
    if [ -z "$1" ]; then
        play_sound error
        OUT+=("cat: fehlender Dateiname")
        return
    fi
    local np
    np="$(resolve_path "$1" "$CWD")"
    LAST_CAT_PATH="$np"
    zone_denied cat "$1" "$np" && return
    district_ensure "$np"          # Stadtteil bei Bedarf laden
    if [ -z "${TYPE[$np]}" ]; then
        play_sound error
        OUT+=("cat: $1: Datei oder Verzeichnis nicht gefunden")
        return
    fi
    if [ "${TYPE[$np]}" = "d" ]; then
        play_sound error
        OUT+=("cat: $1: Ist ein Verzeichnis")
        return
    fi
    if is_binary_name "$np"; then
        play_sound error
        OUT+=("cat: $1: Binärdatei – »cat« würde nur Datenmüll ausspucken.")
        OUT+=("Vielleicht hilft »file $1«.")
        return
    fi
    if [[ "$np" == /proc/* || "$np" == /sys/* || "$np" == /dev/* ]]; then
        play_sound error
        OUT+=("cat: $1: Keine Berechtigung")
        return
    fi
    LAST_CAT_OK=1
    play_sound cmd_cat
    local c
    if [ -n "${CONTENT[$np]}" ]; then
        printf -v c '%b' "${CONTENT[$np]}"
        local l
        while IFS= read -r l; do OUT+=("$l"); done <<< "$c"
    else
        OUT+=("[Datei ist leer]")
    fi
}
