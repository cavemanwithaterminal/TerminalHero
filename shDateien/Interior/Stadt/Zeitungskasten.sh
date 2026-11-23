# ============================================================
#  TerminalHero - Interior: Zeitungskasten (Stadt)
# ------------------------------------------------------------
#  Die fünf grauen DailyPulse-Zeitungskästen in den Bezirken. Einer
#  steht in jedem Stadtteil (Orte/*.sh: zeitungskasten_place).
#
#  Sie sind KEINE Items: Man kauft an ihnen eine Ausgabe (10 Bits) und
#  benutzt sie mit »use Zeitungskasten«. Im Kasten liegt immer nur die
#  AKTUELLE Ausgabe (ZEITUNG_EDITION, kern/state.sh). Erscheint später
#  eine neue Edition, wird sie zentral gesetzt - alle Kästen zeigen und
#  verkaufen dann diese eine Ausgabe.
#
#  Jacks Quest »Die langweiligste Ausgabe« (Charakter/verlag.sh):
#     - Ohne Schlüssel:  Exemplar kaufen · Nichts tun
#     - Mit Schlüssel:   Exemplar kaufen · Zeitungskasten leeren · Nichts tun
#  Jeder der fünf Kästen lässt sich genau EINMAL leeren (Bitmaske
#  ZEITUNG_EMPTIED). Ein geleerter Kasten verkauft nichts mehr und gibt
#  ein Zeitungsbündel (Items/Quest/Zeitungsbündel.sh) heraus.
#
#  Rachels »Die neueste Auflage: Sperrzone« (Charakter/verlag.sh) dreht
#  das um: Alle fünf Kästen sind leer, der Agent trägt fünf Bündel der
#  neuen Ausgabe. An jedem leeren Kasten gibt es einmalig
#  »Zeitungskasten befüllen«; danach verkauft er die neue Ausgabe. Das
#  Bit in ZEITUNG_EMPTIED wird dabei gelöscht - ein Kasten kann pro
#  Ausgabe nur einmal befüllt werden.
#
#  Angemeldet wird das Objekt über interior_define (kern/interior.sh);
#  aufgestellt wird es von den Stadtteil-Dateien. Die Benutzungsfunktion
#  bekommt von use.sh neben der id auch den PFAD des Kastens ($2), damit
#  jeder Bezirk seinen eigenen Leerungszustand hat.
# ============================================================

# Preis der aktuellen Ausgabe. Die Höhe steht HIER (nicht am Item), weil
# sie zum Verkauf am Kasten gehört - genauso wie die Menge an einem
# Bits-Fundort steht.
ZEITUNG_PRICE=10

# Extra-Ausgabe nach Neks Beerdigung. Sie liegt ZUSÄTZLICH zur aktuellen
# Hauptausgabe in den Kästen und wird für denselben Preis verkauft.
ZEITUNG_EXTRA_ID=extraausgabe
ZEITUNG_EXTRA_DAYS=5

# Reihenfolge der fünf Bezirke = Bitposition in ZEITUNG_EMPTIED.
declare -ga ZEITUNG_BOX_KEYS=(sued nord west ost zentrum)
declare -gA ZEITUNG_BOX_LABEL=(
    [sued]="Süddistrikt"
    [nord]="Norddistrikt"
    [west]="Westdistrikt"
    [ost]="Ostdistrikt"
    [zentrum]="Zentrum"
)

interior_define zeitungskasten stadt \
    "Zeitungskasten" \
    "Ein grauer Metallkasten mit abgerundeter Ecke, auf einem massiven Ständer. Vorne ein schmales Ausgabefach mit Klappe, daneben das eingeprägte DailyPulse-Signet: ein Kreis, ein Strich, ein Punkt. Der Lack ist an den Kanten abgeplatzt; irgendwer hat »LÜGT DOCH« hineingeritzt und später versucht, es zu übermalen. Im Kasten liegt immer nur die aktuelle Ausgabe. Benutzen: use Zeitungskasten."

interior_talk zeitungskasten zeitungskasten_gespraech
interior_use  zeitungskasten zeitungskasten_use

interior_file_text zeitungskasten \
    "Typ    : Verkaufsautomat (DailyPulse)\nPreis  : 10 Bits pro Exemplar\nBestand: immer nur die aktuelle Ausgabe\nZugang : Münzfach vorne; Rückfach nur mit Schlüssel"

# Register für die Stadtteil-Dateien: Kasten an den Bezirkspfad stellen.
zeitungskasten_place() {   # $1 = Bezirksordner (z. B. "$SUED_PREFIX")
    [ -n "${1:-}" ] || return 0
    interior_place zeitungskasten "${1%/}/Zeitungskasten"
}

