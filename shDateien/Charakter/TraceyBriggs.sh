# ============================================================
#  TerminalHero - Charakter: Tracey Briggs
# ------------------------------------------------------------
#  Tracey ist Rachels Zeitungsverteilerin. Sie ist keine feste
#  Angestellte, sondern eine Tagelöhnerin: meistens trägt sie für den
#  DailyPulse die Zeitungen aus, manchmal arbeitet sie im Restaurant oder
#  nimmt hier und da kleinere Jobs an.
#
#  Im Spiel steht sie zuerst im Ostdistrikt, direkt vor Jimmys Haus. Dort
#  hat sie gerade Jimmy Page die aktuelle Ausgabe verkauft, als der Agent
#  sie im Auftrag von Rachel sucht (TRACEY_GIVEN). Danach geht sie zurück
#  in den DailyPulse-Verlag (TRACEY_FOUND) und ist dort ansprechbar.
#  Sobald Rachel sich bei ihr bedankt hat (TRACEY_DONE), ist Traceys
#  Vermissten-Quest abgeschlossen. Danach hat sie wieder ihren Rhythmus:
#  Sie zieht als Zeitungsausträgerin zwischen den fünf Stadtdistrikten und
#  dem Haupteingang umher und bleibt je 4 SPIELSTUNDEN an einem Ort. Der
#  Wechsel hängt an der Spieluhr (kern/Uhrzeit.sh), nicht an Echtzeit.
#
#  Bei ihr kann man - wie am Zeitungskasten - die aktuelle DailyPulse-
#  Ausgabe kaufen (ZEITUNG_EDITION / ZEITUNG_PRICE). Sie hat immer ein
#  Exemplar dabei.
#
#  EAGER geladen (require_char TraceyBriggs): tracey_apply_state setzt ihre
#  Datei beim Start, beim Laden eines Spielstands und nach dem Fund an den
#  richtigen Ort; tracey_schedule_apply rückt sie im Hauptlauf weiter. Die
#  Mechanik dafür (TYPE + CHILDREN) steckt in kern/fs.sh.
# ============================================================

# --- Wo Tracey gerade ist ----------------------------------------------
tracey_ost_dir()    { printf '%s/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt' "$HOME_DIR"; }
tracey_verlag_dir() { printf '%s/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse' "$HOME_DIR"; }

# Ist Tracey nach ihrer Quest wieder auf Stadttour? Erst wenn Rachel sich
# im Verlag bedankt hat (TRACEY_DONE), verlässt sie den festen Platz.
tracey_wander_active() { [ "${TRACEY_DONE:-0}" = "1" ]; }

# Startzeit der Tour: Spielminute, in der Rachel sich bedankt hat. Der Wert
# wird gespeichert (TRACEY_TOUR_START), damit die Stationen auch nach einem
# Neuladen exakt 4 Spielstunden dauern und nicht an der Uhrzeit hängen.
tracey_tour_ensure_start() {
    local now
    tracey_wander_active || return 0
    case "${TRACEY_TOUR_START:-}" in
        ''|*[!0-9]*)
            now="$(uhrzeit_minutes)"
            TRACEY_TOUR_START="$now"
            ;;
    esac
    return 0
}

# Die sechs Orte ihrer Tour. Ein Wechsel alle 4 Spielstunden = 240
# Spielminuten; sechs Orte ergeben einen 24-Stunden-Rhythmus.
# Reihenfolge: Süddistrikt -> Zentrum -> Ostdistrikt -> Norddistrikt ->
# Westdistrikt -> Haupteingang, dann von vorn.
tracey_wander_dir() {
    local base elapsed slot
    base="$(district_base)"
    tracey_tour_ensure_start
    elapsed=$(( $(uhrzeit_minutes) - ${TRACEY_TOUR_START:-0} ))
    [ "$elapsed" -lt 0 ] && elapsed=0
    slot=$(( (elapsed / 240) % 6 ))
    case "$slot" in
        0) printf '%s/Süddistrikt' "$base" ;;
        1) printf '%s/Zentrum' "$base" ;;
        2) printf '%s/Ostdistrikt' "$base" ;;
        3) printf '%s/Norddistrikt' "$base" ;;
        4) printf '%s/Westdistrikt' "$base" ;;
        5) printf '%s' "$base" ;;
    esac
}

tracey_dir() {
    if tracey_wander_active; then
        tracey_wander_dir
    elif [ "${TRACEY_FOUND:-0}" = "1" ] && [ "${AUFLAGE_GIVEN:-0}" != "1" ]; then
        # Nach dem Fund ist sie im Verlag - bis die Sperrzone-Ausgabe
        # verteilt wird. Vor TRACEY_DONE bleibt dieser feste Platz.
        tracey_verlag_dir
    else
        tracey_ost_dir
    fi
}

