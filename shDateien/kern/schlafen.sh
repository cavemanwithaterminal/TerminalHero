# ============================================================
#  TerminalHero - Schlafen (Mechanik für Schlafplätze)
# ------------------------------------------------------------
#  Ein Schlafplatz ist ein Interior-Objekt (z. B. die Matratze in der
#  eingestürzten Baracke, ein Bett oder ein Doppelbett). Benutzt wird er
#  mit »use <platz>« (InGameBefehle/use.sh) - das ruft schlafen_start <id>
#  hier auf.
#
#  Ablauf:
#     1. Kleines Fenster: mit ↑/↓ stellt man die Stunden ein. Live
#        wird angezeigt, wie viele Tokens der Schlaf einbringt.
#     2. Enter schläft ("Du schläfst"), Esc/Q bricht ab.
#     3. Der Bildschirm wird kurz schwarz, nur ein Satz steht da:
#        »Du schläfst«.
#     4. Zurück im Spiel: Die Spielzeit ist um die Stunden vorgerückt
#        (kern/Uhrzeit.sh) und die Tokens sind regeneriert.
#
#  GRENZEN (nur hier, NICHT in den Objekten):
#     höchstens SLEEP_MAX_STREAK Stunden AM STÜCK und
#     höchstens SLEEP_MAX_DAY Stunden PRO SPIELTAG.
#  Der Zähler je Spieltag steht in SLEEP_HOURS_TODAY + SLEEP_DAY
#  (kern/state.sh, im Spielstand gesichert) und wird bei einem neuen
#  Spieltag zurückgesetzt. ALLE Schlafplätze teilen sich diesen Zähler:
#  Wer auf der Matratze geschlafen hat, hat das Budget auch für Bett und
#  Doppelbett verbraucht.
#
#  Die TOKENS JE STUNDE stehen NICHT hier, sondern im Schlafplatz
#  selbst (Interior/.../<Objekt>.sh: interior_sleep_rate <id> <n>).
#  Diese Datei liest den Wert nur aus (interior_sleep_rate_of <id>).
#  Sitzen ist eine getrennte Mechanik mit eigenem Tageszähler
#  (kern/sitzen.sh, SIT_HOURS_TODAY/SIT_DAY).
#
#  Lazy geladen: use.sh holt schlafen_start über th_source_if_fn. Die
#  Zeichenprimitive (draw_box, put_text, center_text, clear_region,
#  pos, repeat) kommen aus kern/ui.sh, die Farben aus theme.sh.
# ============================================================

SLEEP_MAX_STREAK=12        # höchstens so viele Stunden am Stück
SLEEP_MAX_DAY=12           # höchstens so viele Stunden pro Spieltag
SCHLAFEN_BLACK_SECS=3      # so lange steht der Bildschirm schwarz ("Du schläfst")

# ============================================================
#  Einstieg: Schlafplatz benutzen
# ============================================================
# Öffnet das Schlaf-Fenster für den Schlafplatz <id>. Prüft vorher die
# Tagesgrenze (zurückgesetzt bei einem neuen Spieltag).
schlafen_start() {   # $1 = Interior-id des Schlafplatzes
    local id="${1:-}" rate day budget maxh
    [ -n "$id" ] || return 1
    rate="$(interior_sleep_rate_of "$id")"
    [ "$rate" -gt 0 ] 2>/dev/null || rate=0

    # Neuer Spieltag? -> Zähler zurücksetzen.
    day="$(uhrzeit_day)"
    [ "${SLEEP_DAY:--1}" = "$day" ] || { SLEEP_HOURS_TODAY=0; SLEEP_DAY="$day"; }

    # Erlaubte Stunden: am Stück begrenzt und um das Tagesbudget gekürzt.
    budget=$(( SLEEP_MAX_DAY - ${SLEEP_HOURS_TODAY:-0} ))
    maxh=$SLEEP_MAX_STREAK
    [ "$budget" -lt "$maxh" ] && maxh=$budget

    if [ "$maxh" -lt 1 ]; then
        play_sound error
        OUT+=("")
        OUT+=("Ich habe heute schon ${SLEEP_MAX_DAY} Stunden geschlafen.")
        OUT+=("Mehr geht erst an einem neuen Tag.")
        return 0
    fi

    schlafen_screen "$id" "$rate" "$maxh"
    return 0
}

