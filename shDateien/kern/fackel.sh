# ============================================================
#  TerminalHero - Fackel (Licht für das Ordner-Fenster)
# ------------------------------------------------------------
#  Die »Einfache Fackel« ist ein benutzbarer Gegenstand aus
#  NutzbareItems/EinfacheFackel.sh. Wird sie im Inventar benutzt,
#  brennt sie für FACKEL_HOURS SPIELSTUNDEN. Die große »Fackel«
#  (NutzbareItems/Fackel2.sh) brennt 8 Stunden - die Stunden stehen
#  beim Aufruf von fackel_light.
#
#  Solange sie brennt, zeigt das rechte Ordner-Fenster den Inhalt
#  des aktuellen Ordners AUTOMATISCH an - ganz ohne »ls«. Das gilt
#  nur für sichtbare Einträge; versteckte Dateien bleiben verborgen,
#  solange der Agent nicht ausdrücklich »ls -a« benutzt.
#
#  Die Brenndauer rechnet in Spielminuten (kern/Uhrzeit.sh), damit
#  Schlafen/Sitzen die Fackel genauso altern lassen wie normales
#  Spielen. TORCH_UNTIL_MIN steht in kern/state.sh und wird im
#  Spielstand gesichert.
#
#  Nur Funktionsdefinitionen; die Anzeige steckt in kern/render.sh.
# ============================================================

FACKEL_HOURS=3
FACKEL_MINUTES=$(( FACKEL_HOURS * 60 ))

# Brennt die Fackel gerade? (0 = ja)
fackel_active() {
    local now
    [ "${TORCH_UNTIL_MIN:-0}" -gt 0 ] 2>/dev/null || return 1
    now="$(uhrzeit_minutes)"
    [ "$TORCH_UNTIL_MIN" -gt "$now" ]
}

# Ein Fackel-Item benutzen: EIN Exemplar verbrauchen und anzünden.
#   $1 = Item-id, $2 = Stunden
# Brennt bereits eine Fackel, wird keine weitere verbraucht: Der Agent
# bekommt nur den Hinweis, dass es schon hell genug ist.
fackel_use() {   # <item-id> <stunden>
    local id="$1" hours="$2"
    if declare -F fackel_active >/dev/null 2>&1 && fackel_active; then
        OUT+=("")
        OUT+=("Die Fackel brennt bereits. Es ist hell genug.")
        return 0
    fi
    # EIN Exemplar aus dem Inventar nehmen. Ohne Verbrauch ließe sich
    # dieselbe Fackel beliebig oft wieder anzünden.
    inv_remove "$id" 1
    fackel_light "$hours"
}

# Fackel anzünden (oder die Brenndauer erneuern).
# $1 = Stunden (optional; Standard: FACKEL_HOURS). Die Fackel-Arten
# (Einfache Fackel, Fackel) brennen so unterschiedlich lange.
# Die Meldung landet im Ausgabe-/Dialogfenster.
fackel_light() {   # [$stunden]
    local hours="${1:-$FACKEL_HOURS}" now
    now="$(uhrzeit_minutes)"
    TORCH_UNTIL_MIN=$(( now + hours * 60 ))
    play_sound select
    OUT+=("")
    OUT+=("Fackel angezündet")
    OUT+=("   Sie brennt ${hours} Spielstunden. Ordnerinhalte")
    OUT+=("   werden so lange automatisch angezeigt.")
    return 0
}

# Ist die Brennzeit abgelaufen? Setzt die Fackel aus und meldet es
# genau einmal. Rückgabe 0 = gerade erloschen (Neuzeichnen nötig).
fackel_tick() {
    local now
    [ "${TORCH_UNTIL_MIN:-0}" -gt 0 ] 2>/dev/null || return 1
    now="$(uhrzeit_minutes)"
    [ "$TORCH_UNTIL_MIN" -le "$now" ] || return 1
    TORCH_UNTIL_MIN=0
    OUT+=("")
    OUT+=("Die Fackel ist erloschen.")
    return 0
}