# Anzeigename des aktuellen Ortes (Dialogkopf, Dateitext).
tracey_place_label() {
    local p="${1:-$(tracey_dir)}"
    case "$p" in
        "$(district_base)")        printf 'HAUPTEINGANG' ;;
        *"/Norddistrikt")          printf 'NORDDISTRIKT' ;;
        *"/Ostdistrikt")           printf 'OSTDISTRIKT' ;;
        *"/Süddistrikt")           printf 'SÜDDISTRIKT' ;;
        *"/Westdistrikt")          printf 'WESTDISTRIKT' ;;
        *"/Zentrum")               printf 'ZENTRUM' ;;
        *"/DailyPulse")            printf 'DAILYPULSE · VERLAG' ;;
        *)                         printf 'UNTERWEGS' ;;
    esac
}

tracey_header() {
    local d
    d="$(tracey_dir)"
    if [ "$d" = "$(tracey_verlag_dir)" ]; then
        printf 'DAILYPULSE · VERLAG'
    elif [ "$d" = "$(tracey_ost_dir)" ] && ! tracey_wander_active; then
        printf 'OSTDISTRIKT · VOR JIMMYS HAUS'
    else
        printf '%s · STADTTOUR' "$(tracey_place_label "$d")"
    fi
}

tracey_file_path() {
    local d
    d="$(tracey_dir)"
    [ -n "$d" ] && printf '%s/TraceyBriggs' "$d"
}

tracey_file_text() {
    local status="vor Jimmys Haus im Ostdistrikt"
    if tracey_wander_active; then
        status="auf Stadttour – gerade im $(tracey_place_label)"
    elif [ "${TRACEY_FOUND:-0}" = "1" ] && [ "${AUFLAGE_GIVEN:-0}" != "1" ]; then
        status="zurück im DailyPulse-Verlag"
    elif [ "${AUFLAGE_GIVEN:-0}" = "1" ]; then
        status="mit der Sperrzone-Ausgabe im Ostdistrikt"
    fi

    printf '%s\n' \
        "[DATEI]  Tracey Briggs   ::   DailyPulse-Austrägerin" \
        "Tagelöhnerin. Meistens Zeitungen, manchmal Restaurant, immer unterwegs." \
        "──────────────────────────────────────────────" \
        "Status : $status" \
        "Tour   : Haupteingang + fünf Distrikte, alle 4 Spielstunden ein Ort" \
        "Form   : Datei. Ein User würde sagen: »ständig in Bewegung«." \
        "" \
        "»Ich brauche keinen festen Platz. Ich brauche nur eine Tour," \
        " die sich lohnt.«" \
        "" \
        "cat TraceyBriggs  →  ihre Notizen lesen"
}

tracey_gone() {   # $1 = Pfad
    fs_remove "$1"
    unset "CONTENT[$1]" "DIALOG[$1]" 2>/dev/null
}

# Setzt Tracey an genau einen Ort - abhängig vom Queststand. Idempotent:
# alte Standorte werden geräumt, der aktuelle bleibt. Geräumt werden alle
# möglichen Plätze, damit sie beim Ortswechsel nicht doppelt existiert.
tracey_apply_state() {
    local base p q
    tracey_tour_ensure_start
    base="$(district_base)"
    p="$(tracey_file_path)"

    for q in \
        "$(tracey_verlag_dir)/TraceyBriggs" \
        "$base/TraceyBriggs" \
        "$base/Norddistrikt/TraceyBriggs" \
        "$base/Ostdistrikt/TraceyBriggs" \
        "$base/Süddistrikt/TraceyBriggs" \
        "$base/Westdistrikt/TraceyBriggs" \
        "$base/Zentrum/TraceyBriggs"
    do
        [ "$q" = "$p" ] && continue
        tracey_gone "$q"
    done
    [ -n "$p" ] || return 0

    fs_add f "$p"
    CONTENT["$p"]="$(tracey_file_text)"
    DIALOG["$p"]="dialog_tracey"
    TRACEY_ACTIVE_PATH="$p"
    return 0
}

# Im Hauptlauf: Ist der 4-Stunden-Slot weitergelaufen, zieht Tracey um.
# Der schnelle Weg über TRACEY_ACTIVE_PATH spart unnötige FS-Arbeit.
tracey_schedule_apply() {
    local p
    tracey_wander_active || return 0
    tracey_tour_ensure_start
    p="$(tracey_file_path)"
    [ -n "$p" ] || return 0
    [ "$p" = "${TRACEY_ACTIVE_PATH:-}" ] && return 0
    tracey_apply_state
}

