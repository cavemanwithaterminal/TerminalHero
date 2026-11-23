# ============================================================
#  TerminalHero - Terminal-Befehl: cd
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#  Verzeichnis wechseln. »cd ..«, »cd -« und nacktes »cd« (später erlernt).
# ============================================================

builtin_cd() {
    local target
    if [ -z "$1" ]; then
        # Nacktes "cd" (Rückweg nach /home) muss erst im Spielverlauf erlernt werden.
        if [ "$CD_BARE_KNOWN" != "1" ]; then
            play_sound error
            OUT+=("cd: Wohin? Ich erinnere mich nur an »cd ..« und »cd <verzeichnis>«.")
            return
        fi
        target="$HOME_DIR"
    else
        target="$1"
    fi

    case "$target" in
        "~")   target="$HOME_DIR" ;;
        "~/")  target="$HOME_DIR" ;;
        "~/"*) target="$HOME_DIR/${target:2}" ;;
        "-")   target="$OLDPWD" ;;
    esac
    local np dpath in_city=0
    np="$(normalize_path "$target" "$CWD")"
    # Direkt in einen anderen Stadtteil: »cd Ostdistrikt« funktioniert nur
    # INNERHALB der Stadt (Haupteingang und seine Stadtteile). Von außen -
    # etwa vom Friedhof - bleibt das Wort ein normaler relativer Pfad und
    # läuft ins Leere. Nur wenn der relative Pfad so nicht existiert, wird
    # das Wort als Stadtteil gelesen; ein echter Ordner gleichen Namens vor
    # Ort hat Vorrang. Auch Unterpfade gehen:
    # »cd Ostdistrikt/DetekteiHolmes«.
    case "$CWD" in
        "$(district_base)"|"$(district_base)"/*) in_city=1 ;;
    esac
    if [ -z "${TYPE[$np]:-}" ] && [[ "$target" != /* ]] && [[ "$target" != "~"* ]]; then
        dpath="$(district_path_by_name "${target%%/*}")"
        if [ -n "$dpath" ]; then
            if [ "$in_city" = "1" ]; then
                if [ "$target" = "${target%%/*}" ]; then
                    np="$dpath"
                else
                    np="$(normalize_path "$dpath/${target#*/}" "$CWD")"
                fi
            else
                play_sound error
                OUT+=("cd: $target: Von außerhalb der Stadt kann ich nicht direkt in einen Stadtteil wechseln.")
                return
            fi
        fi
    fi
    district_ensure "$np"          # Stadtteil bei Bedarf laden (Welt verfügbar machen)
    if [ -z "${TYPE[$np]}" ]; then
        play_sound error
        OUT+=("cd: $target: Datei oder Verzeichnis nicht gefunden")
        return
    fi
    if [ "${TYPE[$np]}" != "d" ]; then
        play_sound error
        OUT+=("cd: $target: Kein Verzeichnis")
        return
    fi
    # Den Agenten-Ordner erst verlassen, nachdem mit dem General (README) gesprochen wurde.
    if [ "$README_DONE" != "1" ] && [ "$np" != "$AGENT_DIR" ] && [[ "$np" != "$AGENT_DIR/"* ]]; then
        play_sound error
        OUT+=("Ich kann den Agenten-Ordner noch nicht verlassen.")
        OUT+=("Erst muss ich mit dem General sprechen – »touch README«.")
        return
    fi
    # Aus dem Agenten-Ordner führt nach dem Tutorial nur »cd ..« in den
    # Downloads-Ordner. Direkte Sprünge in Geschwisterordner (z. B.
    # »cd ../DetektivConan«) würden den ersten Downloads-Besuch und damit
    # »achievements« sowie den Kompass umgehen.
    if [ "$README_DONE" = "1" ] && [ "$CWD" = "$AGENT_DIR" ] \
       && [ "$np" != "$AGENT_DIR" ] && [[ "$np" != "$AGENT_DIR/"* ]] \
       && [ "$np" != "$HOME_DIR/Downloads" ]; then
        play_sound error
        OUT+=("Aus dem Agenten-Ordner führt nur »cd ..« in den Downloads-Ordner.")
        return
    fi
    # Bevor Pixi getroffen wurde, darf man den Downloads-Bereich nur in
    # Richtung ~ selbst verlassen. So lässt sich die erste Begegnung nicht
    # über einen direkten Sprung (z. B. »cd ~/Schreibtisch«) umgehen.
    if [ "${TUT_DONE:-0}" = "1" ] && [ "${HOME_FIRST_VISIT:-0}" != "1" ]; then
        case "$CWD" in
            "$HOME_DIR/Downloads"|"$HOME_DIR/Downloads/"*)
                case "$np" in
                    "$HOME_DIR"|"$HOME_DIR/Downloads"|"$HOME_DIR/Downloads/"*) ;;
                    "$HOME_DIR/"*)
                        play_sound error
                        OUT+=("Bevor ich hier verschwinde, muss ich Pixi treffen – »cd ..« führt mich zu ihr.")
                        return ;;
                esac ;;
        esac
    fi
    # Nach dem Pixi-Treffen ist der Weg nach draußen (über ~/ hinaus) versiegelt.
    zone_denied cd "$target" "$np" && return
    OLDPWD="$CWD"
    if [ "$np" != "$CWD" ]; then
        # Frisch betretenen Ordner erst wieder mit pwd/ls erkunden.
        SHOW_PATH=0
        SHOW_LS=0
    fi
    CWD="$np"
    VIEW_DIR="$np"
    # Eine gezogene Leiche folgt in den neuen Ordner (Charakter/NeksLeiche.sh).
    declare -F neks_leiche_follow_cwd >/dev/null 2>&1 && neks_leiche_follow_cwd
    play_sound cmd_cd
    # Errungenschaften können an einem erfolgreichen Ordnerwechsel hängen.
    if [ "$np" != "$OLDPWD" ] && declare -F achievements_on_dir_change >/dev/null 2>&1; then
        achievements_on_dir_change "$OLDPWD" "$np"
    fi
}
