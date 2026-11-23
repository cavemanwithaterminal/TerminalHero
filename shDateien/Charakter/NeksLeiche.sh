# ============================================================
#  TerminalHero - Charakter: Neks Leiche
# ------------------------------------------------------------
#  Nek Molerat ist die Stadtwache, nach der Simon Guard und Simple Jon
#  suchen. Er ist nicht zurückgekommen: In der Molerathöhle liegt seine
#  Leiche. Die Datei ist keine gewöhnliche Datei, sondern eine beseelte
#  Figur - »touch« beginnt ein kurzes, stilles Gespräch, »cat« liest
#  den Befund, »file« zeigt die Metadaten.
#
#  Die Leiche ist dynamisch: Sie liegt zunächst in der Molerathöhle und
#  wird mit »grep NeksLeiche« hinter dem Agenten hergezogen. Solange sie
#  gezogen wird, wandert ihr TYPE-Eintrag bei jedem Ortswechsel in den
#  aktuellen Ordner; »ls« zeigt dann das zusätzliche Symbol »↳« neben
#  dem Namen (kern/ui.sh). Ein zweites »grep« legt sie im aktuellen
#  Ordner ab.
#
#  Durchsuchen: Wer »search« gelernt hat, kann die Leiche mit
#  »search NeksLeiche« durchsuchen und findet 30 Bits sowie ihr Amulett
#  (Items/Schmuck/NeksAmulett.sh). Der Such-Haken steht im Register
#  kern/search.sh.
#
#  Gespeichert werden NEKS_LEICHE_PATH (aktueller Ort),
#  DRAGGED_CORPSE (Pfad, solange sie gezogen wird),
#  NEKS_LEICHE_SEARCHED (Loot schon gefunden) und NEK_FOUND (Questlog).
# ============================================================

# Fester Ausgangsort: die Molerathöhle auf dem Schreibtisch.
neks_leiche_cave_dir() {
    printf '%s/Schreibtisch/Höhleneingang/Molerathöhle' "$HOME_DIR"
}
neks_leiche_default_path() {
    printf '%s/NeksLeiche' "$(neks_leiche_cave_dir)"
}

# Wo liegt die Leiche gerade? Zuerst der gespeicherte/aktuelle Pfad, sonst
# wird der dynamische FS-Eintrag gesucht. Rückgabe 1 = nirgends gefunden.
neks_leiche_path_of() {
    local p
    p="${NEKS_LEICHE_PATH:-}"
    if [ -n "$p" ] && [ -n "${TYPE[$p]:-}" ]; then
        printf '%s' "$p"
        return 0
    fi
    for p in "${!TYPE[@]}"; do
        [ "${p##*/}" = "NeksLeiche" ] || continue
        printf '%s' "$p"
        return 0
    done
    return 1
}

# Liegt die Leiche gerade im aktuellen Ordner? (Für Simon Guard: bringt
# der Agent die Leiche zum Tor, beginnt dort automatisch das Fundgespräch.)
neks_leiche_here() {
    local p
    p="$(neks_leiche_path_of)" || return 1
    [ "${p%/*}" = "${CWD:-}" ]
}

# Questlog: Nek wurde gefunden. Der Hinweis erscheint genau einmal; die
# Quest selbst kann zu diesem Zeitpunkt noch verborgen sein.
neks_leiche_mark_found() {
    [ "${NEK_FOUND:-0}" = "1" ] && return 0
    NEK_FOUND=1
    if [ "${NEK_GIVEN:-0}" = "1" ] && declare -F quest_note >/dev/null 2>&1; then
        quest_note "Hab Nek gefunden. Lag tot in einer Höhle"
    fi
    return 0
}

# Inhalt für »cat«. Der Text bleibt unabhängig vom Ort gleich.
neks_leiche_file_text() {
    printf '%s\n' \
        "[DATEI]  Neks Leiche   ::   Molerathöhle, vor den Toren der Stadt" \
        "Nek Molerat. Stadtwache. Simon Guards Freund." \
        "──────────────────────────────────────────────" \
        "Zustand : leblos. Keine Bewegung, kein Takt, keine Antwort." \
        "Fundort : tief in der Molerathöhle, hinter dem Höhleneingang." \
        "" \
        "Die Uniform ist zerrissen. Am Hals hängt eine dünne Kette –" \
        "das Amulett daran ist unter dem Stoff verschwunden." \
        "" \
        "cat NeksLeiche  →  den Befund lesen" \
        "touch NeksLeiche  →  ihn ansprechen"
}

