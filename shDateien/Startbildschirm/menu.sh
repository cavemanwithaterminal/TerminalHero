. "$SCRIPT_DIR/Startbildschirm/optionsmenu.sh" 2>/dev/null || true
# ============================================================
#  TerminalHero - Startbildschirm: Ablauf
#
#  init_screen (Boot-Sequenz), launch_shell (startet die In-Game-Shell
#  als eigenen Prozess) und main (die Menü-Schleife).
# ============================================================

launch_shell() {   # $1 = "" (neues Spiel) | quick | manual (Spielstand laden)
    local shell="$SCRIPT_DIR/TerminalShell.sh" load="${1:-}"
    if [ ! -f "$shell" ]; then
        printf '\n  %sTerminalShell.sh wurde nicht gefunden.%s\n' "$RED" "$RESET"
        sleep 2
        return 1
    fi
    TERMINALHERO_LOAD="$load" \
    TERMINALHERO_USER="$USERNAME" \
    TERMINALHERO_HOST="$HOSTNAME_" \
    TERMINALHERO_AGENT="$AGENT" \
    TERMINALHERO_START="Downloads" \
    TERMINALHERO_SOUND="$SOUND_ENABLED" \
    TERMINALHERO_CHAPTER1_SEEN="${TERMINALHERO_CHAPTER1_SEEN:-}" \
        bash "$shell"
}
main() {
    ensure_sounds
    hide_cursor
    # Tastaturecho aus: sonst blitzt jede Taste zwischen zwei read -s als
    # Zeichen auf dem Bildschirm auf (z. B. das Leerzeichen zum Überspringen
    # des Prologs). Für die Setup-Eingaben wird es kurz wieder aktiviert.
    stty -echo 2>/dev/null || true
    trap 'stty echo 2>/dev/null; printf "\033[0m"; show_cursor; clear; exit' INT TERM EXIT
    draw_screen

    while true; do
        read_key
        local key="$LAST_KEY"
        case "$key" in
            $'\x1b[A'|$'\x1bOA')
                ((SELECTED--))
                [ "$SELECTED" -lt 0 ] && SELECTED=$((${#OPTIONS[@]} - 1))
                play_sound move
                draw_screen ;;
            $'\x1b[B'|$'\x1bOB')
                ((SELECTED++))
                [ "$SELECTED" -ge ${#OPTIONS[@]} ] && SELECTED=0
                play_sound move
                draw_screen ;;
            $'\n'|$'\r')
                case "$SELECTED" in
                    0)  # --- Spiel starten ---------------------------------
                        play_sound select
                        stty -echo 2>/dev/null || true
                        run_intro
                        # Kapitel 1 direkt nach dem Introtext anzeigen (7 Sekunden).
                        # (Startbildschirm-Kontext: Archiv-Modul bei Bedarf laden.)
                        . "$SCRIPT_DIR/InGameBefehle/archive.sh" 2>/dev/null || true
                        if declare -F archive_show_chapter_timed >/dev/null 2>&1; then
                            archive_show_chapter_timed 1
                            # Bild danach vollständig entfernen (kein Rest im Hintergrund).
                            printf '%s' "$UI_BG"
                            clear
                        elif declare -F archive_draw_kapitel1 >/dev/null 2>&1; then
                            play_sound online 2>/dev/null || true
                            archive_draw_kapitel1
                            sleep 7
                            printf '%s' "$UI_BG"
                            clear
                        fi
                        export TERMINALHERO_CHAPTER1_SEEN=1
                        stty echo 2>/dev/null || true
                        if run_setup; then
                            stty -echo 2>/dev/null || true
                            init_screen "◤ SYS://${AGENT} ◢" "Agent ${AGENT} wird initialisiert ..."
                            launch_shell ""
                        fi
                        stty -echo 2>/dev/null || true
                        show_cursor
                        hide_cursor
                        draw_screen ;;
                    1)  # --- Spiel laden (Untermenü) -----------------------
                        play_sound select
                        stty -echo 2>/dev/null || true
                        load_menu
                        local lc="$LOAD_CHOICE"
                        case "$lc" in
                            quick|manual|manual1|manual2|manual3)
                                if [ "$lc" = "quick" ]; then
                                    init_screen "◤ SYS://RESTORE ◢" "Quicksave wird geladen ..."
                                else
                                    init_screen "◤ SYS://RESTORE ◢" "Spielstand wird geladen ..."
                                fi
                                launch_shell "$lc"
                                ;;
                        esac
                        stty -echo 2>/dev/null || true
                        show_cursor
                        hide_cursor
                        draw_screen ;;
                    2)  # --- Optionen ---------------
                        play_sound select
                        stty -echo 2>/dev/null || true
                        options_menu
                        stty -echo 2>/dev/null || true
                        show_cursor
                        hide_cursor
                        draw_screen ;;
                    3)  # --- Beenden ---------------------------------------
                        printf '\033[0m'; show_cursor; clear; exit 0 ;;
                esac ;;
            'q'|'Q')
                printf '\033[0m'; show_cursor; clear; exit 0 ;;
        esac
    done
}
