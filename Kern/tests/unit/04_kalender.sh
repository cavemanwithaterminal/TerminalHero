# ============================================================
#  Unit-Test-Teil: Kalender (cal)
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Kalender (cal)"
# ==================================================================
# Der Kalender rechnet mit derselben Spielzeit wie die Uhr:
# 1 echte Stunde = 1 Spieltag. Start ist der 25.01.240, 06:00.
# 10 echte Jahre + 1 echter Tag = 240 Spieljahre + 24 Spieltage.
. "$SCRIPT_DIR/kern/kalender.sh"
. "$SCRIPT_DIR/TerminalBefehle/cal.sh"

WORLD_SECS=0; WORLD_STARTED=1
CAL_UNTIL_MIN=0
chk "Startdatum: 25.01.240" "25.01.240" "$(cal_date_text)"
cal_add_days 0
chk "Startdatum in Teilen" "25 1 240" "$CAL_D $CAL_M $CAL_Y"
cal_add_days 6
chk "31.01.240 nach 6 Tagen" "31 1 240" "$CAL_D $CAL_M $CAL_Y"
cal_add_days 7
chk "01.02.240 nach 7 Tagen" "1 2 240" "$CAL_D $CAL_M $CAL_Y"
cal_add_days 34
chk "28.02.240 nach 34 Tagen" "28 2 240" "$CAL_D $CAL_M $CAL_Y"
cal_add_days 35
chk "01.03.240 nach 35 Tagen" "1 3 240" "$CAL_D $CAL_M $CAL_Y"
cal_add_days 340
chk "31.12.240 nach 340 Tagen" "31 12 240" "$CAL_D $CAL_M $CAL_Y"
cal_add_days 341
chk "01.01.241 nach 341 Tagen" "1 1 241" "$CAL_D $CAL_M $CAL_Y"

# Das Datum springt um Mitternacht um, nicht um 06:00.
WORLD_SECS=2699
chk "vor Mitternacht: noch 25.01.240" "25.01.240" "$(cal_date_text)"
WORLD_SECS=2700
chk "nach Mitternacht: 26.01.240" "26.01.240" "$(cal_date_text)"
WORLD_SECS=3600
chk "24 Spielstunden später: 26.01.240" "26.01.240" "$(cal_date_text)"
WORLD_SECS=7200
chk "48 Spielstunden später: 27.01.240" "27.01.240" "$(cal_date_text)"

# Kosten und EXP: nur wer »cal« kennt, bezahlt 50 Tokens; die Absage
# vor dem Erlernen bleibt kostenlos.
WORLD_SECS=0; CAL_UNTIL_MIN=0; LEARNED=()
chk "cal vor dem Erlernen kostet 0" "0" "$(token_cost_of cal)"
chk "cal vor dem Erlernen gibt 0 EXP" "0" "$(token_exp_of cal)"
LEARNED=(cal)
chk "cal nach dem Erlernen kostet 50" "50" "$(token_cost_of cal)"
chk "cal nach dem Erlernen gibt 10 EXP" "10" "$(token_exp_of cal)"

# Befehl: setzt die Anzeige für 24 Spielstunden und nennt das Datum.
WORLD_SECS=0; CAL_UNTIL_MIN=0; LEARNED=(cal); OUT=()
builtin_cal
chk "cal setzt die Anzeigedauer (1440 Minuten)" "1440" "$CAL_UNTIL_MIN"
chk "cal nennt das Datum" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Kalender: 25.01.240')"
chk "cal nennt die 24 Spielstunden" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c '24 Spielstunden')"
cal_active; chk_rc "cal ist direkt nach der Eingabe aktiv" "$?" 0
WORLD_SECS=3599
cal_active; chk_rc "cal ist kurz vor Ablauf noch aktiv" "$?" 0
WORLD_SECS=3600
cal_active; chk_rc "cal ist nach 24 Spielstunden aus" "$?" 1

# Unbekannter Befehl: Virus-Absage, keine Anzeige.
WORLD_SECS=0; CAL_UNTIL_MIN=0; LEARNED=(); OUT=()
builtin_cal
chk "cal unbekannt: Virus-Absage" "1" \
    "$(printf '%s\n' "${OUT[@]}" | grep -c 'Diesen Befehl kenne ich nicht mehr')"
chk "cal unbekannt: keine Anzeige" "0" "$CAL_UNTIL_MIN"

# Hilfe: cal ist ein Terminal-Befehl und erscheint erst nach dem Erlernen.
chk "cal ist ein Terminal-Befehl" "1" \
    "$(printf '%s\n' "${HELP_TERM[@]}" | grep -cx cal)"
chk "cal-Aufruf in der Hilfe" "cal" "${HELP_USAGE[cal]}"
chk "cal wird gelernt" "gelernt" "${HELP_AVAIL[cal]:-}"
LEARNED=(pwd ls cd cat touch)
help_build_rows 0
chk "Hilfe zeigt cal vor dem Erlernen nicht" "0" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx cal)"
LEARNED+=(cal)
help_build_rows 0
chk "Hilfe zeigt cal nach dem Erlernen" "1" \
    "$(printf '%s\n' "${HELP_ROWS[@]}" | grep -cx cal)"

# Aufräumen für die folgenden Abschnitte.
WORLD_SECS=0; CAL_UNTIL_MIN=0; OUT=()
LEARNED=(pwd ls cd cat touch)
tokens_reset
char_reset

