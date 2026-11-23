# ============================================================
#  TerminalHero - Terminal-Befehl: ls
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#  Ordnerinhalt im rechten Fenster zeigen (-a zeigt Verstecktes).
# ============================================================

builtin_ls() {
    local show_all=0 path="" arg
    for arg in "$@"; do
        case "$arg" in
            -a|-la|-al|-l|-1) show_all=1 ;;
            -*) : ;;
            *) path+="$arg " ;;
        esac
    done
    path="${path% }"        # Namen mit Leerzeichen bleiben so erhalten
    local np
    if [ -z "$path" ]; then
        np="$CWD"
    else
        np="$(resolve_path "$path" "$CWD")"
    fi
    zone_denied ls "$path" "$np" && return
    district_ensure "$np"          # Stadtteil bei Bedarf laden
    if [ -z "${TYPE[$np]}" ]; then
        play_sound error
        OUT+=("ls: $path: Datei oder Verzeichnis nicht gefunden")
        return
    fi
    if [ "${TYPE[$np]}" = "f" ]; then
        OUT+=("${np##*/}")
        return
    fi
    # Ordnerfenster rechts auf das Ziel umschalten
    VIEW_DIR="$np"
    SHOW_LS=1
    LS_SHOW_ALL=$show_all
    FOLDER_SCROLL=0            # neue Liste beginnt oben
}