# --- Aktuelle Ausgabe & Preis ------------------------------------------
# Die Edition kommt aus dem Zeitungskasten-Modul. Der Fallback hält die
# Funktion auch dann benutzbar, wenn ein Test nur diese Datei lädt.
tracey_current_edition() {
    local e="${ZEITUNG_EDITION:-bezirke}"
    if declare -F zeitung_current_edition >/dev/null 2>&1; then
        e="$(zeitung_current_edition)"
    fi
    item_exists "$e" || e="bezirke"
    item_exists "$e" && printf '%s' "$e"
}

tracey_price() { printf '%s' "${ZEITUNG_PRICE:-10}"; }

# Ist die Extra-Ausgabe nach Neks Beerdigung gerade im Verkauf?
tracey_extra_active() {
    declare -F zeitung_extra_active >/dev/null 2>&1 || return 1
    zeitung_extra_active
}

# Ein Exemplar verkaufen. Kein eigener dialog_pause - der Aufrufer schließt
# das Gespräch ab. Ohne Argument wird die aktuelle Ausgabe verkauft.
tracey_buy_scene() {
    local eid="${1:-}" price
    [ -n "$eid" ] || eid="$(tracey_current_edition)"
    price="$(tracey_price)"

    if [ -z "$eid" ]; then
        say "Tracey" "Im Moment habe ich keine aktuelle Ausgabe dabei. Morgen wieder."
        return 0
    fi
    if ! declare -F item_exists >/dev/null 2>&1 || ! item_exists "$eid"; then
        say "Tracey" "Diese Ausgabe habe ich gerade nicht dabei."
        return 0
    fi
    if ! bits_take "$price"; then
        play_sound error
        say "Tracey" "So sehr ich will: $(bits_text "$price") sind mehr, als du hast."
        return 0
    fi

    inv_add "$eid"
    play_sound cmd_touch
    OUT+=("")
    OUT+=("   [ Zeitung ]  $(item_name "$eid")")
    OUT+=("   [ Bits ]     -$(bits_text "$price")   (noch $(bits_text "$(bits_count)"))")
    OUT+=("   Ausgabe gekauft. Tracey hat immer ein paar Exemplare dabei.")
    say "Tracey" "Bitte sehr. Und lass dich nicht erwischen, wie du sie umsonst weiterreichst."
}

tracey_buy_menu() {
    local eid price extra=0
    local -a opts=() acts=()
    local act=""
    eid="$(tracey_current_edition)"
    price="$(tracey_price)"
    tracey_extra_active && extra=1
    [ -n "$eid" ] || [ "$extra" = "1" ] || return 0

    while true; do
        OUT+=("")
        opts=(); acts=()
        if [ -n "$eid" ]; then
            say "Tracey" "Aktuelle Ausgabe: »$(item_name "$eid")«. $(bits_text "$price"), wie am Kasten."
            opts+=("Exemplar kaufen ($(bits_text "$price"))"); acts+=("main")
        fi
        if [ "$extra" = "1" ]; then
            say "Tracey" "Und die Extra-Ausgabe mit Neks Nachruf. Auch $(bits_text "$price")."
            opts+=("Extra-Ausgabe kaufen ($(bits_text "$price"))"); acts+=("extra")
        fi
        opts+=("Nichts weiter."); acts+=("leave")
        ask "${opts[@]}"
        act=""
        if [ "${CHOICE:-0}" -ge 1 ] && [ "${CHOICE:-0}" -le "${#acts[@]}" ]; then
            act="${acts[$((CHOICE - 1))]}"
        fi
        case "$act" in
            main)
                tracey_buy_scene "$eid"
                dialog_pause
                continue ;;
            extra)
                tracey_buy_scene extraausgabe
                dialog_pause
                continue ;;
            *)
                break ;;
        esac
    done
    return 0
}

