# ============================================================
#  TerminalHero - Sitzen (Mechanik für Sitzgelegenheiten)
# ------------------------------------------------------------
#  Eine Sitzgelegenheit ist ein Interior-Objekt (z. B. der Stuhl in
#  der Baracke). Benutzt wird sie mit »use <platz>«
#  (InGameBefehle/use.sh) - das ruft sitzen_start <id> hier auf.
#
#  Ablauf:
#     1. Kleines Fenster: mit ↑/↓ stellt man die Stunden ein. Live
#        wird angezeigt, wie viele Tokens das Sitzen einbringt.
#     2. Enter setzt sich ("Du sitzt"), Esc/Q bricht ab.
#     3. Der Bildschirm wird kurz schwarz, nur ein Satz steht da:
#        »Du sitzt«.
#     4. Zurück im Spiel: Die Spielzeit ist um die Stunden vorgerückt
#        (kern/Uhrzeit.sh) und die Tokens sind regeneriert.
#
#  GRENZEN (nur hier, NICHT in den Objekten):
#     höchstens SITZEN_MAX_STREAK Stunden AM STÜCK und
#     höchstens SITZEN_MAX_DAY Stunden PRO SPIELTAG.
#  Der Zähler je Spieltag steht in SIT_HOURS_TODAY + SIT_DAY
#  (kern/state.sh, im Spielstand gesichert) und wird bei einem neuen
#  Spieltag zurückgesetzt.
#
#  Schlafen und Sitzen sind GETRENNTE Mechaniken: Der Schlafzähler
#  (SLEEP_HOURS_TODAY) und der Sitzzähler (SIT_HOURS_TODAY) teilen
#  sich keinen Wert. Man kann also 12 Stunden schlafen UND 12 Stunden
#  sitzen. Alle Sitzgelegenheiten teilen sich dagegen den SIT-Zähler.
#
#  Die TOKENS JE STUNDE stehen NICHT hier, sondern in der
#  Sitzgelegenheit selbst (Interior/.../<Objekt>.sh:
#  interior_sit_rate <id> <n>). Diese Datei liest den Wert nur aus
#  (interior_sit_rate_of <id>).
#
#  Lazy geladen: use.sh holt sitzen_start über th_source_if_fn. Die
#  Zeichenprimitive (draw_box, put_text, center_text, clear_region,
#  pos, repeat) kommen aus kern/ui.sh, die Farben aus theme.sh.
# ============================================================

SITZEN_MAX_STREAK=12       # höchstens so viele Stunden am Stück
SITZEN_MAX_DAY=12          # höchstens so viele Stunden pro Spieltag
SITZEN_BLACK_SECS=3        # so lange steht der Bildschirm schwarz ("Du sitzt")

# ============================================================
#  Einstieg: Sitzgelegenheit benutzen
# ============================================================
# Öffnet das Sitz-Fenster für die Sitzgelegenheit <id>. Prüft vorher
# die Tagesgrenze (zurückgesetzt bei einem neuen Spieltag).
sitzen_start() {   # $1 = Interior-id der Sitzgelegenheit
    local id="${1:-}" rate day budget maxh
    [ -n "$id" ] || return 1
    rate="$(interior_sit_rate_of "$id")"
    [ "$rate" -gt 0 ] 2>/dev/null || rate=0

    # Neuer Spieltag? -> Zähler zurücksetzen.
    day="$(uhrzeit_day)"
    [ "${SIT_DAY:--1}" = "$day" ] || { SIT_HOURS_TODAY=0; SIT_DAY="$day"; }

    # Erlaubte Stunden: am Stück begrenzt und um das Tagesbudget gekürzt.
    budget=$(( SITZEN_MAX_DAY - ${SIT_HOURS_TODAY:-0} ))
    maxh=$SITZEN_MAX_STREAK
    [ "$budget" -lt "$maxh" ] && maxh=$budget

    if [ "$maxh" -lt 1 ]; then
        play_sound error
        OUT+=("")
        OUT+=("Ich habe heute schon ${SITZEN_MAX_DAY} Stunden gesessen.")
        OUT+=("Mehr geht erst an einem neuen Tag.")
        return 0
    fi

    sitzen_screen "$id" "$rate" "$maxh"
    return 0
}

