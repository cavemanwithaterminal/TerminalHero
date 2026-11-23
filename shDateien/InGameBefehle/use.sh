# ============================================================
#  TerminalHero - Spiel-Befehl: use
#
#  »use <objekt>« BENUTZT etwas, das in der Welt steht: Einrichtung
#  aus dem Interior-Register (kern/interior.sh) - zum Beispiel die
#  Matratze in der eingestürzten Baracke oder einen Stuhl. Anders als
#  »grep« (etwas herausziehen) nimmt »use« normalerweise nichts mit: es
#  löst die Benutzung aus - bei der Matratze das Schlaf-Fenster
#  (kern/schlafen.sh), beim Stuhl das Sitz-Fenster (kern/sitzen.sh).
#
#  Ausnahme Fundorte: Ein Fundort mit dem Modus »use« (world_item_place
#  ... use) wird ebenfalls mit »use« eingesammelt. Für Bits gilt das
#  ausdrücklich NICHT - sie werden mit »grep Bits« aufgenommen.
#
#  Zu Spielbeginn GESPERRT (Amnesie): Der Virus hat den Befehl
#  mitgenommen. Erst in der Baracken-Szene bringt Pixi dem Agenten
#  »use« bei (Charakter/verlag.sh) - dort weist sie auf die Matratze hin.
#
#  Aufruf:  use <objekt>
#
#  Die Benutzungsfunktion bekommt die Interior-id als $1 und seit den
#  Zeitungskästen zusätzlich den aufgelösten PFAD als $2. So können
#  mehrere gleichartige Objekte (fünf Kästen) ihren eigenen Zustand
#  führen, ohne fünf verschiedene Interior-IDs zu brauchen.
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
# ============================================================

builtin_use() {
    if ! knows use; then
        play_sound error
        OUT+=("»use« …? Diesen Befehl kenne ich nicht mehr.")
        OUT+=("Der Virus hat ihn mir genommen – wie so vieles. Noch.")
        return
    fi
    if [ -z "$1" ]; then
        play_sound error
        OUT+=("use: Was soll ich benutzen?")
        OUT+=("Verwendung: use <objekt>")
        return
    fi

    local arg="$1" np id fn
    np="$(resolve_path "$arg" "$CWD")"
    zone_denied use "$arg" "$np" && return
    district_ensure "$np"          # Stadtteil bei Bedarf laden

    id="${INTERIOR_AT[$np]:-}"
    if [ -z "$id" ]; then
        # Fundort mit Aufnahme-Modus »use« (Sonderfälle, keine Bits): einsammeln.
        if [ -n "${WORLD_ITEM[$np]:-}" ]; then
            if [ "${WORLD_MODE[$np]:-grep}" = "use" ]; then
                play_sound cmd_touch
                world_item_pickup "$np"
            else
                play_sound error
                OUT+=("use: $arg: Das muss ich herausziehen – mit »grep ${arg##*/}«.")
            fi
            return
        fi
        play_sound error
        if [ -z "${TYPE[$np]:-}" ]; then
            OUT+=("use: $arg: Datei oder Verzeichnis nicht gefunden")
        else
            OUT+=("use: $arg: Das lässt sich nicht benutzen.")
        fi
        return
    fi

    fn="${INTERIOR_USE[$id]:-}"
    if [ -z "$fn" ]; then
        play_sound error
        OUT+=("use: $arg: Dafür gibt es keine Verwendung.")
        return
    fi

    th_source_if_fn "$fn"          # Benutzungs-Modul bei Bedarf laden
    play_sound cmd_touch
    "$fn" "$id" "$np"
}
