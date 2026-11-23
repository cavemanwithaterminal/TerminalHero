# ============================================================
#  TerminalHero - Terminal-Befehl: pwd
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#  Aktuellen Pfad ausgeben und das PFAD-Fenster erwachen lassen.
# ============================================================

builtin_pwd() {
    SHOW_PATH=1
    OUT+=("$CWD")
}
