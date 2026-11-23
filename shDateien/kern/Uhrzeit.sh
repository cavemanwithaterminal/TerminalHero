# ============================================================
#  TerminalHero - Uhrzeit (In-Game-Zeit)
# ------------------------------------------------------------
#  Die Spielwelt hat eine eigene Uhr. Sie beginnt zu laufen, sobald das
#  Gespräch mit dem General (README) anfängt - Startzeit: 06:00.
#
#  Zeitraffer:  1 ECHTE STUNDE = 1 GANZER SPIELTAG
#     3600 echte Sekunden  = 1440 Spielminuten  =>  1 Spielminute = 2,5 s
#     Umrechnung ohne bc:  Spielminuten = Sekunden * 2 / 5
#
#  Die Zeit läuft NUR, während gespielt wird (kein Fortschritt, während das
#  Spiel geschlossen ist) - wichtig für spätere Tagesabläufe/Routinen der
#  NPCs. Gespeichert wird nur die angesammelte Spielzeit (WORLD_SECS).
#
#  ANGEZEIGT wird die Uhr erst, wenn der Agent die »Armbanduhr« bei sich
#  trägt (Spezial-Item). Sie sitzt als Notch in der Trennlinie zwischen
#  PFAD-Fenster (oben) und Ordner-/Ls-Fenster (unten rechts), horizontal
#  mittig über dem Ordner-Fenster.
#
#  Nur Funktionsdefinitionen + Startwerte; die Zeichenprimitive kommen aus
#  kern/ui.sh, die Geometrie aus render.sh/geom().
# ============================================================

# --- Startwerte -------------------------------------------------------
CLOCK_START_MIN=$(( 6 * 60 ))   # Spielbeginn: 06:00 (Minuten seit Mitternacht)
CLOCK_DAY_MIN=1440              # Minuten eines Spieltags (24 h)
CLOCK_MIN_NUM=2                 # Spielminuten = Sekunden * 2 / 5  (s. o.)
CLOCK_MIN_DEN=5

WORLD_SECS=0                    # angesammelte ECHTE Spielsekunden (wird gespeichert)
WORLD_STARTED=0                 # 1 = Uhr läuft (General-Gespräch hat begonnen)

# Flüchtig (nie gespeichert):
WORLD_LAST=0                    # Zeitstempel des letzten Ticks (epoch)
WORLD_SHOWN_MIN=-1              # zuletzt ANGEZEIGTE Spielminute (fürs Neuzeichnen)

# Zurücksetzen auf den Startzustand (Frischstart).
# Dev-/Test-Haken: TH_WORLD_SECS belegt die Spielzeit vor und startet die Uhr.
uhrzeit_reset() {
    WORLD_SECS=0
    WORLD_STARTED=0
    WORLD_LAST=0
    WORLD_SHOWN_MIN=-1
    if [ -n "${TH_WORLD_SECS:-}" ]; then
        WORLD_SECS=$TH_WORLD_SECS
        WORLD_STARTED=1
    fi
}

uhrzeit_running() { [ "${WORLD_STARTED:-0}" = "1" ]; }

# Uhr starten (idempotent) - im Moment, in dem das General-Gespräch beginnt.
uhrzeit_start() {
    uhrzeit_running && return 0
    WORLD_STARTED=1
    WORLD_LAST="$(date +%s)"
    WORLD_SHOWN_MIN=-1
}

# Vergangene Spielminuten seit Spielbeginn.
uhrzeit_minutes() {
    printf '%s' $(( ${WORLD_SECS:-0} * CLOCK_MIN_NUM / CLOCK_MIN_DEN ))
}

# Aktuelle Uhrzeit als HH:MM (24-Stunden-Format, nullgepolstert).
uhrzeit_text() {
    local m=$(( CLOCK_START_MIN + $(uhrzeit_minutes) ))
    m=$(( m % CLOCK_DAY_MIN ))
    [ "$m" -lt 0 ] && m=$(( m + CLOCK_DAY_MIN ))
    printf '%02d:%02d' $(( m / 60 )) $(( m % 60 ))
}

# Zeit fortschreiben (läuft nur während des Spielens).
# Rückgabe 0, wenn sich die angezeigte Spielminute geändert hat (=> Neuzeichnen).
uhrzeit_tick() {
    uhrzeit_running || return 1
    local now last m
    now="$(date +%s)"; last="${WORLD_LAST:-0}"
    if [ "$now" -gt "$last" ]; then
        WORLD_SECS=$(( ${WORLD_SECS:-0} + now - last ))
        WORLD_LAST=$now
    fi
    m="$(uhrzeit_minutes)"
    [ "$m" != "${WORLD_SHOWN_MIN:-}" ] || return 1
    WORLD_SHOWN_MIN=$m
    return 0
}

# Spieltag-Nummer (0 = Starttag). Ein Spieltag hat 1440 Minuten und
# wechselt um Mitternacht; die Startzeit 06:00 liegt in Tag 0.
# Genutzt u. a. vom Schlaf-Zähler (kern/schlafen.sh).
uhrzeit_day() {
    printf '%s' $(( ( CLOCK_START_MIN + $(uhrzeit_minutes) ) / CLOCK_DAY_MIN ))
}

# Spielzeit um <stunden> SPIELSTUNDEN vorrücken (z. B. Schlaf).
# 1 Spielstunde = 60 Spielminuten = 60 * 5/2 = 150 echte Sekunden.
# Der Zeitanker wird neu gesetzt, damit die Wartezeit der Schlaf-Szene
# nicht doppelt zählt. Ohne laufende Uhr passiert nichts.
uhrzeit_advance_hours() {
    local h="${1:-0}"
    [ "$h" -gt 0 ] 2>/dev/null || return 0
    uhrzeit_running || return 0
    WORLD_SECS=$(( ${WORLD_SECS:-0} + h * (CLOCK_DAY_MIN / 24) * CLOCK_MIN_DEN / CLOCK_MIN_NUM ))
    WORLD_SHOWN_MIN=-1
    WORLD_LAST="$(date +%s)"
    return 0
}

# Die Uhrzeit in die Trennlinie zwischen PFAD- und Dialog-Fenster setzen.
# Ohne Armbanduhr (oder ohne laufende Uhr) passiert nichts.
uhrzeit_draw() {
    inv_has armbanduhr || return 0
    uhrzeit_running    || return 0

    local row=$(( PATH_TOP + PATH_H - 1 ))              # Unterkante PFAD-Fenster
    local cx=$(( RIGHT_X + RIGHT_W / 2 ))               # Mitte des Ordner-Fensters
    local t="╡ ◷ $(uhrzeit_text) ╞"
    local x=$(( cx - ${#t} / 2 ))
    [ "$x" -lt 2 ] && x=2
    put_text "$row" "$x" "${#t}" "$t" "$TITLE$BOLD"
}