# Welche Bitposition hat der Kasten an <pfad>? (-1 = kein Bezirk)
zeitung_box_index() {   # $1 = Pfad des Kastens
    local dk k i=0
    dk="$(district_key_of_path "${1:-}")"
    [ -n "$dk" ] || { printf '%s' "-1"; return 0; }
    for k in "${ZEITUNG_BOX_KEYS[@]}"; do
        if [ "$k" = "$dk" ]; then
            printf '%s' "$i"
            return 0
        fi
        i=$(( i + 1 ))
    done
    printf '%s' "-1"
}

zeitung_box_label() {   # $1 = Pfad des Kastens
    local k
    k="$(district_key_of_path "${1:-}")"
    printf '%s' "${ZEITUNG_BOX_LABEL[$k]:-}"
}

# 0 = dieser Kasten wurde bereits geleert, 1 = noch voll.
zeitung_box_is_empty() {   # $1 = Pfad des Kastens
    local i
    i="$(zeitung_box_index "$1")"
    [ "$i" -ge 0 ] 2>/dev/null || return 1
    [ $(( ${ZEITUNG_EMPTIED:-0} & (1 << i) )) -ne 0 ]
}

# Kasten als geleert markieren. Rückgabe 1, wenn er schon leer war -
# so kann ein Kasten niemals zwei Bündel liefern.
zeitung_box_mark_empty() {   # $1 = Pfad des Kastens
    local i bit
    i="$(zeitung_box_index "$1")"
    [ "$i" -ge 0 ] 2>/dev/null || return 1
    bit=$(( 1 << i ))
    [ $(( ${ZEITUNG_EMPTIED:-0} & bit )) -ne 0 ] && return 1
    ZEITUNG_EMPTIED=$(( ${ZEITUNG_EMPTIED:-0} | bit ))
    return 0
}

# Kasten mit der aktuellen Ausgabe befüllen: Bit löschen. Rückgabe 1,
# wenn der Kasten bereits voll ist - so gibt es pro Ausgabe nur ein
# Bündel pro Kasten.
zeitung_box_mark_filled() {   # $1 = Pfad des Kastens
    local i bit
    i="$(zeitung_box_index "$1")"
    [ "$i" -ge 0 ] 2>/dev/null || return 1
    bit=$(( 1 << i ))
    [ $(( ${ZEITUNG_EMPTIED:-0} & bit )) -eq 0 ] && return 1
    ZEITUNG_EMPTIED=$(( ${ZEITUNG_EMPTIED:-0} & ~bit ))
    return 0
}

# Wie viele der fünf Kästen sind schon geleert?
zeitung_boxes_emptied() {
    local i n=0
    for ((i = 0; i < ${#ZEITUNG_BOX_KEYS[@]}; i++)); do
        [ $(( ${ZEITUNG_EMPTIED:-0} & (1 << i) )) -ne 0 ] && n=$(( n + 1 ))
    done
    printf '%s' "$n"
}

# Wie viele der fünf Kästen sind mit der aktuellen Ausgabe befüllt?
zeitung_boxes_filled() {
    printf '%s' "$(( ${#ZEITUNG_BOX_KEYS[@]} - $(zeitung_boxes_emptied) ))"
}

# Aktuelle Ausgabe als Item-ID. Fällt auf die erste Edition zurück, falls
# ein alter/defekter Spielstand eine unbekannte ID enthält.
zeitung_current_edition() {
    local e="${ZEITUNG_EDITION:-bezirke}"
    item_exists "$e" || e="bezirke"
    item_exists "$e" && printf '%s' "$e"
}

# Ist <tag> innerhalb des Verkaufszeitraums der Extra-Ausgabe? Der erste
# und der letzte Tag zählen mit; ohne gesetzten Zeitraum (-1) nie.
zeitung_extra_available_on() {   # $1 = Spieltag
    local d="${1:-}" start until
    case "$d" in ''|*[!0-9]*) return 1 ;; esac
    start="${ZEITUNG_EXTRA_DAY:--1}"
    until="${ZEITUNG_EXTRA_UNTIL:--1}"
    case "$start" in ''|*[!0-9-]*) return 1 ;; esac
    case "$until" in ''|*[!0-9-]*) return 1 ;; esac
    [ "$start" -ge 0 ] 2>/dev/null || return 1
    [ "$until" -ge "$start" ] 2>/dev/null || return 1
    [ "$d" -ge "$start" ] && [ "$d" -le "$until" ]
}

