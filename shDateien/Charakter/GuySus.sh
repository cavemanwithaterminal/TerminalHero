# ============================================================
#  TerminalHero - Charakter: Guy Sus
# ------------------------------------------------------------
#  Guy Sus wartet im Höhleneingang. Er weiß, was in der
#  Molerathöhle lauert: drei Molerats und eine Leiche mit einem
#  glänzenden Amulett. Wer den Höhleneingang zum ersten Mal
#  betritt, wird automatisch von ihm angesprochen.
#
#  Er bietet »Plündern lernen« an: 2 Skillpunkte + 25 Bits,
#  dafür wird der Befehl »search« gelernt. Vor dem Lernen nennt
#  er den Preis und fragt noch einmal nach. Danach endet das
#  Gespräch sofort.
#
#  Zwei spätere Szenen:
#    - Alle Molerats gelöscht -> Guy kommt in die Höhle.
#    - Leiche in den Höhleneingang gezogen -> Guy wartet draußen.
#  In beiden fragt er, ob die Leiche durchsucht wurde. Nach dem
#  Abschied verschwindet seine Datei (GUY_SUS_GONE=1).
#
#  Persistenz: GUY_SUS_MET, GUY_SUS_GONE, GUY_SUS_CAVE_DONE,
#  GUY_SUS_OUTSIDE_DONE (State/Save/Migration). Die Datei selbst
#  wird dynamisch über guy_sus_apply_state aufgebaut.
# ============================================================

guy_sus_dir() {
    printf '%s/Schreibtisch/Höhleneingang' "$HOME_DIR"
}

guy_sus_path() {
    printf '%s/GuySus' "$(guy_sus_dir)"
}

guy_sus_file_text() {
    printf '%s\n' \
        "[DATEI]  Guy Sus   ::   Höhleneingang" \
        "Ein Informant mit nervösen Fingern und wachen Augen." \
        "──────────────────────────────────────────────" \
        "Status : wartet auf jemanden, der zuhört" \
        "Weiß   : etwas über die Molerats und die Leiche" \
        "" \
        "»Hey. Pssst. Vorsicht.«" \
        "" \
        "cat GuySus    →  seine Notizen lesen" \
        "touch GuySus  →  ihn ansprechen"
}

guy_sus_place() {   # <pfad>
    local p="$1"
    [ -n "$p" ] || return 1
    fs_add f "$p"
    CONTENT["$p"]="$(guy_sus_file_text)"
    DIALOG["$p"]="dialog_guy_sus"
    return 0
}

# Guy verschwindet: Datei, Inhalt und Dialog entfernen.
guy_sus_gone() {
    local p
    GUY_SUS_MET=1
    GUY_SUS_GONE=1
    p="$(guy_sus_path)"
    fs_remove "$p"
    unset "CONTENT[$p]" "DIALOG[$p]" 2>/dev/null
    return 0
}

# Beim Start/Laden: Guy steht im Höhleneingang, solange er nicht
# verschwunden ist.
guy_sus_apply_state() {
    if [ "${GUY_SUS_GONE:-0}" = "1" ]; then
        GUY_SUS_MET=1
        guy_sus_gone
        return 0
    fi
    guy_sus_place "$(guy_sus_path)"
    return 0
}

guy_sus_searched() {
    [ "${NEKS_LEICHE_SEARCHED:-0}" = "1" ] && return 0
    declare -F inv_has >/dev/null 2>&1 && inv_has neksamulett
}

# --- Lernen: search -------------------------------------------------
# Rückgabe 0 = gelernt bzw. bereits bekannt; 1 = zu wenig Punkte/Bits.
guy_sus_teach_search() {
    if declare -F knows >/dev/null 2>&1 && knows search; then
        say "Guy Sus" "Du weißt doch längst, wie man Leichen plündert."
        return 0
    fi

    if [ "${SKILL_POINTS:-0}" -lt 2 ] || [ "$(bits_count)" -lt 25 ]; then
        play_sound error
        say "Guy Sus" "So wird das nichts. Du brauchst 2 Skillpunkte und 25 Bits."
        say "Guy Sus" "Komm wieder, wenn du beides hast."
        return 1
    fi

    SKILL_POINTS=$(( SKILL_POINTS - 2 ))
    bits_take 25
    learn_cmd search
    say "Guy Sus" "Dann pass auf: Nicht mit den Händen. Mit dem Kopf. Der Befehl heißt »search«."
    say "Guy Sus" "Damit kannst du Leichen durchsuchen. Und jetzt nichts wie rein – aber vorsichtig."
    return 0
}

