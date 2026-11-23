# ============================================================
#  TerminalHero - Objekte durchsuchen (Register)
# ------------------------------------------------------------
#  Manche Objekte in der Welt sind mehr als eine Datei: Eine Leiche
#  kann durchsucht werden, ein Schrank, eine Kiste. Statt den Befehl
#  »search« mit Sonderfällen zu füllen, meldet jedes solche Objekt
#  seine eigene Suchfunktion hier an:
#
#     search_define <pfad> <funktion>
#
#  Die Funktion läuft, wenn der Agent »search <objekt>« eingibt. Sie
#  bekommt den aufgelösten Pfad als $1 und schreibt ihre Ausgabe nach
#  OUT (wie ein Dialog oder »grep«).
#
#  Das Register ist reiner Laufzeitzustand: Die Objekte melden sich
#  beim Aufbau ihres Ortes bzw. beim Laden erneut an. Es wird nicht
#  gespeichert.
# ============================================================

declare -gA SEARCH_TARGET_FN=()   # Pfad -> Suchfunktion

# Suchfunktion anmelden (idempotent; ein erneuter Aufruf aktualisiert sie).
search_define() {   # <pfad> <funktion>
    [ -n "${1:-}" ] && [ -n "${2:-}" ] || return 1
    SEARCH_TARGET_FN["$1"]="$2"
    return 0
}

# Suchfunktion eines Pfads (leer, wenn das Objekt nicht durchsuchbar ist).
search_fn_of() { printf '%s' "${SEARCH_TARGET_FN[$1]:-}"; }

# Objekt aus dem Register nehmen (z. B. wenn es den Ort wechselt).
search_forget() {   # <pfad>
    [ -n "${1:-}" ] || return 0
    unset "SEARCH_TARGET_FN[$1]"
    return 0
}