# Wird die Extra-Ausgabe gerade an Kästen und bei Tracey verkauft?
zeitung_extra_active() {
    item_exists "$ZEITUNG_EXTRA_ID" || return 1
    declare -F uhrzeit_day >/dev/null 2>&1 || return 1
    local d
    d="$(uhrzeit_day 2>/dev/null)" || return 1
    zeitung_extra_available_on "$d"
}

# Nach der Beerdigung: Sobald alle Gäste den Friedhof verlassen haben
# (also am Tag nach der Trauerfeier), erscheint die Extra-Ausgabe. Der
# Aufruf ist idempotent und meldet das Erscheinen genau einmal.
zeitung_extra_maybe_start() {
    [ "${NEK_FUNERAL_DONE:-0}" = "1" ] || return 1
    [ "${NEK_FUNERAL_FAILED:-0}" = "1" ] && return 1
    [ "${ZEITUNG_EXTRA_DAY:--1}" -lt 0 ] 2>/dev/null || return 1
    item_exists "$ZEITUNG_EXTRA_ID" || return 1
    declare -F uhrzeit_day >/dev/null 2>&1 || return 1

    local day fday
    day="$(uhrzeit_day 2>/dev/null)" || return 1
    fday="${NEK_FUNERAL_DAY:--1}"
    case "$day" in ''|*[!0-9]*) return 1 ;; esac
    case "$fday" in ''|*[!0-9]*) return 1 ;; esac
    [ "$day" -gt "$fday" ] || return 1

    ZEITUNG_EXTRA_DAY="$day"
    ZEITUNG_EXTRA_UNTIL=$(( day + ZEITUNG_EXTRA_DAYS - 1 ))
    if [ "${ZEITUNG_EXTRA_SHOWN:-0}" != "1" ]; then
        ZEITUNG_EXTRA_SHOWN=1
        OUT+=("")
        OUT+=("[ DAILYPULSE ]  Extra-Ausgabe erschienen: »$(item_name "$ZEITUNG_EXTRA_ID")«.")
        OUT+=("   Liegt ab heute an allen fünf Zeitungskästen und bei Tracey aus.")
        if declare -F quest_note >/dev/null 2>&1; then
            quest_note "Die Extra-Ausgabe mit Neks Nachruf erscheint – einige Tage an den Kästen und bei Tracey."
        fi
    fi
    return 0
}

# Eine Ausgabe am Kasten verkaufen. Rückgabe 0 = gekauft.
zeitung_sell_edition() {   # $1 = Item-ID
    local eid="${1:-}"
    [ -n "$eid" ] || return 1
    if ! bits_take "$ZEITUNG_PRICE"; then
        play_sound error
        say "-" "So sehr ich will: $(bits_text "$ZEITUNG_PRICE") sind mehr, als ich habe."
        return 1
    fi
    inv_add "$eid"
    play_sound cmd_touch
    OUT+=("")
    OUT+=("   [ Zeitung ]  $(item_name "$eid")")
    OUT+=("   [ Bits ]     -$(bits_text "$ZEITUNG_PRICE")   (noch $(bits_text "$(bits_count)"))")
    OUT+=("   Ausgabe gekauft. Der Kasten hat noch mehr – solange die Ausgabe aktuell ist.")
    return 0
}

# Neue Ausgabe erscheint: zentral setzen und alle Kästen wieder füllen.
# Wird von späteren DailyPulse-Ausgaben aufgerufen; die Kästen selbst
# kennen keine Editionsliste.
zeitung_set_edition() {   # $1 = Item-ID der neuen Ausgabe
    [ -n "${1:-}" ] || return 1
    item_exists "$1" || return 1
    ZEITUNG_EDITION="$1"
    ZEITUNG_EMPTIED=0
    return 0
}

# Neue Ausgabe ist gedruckt, aber noch nicht in den Kästen: Edition
# setzen und alle fünf Kästen als leer markieren. Rachels fünf Bündel
# füllen sie danach einzeln wieder (Charakter/verlag.sh).
zeitung_await_distribution() {   # $1 = Item-ID der neuen Ausgabe
    [ -n "${1:-}" ] || return 1
    item_exists "$1" || return 1
    ZEITUNG_EDITION="$1"
    ZEITUNG_EMPTIED=31
    return 0
}

