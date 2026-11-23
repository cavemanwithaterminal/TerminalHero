# ============================================================
#  TerminalHero - Gegnerart: Molerats
# ------------------------------------------------------------
#  Molerats sind große, angriffslustige Schweine (Kategorie
#  »Virus«). Sie greifen nach drei Sekunden an, machen 10 Tokens
#  Schaden pro Sekunde und lassen MoleratCode fallen.
#
#  Vorkommen:
#    * Molerathöhle (Höhleneingang): drei feste Molerats. Sie
#      kehren nach dem Löschen nicht zurück (alte Story-Regel).
#    * Brachland/Steppe/Moleratgebiet: zwei Molerats, danach
#      jeweils 1.1/1.2, 2.1/2.2 und 3.1/3.2 mit je drei Molerats.
#      In diesen Gebieten spawnen getötete Molerats nach 24
#      Ingame-Stunden einzeln nach, solange das Gebietsmaximum
#      noch nicht erreicht ist. Jedes Gebiet hat seinen eigenen
#      Zähler und seinen eigenen Respawn-Timer.
#    * Brachland/Steppe/Canyon/Höhleneingang: drei Tunnel
#      (Höhlentunnel1 -> 2 -> 3), in jedem genau ein Molerat.
#      Getötete Tunnel-Molerats kommen nach 24 Ingame-Stunden
#      einzeln nach, maximal jedoch ein Molerat je Tunnel.
#    * GroßeHöhlenkammer: fünf Molerats (24h-Takt, max. 5) und
#      bis zu zwei MoleratKrieger (48h-Takt, max. 2). Krieger
#      machen 15 Tokens/s Schaden, greifen nach 3 Sekunden an,
#      kosten 75 zusätzliche rm-Tokens und lassen 3 MoleratCode
#      fallen. Molerats lassen seit dieser Erweiterung 2 Code fallen.
#    * KöniginnenKammer (hinter dem Großen Höhleneingang/Breiten
#      Tunnel): drei MoleratKrieger (48h-Takt, max. 3, eigener
#      Zähler). Die dortige MoleratKönigin steht in einer eigenen
#      Datei (Gegner/MoleratKoenigin.sh) und respawnt nicht.
#
#  Die Dateien heißen bewusst Molerat1, Molerat2, Molerat3 -
#  ohne Klammern, damit man sie im CLI schnell tippen kann.
#  »rm Molerat1 Molerat2 Molerat3« löscht alle drei in einem Aufruf.
#
#  Der Tod in der Höhle wird als Bitmaske gespeichert (MOLERATS_DEAD):
#     Bit 1 = Molerat1 · Bit 2 = Molerat2 · Bit 4 = Molerat3
#  Die neuen Gebiete nutzen dagegen MOLERAT_AREA_DEAD[Gebiet] und
#  MOLERAT_AREA_NEXT[Gebiet] (Anzahl Toter + nächster Spawn in
#  absoluten Ingame-Minuten). So bleibt die alte Höhlen-Story
#  unberührt und jedes Gebiet zählt unabhängig.
# ============================================================

# Fester Ort: die Molerathöhle auf dem Schreibtisch.
molerats_cave_dir() {
    printf '%s/Schreibtisch/Höhleneingang/Molerathöhle' "$HOME_DIR"
}

molerats_path() {   # <1|2|3>
    printf '%s/Molerat%s' "$(molerats_cave_dir)" "$1"
}

# Neuer Außenbereich: Brachland/Steppe mit dem Moleratgebiet.
molerats_steppe_dir() {
    printf '%s/Schreibtisch/Brachland/Steppe' "$HOME_DIR"
}

molerats_gebiet_dir() {
    printf '%s/Moleratgebiet' "$(molerats_steppe_dir)"
}

# Höhlentunnel im Canyon: Höhlentunnel1 -> 2 -> 3.
molerats_canyon_dir() {
    printf '%s/Canyon' "$(molerats_steppe_dir)"
}

