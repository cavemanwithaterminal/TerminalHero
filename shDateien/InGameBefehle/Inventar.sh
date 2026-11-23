# ============================================================
#  TerminalHero - Inventar
#
#  Zeigt das Inventar-Fenster (Befehl »inventar«, Aliase »inv« /
#  »inventory« / »inventur«): ein eigenes, vollflächiges Fenster -
#  bewusst NICHT in die 4-Fenster-Spiel-GUI geladen.
#
#  Aufbau:
#    ┌ INVENTAR ──────────────────────────────── 42 Bits ┐
#    │ [Spezial] [Quest] [Plunder] [Schmuck] [Waffen] …  │  Reiter (←/→)
#    │  ┌ DETAILS ─────────┐  ┌ ITEMS [n] ──────────────┐ │
#    │  │ Name, Kategorie, │  │ Item-Liste (↑/↓ wählen) │ │
#    │  │ Stückzahl, Text  │  │                         │ │
#    │  └──────────────────┘  └─────────────────────────┘ │
#    └───────────────────────────────────────────────────┘
#
#  Oben rechts steht der Kontostand in »Bits« (der Währung; kern/items.sh).
#  Die Währung ist bewusst KEIN Item in den Reitern, sondern nur dieser Zähler.
#  Bei schmalen Fenstern (80x24/60x24) scrollt die Reiterzeile um den aktiven
#  Reiter und zeigt mit ‹/› an, dass weitere Kategorien verborgen sind.
#
#  Bedienung: ←/→ Kategorie · ↑/↓ Item wählen · Tab Fokus ·
#             Enter/e Aktion (benutzen / ausrüsten bzw. abrüsten / ablegen /
#             nichts tun; bei nicht ausrüstbaren Items entfällt ausrüsten) ·
#             Esc/Q schließen   (genau DIESE zwei Schließtasten)
#
#  Das Fenster nutzt das große, feste Overlay (overlay_geom).
#
#  Der KATALOG (welche Items es gibt) und das INVENTAR (was der Agent
#  trägt) stecken in kern/items.sh; die Items selbst melden sich in
#  Items/<Kategorie>/<Item>.sh an. Diese Datei zeichnet nur das Fenster.
#
#  Nur Funktionsdefinitionen; Zeichenprimitive (put_text, draw_box,
#  clear_region, center_text, wrap_line, repeat, overlay_geom) aus ui.sh.
# ============================================================

# Aktuell angezeigte Item-IDs der gewählten Kategorie (vom Zeichnen gefüllt).
INV_SHOWN=()

# Symbol für getragene Ausrüstung (im Item-Reiter und in den Details).
INV_WORN_MARK="♦"

# Optionen des Item-Aktionsfensters für ein bestimmtes Item. Die
# Reihenfolge ist fest: benutzen, ausrüsten/abrüsten (nur Ausrüstung),
# ablegen, nichts tun. Ergebnis in INV_ACTION_OPTS (globale Liste für
# Paint/Test); INV_ACTION_KEYS hält die zugehörigen Aktionen, damit die
# Auswertung nicht an festen Nummern hängt.
declare -ga INV_ACTION_OPTS=()
declare -ga INV_ACTION_KEYS=()
inventar_action_opts() {   # <item-id>
    local id="$1"
    INV_ACTION_OPTS=("benutzen")
    INV_ACTION_KEYS=("use")
    if declare -F equip_item_equippable >/dev/null 2>&1 \
       && equip_item_equippable "$id"; then
        if equip_item_worn "$id"; then
            INV_ACTION_OPTS+=("abrüsten")
        else
            INV_ACTION_OPTS+=("ausrüsten")
        fi
        INV_ACTION_KEYS+=("equip")
    fi
    INV_ACTION_OPTS+=("ablegen" "nichts tun")
    INV_ACTION_KEYS+=("drop" "nothing")
}

# ============================================================
#  Befehls-Eingang (Verdrahtung für TerminalShell.sh)
# ============================================================
# Ist <wort> der Inventar-Befehl? (Groß-/Kleinschreibung egal)
inventar_is_command() {
    case "${1,,}" in
        inventar|inventory|inv|inventur) return 0 ;;
    esac
    return 1
}

