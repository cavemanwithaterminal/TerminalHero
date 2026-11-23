# ============================================================
#  TerminalHero - Eingabe & Scrollen
#
#  Liest Bytes/Tasten (inkl. Escape-Sequenzen), sammelt Scroll-Tasten zu
#  einem "Schwung" (flüssiges Blättern), verwaltet Tab-Vervollständigung
#  und liest die Kommandozeile zeichenweise (damit Pfeiltasten scrollen
#  können). Der Zustand (CMD_BUFFER, SCROLL, ...) kommt aus kern/state.sh.
# ============================================================

read_byte_t() {
    if [ -n "$IN_BYTES" ]; then
        LAST_BYTE="${IN_BYTES:0:1}"
        IN_BYTES="${IN_BYTES:1}"
        return 0
    fi
    local rc
    if [ -z "$1" ]; then
        IFS= read -rsN1 LAST_BYTE
        rc=$?
    else
        IFS= read -rsN1 -t "$1" LAST_BYTE
        rc=$?
    fi
    [ "$rc" -eq 0 ] && return 0
    [ "$rc" -gt 128 ] && return 1      # Timeout
    return 2                            # EOF / geschlossen
}
read_key_t() {
    LAST_KEY=""
    LAST_KEY_RC=0
    if [ "${#KEYQ[@]}" -gt 0 ]; then
        LAST_KEY="${KEYQ[0]}"
        KEYQ=("${KEYQ[@]:1}")
        return 0
    fi
    local rc
    read_byte_t "$1"; rc=$?
    if [ "$rc" -ne 0 ]; then LAST_KEY_RC=$rc; return 1; fi
    local k="$LAST_BYTE" ext="" ch
    if [ "$k" = $'\x1b' ]; then
        while read_byte_t 0.03; do
            ch="$LAST_BYTE"
            ext+="$ch"
            case "$ch" in [A-Za-z]|'~') break ;; esac
        done
        k="$k$ext"
    fi
    LAST_KEY="$k"
    return 0
}
read_key2() { read_key_t ""; }
scroll_key_delta() {
    case "$1" in
        $'\x1b[A'|$'\x1bOA'|$'\x1b[5~') SCROLL_KEY_DELTA=1 ;;
        $'\x1b[B'|$'\x1bOB'|$'\x1b[6~') SCROLL_KEY_DELTA=-1 ;;
        $'\x1b[H'|$'\x1bOH')             SCROLL_KEY_DELTA=999999 ;;
        $'\x1b[F'|$'\x1bOF')             SCROLL_KEY_DELTA=-999999 ;;
        *)                               SCROLL_KEY_DELTA="" ;;
    esac
}
scroll_burst() {   # $1 = erstes Delta
    local delta="$1"
    while :; do
        # 1) alles sofort Verfügbare einsammeln (ohne zwischendurch zu zeichnen)
        while read_key_t 0.002; do
            scroll_key_delta "$LAST_KEY"
            if [ -n "$SCROLL_KEY_DELTA" ]; then
                delta=$(( delta + SCROLL_KEY_DELTA ))
            else
                KEYQ+=("$LAST_KEY"); break
            fi
        done
        SCROLL=$(( SCROLL + delta )); delta=0
        render
        # 2) kurz auf die nächste Taste warten - begrenzt die Bildrate,
        #    beendet den Schwung aber sofort nach dem Loslassen.
        read_key_t 0.06 || break
        scroll_key_delta "$LAST_KEY"
        if [ -n "$SCROLL_KEY_DELTA" ]; then
            delta="$SCROLL_KEY_DELTA"
        else
            KEYQ+=("$LAST_KEY"); break
        fi
    done
}
handle_scroll_key() {
    scroll_key_delta "$1"
    [ -n "$SCROLL_KEY_DELTA" ] || return 1
    scroll_burst "$SCROLL_KEY_DELTA"
    return 0
}
dialog_pause() {
    DIALOG_ACTIVE=1
    # Im Dialog wird NUR mit den Pfeiltasten geblättert - Bild↑/Bild↓
    # gehören dem ORDNER-Fenster (siehe read_command).
    DIALOG_HINT="   ↑/↓ blättern   ·   Enter weiter > "
    render
    while true; do
        read_key2 || return 0
        case "$LAST_KEY" in
            $'\x1b[A'|$'\x1bOA') SCROLL=$(( SCROLL + 1 )); render; continue ;;
            $'\x1b[B'|$'\x1bOB') SCROLL=$(( SCROLL - 1 )); render; continue ;;
            ''|$'\n'|$'\r'|' '|q|Q) return 0 ;;
        esac
    done
}
common_prefix() {
    local a="$1" b="$2" i=0
    while [ "$i" -lt "${#a}" ] && [ "$i" -lt "${#b}" ] && [ "${a:i:1}" = "${b:i:1}" ]; do
        i=$((i + 1))
    done
    printf '%s' "${a:0:i}"
}
show_candidates() {
    local basedir="$1"; shift
    local sig="$basedir|$*"
    [ "$sig" = "$COMP_SIG" ] && return 0
    COMP_SIG="$sig"

    local -a shown=() n
    while IFS= read -r n; do
        if [ "${TYPE["$basedir/$n"]:-}" = "d" ]; then shown+=("$n/"); else shown+=("$n"); fi
    done < <(printf '%s\n' "$@" | sort)

    OUT+=("")
    OUT+=("   ⟂ ${#shown[@]} Treffer: ${shown[*]}")
}
# Befehlsnamen vervollständigen (Tab, solange noch kein Leerzeichen in der
# Zeile steht): angeboten wird nur, was der Agent (wieder) KENNT - der Virus
# hat ihm den Rest genommen. Die Liste kommt aus dem Hilfe-Register
# (HELP_TERM/HELP_GAME + help_is_known, InGameBefehle/help.sh), damit sie
# nicht doppelt gepflegt werden muss.
complete_command() {   # $1 = bisher getippter Befehlsanfang
    local w="$1"
    [ -n "$w" ] || { COMP_SIG=""; return 0; }

    local -a cands=() id
    if [ "${TUT_STAGE:-0}" -ge 1 ] && [ "${TUT_STAGE:-0}" -le 4 ]; then
        # Im Tutorial ist genau ein Befehl dran (tut_expected).
        id="$(tut_expected)"
        [ -n "$id" ] && case "$id" in "$w"*) cands=("$id") ;; esac
    else
        for id in "${HELP_TERM[@]}" "${HELP_GAME[@]}"; do
            help_is_known "$id" || continue
            case "$id" in "$w"*) cands+=("$id") ;; esac
        done
    fi

    case "${#cands[@]}" in
        0) COMP_SIG="" ;;
        1) CMD_BUFFER="${cands[0]} "; COMP_SIG="" ;;
        *)
            # Bis zum gemeinsamen Anfang ergänzen (wie im echten Terminal) ...
            local common="${cands[0]}" e
            for e in "${cands[@]:1}"; do
                common="$(common_prefix "$common" "$e")"
                [ -z "$common" ] && break
            done
            [ "${#common}" -gt "${#w}" ] && CMD_BUFFER="$common"
            # ... und die Möglichkeiten einmalig auflisten.
            local sig="cmd|$w"
            [ "$sig" = "$COMP_SIG" ] && return 0
            COMP_SIG="$sig"
            OUT+=("")
            OUT+=("   ⟂ ${#cands[@]} Befehle: ${cands[*]}") ;;
    esac
    return 0
}
complete_path() {
    local L="$CMD_BUFFER"

    # Ohne Leerzeichen ist das der Befehl selbst -> Befehlsnamen ergänzen.
    [[ "$L" == *" "* ]] || { complete_command "$L"; return 0; }

    local partial prefix
    partial="${L##* }"
    prefix="${L%"$partial"}"

    # In Ordneranteil + Namensanfang zerlegen
    local dirpart name
    if [[ "$partial" == */* ]]; then
        dirpart="${partial%/*}/"
        name="${partial##*/}"
    else
        dirpart=""
        name="$partial"
    fi

    # Basisordner auflösen (~, absolut, relativ)
    local basedir
    case "$dirpart" in
        "~/"*) basedir="$HOME_DIR/${dirpart:2}" ;;
        "~")   basedir="$HOME_DIR" ;;
        /*)    basedir="$dirpart" ;;
        *)     basedir="$CWD/$dirpart" ;;
    esac
    basedir="$(normalize_path "$basedir" "$CWD")"

    # In gesperrten Zonen gibt es keine Vorschläge.
    if outside_home "$basedir"; then
        COMP_SIG=""
        return 0
    fi

    district_ensure "$basedir"     # Stadtteil bei Bedarf laden (Inhalte fürs Vervollständigen)
    [ "${TYPE[$basedir]:-}" = "d" ] || { COMP_SIG=""; return 0; }

    # Kandidaten sammeln (versteckte nur bei ausdrücklichem ».«-Beginn)
    local -a cands=()
    local e
    while IFS= read -r e; do
        [ -n "$e" ] || continue
        if [ -n "$name" ] && [[ "$e" != "$name"* ]]; then continue; fi
        if [ "${name:0:1}" != "." ] && [[ "$e" == .* ]]; then continue; fi
        cands+=("$e")
    done <<< "${CHILDREN[$basedir]}"

    case "${#cands[@]}" in
        0) COMP_SIG="" ;;
        1)
            local repl="${dirpart}${cands[0]}"
            [ "${TYPE["$basedir/${cands[0]}"]}" = "d" ] && repl+="/"
            CMD_BUFFER="${prefix}${repl}"
            COMP_SIG="" ;;
        *)
            # Bis zum gemeinsamen Anfang ergänzen (wie im echten Terminal) ...
            local common="${cands[0]}"
            for e in "${cands[@]:1}"; do
                common="$(common_prefix "$common" "$e")"
                [ -z "$common" ] && break
            done
            if [ "${#common}" -gt "${#name}" ]; then
                CMD_BUFFER="${prefix}${dirpart}${common}"
            fi
            # ... und die Möglichkeiten auflisten.
            show_candidates "$basedir" "${cands[@]}" ;;
    esac
    return 0
}
read_command() {
    CMD_BUFFER=""
    COMP_SIG=""
    draw_prompt
    while true; do
        if ! read_key_t 1; then
            [ "$LAST_KEY_RC" = "2" ] && { CMD_BUFFER=""; return 1; }   # EOF
            # Leerlauf: fällige Token-Regeneration und Spielzeit einsammeln.
            local dirty=1
            tokens_tick && dirty=0
            uhrzeit_tick && dirty=0
            nek_funeral_tick && dirty=0
            fackel_tick && dirty=0
            declare -F gegner_tick >/dev/null 2>&1 && { gegner_tick && dirty=0; }
            [ "$dirty" = "0" ] && render
            continue
        fi
        # Bild↑/Bild↓ scrollen das ORDNER-Fenster, wenn es Inhalt zeigt;
        # sonst wie bisher die Ausgabe. Pfeiltasten bleiben bei der Ausgabe.
        case "$LAST_KEY" in
            $'\x1b[5~') folder_scroll_page -1 && continue ;;
            $'\x1b[6~') folder_scroll_page  1 && continue ;;
        esac
        handle_scroll_key "$LAST_KEY" && continue
        case "$LAST_KEY" in
            $'\x7f'|$'\b') [ -n "$CMD_BUFFER" ] && { CMD_BUFFER="${CMD_BUFFER%?}"; COMP_SIG=""; draw_prompt; } ;;
            $'\t')         complete_path; render ;;
            $'\n'|$'\r')   return 0 ;;
            $'\x1b'*)      : ;;
            $'\x04')       [ -z "$CMD_BUFFER" ] && return 1 ;;
            *)             CMD_BUFFER+="$LAST_KEY"; COMP_SIG=""; draw_prompt ;;
        esac
    done
}