# --- »touch Zeitungskasten«: kurz mustern ----------------------------
zeitungskasten_gespraech() {
    local eid p
    p="${CWD%/}/Zeitungskasten"       # Kasten steht im aktuellen Bezirksordner
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ ZEITUNGSKASTEN · DAILYPULSE ═════")
    OUT+=("")
    render

    say "-" "Der Kasten steht schief auf seinem Ständer. Die Klappe klemmt, das Münzfach ist blank gerieben."
    if zeitung_box_is_empty "$p"; then
        if [ "${AUFLAGE_GIVEN:-0}" = "1" ] && [ "${AUFLAGE_DONE:-0}" != "1" ]; then
            say "-" "Das Ausgabefach ist leer. Der Kasten wartet auf die neue Ausgabe."
        else
            say "-" "Das Ausgabefach ist leer. Jack hat die Ausgabe bereits abgeholt."
            say "-" "Zurück bleibt nur das Fach mit den abgestoßenen Kanten und ein modriger Geruch nach Papier."
        fi
    else
        eid="$(zeitung_current_edition)"
        if [ -n "$eid" ]; then
            say "-" "Im Ausgabefach: »$(item_name "$eid")«. Preis: $(bits_text "$ZEITUNG_PRICE")."
            say "-" "An der Seite klebt ein handgeschriebener Zettel: »Nur die NEUE Ausgabe. Nicht die alte. Bitte.«"
        else
            say "-" "Das Ausgabefach ist leer. Für diese Ausgabe gibt es derzeit nichts zu kaufen."
        fi
    fi
    if zeitung_extra_active; then
        say "-" "Daneben steckt die Extra-Ausgabe: »$(item_name "$ZEITUNG_EXTRA_ID")«. Ebenfalls $(bits_text "$ZEITUNG_PRICE"), nur für kurze Zeit."
    fi
    say "-" "Benutzen: use Zeitungskasten"
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# --- »use Zeitungskasten«: kaufen, leeren oder befüllen --------------
zeitungskasten_use() {   # $1 = Interior-id, $2 = Pfad des Kastens
    local id="${1:-zeitungskasten}" p="${2:-}" eid n filled extra=0
    local -a opts=()
    local action_buy=1 action_extra=0 action_empty=0 action_none=2 idx

    [ -n "$p" ] || p="$CWD/Zeitungskasten"
    idx="$(zeitung_box_index "$p")"
    if [ "$idx" -lt 0 ] 2>/dev/null; then
        play_sound error
        OUT+=("use: Dieser Zeitungskasten gehört zu keinem Bezirk.")
        return 0
    fi

    eid="$(zeitung_current_edition)"
    zeitung_extra_active && extra=1
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ ZEITUNGSKASTEN · $(zeitung_box_label "$p") ═════")
    OUT+=("DailyPulse    Ausgabe: $(item_name "$eid")    Preis: $(bits_text "$ZEITUNG_PRICE")")
    if [ "$extra" = "1" ]; then
        OUT+=("Extra-Ausgabe: $(item_name "$ZEITUNG_EXTRA_ID")    Preis: $(bits_text "$ZEITUNG_PRICE")")
    fi
    OUT+=("")
    render

    if zeitung_box_is_empty "$p"; then
        # Rachels Verteilung: Der leere Kasten wartet auf ein Bündel der
        # neuen Ausgabe. Jeder Kasten nimmt genau ein Bündel auf.
        if [ "${AUFLAGE_GIVEN:-0}" = "1" ] && [ "${AUFLAGE_DONE:-0}" != "1" ]; then
            say "-" "Der Kasten ist leer. Er wartet auf die neue Ausgabe."
            if ! inv_has zeitungsschluessel; then
                say "-" "Ohne den Zeitungskastenschlüssel lässt sich das Rückfach nicht öffnen."
                dialog_pause
                DIALOG_ACTIVE=0; DIALOG_HINT=""
                return 0
            fi
            n="$(inv_count sperrzonebuendel)"
            if [ "$n" -le 0 ] 2>/dev/null; then
                say "-" "Du hast keine Zeitungsbündel mehr. Rachel hat dir fünf mitgegeben – für jeden Bezirk eines."
                dialog_pause
                DIALOG_ACTIVE=0; DIALOG_HINT=""
                return 0
            fi

            say "-" "Im Rückfach sitzt das Schloss. Der Schlüssel passt."
            say "-" "Du hast noch ${n} Bündel dabei. Diesen Kasten befüllen?"
            ask "Zeitungskasten befüllen." "Nichts tun."

            if [ "$CHOICE" = "1" ]; then
                if zeitung_box_mark_filled "$p"; then
                    inv_remove sperrzonebuendel 1
                    filled="$(zeitung_boxes_filled)"
                    play_sound online
                    OUT+=("")
                    OUT+=("   [ Zeitungsbündel ]  -1   (im Inventar: $(inv_count sperrzonebuendel))")
                    OUT+=("   Zeitungskasten befüllt: ${filled}/5")
                    if [ "$filled" -ge 5 ]; then
                        OUT+=("")
                        OUT+=("   Alle fünf Kästen sind befüllt. Bring Rachel die Nachricht.")
                        quest_note "Alle fünf Zeitungskästen mit der Sperrzone-Ausgabe befüllt – zurück zu Rachel."
                    fi
                    dialog_pause
                else
                    play_sound error
                    say "-" "Der Kasten ist bereits befüllt."
                    dialog_pause
                fi
            fi
            DIALOG_ACTIVE=0; DIALOG_HINT=""
            return 0
        fi

        say "-" "Der Kasten ist leer. Jack hat die Ausgabe bereits abgeholt."
        say "-" "Zurück bleibt nur das Fach mit den abgestoßenen Kanten und ein modriger Geruch nach Papier."
        if [ "$extra" = "1" ]; then
            say "-" "In der Seitenhalterung steckt noch die Extra-Ausgabe: »$(item_name "$ZEITUNG_EXTRA_ID")«. Preis: $(bits_text "$ZEITUNG_PRICE")."
            ask "Extra-Ausgabe kaufen" "Nichts tun."
            [ "$CHOICE" = "1" ] && zeitung_sell_edition "$ZEITUNG_EXTRA_ID"
        fi
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return 0
    fi

    if [ -z "$eid" ]; then
        say "-" "Im Kasten liegt keine Ausgabe. Vielleicht erscheint die nächste erst morgen."
        if [ "$extra" = "1" ]; then
            say "-" "In der Seitenhalterung steckt noch die Extra-Ausgabe: »$(item_name "$ZEITUNG_EXTRA_ID")«. Preis: $(bits_text "$ZEITUNG_PRICE")."
            ask "Extra-Ausgabe kaufen" "Nichts tun."
            [ "$CHOICE" = "1" ] && zeitung_sell_edition "$ZEITUNG_EXTRA_ID"
        fi
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return 0
    fi

    say "-" "Ein grauer Metallkasten, in dem die aktuelle DailyPulse-Ausgabe steckt: »$(item_name "$eid")«."

    while true; do
        say "-" "Das Münzfach ist blank, die Klappe klemmt. Preis: $(bits_text "$ZEITUNG_PRICE"). Du hast $(bits_text "$(bits_count)")."

        opts=("Exemplar kaufen")
        action_buy=1
        action_extra=0
        action_empty=0
        if [ "$extra" = "1" ]; then
            opts+=("Extra-Ausgabe kaufen")
            action_extra=${#opts[@]}
        fi
        # Leeren gehört zu Jacks Quest »Die langweiligste Ausgabe«. Nach
        # deren Abschluss bleibt der Schlüssel zwar im Inventar, die
        # alten Ausgaben sind aber längst Papier.
        if [ "${ZEITUNG_GIVEN:-0}" = "1" ] && [ "${ZEITUNG_DONE:-0}" != "1" ] \
           && inv_has zeitungsschluessel; then
            opts+=("Zeitungskasten leeren")
            action_empty=${#opts[@]}
        fi
        opts+=("Nichts tun")
        action_none=${#opts[@]}
        ask "${opts[@]}"

        if [ "$CHOICE" = "$action_buy" ]; then
            zeitung_sell_edition "$eid" || true
            dialog_pause
            continue
        elif [ "$CHOICE" = "$action_extra" ]; then
            zeitung_sell_edition "$ZEITUNG_EXTRA_ID" || true
            dialog_pause
            continue
        elif [ "$CHOICE" = "$action_empty" ]; then
            if zeitung_box_mark_empty "$p"; then
                inv_add zeitungsbuendel
                n="$(zeitung_boxes_emptied)"
                play_sound online
                OUT+=("")
                OUT+=("   [ Zeitungsbündel ]  +1   (im Inventar: $(inv_count zeitungsbuendel))")
                OUT+=("   Zeitungskasten geleert: ${n}/5")
                if [ "$n" -ge 5 ]; then
                    OUT+=("")
                    OUT+=("   Alle fünf Kästen sind leer. Bring die Bündel zu Jack.")
                    quest_note "Alle fünf Zeitungskästen geleert – zurück zu Jack in den DailyPulse-Verlag."
                fi
                dialog_pause
                break
            else
                play_sound error
                say "-" "Der Kasten lässt sich nicht öffnen. Das Schloss klemmt."
                dialog_pause
            fi
        else
            break
        fi
    done

    DIALOG_ACTIVE=0; DIALOG_HINT=""
    return 0
}