molerats_canyon_hole_dir() {
    printf '%s/Höhleneingang' "$(molerats_canyon_dir)"
}

# Große Höhlenkammer am Ende der Canyon-Tunnelkette. Hier leben fünf
# Molerats und bis zu zwei MoleratKrieger (eigene Zähler/Timer unten).
molerats_chamber_dir() {
    printf '%s/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer' \
        "$(molerats_canyon_hole_dir)"
}

# Vom Nordgang der Großen Höhlenkammer führt der Weg in den Großen
# Höhleneingang und von dort durch den Breiten Tunnel tiefer in den Berg.
molerats_grosser_eingang_dir() {
    printf '%s/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang' \
        "$(molerats_chamber_dir)"
}

# KöniginnenKammer: Reich der MoleratKönigin, Wache der drei Krieger.
molerats_koenigin_dir() {
    printf '%s/BreiterTunnel/KöniginnenKammer' "$(molerats_grosser_eingang_dir)"
}

# Alle Gebiete in fester Reihenfolge. Der Schlüssel ist der Ordnername
# im Moleratgebiet bzw. im Canyon-Höhleneingang; die Große Höhlenkammer
# wird über molerats_chamber_dir() auf ihren (umlautfreien) Schlüssel
# abgebildet.
molerats_area_keys() {
    printf '%s\n' \
        Moleratgebiet \
        Moleratgebiet1.1 Moleratgebiet1.2 \
        Moleratgebiet2.1 Moleratgebiet2.2 \
        Moleratgebiet3.1 Moleratgebiet3.2 \
        Hoehlentunnel1 Hoehlentunnel2 Hoehlentunnel3 \
        GrosseHoehlenkammer
}

molerats_area_path() {   # <Gebietsname>
    local base; base="$(molerats_gebiet_dir)"
    local hole; hole="$(molerats_canyon_hole_dir)"
    case "$1" in
        Moleratgebiet)   printf '%s' "$base" ;;
        Moleratgebiet1.1) printf '%s/Moleratgebiet1.1' "$base" ;;
        Moleratgebiet1.2) printf '%s/Moleratgebiet1.1/Moleratgebiet1.2' "$base" ;;
        Moleratgebiet2.1) printf '%s/Moleratgebiet2.1' "$base" ;;
        Moleratgebiet2.2) printf '%s/Moleratgebiet2.1/Moleratgebiet2.2' "$base" ;;
        Moleratgebiet3.1) printf '%s/Moleratgebiet3.1' "$base" ;;
        Moleratgebiet3.2) printf '%s/Moleratgebiet3.1/Moleratgebiet3.2' "$base" ;;
        Hoehlentunnel1)   printf '%s/Höhlentunnel1' "$hole" ;;
        Hoehlentunnel2)   printf '%s/Höhlentunnel1/Höhlentunnel2' "$hole" ;;
        Hoehlentunnel3)   printf '%s/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3' "$hole" ;;
        GrosseHoehlenkammer) printf '%s' "$(molerats_chamber_dir)" ;;
        *) return 1 ;;
    esac
}

molerats_area_max() {    # <Gebietsname> -> 1, 2, 3 oder 5
    case "$1" in
        Moleratgebiet)                   printf '2' ;;
        Hoehlentunnel1|Hoehlentunnel2|Hoehlentunnel3) printf '1' ;;
        GrosseHoehlenkammer)             printf '5' ;;
        *)                               printf '3' ;;
    esac
}

# Gebietsname zu einem Ordnerpfad (leer, wenn es kein Moleratgebiet ist).
molerats_area_key_of_path() {
    local p="$1" k
    [ -n "$p" ] || return 1
    for k in $(molerats_area_keys); do
        if [ "$p" = "$(molerats_area_path "$k")" ]; then
            printf '%s' "$k"
            return 0
        fi
    done
    return 1
}

# Die Gegnerart bei kern/gegner.sh anmelden (idempotent).
molerats_define_type() {
    gegner_define_type molerat virus "Molerat" \
        3 10 50 moleratcode 2 molerat_on_kill "Oink, Oink"
}