# ============================================================
#  Fenster (klein, mittig)
# ============================================================
# Zeichnet das Sitz-Fenster: Stunden einstellen + Live-Vorschau.
sitzen_paint() {   # $1 = id, $2 = Tokens je Stunde, $3 = Stunden, $4 = max
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

    draw_box "$x" "$y" "$w" "$hh" "SITZEN" "$FRAME_HI"
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
        "$(center_text "↑/↓ (max ${maxh})  ·  Enter sitzen  ·  Esc/Q raus" "$iw")" "$MENU_C"
}

# Das Fenster: ↑/↓ wählen die Stunden, Enter setzt sich, Esc/Q bricht ab.
sitzen_screen() {   # $1 = id, $2 = Tokens je Stunde, $3 = Höchststunden
    local id="$1" rate="$2" maxh="$3"
    local h=1
    [ "$h" -gt "$maxh" ] && h="$maxh"
    [ "$h" -lt 1 ] && h=1

    play_sound select
    printf '%s' "$UI_BG"
    clear

    while true; do
        sitzen_paint "$id" "$rate" "$h" "$maxh"
        read_key_t "" || break
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') [ "$h" -lt "$maxh" ] && { h=$(( h + 1 )); play_sound move; } ;;   # hoch
            $'\x1b[B'|$'\x1bOB') [ "$h" -gt 1 ] && { h=$(( h - 1 )); play_sound move; } ;;         # runter
            $'\n'|$'\r')         play_sound cmd_touch
                                 sitzen_do "$id" "$rate" "$h"; break ;;      # sitzen
            $'\x1b'|q|Q)         break ;;                                     # abbrechen
        esac
    done

    # Danach die Spiel-GUI vollständig neu aufbauen.
    FIRST_RENDER=1
    return 0
}

# ============================================================
#  Sitzen: schwarzer Bildschirm + Wirkung
# ============================================================
sitzen_do() {   # $1 = id, $2 = Tokens je Stunde, $3 = Stunden
    local id="$1" rate="$2" h="$3"
    [ "$h" -gt 0 ] 2>/dev/null || return 0

    local day before after gain
    day="$(uhrzeit_day)"                 # Tag, AN dem gesessen wird
    before="${TOKENS_CUR:-0}"

    sitzen_black "$h"                    # kurzer schwarzer Bildschirm

    # Tokens regenerieren (höchstens bis TOKENS_MAX).
    after=$(( before + h * rate ))
    [ "$after" -gt "${TOKENS_MAX:-0}" ] && after="${TOKENS_MAX:-0}"
    TOKENS_CUR=$after
    gain=$(( after - before ))

    # Spielzeit vorrücken und den Tagessitz vermerken.
    uhrzeit_advance_hours "$h"
    SIT_DAY="$day"
    SIT_HOURS_TODAY=$(( ${SIT_HOURS_TODAY:-0} + h ))

    play_sound online
    OUT+=("")
    if [ "$h" = "1" ]; then
        OUT+=("── Du hast eine Stunde gesessen. ──")
    else
        OUT+=("── Du hast ${h} Stunden gesessen. ──")
    fi
    OUT+=("   Tokens regeneriert: +${gain}   (${TOKENS_CUR} / ${TOKENS_MAX})")
    [ "${TOKENS_CUR}" -ge "${TOKENS_MAX}" ] && OUT+=("   Der Speicher ist voll.")
    return 0
}

# Kurz schwarz werden: nur "Du sitzt" steht da.
# Dev-/Test-Haken: TH_SIT_SECS überschreibt die Dauer.
sitzen_black() {
    local secs="${TH_SIT_SECS:-$SITZEN_BLACK_SECS}"
    geom
    printf '\033[48;5;16m\033[38;5;250m'   # schwarzer Grund, heller Text
    clear
    local msg="Du sitzt"
    local rr=$(( ROWS / 2 ))
    local cc=$(( (COLS - ${#msg}) / 2 + 1 )); [ "$cc" -lt 1 ] && cc=1
    pos "$rr" "$cc"
    printf '%s' "$msg"
    sleep "$secs"
}