# Öffnet das Inventar, wenn <wort> der Befehl ist – aber nur, wenn der
# General den Befehl im README-Gespräch (Tutorial) beigebracht hat.
# Rückgabe 0 = war der Inventar-Befehl (Fenster bzw. Absage).
# Rückgabe 1 = kein Inventar-Befehl (Zeile läuft normal weiter).
inventar_handles() {
    inventar_is_command "$1" || return 1
    if knows inventar; then
        inventar_screen
    else
        play_sound error
        OUT+=("»inventar« …? Nein. Auch diesen Befehl hat der Virus mir genommen. Noch.")
    fi
    return 0
}

# ============================================================
#  Fenster
# ============================================================
# Item-IDs einer Kategorie einsammeln: $1 = Kategorie-Index in ITEM_CATS
inv_build_shown() {
    INV_SHOWN=()
    local cat="${ITEM_CATS[${1:-0}]:-}" id
    while IFS= read -r id; do
        [ -n "$id" ] && INV_SHOWN+=("$id")
    done < <(inv_ids_in_cat "$cat")
}

# ============================================================
#  Item-Aktion (kleines Fenster über dem Inventar)
# ------------------------------------------------------------
#  Enter/e auf einem gewählten Item öffnet ein eigenes kleines
#  Fenster:
#     Item "Name" benutzen?
#     1) benutzen   2) ablegen   3) nichts tun
#  Bei ausrüstbaren Items (Schmuck, Waffen, Rüstung) steht an zweiter
#  Stelle »ausrüsten« – oder »abrüsten«, wenn das Item schon getragen wird:
#     1) benutzen   2) ausrüsten   3) ablegen   4) nichts tun
#
#  »benutzen« öffnet bei lesbaren Items (item_readable) das
#  Lesefenster aus InGameBefehle/Lesen.sh. Sonst ruft es den
#  optionalen Item-Haken item_use_<id> auf (z. B. Schlafsack:
#  ablegen, Fackel: anzünden). »ablegen« legt genau EIN Exemplar
#  in den aktuellen Ordner; dort kann es mit »grep« wieder
#  aufgenommen werden (kern/items.sh).
# ============================================================
inventar_action_paint() {   # $1 = Item-id, $2 = Auswahl
    local id="$1" sel="$2"
    local q="Item \"$(item_name "$id")\" benutzen?"
    local -a qlines=()
    local -a opts=()
    local line
    inventar_action_opts "$id"
    opts=("${INV_ACTION_OPTS[@]}")

    geom
    local w=$(( COLS - 8 )) hh
    [ "$w" -gt 56 ] && w=56
    [ "$w" -lt 38 ] && w=38
    local iw=$(( w - 4 ))
    while IFS= read -r line; do qlines+=("$line"); done < <(wrap_line "$q" "$iw")
    # 1 Leerzeile + Frage + 1 Leerzeile + Optionen + 1 Leerzeile + Hilfe,
    # dazu Rahmen oben/unten.
    hh=$(( ${#qlines[@]} + ${#opts[@]} + 6 ))
    [ "$hh" -lt 10 ] && hh=10
    local x=$(( (COLS - w) / 2 + 1 )); [ "$x" -lt 1 ] && x=1
    local y=$(( (ROWS - hh) / 2 + 1 )); [ "$y" -lt 1 ] && y=1

    draw_box "$x" "$y" "$w" "$hh" "ITEM" "$FRAME_HI"
    clear_region "$((y + 1))" "$((x + 2))" "$iw" "$((hh - 2))"

    local r=$(( y + 1 )) i t col
    put_text "$r" "$((x + 2))" "$iw" "" "$FG"; ((r++))
    for line in "${qlines[@]}"; do
        put_text "$r" "$((x + 2))" "$iw" "$(center_text "$line" "$iw")" "$TITLE$BOLD"
        ((r++))
    done
    put_text "$r" "$((x + 2))" "$iw" "" "$FG"; ((r++))
    local num
    for i in "${!opts[@]}"; do
        num=$(( i + 1 ))
        if [ "$i" = "$sel" ]; then
            t="▸ ${num}) ${opts[i]}"
            col="$ACCENT$BOLD"
        else
            t="  ${num}) ${opts[i]}"
            col="$FG"
        fi
        put_text "$r" "$((x + 2))" "$iw" "$t" "$col"
        ((r++))
    done
    put_text "$r" "$((x + 2))" "$iw" "" "$FG"; ((r++))
    put_text "$r" "$((x + 2))" "$iw" \
        "$(center_text "↑/↓ · Enter · 1-${#opts[@]} · Esc" "$iw")" "$MENU_C"
}

# Benutzen-Haken eines Items ausführen (falls vorhanden). Lesbare Items
# bekommen Vorrang: Ihr »benutzen« öffnet das Lesefenster.
inventar_use_item() {   # $1 = Item-id
    local id="$1" hook="item_use_${id}"
    if item_is_readable "$id"; then
        if declare -F lesen_screen >/dev/null 2>&1; then
            lesen_screen "$id"
            return 0
        fi
        play_sound error
        OUT+=("")
        OUT+=("» $(item_name "$id") « kann gerade nicht gelesen werden.")
        return 1
    fi
    if declare -F "$hook" >/dev/null 2>&1; then
        "$hook"
        return 0
    fi
    play_sound error
    OUT+=("")
    OUT+=("» $(item_name "$id") « lässt sich nicht benutzen.")
    return 1
}

# Kleines Aktionsfenster: benutzen / ausrüsten bzw. abrüsten / ablegen / nichts.
inventar_item_actions() {   # $1 = Item-id
    local id="$1" sel=0 last
    [ -n "$id" ] || return 1
    [ "$(inv_count "$id")" -gt 0 ] || return 1

    play_sound select
    while true; do
        inventar_action_opts "$id"
        last=$(( ${#INV_ACTION_OPTS[@]} - 1 ))
        [ "$sel" -gt "$last" ] && sel="$last"
        inventar_action_paint "$id" "$sel"
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') [ "$sel" -gt 0 ] && sel=$(( sel - 1 )) ;;
            $'\x1b[B'|$'\x1bOB') [ "$sel" -lt "$last" ] && sel=$(( sel + 1 )) ;;
            1) sel=0; break ;;
            2) [ "$last" -ge 1 ] && { sel=1; break; } ;;
            3) [ "$last" -ge 2 ] && { sel=2; break; } ;;
            4) [ "$last" -ge 3 ] && { sel=3; break; } ;;
            e|E) sel=0; break ;;
            $'\n'|$'\r') break ;;
            $'\x1b'|q|Q) return 0 ;;
        esac
    done

    case "${INV_ACTION_KEYS[$sel]:-nothing}" in
        use)    inventar_use_item "$id" ;;
        equip)  # ausrüsten bzw. abrüsten – je nach aktuellem Zustand
                if declare -F equip_item_worn >/dev/null 2>&1 \
                   && equip_item_worn "$id"; then
                    equip_unwear "$id"
                else
                    equip_wear "$id"
                fi ;;
        drop)   world_item_drop "$id" 1 ;;
        nothing) : ;;                        # nichts tun: nur schließen
    esac
    return 0
}