# Das Lernmenü. Bei »Später« oder zu wenig Guthaben bleibt das
# Gespräch stehen, bis der Spieler Enter drückt; nach dem Lernen
# endet es direkt (so gewünscht).
guy_sus_offer_search() {
    if declare -F knows >/dev/null 2>&1 && knows search; then
        say "Guy Sus" "Du weißt ja schon, wie man Leichen plündert. Dann nichts wie rein."
        return 0
    fi
    OUT+=("")
    ask "Plündern lernen" "Später."
    case "${CHOICE:-0}" in
        1)
            OUT+=("")
            say "Guy Sus" "Das kostet 2 Skillpunkte und 25 Bits."
            say "Guy Sus" "Willst du es wirklich lernen?"
            ask "Ja, bring es mir bei." "Nein, danke."
            if [ "${CHOICE:-0}" = "1" ]; then
                if ! guy_sus_teach_search; then
                    dialog_pause
                fi
            else
                say "Guy Sus" "Dann eben nicht. Ohne »search« bleibt die Leiche, wie sie ist."
            fi ;;
        *)
            say "Guy Sus" "Dann pass auf dich auf. Die Höhle ist kein Spielplatz." ;;
    esac
    return 0
}

# --- Erstes Gespräch beim Betreten des Höhleneingangs --------------
dialog_guy_sus_intro() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    GUY_SUS_MET=1
    OUT+=("═════ HÖHLENEINGANG · GUY SUS ═════")
    OUT+=("Typ : Informant    Stimmung : nervös")
    OUT+=("")
    render

    say "Guy Sus" "Hey. Pssst. Vorsicht. Da in der Höhle sind Molerats ... oder Molerate. Was auch immer du sie nennen willst."
    OUT+=("")
    ask "Molerats?" "Molerate?"
    say "Guy Sus" "Ob deutsch oder englisch – es sind große, angriffslustige Schweine. Nicht ungefährlich."
    say "Guy Sus" "In der Höhle liegt eine Leiche. Um den Hals trägt sie ein glänzendes Objekt. Das könnte was wert sein."
    say "Guy Sus" "Wenn du reingehst, sei besser vorsichtig."
    say "Guy Sus" "Falls du nicht weißt, wie man Leichen plündert – ich kann es dir beibringen."
    guy_sus_offer_search

    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

# --- Standardgespräch (»touch GuySus«) -----------------------------
dialog_guy_sus() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    GUY_SUS_MET=1
    OUT+=("═════ HÖHLENEINGANG · GUY SUS ═════")
    OUT+=("Typ : Informant    Stimmung : nervös")
    OUT+=("")
    render

    if [ "${GUY_SUS_GONE:-0}" = "1" ]; then
        say "-" "Hier ist niemand mehr. Nur der Wind im Höhleneingang."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return 0
    fi

    say "-" "Guy Sus lehnt an der Felswand und nickt dir zu, als hätte er dich erwartet."
    say "Guy Sus" "Pssst. Die Molerats sind da drin. Große, angriffslustige Schweine."
    say "Guy Sus" "Und die Leiche mit dem glänzenden Objekt liegt noch immer in der Höhle."
    guy_sus_offer_search

    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

