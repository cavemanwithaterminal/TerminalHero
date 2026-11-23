# ============================================================
#  TerminalHero - Echte Spielzeit (Statistik)
# ------------------------------------------------------------
#  Anders als WORLD_SECS (kern/Uhrzeit.sh) zählt diese Zeit die ECHTE
#  Zeit, die das Spiel läuft - ohne Sprünge durch Schlafen oder
#  Zeitraffer. Gespeichert wird der Stand bis zum letzten Save in
#  PLAYTIME_BASE (diese Datei, kern/save.sh); PLAYTIME_START ist nur
#  der flüchtige Anker der aktuellen Sitzung.
#
#  th_save ruft playtime_snapshot() auf, damit der Spielstand die Zeit
#  bis zum Speichern enthält. Danach beginnt der Anker neu - so wird
#  keine Sekunde doppelt gezählt.
# ============================================================

# ============================================================
#  Echte Spielzeit (Statistik)
# ============================================================
PLAYTIME_BASE=0                 # gespeicherte Sekunden bis zum letzten Save
PLAYTIME_START=0                # flüchtiger Sitzungsanker (nie gespeichert)

# Aktuellen Gesamtstand in Sekunden berechnen (ohne ihn zu verändern).
playtime_seconds() {
    local base="${PLAYTIME_BASE:-0}" start="${PLAYTIME_START:-0}" now
    case "$base" in ''|*[!0-9]*) base=0 ;; esac
    [ "$base" -lt 0 ] 2>/dev/null && base=0
    if [ "$start" -gt 0 ] 2>/dev/null; then
        now="$(date +%s)"
        [ "$now" -gt "$start" ] && base=$(( base + now - start ))
    fi
    printf '%s' "$base"
}

# Gesamtzeit als "HH h MM min SS s". $1 = Sekunden (sonst aktueller Stand).
playtime_text() {
    local total="${1:-}" h m s
    [ -n "$total" ] || total="$(playtime_seconds)"
    [ "$total" -ge 0 ] 2>/dev/null || total=0
    h=$(( total / 3600 ))
    m=$(( (total % 3600) / 60 ))
    s=$(( total % 60 ))
    printf '%02d h %02d min %02d s' "$h" "$m" "$s"
}

# Spielstand-Snapshot: Zeit bis jetzt festschreiben, Anker neu setzen.
playtime_snapshot() {
    PLAYTIME_BASE="$(playtime_seconds)"
    PLAYTIME_START="$(date +%s)"
}