# Eine Reiterzeile: $1=Zeile $2=x $3=fokus(0|1) $4=aktiv $5=Breite
# $6.. = Beschriftungen. Passen nicht alle Reiter in die Breite (z. B.
# sechs Kategorien im 80x24-Fenster), wird um den aktiven Reiter ein
# Ausschnitt gezeigt. »‹«/»›« zeigen verborgene Reiter an; ←/→ scrollt
# den Ausschnitt automatisch mit, weil der aktive Reiter immer sichtbar ist.
inv_tab_row() {
    local row="$1" x="$2" foc="$3" sel="$4" maxw="$5"; shift 5
    local labels=("$@") i t col
    local -a texts=() widths=()
    local total=0 n="${#labels[@]}"
    for i in "${!labels[@]}"; do
        texts[i]="[ ${labels[i]} ]"
        widths[i]="${#texts[i]}"
        [ "$i" -gt 0 ] && total=$(( total + 2 ))
        total=$(( total + widths[i] ))
    done

    local first=0 last=$(( n - 1 )) budget used need
    if [ "$total" -gt "$maxw" ] && [ "$n" -gt 0 ]; then
        # Vier Zeichen für beide Pfeile reservieren; der Ausschnitt wird
        # vom aktiven Reiter aus nach links und rechts aufgefüllt.
        budget=$(( maxw - 4 ))
        [ "$budget" -lt 10 ] && budget=10
        first="$sel"; last="$sel"
        used="${widths[$sel]}"
        while [ "$first" -gt 0 ]; do
            need=$(( 2 + widths[first - 1] ))
            [ $(( used + need )) -le "$budget" ] || break
            first=$(( first - 1 )); used=$(( used + need ))
        done
        while [ "$last" -lt $(( n - 1 )) ]; do
            need=$(( 2 + widths[last + 1] ))
            [ $(( used + need )) -le "$budget" ] || break
            last=$(( last + 1 )); used=$(( used + need ))
        done
    fi

    [ "$foc" = "1" ] && put_text "$row" "$((x - 2))" 1 "▸" "$ACCENT$BOLD"
    local pos="$x" end
    if [ "$first" -gt 0 ]; then
        put_text "$row" "$x" 1 "‹" "$MUTED"
        pos=$(( x + 2 ))
    fi
    for (( i = first; i <= last; i++ )); do
        t="${texts[i]}"
        if [ "$i" = "$sel" ]; then
            if [ "$foc" = "1" ]; then col="$ACCENT$BOLD"; else col="$TITLE$BOLD"; fi
        else
            col="$MUTED"
        fi
        put_text "$row" "$pos" "${#t}" "$t" "$col"
        end=$(( pos + ${#t} - 1 ))
        pos=$(( pos + ${#t} + 2 ))
    done
    if [ "$last" -lt $(( n - 1 )) ]; then
        put_text "$row" "$(( end + 2 ))" 1 "›" "$MUTED"
    fi
}

inventar_paint() {   # $1 = Fokus (0 Reiter, 1 Liste)  $2 = Kategorie-Index  $3 = Auswahl
    local foc="$1" cat_i="$2" sel="$3"
    overlay_geom
    inv_build_shown "$cat_i"

    local pw="$OV_W" ph="$OV_H" px="$OV_X" py="$OV_Y" inner="$OV_INNER"

    clear_region "$((py + 1))" "$((px + 1))" "$inner" "$((ph - 2))"
    draw_box "$px" "$py" "$pw" "$ph" "" "$FRAME_HI"
    put_text "$((py + 1))" "$((px + 1))" "$inner" \
        "$(center_text '◤  INVENTAR  ◢' "$inner")" "$TITLE$BOLD"
    # Geld rechts in der Kopfzeile: Die Währung »Bit/Bits« ist KEIN Item im
    # Reiter-Raster, sie hat nur diesen Zähler (kern/items.sh).
    put_right "$((py + 1))" "$((px + 1))" "$((inner - 1))" \
        "$(bits_text "$(bits_count)")  " "$GOOD$BOLD"

    # --- Kategorie-Reiter (mit Stückzahl je Kategorie) ---
    local labels=() i c n lbl
    for i in "${!ITEM_CATS[@]}"; do
        c="${ITEM_CATS[i]}"
        n="$(inv_cat_count "$c")"
        lbl="$(item_cat_label "$c")"
        [ "$n" -gt 0 ] && lbl="${lbl} ${n}"
        labels+=("$lbl")
    done
    local f1=0; [ "$foc" = "0" ] && f1=1
    inv_tab_row "$((py + 2))" "$((px + 4))" "$f1" "$cat_i" \
        "$(( inner - 3 ))" "${labels[@]}"
    put_text "$((py + 3))" "$((px + 1))" "$inner" "$(repeat '─' "$inner")" "$FRAME"

    # --- zwei Kästen (wie Questlog: Details links / Liste rechts) ---
    local ptop=$(( py + 5 )) phgt=$(( ph - 8 ))
    [ "$phgt" -lt 3 ] && phgt=3
    local avail=$(( pw - 4 )) gap=1
    local lw=$(( (avail - gap) * 58 / 100 ))
    [ "$lw" -lt 20 ] && lw=20
    local rw=$(( avail - gap - lw ))
    [ "$rw" -lt 16 ] && { rw=16; lw=$(( avail - gap - rw )); }
    local lx=$(( px + 2 )) rx=$(( px + 2 + lw + gap ))
    local rmax=$(( ptop + phgt - 2 ))

    # --- links: Details zum gewählten Item ---
    local iid=""
    [ "${#INV_SHOWN[@]}" -gt 0 ] && iid="${INV_SHOWN[$sel]}"
    draw_box "$lx" "$ptop" "$lw" "$phgt" "DETAILS" "$FRAME"
    local dcw=$(( lw - 4 )); [ "$dcw" -lt 5 ] && dcw=5
    local rr=$(( ptop + 1 )) wl line d

    if [ -z "$iid" ]; then
        put_text "$rr" "$((lx + 2))" "$dcw" "(kein Item in dieser Kategorie)" "$MUTED"
    else
        while IFS= read -r wl; do
            [ "$rr" -le "$rmax" ] || break
            put_text "$rr" "$((lx + 2))" "$dcw" "$wl" "$TITLE$BOLD"; ((rr++))
        done < <(wrap_line "◈ $(item_name "$iid")" "$dcw")
        if [ "$rr" -le "$rmax" ]; then
            put_text "$rr" "$((lx + 2))" "$dcw" \
                "Kategorie: $(item_cat_label "$(item_cat "$iid")")" "$ACCENT"; ((rr++))
        fi
        if [ "$rr" -le "$rmax" ]; then
            put_text "$rr" "$((lx + 2))" "$dcw" \
                "Stückzahl: $(inv_count "$iid")" "$GOOD"; ((rr++))
        fi
        if declare -F equip_item_worn >/dev/null 2>&1 && equip_item_worn "$iid"; then
            if [ "$rr" -le "$rmax" ]; then
                put_text "$rr" "$((lx + 2))" "$dcw" \
                    "Wird getragen ${INV_WORN_MARK}" "$ACCENT$BOLD"; ((rr++))
            fi
        fi
        [ "$rr" -le "$rmax" ] && ((rr++))         # Leerzeile
        d="$(item_desc "$iid")"
        while IFS= read -r line; do
            while IFS= read -r wl; do
                [ "$rr" -le "$rmax" ] || break 2
                put_text "$rr" "$((lx + 2))" "$dcw" "$wl" "$FG"; ((rr++))
            done < <(wrap_line "$line" "$dcw")
        done <<< "$d"
    fi

    # --- rechts: Item-Liste ---
    draw_box "$rx" "$ptop" "$rw" "$phgt" "ITEMS [${#INV_SHOWN[@]}]" "$FRAME"
    local rcw=$(( rw - 4 )); [ "$rcw" -lt 5 ] && rcw=5
    local inner_h=$(( phgt - 2 )); [ "$inner_h" -lt 1 ] && inner_h=1
    local rrow=$(( ptop + 1 ))
    if [ "${#INV_SHOWN[@]}" -eq 0 ]; then
        put_text "$rrow" "$((rx + 2))" "$rcw" "(keine Items)" "$MUTED"
    else
        local first=0
        [ "$sel" -ge "$inner_h" ] && first=$(( sel - inner_h + 1 ))
        local j="$first" id2 mark col q worn
        while [ "$j" -lt "${#INV_SHOWN[@]}" ] && [ "$rrow" -le "$rmax" ]; do
            id2="${INV_SHOWN[$j]}"; mark="  "; col="$FG"; worn=""
            if [ "$j" = "$sel" ]; then
                if [ "$foc" = "1" ]; then mark="▸ "; col="$ACCENT$BOLD"; else mark="· "; col="$TITLE$BOLD"; fi
            fi
            if declare -F equip_item_worn >/dev/null 2>&1 && equip_item_worn "$id2"; then
                worn=" ${INV_WORN_MARK}"
            fi
            q="$(inv_count "$id2")"
            if [ "$q" -gt 1 ]; then
                put_text "$rrow" "$((rx + 2))" "$rcw" "${mark}$(item_name "$id2") ×${q}${worn}" "$col"
            else
                put_text "$rrow" "$((rx + 2))" "$rcw" "${mark}$(item_name "$id2")${worn}" "$col"
            fi
            j=$(( j + 1 )); ((rrow++))
        done
    fi

    # --- Fußzeile ---
    local hint
    if [ "$inner" -ge 76 ]; then
        hint='←/→ Kategorie · ↑/↓ Auswahl · Tab · Enter/e Aktion · Esc/Q schließen'
    else
        hint='←/→ · ↑/↓ · Enter/e · Esc/Q'
    fi
    put_text "$((py + ph - 2))" "$((px + 1))" "$inner" "$(center_text "$hint" "$inner")" "$MENU_C"
}

# Das Inventar-Fenster: eigene Schleife mit Reiter- und Listen-Navigation.
inventar_screen() {
    play_sound select

    # Eigener Bildschirm: Spiel-GUI komplett überdecken.
    printf '%s' "$UI_BG"
    clear

    local foc=0 cat_i=0 sel=0
    while true; do
        inventar_paint "$foc" "$cat_i" "$sel"
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA')                       # hoch
                case "$foc" in
                    1) if [ "$sel" -gt 0 ]; then sel=$(( sel - 1 )); else foc=0; fi ;;
                esac ;;
            $'\x1b[B'|$'\x1bOB')                       # runter
                case "$foc" in
                    0) [ "${#INV_SHOWN[@]}" -gt 0 ] && { foc=1; sel=0; } ;;
                    1) [ "$sel" -lt $(( ${#INV_SHOWN[@]} - 1 )) ] && sel=$(( sel + 1 )) ;;
                esac ;;
            $'\x1b[D'|$'\x1bOD')                       # links: Kategorie zurück
                [ "$cat_i" -gt 0 ] && { cat_i=$(( cat_i - 1 )); sel=0; } ;;
            $'\x1b[C'|$'\x1bOC')                       # rechts: Kategorie vor
                [ "$cat_i" -lt $(( ${#ITEM_CATS[@]} - 1 )) ] && { cat_i=$(( cat_i + 1 )); sel=0; } ;;
            $'\t')                                     # Fokus wechseln
                if [ "$foc" = "0" ]; then
                    [ "${#INV_SHOWN[@]}" -gt 0 ] && { foc=1; sel=0; }
                else
                    foc=0
                fi ;;
            $'\n'|$'\r'|e|E)                           # Item-Aktion öffnen
                if [ "$foc" = "1" ] && [ "${#INV_SHOWN[@]}" -gt 0 ]; then
                    inventar_item_actions "${INV_SHOWN[$sel]}"
                    # Nach Ablegen kann die Liste kürzer sein.
                    inv_build_shown "$cat_i"
                    if [ "${#INV_SHOWN[@]}" -gt 0 ]; then
                        [ "$sel" -ge "${#INV_SHOWN[@]}" ] && sel=$(( ${#INV_SHOWN[@]} - 1 ))
                    else
                        foc=0; sel=0
                    fi
                elif [ "${#INV_SHOWN[@]}" -gt 0 ]; then
                    foc=1; sel=0
                fi ;;
            $'\x1b'|q|Q)                               # schließen (Esc oder Q)
                break ;;
        esac
    done

    # Danach die Spiel-GUI vollständig neu aufbauen (Inventar-Fenster weg).
    FIRST_RENDER=1
    return 0
}