# Die Leiche an einem Pfad einsetzen bzw. Inhalt, Dialog und Such-Haken
# auffrischen. fs_add ist idempotent; die Register werden immer gesetzt.
neks_leiche_place() {   # <pfad>
    local p="$1"
    [ -n "$p" ] || return 1
    declare -F search_define >/dev/null 2>&1 || th_source_if_fn search_define
    fs_add f "$p"
    CONTENT["$p"]="$(neks_leiche_file_text)"
    DIALOG["$p"]="dialog_neks_leiche"
    search_define "$p" neks_leiche_search
    NEKS_LEICHE_PATH="$p"
    return 0
}

# Leiche in einen Ordner verschieben. Der alte Inhalt/Dialog/Such-Haken
# wird entfernt, im Zielordner neu aufgebaut. Rückgabe 1 = Ziel belegt.
neks_leiche_move_to_dir() {   # <zielordner>
    local dest="$1" src target
    [ -n "$dest" ] || return 1
    [ "${TYPE[$dest]:-}" = "d" ] || return 1
    src="$(neks_leiche_path_of)" || return 1
    target="$dest/NeksLeiche"
    [ "$src" = "$target" ] && { NEKS_LEICHE_PATH="$src"; return 0; }
    [ -n "${TYPE[$target]:-}" ] && return 1

    fs_remove "$src"
    unset "CONTENT[$src]" "DIALOG[$src]"
    search_forget "$src"
    neks_leiche_place "$target"
    return 0
}

# Simon hat die Leiche übernommen: endgültig aus der Welt nehmen. Danach
# gibt es kein Ziel mehr zum Ziehen; der Zustand NEK_CORPSE_BROUGHT hält
# fest, dass sie beim Torwächter angekommen ist.
neks_leiche_remove() {
    local p
    for p in "${!TYPE[@]}"; do
        [ "${p##*/}" = "NeksLeiche" ] || continue
        fs_remove "$p"
        unset "CONTENT[$p]" "DIALOG[$p]" 2>/dev/null
        declare -F search_forget >/dev/null 2>&1 && search_forget "$p"
    done
    NEKS_LEICHE_PATH=""
    DRAGGED_CORPSE=""
    return 0
}

# Nach einem erfolgreichen Ortswechsel: Die gezogene Leiche folgt in den
# neuen Ordner. Ist dort kein Platz, bleibt sie zurück.
neks_leiche_follow_cwd() {
    [ -n "${DRAGGED_CORPSE:-}" ] || return 0
    [ "${TYPE[$CWD]:-}" = "d" ] || return 0
    [ "$NEKS_LEICHE_PATH" = "$CWD/NeksLeiche" ] && return 0
    if ! neks_leiche_move_to_dir "$CWD"; then
        DRAGGED_CORPSE=""
        play_sound error
        OUT+=("Die Leiche passt hier nicht hin – ich muss sie zurücklassen.")
        return 0
    fi
    DRAGGED_CORPSE="$NEKS_LEICHE_PATH"
    return 0
}

# Beim Start/Laden: Leiche an ihrem gespeicherten Ort aufbauen. Ältere
# Stände ohne Pfad bekommen sie in die Molerathöhle. Wird eine gezogene
# Leiche geladen, steht sie beim Agenten im aktuellen Ordner.
neks_leiche_apply_state() {
    local p parent
    # Nach der Übergabe an Simon darf die Leiche beim Laden nicht wieder
    # in der Höhle (oder am Tor) auftauchen.
    if [ "${NEK_CORPSE_BROUGHT:-0}" = "1" ]; then
        neks_leiche_remove
        return 0
    fi
    if p="$(neks_leiche_path_of)"; then
        parent="${p%/*}"; [ -z "$parent" ] && parent="/"
        [ -n "${TYPE[$parent]:-}" ] || p="$(neks_leiche_default_path)"
    else
        p="$(neks_leiche_default_path)"
    fi
    neks_leiche_place "$p"

    if [ -n "${DRAGGED_CORPSE:-}" ]; then
        if [ "${TYPE[$CWD]:-}" = "d" ] \
           && [ "$NEKS_LEICHE_PATH" != "$CWD/NeksLeiche" ]; then
            neks_leiche_move_to_dir "$CWD" || true
        fi
        [ "$NEKS_LEICHE_PATH" = "$CWD/NeksLeiche" ] || DRAGGED_CORPSE=""
    fi
    return 0
}

# Ist das grep-Ziel die Leiche? Wird von grep und der Token-Wirtschaft
# benutzt. Ein zweites Argument (Textsuche in einer Datei) fällt nicht
# hierher, weil dann der ganze Ausdruck kein Pfad zur Leiche ist.
neks_leiche_is_corpse_target() {
    local arg="${1:-}" np
    [ -n "$arg" ] || return 1
    np="$(resolve_path "$arg" "$CWD")"
    [ "${np##*/}" = "NeksLeiche" ] || return 1
    [ -n "${TYPE[$np]:-}" ] || return 1
    return 0
}

