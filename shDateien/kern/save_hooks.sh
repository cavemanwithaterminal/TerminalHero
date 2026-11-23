# ============================================================
#  TerminalHero - Speicher-Haken (Hauptschleife)
#
#  maybe_unlock_save  – beim ersten Betreten des Downloads-Bereichs (nach
#                       abgeschlossenem Tutorial) kehrt die Erinnerung an
#                       »save« zurück.
#  autosave_tick      – regelmäßiger automatischer Quicksave.
#  Wird in kern/save.sh eingebunden (dort liegen th_save/th_load).
# ============================================================

# Intervall des automatischen Quicksaves in Sekunden (Testhaken: TH_AUTOSAVE_SECS).
TH_SAVE_INTERVAL="${TH_AUTOSAVE_SECS:-600}"
TH_NEXT_AUTOSAVE=0

maybe_unlock_save() {
    [ "$SAVE_LEARNED" = "1" ] && return 0
    [ "$TUT_DONE" = "1" ]   || return 0
    # Nur im Downloads-Bereich – aber noch NICHT im Agenten-Ordner (Tutorial).
    case "$CWD" in
        "$HOME_DIR/Downloads"|"$HOME_DIR/Downloads/"*) ;;
        *) return 0 ;;
    esac
    case "$CWD" in
        "$AGENT_DIR"|"$AGENT_DIR/"*) return 0 ;;
    esac

    SAVE_LEARNED=1
    knows save && return 0
    OUT+=("")
    OUT+=("[ Gedächtnis: Ein Riss schließt sich. ]")
    OUT+=("Hier unten, zwischen all den Downloads, finde ich ein Stück zurück:")
    # Wie JEDER erlernte Befehl: grüne Meldung + Sound (kern/learn.sh).
    learn_cmd save
    OUT+=("Ab jetzt sichere ich meinen Spielstand selbst – mit »save«.")
}
autosave_tick() {
    [ "${TH_SAVE_INTERVAL:-0}" -gt 0 ] || return 0
    local now; now="$(date +%s)"
    [ "$now" -ge "${TH_NEXT_AUTOSAVE:-0}" ] || return 0
    TH_NEXT_AUTOSAVE=$(( now + TH_SAVE_INTERVAL ))
    if th_save quick; then
        OUT+=("   [ Autosave: Quicksave aktualisiert – $(date '+%H:%M') ]")
    fi
}
