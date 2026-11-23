# ============================================================
#  TerminalHero - Charakter: Torwächter (Kompatibilitätsdatei)
# ------------------------------------------------------------
#  Der Torwächter heißt Simon Guard; sein Gespräch steht in
#  Charakter/SimonGuard.sh. Diese Datei bleibt nur für alte
#  Verweise auf »dialog_torwaechter« erhalten. Neue Szenen und
#  der Eintrag im Dateisystem sprechen dialog_simon_guard an.
# ============================================================

dialog_torwaechter() {
    if ! declare -F dialog_simon_guard >/dev/null 2>&1; then
        # Wird die Datei direkt (z. B. in einem Test) geladen, obwohl
        # SimonGuard.sh noch nicht im Speicher ist, laden wir sie nach.
        . "$SCRIPT_DIR/Charakter/SimonGuard.sh"
    fi
    dialog_simon_guard "$@"
}