# »grep NeksLeiche«: Ziehen oder ablegen. Rückgabe 0 = behandelt.
neks_leiche_grep() {   # <pfad>
    local np="$1"
    neks_leiche_mark_found
    if [ -n "${DRAGGED_CORPSE:-}" ] && [ "$DRAGGED_CORPSE" = "$np" ]; then
        DRAGGED_CORPSE=""
        play_sound select
        OUT+=("")
        OUT+=("Du hast eine Leiche abgelegt.")
        OUT+=("Neks Leiche bleibt hier liegen.")
        return 0
    fi
    if [ -n "${DRAGGED_CORPSE:-}" ]; then
        play_sound error
        OUT+=("Ich ziehe bereits eine Leiche hinter mir her.")
        OUT+=("Erst ablegen – mit »grep ${DRAGGED_CORPSE##*/}«.")
        return 0
    fi
    if [ "${TYPE[$CWD]:-}" != "d" ]; then
        play_sound error
        OUT+=("Hier kann ich die Leiche nicht ziehen.")
        return 0
    fi
    if [ "$np" != "$CWD/NeksLeiche" ] && ! neks_leiche_move_to_dir "$CWD"; then
        play_sound error
        OUT+=("Hier ist kein Platz für die Leiche.")
        return 0
    fi
    DRAGGED_CORPSE="$NEKS_LEICHE_PATH"
    play_sound select
    OUT+=("")
    OUT+=("Du ziehst jetzt eine Leiche hinter dir her.")
    OUT+=("Neks Leiche folgt dir ab jetzt in jeden Ordner.")
    return 0
}

# »search NeksLeiche«: Loot freilegen und einsammeln.
neks_leiche_search() {   # <pfad>
    OUT+=("")
    OUT+=("Du durchsuchst Neks Leiche.")
    neks_leiche_mark_found
    if [ "${NEKS_LEICHE_SEARCHED:-0}" = "1" ] || inv_has neksamulett; then
        NEKS_LEICHE_SEARCHED=1
        play_sound error
        OUT+=("Die Taschen sind leer. Das Amulett habe ich bereits.")
        return 0
    fi

    if inv_add neksamulett; then
        NEKS_LEICHE_SEARCHED=1
        bits_add 30
        play_sound select
        OUT+=("Unter dem Stoff findest du eine dünne Kette mit einem kalten,")
        OUT+=("dunklen Stein: Neks Amulett. Du nimmst es an dich.")
        OUT+=("In einer Innentasche stecken außerdem 30 Bits.")
        OUT+=("   [ Bits ]  +30   (Stand: $(bits_text "$(bits_count)"))")
    else
        NEKS_LEICHE_SEARCHED=0
        play_sound error
        OUT+=("Etwas stimmt nicht – das Amulett lässt sich nicht aufnehmen.")
    fi
    return 0
}

# --- Gespräch (»touch NeksLeiche«) --------------------------------------
dialog_neks_leiche() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    neks_leiche_mark_found
    OUT+=("═════ MOLERATHÖHLE · NEKS LEICHE ═════")
    OUT+=("Fund : Nek Molerat    Zustand : leblos")
    OUT+=("")
    render

    say "-" "Hinter dem letzten Felsen liegt eine Gestalt. Die Uniform der Stadtwache ist zerrissen, die Hände liegen still im Geröll."
    say "$AGENT_NAME" "Ah. Ich glaube der sagt nichts mehr."
    say "-" "Du wartest einen Atemzug. Dann noch einen. Die Höhle bleibt stumm."
    say "$AGENT_NAME" "Nek Molerat. Simon Guard sucht dich."

    if [ "${NEKS_LEICHE_SEARCHED:-0}" = "1" ]; then
        say "-" "Das Amulett hast du bereits an dich genommen. Die Leiche ist nur noch Gewicht und eine Nachricht."
    elif declare -F knows >/dev/null 2>&1 && knows search; then
        say "-" "Vielleicht trägt er noch etwas bei sich. Durchsuchen könnte helfen – mit »search NeksLeiche«."
    else
        say "-" "Vielleicht trägt er noch etwas bei sich. Wenn ich nur wüsste, wie man eine Leiche durchsucht."
    fi

    if [ -n "${DRAGGED_CORPSE:-}" ] && [ "$DRAGGED_CORPSE" = "$NEKS_LEICHE_PATH" ]; then
        say "-" "Du hast seine Leiche bereits am Gürtel; ein zweites »grep NeksLeiche« legt sie wieder ab."
    else
        say "-" "Mit »grep NeksLeiche« könnte ich ihn hinter mir herziehen. Vielleicht sollte Simon ihn sehen."
    fi

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
