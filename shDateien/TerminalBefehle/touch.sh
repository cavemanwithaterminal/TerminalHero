# ============================================================
#  TerminalHero - Terminal-Befehl: touch
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#  Gespräch mit einer beseelten Datei ODER Zeitstempel. Neue Dateien
#  anzulegen ist noch gesperrt (TOUCH_CREATE_KNOWN).
# ============================================================

builtin_touch() {
    if [ -z "$1" ]; then
        play_sound error
        OUT+=("touch: fehlender Dateiname")
        return
    fi
    local np
    np="$(resolve_path "$1" "$CWD")"
    zone_denied touch "$1" "$np" && return
    district_ensure "$np"          # Stadtteil bei Bedarf laden

    # Gegner sind keine Gesprächspartner. Für sie gibt es »rm«.
    if [ -n "${GEGNER_AT[$np]:-}" ]; then
        play_sound error
        OUT+=("touch: ${1##*/} ist ein Gegner. Der Virus hört nicht zu.")
        OUT+=("Mit einer ausgerüsteten Waffe lässt er sich mit »rm ${1##*/}« löschen.")
        return
    fi

    # Beseelte Datei -> Gespräch beginnen
    if [ -n "${DIALOG[$np]}" ]; then
        th_source_if_fn "${DIALOG[$np]}"   # Dialog-Modul bei Bedarf laden
        play_sound cmd_touch
        "${DIALOG[$np]}"
        return
    fi

    # Fundort ohne Dialog (nicht beseelt): Der Gegenstand schweigt.
    # (Beseelte Fundorte reagieren schon oben über DIALOG[] – z. B. die
    #  Armbanduhr, die über item_talk angemeldet ist.)
    if [ -n "${WORLD_ITEM[$np]:-}" ]; then
        play_sound cmd_touch
        OUT+=("")
        OUT+=("Der Gegenstand schweigt. Er ist zum Ansehen, Lesen – und zum Herausziehen da.")
        OUT+=("Vielleicht mit »grep ${1##*/}«.")
        return
    fi

    # Existiert schon: nur Zeitstempel aktualisieren
    if [ -n "${TYPE[$np]}" ]; then
        if is_binary_name "$np"; then
            play_sound error
            OUT+=("touch: $1: Das ist nichts zum Anfassen. Nur ansehen – mit »file $1«.")
            return
        fi
        play_sound cmd_touch
        return
    fi

    # Neue leere Datei anlegen – diese Fähigkeit ist noch gesperrt
    if [ "${TOUCH_CREATE_KNOWN:-0}" != "1" ]; then
        play_sound error
        OUT+=("touch: $1: gibt es nicht.")
        OUT+=("  Etwas Neues erschaffen kann ich noch nicht – der Virus hat mir diese Fähigkeit genommen.")
        return
    fi
    local parent="${np%/*}"; [ -z "$parent" ] && parent="/"
    if [ -z "${TYPE[$parent]}" ] || [ "${TYPE[$parent]}" != "d" ]; then
        play_sound error
        OUT+=("touch: $1: Zielverzeichnis existiert nicht")
        return
    fi
    TYPE["$np"]="f"
    CHILDREN["$parent"]+="$(basename "$np")"$'\n'
    play_sound cmd_touch
    OUT+=("touched: ${np##*/}")
}
