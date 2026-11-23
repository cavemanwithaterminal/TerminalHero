# ============================================================
#  TerminalHero - Terminal-Befehl: cal
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#
#  »cal« zeigt den In-Game-Kalender. Das Datum erscheint für
#  24 Spielstunden mittig auf der oberen Linie des PFAD-Fensters
#  und verschwindet danach wieder. Ein erneutes »cal« blendet es
#  wieder ein (und erneuert die 24 Stunden).
#
#  Zu Spielbeginn GESPERRT (Amnesie): Der Virus hat den Befehl
#  mitgenommen. Einen Lehrer gibt es noch nicht (später).
#
#  Kosten: 50 Tokens, 10 EXP (kern/tokens.sh). Nur wer den Befehl
#  kennt, bezahlt - vor dem Erlernen bleibt die Virus-Absage kostenlos.
# ============================================================

builtin_cal() {
    if ! knows cal; then
        play_sound error
        OUT+=("»cal« …? Diesen Befehl kenne ich nicht mehr.")
        OUT+=("Der Virus hat ihn mir genommen – wie so vieles. Noch.")
        return
    fi

    cal_reveal
    play_sound select
    OUT+=("")
    OUT+=("Kalender: $(cal_date_text)")
    OUT+=("Das Datum bleibt ${CAL_VISIBLE_HOURS} Spielstunden oben im PFAD-Fenster sichtbar.")
}
