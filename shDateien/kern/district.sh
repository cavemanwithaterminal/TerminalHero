# ============================================================
#  TerminalHero - Stadtteile (Distrikte)
#
#  Jeder Stadtteil bringt seine eigene "Welt" mit (Ordner, Dateien,
#  Inhalte, Dialoge). Diese Welt steht in einer eigenen Datei im
#  Projektordner (<Stadtteil>.sh) und wird geladen, sobald der Spieler
#  den Stadtteil betritt. Verlässt er ihn Richtung Haupteingang, ist
#  wieder allein die Basis (TerminalShell.sh) zuständig.
#
#  Aufbau einer Stadtteil-Datei:
#     district_build_<key>()   registriert Ordner/Dateien/Inhalte/Dialoge
#                              (über addp / CONTENT[] / DIALOG[])
#     district_enter_<key>()   (optional) läuft bei jedem Betreten
#     district_leave_<key>()   (optional) läuft bei jedem Verlassen
#
#  Die Datei wird per "source" geladen - KEIN eigener Prozess. Dadurch
#  stehen Token-Wirtschaft, Speichern/Laden und alle Befehle unverändert
#  zur Verfügung: der Stadtteil ist Teil desselben Spiels.
# ============================================================

# Schlüssel -> Datei- und Ordnername. Reihenfolge = Laufreihenfolge.
DISTRICT_KEYS=(sued nord west ost zentrum)

declare -gA DISTRICT_FILE=(
    [sued]="Süddistrikt.sh"
    [nord]="Norddistrikt.sh"
    [west]="Westdistrikt.sh"
    [ost]="Ostdistrikt.sh"
    [zentrum]="Zentrum.sh"
)
declare -gA DISTRICT_DIRNAME=(
    [sued]="Süddistrikt"
    [nord]="Norddistrikt"
    [west]="Westdistrikt"
    [ost]="Ostdistrikt"
    [zentrum]="Zentrum"
)

declare -gA DISTRICT_LOADED=()   # Schlüssel -> 1 (Welt schon registriert)
DISTRICT_ACTIVE=""              # Schlüssel des Stadtteils, in dem wir stehen ("" = Basis)

# Basispfad, unter dem alle Stadtteile liegen.
district_base() { printf '%s/Schreibtisch/DesktopCity/Haupteingang' "$HOME_DIR"; }

# Ortsname (»Ostdistrikt«, auch klein geschrieben) -> voller Pfad des
# Stadtteils. Leer, wenn das Wort kein Stadtteil ist.
district_path_by_name() {
    local w="${1:-}" k d
    [ -n "$w" ] || return 0
    # Der Haupteingang ist selbst kein Stadtteil, aber innerhalb der Stadt
    # ein direktes Ziel: von jedem Bezirk dorthin und vom Haupteingang in
    # jeden Bezirk. Von außerhalb bleibt die Sperre in cd.sh bestehen.
    if [ "${w,,}" = "haupteingang" ]; then
        district_base
        return 0
    fi
    for k in "${DISTRICT_KEYS[@]}"; do
        d="${DISTRICT_DIRNAME[$k]}"
        if [ "$d" = "$w" ] || [ "${d,,}" = "${w,,}" ]; then
            printf '%s/%s' "$(district_base)" "$d"
            return 0
        fi
    done
    return 0
}

# Zu welchem Stadtteil gehört <pfad> (der Stadtteil selbst oder etwas darunter)?
# Gibt den Schlüssel aus ("" = kein Stadtteil).
district_key_of_path() {
    local p="$1" base rest first k
    base="$(district_base)"
    case "$p" in
        "$base"/*) ;;
        *) return 0 ;;
    esac
    rest="${p#"$base"/}"
    first="${rest%%/*}"
    for k in "${DISTRICT_KEYS[@]}"; do
        if [ "${DISTRICT_DIRNAME[$k]}" = "$first" ]; then printf '%s' "$k"; return 0; fi
    done
    return 0
}

# Registriert die Welt eines Stadtteils - genau einmal pro Sitzung.
# Fehlt die Datei oder ein Aufbau, passiert nichts (kein Fehler).
district_load() {
    local k="$1" f fn
    [ -n "$k" ] || return 0
    [ "${DISTRICT_LOADED[$k]:-0}" = "1" ] && return 0

    f="$SCRIPT_DIR/Orte/${DISTRICT_FILE[$k]}"
    if [ ! -f "$f" ]; then
        DISTRICT_LOADED[$k]=1
        return 0
    fi
    # shellcheck disable=SC1090
    . "$f"
    DISTRICT_LOADED[$k]=1

    fn="district_build_$k"
    if declare -F "$fn" >/dev/null 2>&1; then
        "$fn"
        items_world_refresh       # Welt-Gegenstände (Fundorte) ins Dateisystem legen
        world_drops_refresh       # vom Spieler abgelegte Items wieder aufstellen
        interior_world_refresh    # Einrichtung (Interior) ins Dateisystem legen
        build_children            # neu hinzugekommene Ordner/Dateien einbinden
    fi
    return 0
}

# Ortswechsel auswerten: alten Stadtteil verlassen, neuen betreten.
# Wird nach jedem Befehl aufgerufen; tut nur etwas, wenn sich der Stadtteil ändert.
district_sync() {
    local k lf ef
    k="$(district_key_of_path "$CWD")"
    [ "$k" = "$DISTRICT_ACTIVE" ] && return 0

    if [ -n "$DISTRICT_ACTIVE" ]; then
        lf="district_leave_$DISTRICT_ACTIVE"
        declare -F "$lf" >/dev/null 2>&1 && "$lf"
    fi
    DISTRICT_ACTIVE="$k"
    if [ -n "$k" ]; then
        district_load "$k"
        ef="district_enter_$k"
        declare -F "$ef" >/dev/null 2>&1 && "$ef"
    fi
    return 0
}

# Beim Spielstart/Laden: Stadtteil still laden, aber KEINE Betreten-Szene
# abspielen (sonst würde sie bei jedem Laden erneut erscheinen).
district_prepare() {
    local k
    k="$(district_key_of_path "$CWD")"
    DISTRICT_ACTIVE="$k"
    [ -n "$k" ] && district_load "$k"
    return 0
}

# Stellt sicher, dass der Stadtteil zu <pfad> geladen ist - für ls/cat/Tab,
# ohne den Stadtteil selbst zu betreten. Rückgabe immer 0.
district_ensure() {
    local k
    k="$(district_key_of_path "$1")"
    [ -n "$k" ] && district_load "$k"
    return 0
}