# --- MoleratKrieger -------------------------------------------------
# Schwerer Gegner in der Großen Höhlenkammer: 15 Tokens/s, Angriff nach
# drei Sekunden, 75 zusätzliche rm-Kosten und drei MoleratCode als Beute.
# Die EXP ergeben sich wie bei allen Kämpfen aus den bezahlten Tokens
# (1 EXP je 5 Tokens): 50 Grundkosten + 75 Kriegerkosten = 125 Tokens,
# also 25 EXP pro Krieger.
molerats_krieger_define_type() {
    gegner_define_type moleratkrieger virus "MoleratKrieger" \
        3 15 75 moleratcode 3 moleratkrieger_on_kill \
        "GRRR! Ein MoleratKrieger versperrt den Weg."
}

# Welche Kammern halten MoleratKrieger? Jede führt ihren eigenen Zähler
# und Timer in MOLERAT_KRIEGER_DEAD/NEXT.
molerats_krieger_area_keys() {
    printf '%s\n' GrosseHoehlenkammer KoeniginnenKammer
}

molerats_krieger_max() {   # <Gebiet> -> 2 in der Großen Kammer, 3 beim Nest
    case "${1:-GrosseHoehlenkammer}" in
        KoeniginnenKammer) printf '3' ;;
        *)                 printf '2' ;;
    esac
}

molerats_krieger_area_dir() {   # <Gebiet> -> Ordner der Kammer
    case "$1" in
        GrosseHoehlenkammer) molerats_chamber_dir ;;
        KoeniginnenKammer)   molerats_koenigin_dir ;;
        *) return 1 ;;
    esac
}

molerats_krieger_area_of_path() {   # <Ordner> -> Gebietsname
    local p="$1" a
    [ -n "$p" ] || return 1
    for a in $(molerats_krieger_area_keys); do
        if [ "$p" = "$(molerats_krieger_area_dir "$a")" ]; then
            printf '%s' "$a"
            return 0
        fi
    done
    return 1
}

molerats_krieger_path() {   # <Gebiet> <1|2|3>
    printf '%s/MoleratKrieger%s' "$(molerats_krieger_area_dir "$1")" "$2"
}

molerats_krieger_dead() {   # [<Gebiet>] -> Anzahl toter Krieger
    local k="${1:-GrosseHoehlenkammer}" v
    v="${MOLERAT_KRIEGER_DEAD[$k]:-0}"
    case "$v" in ''|*[!0-9]*) v=0 ;; esac
    printf '%s' "$v"
}

molerats_krieger_next() {   # [<Gebiet>] -> nächster Spawn (absolute Spielminute)
    local k="${1:-GrosseHoehlenkammer}" v
    v="${MOLERAT_KRIEGER_NEXT[$k]:-0}"
    case "$v" in ''|*[!0-9]*) v=0 ;; esac
    printf '%s' "$v"
}

# 48 Ingame-Stunden Takt (zwei Spieltage).
molerats_krieger_interval() {
    printf '%s' "$(( ${CLOCK_DAY_MIN:-1440} * 2 ))"
}

molerats_krieger_normalize_state() {   # [<Gebiet>]
    local k="${1:-GrosseHoehlenkammer}" max dead next
    max="$(molerats_krieger_max "$k")"
    dead="$(molerats_krieger_dead "$k")"
    next="$(molerats_krieger_next "$k")"
    [ "$dead" -gt "$max" ] && dead="$max"
    [ "$dead" -lt 0 ] && dead=0
    if [ "$dead" -eq 0 ]; then
        next=0
    elif [ "$next" -le 0 ]; then
        next=$(( $(molerats_now_minutes) + $(molerats_krieger_interval) ))
    fi
    MOLERAT_KRIEGER_DEAD["$k"]="$dead"
    MOLERAT_KRIEGER_NEXT["$k"]="$next"
}

