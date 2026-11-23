# ============================================================
#  TerminalHero - Kalender (In-Game-Datum)
# ------------------------------------------------------------
#  Das In-Game-Datum wird aus derselben Spielzeit berechnet wie die
#  Uhr in kern/Uhrzeit.sh:
#
#      1 echte Stunde  = 1 Spieltag  (24 Spielstunden)
#      1 echter Tag    = 24 Spieltage
#      1 echtes Jahr   = 24 Spieljahre
#
#  Der Agent ist zu Spielbeginn 10 echte Jahre und 1 echten Tag alt.
#  Das sind 240 Spieljahre und 24 Spieltage. Vom Geburtstag am
#  01.01.000 aus gerechnet ist der Start deshalb:
#
#      25.01.240  (nicht der 24.01.: der 24.01. wäre der 23. volle Tag)
#
#  Die Uhr startet um 06:00. Für das Datum zählt aber der volle Tag ab
#  Mitternacht, damit es - wie im echten Leben - um 00:00 umspringt.
#  Die Monate haben die echten Längen; der Februar hat 28 Tage (keine
#  Schaltjahre).
#
#  Angezeigt wird das Datum nur nach Eingabe von »cal« - dann für
#  24 Spielstunden als Notch mittig auf der OBEREN Linie des PFAD-
#  Fensters. CAL_UNTIL_MIN steht in kern/state.sh und wird gespeichert.
#
#  Nur Funktionsdefinitionen + Startwerte; die Zeichenprimitive kommen
#  aus kern/ui.sh, die Geometrie aus render.sh/geom().
# ============================================================

# --- Kalenderdaten ---------------------------------------------------
declare -ga CAL_MONTH_DAYS=(31 28 31 30 31 30 31 31 30 31 30 31)
CAL_BASE_DAY=25
CAL_BASE_MONTH=1
CAL_BASE_YEAR=240
CAL_START_MIN=360              # 06:00, wie CLOCK_START_MIN in Uhrzeit.sh
CAL_DAY_MIN=1440
CAL_VISIBLE_HOURS=24
CAL_VISIBLE_MIN=$(( CAL_VISIBLE_HOURS * 60 ))

# --- Datumsteile nach dem Startdatum (für Tests und cal_date_text) ---
# Setzt CAL_D / CAL_M / CAL_Y auf das Datum <tage> Tage nach dem
# Startdatum. Die Monatslängen kommen aus CAL_MONTH_DAYS.
cal_add_days() {
    local days="${1:-0}" d="$CAL_BASE_DAY" m="$CAL_BASE_MONTH" y="$CAL_BASE_YEAR"
    local dim left
    case "$days" in
        ''|*[!0-9]*) days=0 ;;
    esac
    while [ "$days" -gt 0 ]; do
        dim="${CAL_MONTH_DAYS[m-1]}"
        left=$(( dim - d ))
        if [ "$days" -le "$left" ]; then
            d=$(( d + days ))
            days=0
            break
        fi
        days=$(( days - left - 1 ))
        d=1
        m=$(( m + 1 ))
        if [ "$m" -gt 12 ]; then
            m=1
            y=$(( y + 1 ))
        fi
    done
    CAL_D=$d
    CAL_M=$m
    CAL_Y=$y
}

# Wie viele volle Spieltage sind seit dem Startdatum vergangen?
# Die Startuhr steht auf 06:00; deshalb werden die 360 Minuten bis
# Mitternacht mitgezählt. So springt das Datum um 00:00 um.
cal_day_offset() {
    printf '%s' $(( ( CAL_START_MIN + $(uhrzeit_minutes) ) / CAL_DAY_MIN ))
}

# Aktuelles In-Game-Datum als TT.MM.JJJJ (z. B. 25.01.240).
cal_date_text() {
    cal_add_days "$(cal_day_offset)"
    printf '%02d.%02d.%d' "$CAL_D" "$CAL_M" "$CAL_Y"
}

# Datum für einen absoluten Spieltag (0 = Starttag) als TT.MM.JJJJ.
# Läuft in einer Subshell, damit die aktuellen CAL_D/M/Y unberührt bleiben.
cal_date_text_for_day() {
    local days="${1:-0}"
    case "$days" in
        ''|*[!0-9]*) return 0 ;;
    esac
    (
        cal_add_days "$days"
        printf '%02d.%02d.%d' "$CAL_D" "$CAL_M" "$CAL_Y"
    )
}

# Ist die Kalenderanzeige gerade aktiv? (0 = ja)
cal_active() {
    local now
    [ "${CAL_UNTIL_MIN:-0}" -gt 0 ] 2>/dev/null || return 1
    now="$(uhrzeit_minutes)"
    [ "$CAL_UNTIL_MIN" -gt "$now" ]
}

# Kalender für 24 Spielstunden einblenden (oder die Dauer erneuern).
cal_reveal() {
    CAL_UNTIL_MIN=$(( $(uhrzeit_minutes) + CAL_VISIBLE_MIN ))
}

# Das Datum mittig auf die obere Linie des PFAD-Fensters setzen.
# Ohne erlerntes »cal« oder nach Ablauf der 24 Stunden passiert nichts;
# die normale Rahmenlinie bleibt dann stehen.
cal_draw() {
    declare -F knows >/dev/null 2>&1 && knows cal || return 0
    cal_active || return 0

    local t="╡ ◷ $(cal_date_text) ╞"
    local x=$(( (COLS - ${#t}) / 2 + 1 ))
    [ "$x" -lt 2 ] && x=2
    [ "$x" -gt $(( COLS - ${#t} + 1 )) ] && return 0
    put_text "$PATH_TOP" "$x" "${#t}" "$t" "$TITLE$BOLD"
}