# --- Die Begegnung, durch die sie gefunden wird -----------------------
# Nur aktiv, solange Rachels Quest läuft und Tracey noch nicht gefunden
# wurde. Kein Ablehnen: Der Agent richtet Rachels Auftrag aus, Tracey
# macht sich sofort auf den Weg.
tracey_found_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ OSTDISTRIKT · VOR JIMMYS HAUS ═════")
    OUT+=("Ort : Ostdistrikt    Status : Tracey gefunden")
    OUT+=("")
    render

    say "-" "Vor dem schmalen Haus steht eine Frau mit einem fast leeren Zeitungskorb. Sie klopft sich gerade den Staub von den Ärmeln."
    say "$AGENT_NAME" "Tracey? Rachel sucht dich. Sie sollte längst von ihrer Tour zurück sein."
    say "Tracey" "Rachel schickt dich? Dann ist es wohl ernst."
    say "Tracey" "Ja, bin hier fertig. Ich mache mich auf den Weg zu Rachel."
    say "-" "Sie nickt zu dem Haus hinter sich."
    say "Tracey" "Ich hab Jimmy gerade die aktuelle Ausgabe gebracht. Die langweilige Stadttour von Jack."
    say "Tracey" "Er hat 100 Bits dafür bezahlt. Sammler zahlen eben, wenn sie etwas unbedingt haben wollen."
    say "Tracey" "Sag Rachel, ich bin gleich da. Und sag ihr, dass ich keine Eskorte brauche."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Geh zum DailyPulse-Verlag (Süddistrikt) und sprich mit Rachel.")
    TRACEY_FOUND=1
    quest_note "Hab Tracey gefunden – sie ist auf dem Weg zurück zu Rachel."
    tracey_apply_state
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Einmaliger Konkurrenz-Dialog nach Jimmys erstem Kauf --------------
# Sobald der Agent Jimmy eine Ausgabe verkauft hat, sieht Tracey in ihm
# eine Konkurrentin/einen Konkurrenten. Der Dialog erscheint genau einmal.
tracey_rival_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ $(tracey_header) ═════")
    OUT+=("Tracey Briggs    Rolle: Zeitungsausträgerin")
    OUT+=("")
    render

    say "-" "Tracey mustert dich, als hätte sie gerade eine Schlagzeile gelesen, die ihr nicht gefällt."
    say "Tracey" "Aha! Du bist jetzt also meine Konkurrenz! ... Wie du willst!"
    say "Tracey" "Aber merk dir eines: Ich kenne jede Tour, jeden Kasten und jeden, der dafür zahlt."
    say "Tracey" "Wenn du mir eine Ausgabe vor der Nase wegschnappst, reden wir noch einmal."
    TRACEY_RIVAL_SEEN=1
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- Gespräch (»touch TraceyBriggs«) -----------------------------------
dialog_tracey() {
    local eid
    if [ "${TRACEY_GIVEN:-0}" = "1" ] && [ "${TRACEY_FOUND:-0}" != "1" ]; then
        tracey_found_scene
        return 0
    fi

    if [ "${JIMMY_FIRST_SALE:-0}" = "1" ] \
       && [ "${TRACEY_RIVAL_SEEN:-0}" != "1" ]; then
        tracey_rival_scene
        return 0
    fi

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ $(tracey_header) ═════")
    OUT+=("Tracey Briggs    Rolle: Zeitungsausträgerin")
    OUT+=("")
    render

    if [ "${TRACEY_DONE:-0}" = "1" ]; then
        say "Tracey" "Da bist du ja wieder. Rachel hat sich bedankt – und ich sag's ja: keiner legt sich mit mir an."
        say "-" "Sie grinst kurz, dann hat sie schon wieder den nächsten Stapel im Arm."
    elif [ "${TRACEY_FOUND:-0}" = "1" ]; then
        say "Tracey" "Ich bin schon da. Rachel wartet wohl schon."
        say "Tracey" "Sag ihr, ich komme, sobald ich den Korb abgestellt habe."
    else
        say "-" "Die Frau sortiert Zeitungen auf einem wackligen Stapel. Sie mustert dich, bevor du etwas sagen kannst."
        say "Tracey" "Tracey Briggs. Ich trag die DailyPulse aus – meistens jedenfalls."
        say "Tracey" "Manchmal arbeite ich im Restaurant, manchmal nehme ich kleinere Jobs an. Hauptsache, es bewegt sich was."
        say "Tracey" "Wenn du eine aktuelle Ausgabe brauchst: Ich hab immer eine dabei."
    fi

    if [ "$(tracey_current_edition)" = "sperrzone" ]; then
        say "Tracey" "Die Sperrzone-Ausgabe? Ja, ich hab ein paar dabei. Die geht weg wie warmes Brot."
        say "Tracey" "Rachel hat sich diesmal selbst übertroffen. Sag ihr das aber nicht – sie wird sonst unausstehlich."
    fi
    if tracey_extra_active; then
        say "Tracey" "Die Extra-Ausgabe mit Neks Nachruf habe ich auch. Nur ein paar Tage, dann ist sie weg."
    fi

    tracey_buy_menu
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