# <lebendig> Krieger in einer Kammer aufbauen (Plätze 1..max).
molerats_krieger_place() {   # <Gebiet> [<lebendig>]
    local k="${1:-GrosseHoehlenkammer}" alive="${2:-0}" max i p
    max="$(molerats_krieger_max "$k")"
    [ "$alive" -lt 0 ] && alive=0
    [ "$alive" -gt "$max" ] && alive="$max"
    for (( i = 1; i <= max; i++ )); do
        p="$(molerats_krieger_path "$k" "$i")"
        if [ "$i" -le "$alive" ]; then
            gegner_place moleratkrieger "$p"
        else
            gegner_remove_path "$p"
        fi
    done
}

moleratkrieger_on_kill() {
    local p="${1:-}" k max dead
    k="$(molerats_krieger_area_of_path "${p%/*}")" || return 0
    max="$(molerats_krieger_max "$k")"
    dead="$(molerats_krieger_dead "$k")"
    [ "$dead" -ge "$max" ] && return 0
    dead=$(( dead + 1 ))
    MOLERAT_KRIEGER_DEAD["$k"]="$dead"
    if [ "$dead" -eq 1 ] || [ "$(molerats_krieger_next "$k")" -le 0 ]; then
        MOLERAT_KRIEGER_NEXT["$k"]=$(( $(molerats_now_minutes) + $(molerats_krieger_interval) ))
    fi
    return 0
}

# Einmal pro Schleife: fällige Krieger-Nachspawns. Jede Kammer hat ihren
# eigenen 48h-Takt; es kommt höchstens ein Krieger je Kammer und Takt nach.
molerats_krieger_respawn_tick() {
    if declare -F uhrzeit_running >/dev/null 2>&1 && ! uhrzeit_running; then
        return 1
    fi
    molerats_krieger_define_type
    local now k max dead next p ort changed=0
    now="$(molerats_now_minutes)"
    for k in $(molerats_krieger_area_keys); do
        max="$(molerats_krieger_max "$k")"
        dead="$(molerats_krieger_dead "$k")"
        next="$(molerats_krieger_next "$k")"
        [ "$dead" -gt "$max" ] && dead="$max"
        if [ "$dead" -le 0 ]; then
            MOLERAT_KRIEGER_DEAD["$k"]=0
            MOLERAT_KRIEGER_NEXT["$k"]=0
            continue
        fi
        if [ "$next" -le 0 ]; then
            MOLERAT_KRIEGER_NEXT["$k"]=$(( now + $(molerats_krieger_interval) ))
            continue
        fi
        [ "$now" -ge "$next" ] || continue

        dead=$(( dead - 1 ))
        MOLERAT_KRIEGER_DEAD["$k"]="$dead"
        if [ "$dead" -gt 0 ]; then
            MOLERAT_KRIEGER_NEXT["$k"]=$(( next + $(molerats_krieger_interval) ))
        else
            MOLERAT_KRIEGER_NEXT["$k"]=0
        fi
        molerats_krieger_place "$k" $(( max - dead ))
        changed=1

        p="$(molerats_krieger_area_dir "$k")"
        if [ "${CWD:-}" = "$p" ]; then
            if [ "$k" = "KoeniginnenKammer" ]; then
                ort="KöniginnenKammer"
            else
                ort="Großen Höhlenkammer"
            fi
            OUT+=("")
            OUT+=("[ GEGNER ] Ein MoleratKrieger ist in der ${ort} nachgekommen.")
        fi
    done
    [ "$changed" = "1" ] && return 0
    return 1
}

# Bit für einen Höhlen-Molerat (1, 2, 4).
molerat_bit() {
    case "$1" in
        1) printf '1' ;;
        2) printf '2' ;;
        3) printf '4' ;;
        *) return 1 ;;
    esac
}

molerats_all_dead() {
    case "${MOLERATS_DEAD:-0}" in ''|*[!0-9]*) return 1 ;; esac
    [ $(( MOLERATS_DEAD & 7 )) -eq 7 ]
}

# Aktuelle Ingame-Minute, ohne harte Abhängigkeit zur Uhr (Unit-Tests).
molerats_now_minutes() {
    if declare -F uhrzeit_minutes >/dev/null 2>&1; then
        uhrzeit_minutes
    else
        printf '0'
    fi
}

molerats_area_dead() {   # <Gebiet> -> Anzahl toter Molerats
    local k="$1" v
    v="${MOLERAT_AREA_DEAD[$k]:-0}"
    case "$v" in ''|*[!0-9]*) v=0 ;; esac
    printf '%s' "$v"
}

molerats_area_next() {   # <Gebiet> -> nächster Spawn (absolute Spielminute)
    local k="$1" v
    v="${MOLERAT_AREA_NEXT[$k]:-0}"
    case "$v" in ''|*[!0-9]*) v=0 ;; esac
    printf '%s' "$v"
}

# Zustand aller Gebiete auf gültige Werte bringen (ohne Dateisystem).
molerats_normalize_state() {
    local k max dead next
    for k in $(molerats_area_keys); do
        max="$(molerats_area_max "$k")"
        dead="$(molerats_area_dead "$k")"
        next="$(molerats_area_next "$k")"
        [ "$dead" -gt "$max" ] && dead="$max"
        [ "$dead" -lt 0 ] && dead=0
        if [ "$dead" -eq 0 ]; then
            next=0
        elif [ "$next" -le 0 ]; then
            next=$(( $(molerats_now_minutes) + ${CLOCK_DAY_MIN:-1440} ))
        fi
        MOLERAT_AREA_DEAD["$k"]="$dead"
        MOLERAT_AREA_NEXT["$k"]="$next"
    done
    return 0
}

# Ein Gebiet mit <lebendig> Molerats aufbauen. Die niedrigsten Plätze
# werden belegt; nicht benötigte Dateien werden entfernt.
molerats_place_area() {   # <Gebiet> <lebendig>
    local k="$1" alive="${2:-0}" max i p
    max="$(molerats_area_max "$k")"
    [ "$alive" -lt 0 ] && alive=0
    [ "$alive" -gt "$max" ] && alive="$max"
    for (( i = 1; i <= max; i++ )); do
        p="$(molerats_area_path "$k")/Molerat$i"
        if [ "$i" -le "$alive" ]; then
            gegner_place molerat "$p"
        else
            gegner_remove_path "$p"
        fi
    done
    return 0
}

# Nach dem Löschen: Höhle über die Bitmaske, neue Gebiete über ihren
# eigenen Todeszähler und den 24-Stunden-Timer führen.
molerat_on_kill() {
    local p="$1" name="${1##*/}" n bit area max dead
    case "$p" in
        "$(molerats_cave_dir)"/Molerat[1-3])
            n="${name#Molerat}"
            bit="$(molerat_bit "$n")" || return 0
            case "${MOLERATS_DEAD:-0}" in ''|*[!0-9]*) MOLERATS_DEAD=0 ;; esac
            MOLERATS_DEAD=$(( MOLERATS_DEAD | bit ))
            return 0
            ;;
    esac

    area="$(molerats_area_key_of_path "${p%/*}")" || return 0
    max="$(molerats_area_max "$area")"
    dead="$(molerats_area_dead "$area")"
    [ "$dead" -ge "$max" ] && return 0
    dead=$(( dead + 1 ))
    MOLERAT_AREA_DEAD["$area"]="$dead"
    # Der Timer startet beim ersten Toten. Weitere Kills in derselben
    # 24-Stunden-Periode verschieben ihn nicht.
    if [ "$dead" -eq 1 ] || [ "$(molerats_area_next "$area")" -le 0 ]; then
        MOLERAT_AREA_NEXT["$area"]=$(( $(molerats_now_minutes) + ${CLOCK_DAY_MIN:-1440} ))
    fi
    return 0
}

# Beim Start/Laden: tote Molerats entfernen, lebende aufbauen.
molerats_apply_state() {
    molerats_define_type
    case "${MOLERATS_DEAD:-0}" in ''|*[!0-9]*) MOLERATS_DEAD=0 ;; esac
    [ "$MOLERATS_DEAD" -lt 0 ] && MOLERATS_DEAD=0
    [ "$MOLERATS_DEAD" -gt 7 ] && MOLERATS_DEAD=7

    local i p bit k max dead
    for i in 1 2 3; do
        p="$(molerats_path "$i")"
        bit="$(molerat_bit "$i")"
        if [ $(( MOLERATS_DEAD & bit )) -ne 0 ]; then
            gegner_remove_path "$p"
        else
            gegner_place molerat "$p"
        fi
    done

    molerats_normalize_state
    for k in $(molerats_area_keys); do
        max="$(molerats_area_max "$k")"
        dead="$(molerats_area_dead "$k")"
        molerats_place_area "$k" "$(( max - dead ))"
    done

    # MoleratKrieger in beiden Kammern (eigene Zähler, 48h-Takt).
    molerats_krieger_define_type
    local ka
    for ka in $(molerats_krieger_area_keys); do
        molerats_krieger_normalize_state "$ka"
        molerats_krieger_place "$ka" \
            $(( $(molerats_krieger_max "$ka") - $(molerats_krieger_dead "$ka") ))
    done

    # KöniginnenKammer (MoleratKönigin, drei Krieger, Tagebuch). Die Datei
    # meldet sich selbst an und bringt eigenen Zustand mit; fehlt sie,
    # bleibt die übrige Höhle unverändert.
    if ! declare -F molerat_koenigin_apply_state >/dev/null 2>&1 \
       && declare -F th_source_if_fn >/dev/null 2>&1; then
        th_source_if_fn molerat_koenigin_apply_state || true
    fi
    declare -F molerat_koenigin_apply_state >/dev/null 2>&1 \
        && molerat_koenigin_apply_state
    return 0
}

# Einmal pro Spielschleife: fällige Nachspawns anwenden. Pro Gebiet
# kommt höchstens ein Molerat alle 24 Ingame-Stunden zurück.
molerats_respawn_tick() {
    if declare -F uhrzeit_running >/dev/null 2>&1 && ! uhrzeit_running; then
        return 1
    fi
    molerats_define_type
    local now k max dead next p changed=0
    now="$(molerats_now_minutes)"
    for k in $(molerats_area_keys); do
        max="$(molerats_area_max "$k")"
        dead="$(molerats_area_dead "$k")"
        next="$(molerats_area_next "$k")"
        [ "$dead" -gt "$max" ] && dead="$max"
        if [ "$dead" -le 0 ]; then
            MOLERAT_AREA_DEAD["$k"]=0
            MOLERAT_AREA_NEXT["$k"]=0
            continue
        fi
        if [ "$next" -le 0 ]; then
            MOLERAT_AREA_NEXT["$k"]=$(( now + ${CLOCK_DAY_MIN:-1440} ))
            continue
        fi
        [ "$now" -ge "$next" ] || continue

        dead=$(( dead - 1 ))
        MOLERAT_AREA_DEAD["$k"]="$dead"
        if [ "$dead" -gt 0 ]; then
            # Den absoluten 24h-Takt beibehalten. Ist der Timer durch
            # eine große Zeitverschiebung (z. B. Schlafen) überfällig,
            # holt der nächste Schleifendurchlauf den nächsten Spawn nach.
            MOLERAT_AREA_NEXT["$k"]=$(( next + ${CLOCK_DAY_MIN:-1440} ))
        else
            MOLERAT_AREA_NEXT["$k"]=0
        fi
        molerats_place_area "$k" "$(( max - dead ))"
        changed=1

        p="$(molerats_area_path "$k")"
        if [ "${CWD:-}" = "$p" ]; then
            OUT+=("")
            OUT+=("[ GEGNER ] Ein Molerat ist im Gebiet nachgekommen.")
        fi
    done
    if [ "$changed" = "1" ]; then
        return 0
    fi
    # Krieger haben einen eigenen 48h-Takt und werden separat geprüft.
    molerats_krieger_respawn_tick && return 0
    return 1
}
