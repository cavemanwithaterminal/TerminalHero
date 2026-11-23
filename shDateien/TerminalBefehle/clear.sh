# ============================================================
#  TerminalHero - Terminal-Befehl: clear
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#  Bildschirm leeren. Zu Spielbeginn gesperrt (Amnesie) -
#  wird erst wieder erlernt.
# ============================================================

builtin_clear() {
    if ! knows clear; then
        play_sound error
        OUT+=("»clear« …? Nein. Auch diesen Befehl hat der Virus mir genommen. Noch.")
        return
    fi
    OUT=(); WRAP_KEY=""
}