# ============================================================
#  Fenster (klein, mittig)
# ============================================================
# Zeichnet das Schlaf-Fenster: Stunden einstellen + Live-Vorschau.
schlafen_paint() {   # $1 = id, $2 = Tokens je Stunde, $3 = Stunden, $4 = max
    local id="$1" rate="$2" h="$3" maxh="$4"
    local before="${TOKENS_CUR:-0}" wanted=$(( h * rate ))
    local after=$(( before + wanted ))
    [ "$after" -gt "${TOKENS_MAX:-0}" ] && after="${TOKENS_MAX:-0}"
    local gain=$(( after - before ))

    geom
    local w=$(( COLS - 8 )) hh=11
    [ "$w" -gt 52 ] && w=52
    [ "$w" -lt 34 ] && w=34
    local x=$(( (COLS - w) / 2 + 1 )); [ "$x" -lt 1 ] && x=1
    local y=$(( (ROWS - hh) / 2 + 1 )); [ "$y" -lt 1 ] && y=1

    draw_box "$x" "$y" "$w" "$hh" "SCHLAFEN" "$FRAME_HI"
    local iw=$(( w - 4 )) ix=$(( x + 2 ))
    local r=$(( y + 1 ))

    put_text "$r" "$ix" "$iw" "" "$FG"; ((r++))
    put_text "$r" "$ix" "$iw" "$(center_text "◤  $(interior_name "$id")  ◢" "$iw")" "$TITLE$BOLD"; ((r++))
    put_text "$r" "$ix" "$iw" "" "$FG"; ((r++))
    put_text "$r" "$ix" "$iw" "$(center_text "Uhrzeit    $(uhrzeit_text)" "$iw")" "$FG"; ((r++))
    put_text "$r" "$ix" "$iw" "$(center_text "Stunden    ◂  ${h}  ▸" "$iw")" "$ACCENT$BOLD"; ((r++))
    put_text "$r" "$ix" "$iw" "$(center_text "Tokens     +${gain}   (${rate}/Std.)" "$iw")" "$GOOD"; ((r++))
    put_text "$r" "$ix" "$iw" "$(center_text "danach     ${after} / ${TOKENS_MAX}" "$iw")" "$FG"; ((r++))
    put_text "$r" "$ix" "$iw" "" "$FG"; ((r++))
    put_text "$r" "$ix" "$iw" \
        "$(center_text "↑/↓ (max ${maxh})  ·  Enter schlafen  ·  Esc/Q raus" "$iw")" "$MENU_C"
}

# Das Fenster: ↑/↓ wählen die Stunden, Enter schläft, Esc/Q bricht ab.
schlafen_screen() {   # $1 = id, $2 = Tokens je Stunde, $3 = Höchststunden
    local id="$1" rate="$2" maxh="$3"
    local h=8
    [ "$h" -gt "$maxh" ] && h="$maxh"
    [ "$h" -lt 1 ] && h=1

    play_sound select
    printf '%s' "$UI_BG"
    clear

    while true; do
        schlafen_paint "$id" "$rate" "$h" "$maxh"
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') [ "$h" -lt "$maxh" ] && { h=$(( h + 1 )); play_sound move; } ;;   # hoch
            $'\x1b[B'|$'\x1bOB') [ "$h" -gt 1 ] && { h=$(( h - 1 )); play_sound move; } ;;         # runter
            $'\n'|$'\r')         play_sound cmd_touch
                                 schlafen_do "$id" "$rate" "$h"; break ;;    # schlafen
            $'\x1b'|q|Q)         break ;;                                     # abbrechen
        esac
    done

    # Danach die Spiel-GUI vollständig neu aufbauen.
    FIRST_RENDER=1
    return 0
}

# ============================================================
#  Schlafen: schwarzer Bildschirm + Wirkung
# ============================================================
schlafen_do() {   # $1 = id, $2 = Tokens je Stunde, $3 = Stunden
    local id="$1" rate="$2" h="$3"
    [ "$h" -gt 0 ] 2>/dev/null || return 0

    local day before after gain
    day="$(uhrzeit_day)"                 # Tag, AN dem geschlafen wird
    before="${TOKENS_CUR:-0}"

    schlafen_black "$h"                  # kurzer schwarzer Bildschirm

    # Tokens regenerieren (höchstens bis TOKENS_MAX).
    after=$(( before + h * rate ))
    [ "$after" -gt "${TOKENS_MAX:-0}" ] && after="${TOKENS_MAX:-0}"
    TOKENS_CUR=$after
    gain=$(( after - before ))

    # Spielzeit vorrücken und den Tagesschlaf vermerken.
    uhrzeit_advance_hours "$h"
    SLEEP_DAY="$day"
    SLEEP_HOURS_TODAY=$(( ${SLEEP_HOURS_TODAY:-0} + h ))

    play_sound online
    OUT+=("")
    if [ "$h" = "1" ]; then
        OUT+=("── Du hast eine Stunde geschlafen. ──")
    else
        OUT+=("── Du hast ${h} Stunden geschlafen. ──")
    fi
    OUT+=("   Tokens regeneriert: +${gain}   (${TOKENS_CUR} / ${TOKENS_MAX})")
    [ "${TOKENS_CUR}" -ge "${TOKENS_MAX}" ] && OUT+=("   Der Speicher ist voll.")
    return 0
}

# Kurz schwarz werden: nur "Du schläfst" steht da.
# Dev-/Test-Haken: TH_SLEEP_SECS überschreibt die Dauer.
schlafen_black() {
    local secs="${TH_SLEEP_SECS:-$SCHLAFEN_BLACK_SECS}"
    geom
    printf '\033[48;5;16m\033[38;5;250m'   # schwarzer Grund, heller Text
    clear
    local msg="Du schläfst"
    local rr=$(( ROWS / 2 ))
    local cc=$(( (COLS - ${#msg}) / 2 + 1 )); [ "$cc" -lt 1 ] && cc=1
    pos "$rr" "$cc"
    printf '%s' "$msg"
    sleep "$secs"
}
