# ============================================================
#  TerminalHero - TUI starten / beenden
#
#  Alternativer Bildschirm an/aus, Cursor, sauberes Aufräumen - auch bei
#  Strg+C / TERM. TUI_ACTIVE lebt in kern/state.sh.
# ============================================================

tui_start() {
    printf '\033[?1049h'   # alternativer Bildschirm
    TUI_ACTIVE=1
    hide_cursor
}
tui_end() {
    [ "$TUI_ACTIVE" = "1" ] || return 0
    TUI_ACTIVE=0
    show_cursor
    printf '\033[?1049l'
    printf '%s' "$RESET"
}
shell_cleanup() {
    kill $(jobs -p) 2>/dev/null
    tui_end
    trap - EXIT INT TERM
}
on_signal() { shell_cleanup; exit 130; }