# --- Nachspiel: Leiche durchsucht? ---------------------------------
# $1 = "cave" oder "outside". Die ersten Zeilen setzt der Aufrufer.
guy_sus_aftermath_talk() {
    local where="${1:-cave}" line
    say "Guy Sus" "Hast du die Leiche schon durchsucht?"
    ask "Ja." "Nein."
    if [ "${CHOICE:-0}" = "1" ]; then
        say "$AGENT_NAME" "Ja. Hab ein Amulett gefunden"
        say "Guy Sus" "Ein Amulett? Dann hat Nek es wenigstens nicht umsonst getragen."
        say "Guy Sus" "Das ist mehr, als ich zu hoffen wagte. Danke."
    else
        say "$AGENT_NAME" "Nein. Noch nicht."
        say "Guy Sus" "Dann durchsuch sie lieber. Das glänzende Objekt könnte wichtig sein."
        if [ "$where" = "cave" ]; then
            say "Guy Sus" "Aber mach schnell – die Molerats sind nicht zimperlich."
        else
            say "Guy Sus" "Du hast sie ja hier draußen. Da stört dich wenigstens keiner."
        fi
    fi

    say "Guy Sus" "Wer weiß, vielleicht sieht man sich wieder. Die Welt ist klein."
    say "-" "Guy Sus nickt dir zu, tritt zurück – und ist im nächsten Augenblick verschwunden."

    if [ "$where" = "cave" ]; then
        GUY_SUS_CAVE_DONE=1
    else
        GUY_SUS_OUTSIDE_DONE=1
    fi
    guy_sus_gone
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
    return 0
}

# Guy kommt in die Höhle, nachdem alle Molerats gelöscht wurden.
dialog_guy_sus_cave_clear() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ MOLERATHÖHLE · GUY SUS ═════")
    OUT+=("Typ : Informant    Stimmung : euphorisch")
    OUT+=("")
    render

    say "-" "Schritte zwischen den Felsen. Guy Sus tritt aus dem Schatten und starrt auf die leere Höhle."
    say "Guy Sus" "Wow. Das war große Klasse. Den Biestern hast du es gezeigt."
    guy_sus_aftermath_talk cave
    return 0
}

# Guy wartet draußen, wenn die Leiche in den Höhleneingang gezogen wurde.
dialog_guy_sus_outside() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ HÖHLENEINGANG · GUY SUS ═════")
    OUT+=("Typ : Informant    Stimmung : erleichtert")
    OUT+=("")
    render

    say "-" "Guy Sus wartet draußen und mustert dich und die Leiche."
    say "Guy Sus" "Puh, da bist du aber glimpflich davon gekommen. Den Molerats bist du entkommen."
    guy_sus_aftermath_talk outside
    return 0
}

# --- Haken für die Hauptschleife -----------------------------------
# Erstes Betreten des Höhleneingangs: automatischer Dialog.
guy_sus_maybe_intro() {
    [ "${GUY_SUS_MET:-0}" = "1" ] && return 1
    [ "${GUY_SUS_GONE:-0}" = "1" ] && return 1
    [ "${CWD:-}" = "$(guy_sus_dir)" ] || return 1
    dialog_guy_sus_intro
    return 0
}

# Leiche im Höhleneingang: Guy spricht den Agenten draußen an.
guy_sus_maybe_corpse() {
    [ "${GUY_SUS_GONE:-0}" = "1" ] && return 1
    [ "${GUY_SUS_OUTSIDE_DONE:-0}" = "1" ] && return 1
    [ "${CWD:-}" = "$(guy_sus_dir)" ] || return 1
    declare -F neks_leiche_here >/dev/null 2>&1 || return 1
    neks_leiche_here || return 1
    dialog_guy_sus_outside
    return 0
}

# Alle Molerats tot: Guy kommt in die Höhle.
guy_sus_maybe_cave_clear() {
    [ "${GUY_SUS_GONE:-0}" = "1" ] && return 1
    [ "${GUY_SUS_CAVE_DONE:-0}" = "1" ] && return 1
    [ "${CWD:-}" = "$(molerats_cave_dir 2>/dev/null)" ] || return 1
    declare -F molerats_all_dead >/dev/null 2>&1 || return 1
    molerats_all_dead || return 1
    dialog_guy_sus_cave_clear
    return 0
}
