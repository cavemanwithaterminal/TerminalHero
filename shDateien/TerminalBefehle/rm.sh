# ============================================================
#  TerminalHero - Terminal-Befehl: rm
# ------------------------------------------------------------
#  »rm« ist ein KAMPFbefehl. Er löscht Gegner (Kategorie »Virus«)
#  endgültig aus dem Dateisystem. Anders als das echte rm kann er
#  nicht einfach jede Datei anfassen: Der Agent braucht eine
#  ausgerüstete Waffe, die genau diese Kategorie vernichten kann.
#  Waffen unterscheiden zwischen Viren und freundlichen Dateien.
#
#  Aufruf:
#     rm Molerat1
#     rm Molerat1 Molerat2 Molerat3
#
#  Tokenkosten (kern/tokens.sh):
#     Grundkosten 50 + Gegnerkosten je gültigem Ziel.
#     Drei Molerats kosten also 50 + 50 + 50 + 50 = 200 Tokens.
#     EXP: 1 pro 5 bezahlten Tokens (Grund- + Gegnerkosten).
#     50 Tokens = 10 EXP; ein Molerat (100 Tokens) = 20 EXP;
#     drei Molerats (200 Tokens) = 40 EXP.
#
#  Gelernt wird »rm« bei Jack Bones (Survival Jack) im Zentrum.
#  Dort gilt zusätzlich: 50 Tokens Grundkosten plus gegnerabhängige
#  Zusatzkosten, die von Gegner zu Gegner verschieden sind.
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
# ============================================================

builtin_rm() {
    if ! knows rm; then
        play_sound error
        OUT+=("»rm« …? Diesen Befehl kenne ich nicht mehr.")
        OUT+=("Ohne ihn kann ich Gegner nicht löschen.")
        return
    fi
    if [ -z "$1" ]; then
        play_sound error
        OUT+=("rm: Welchen Gegner soll ich löschen?")
        OUT+=("Verwendung: rm <gegner> [<gegner> ...]")
        return
    fi

    # Kampfbefehl ohne ausgerüstete Waffe: nicht benutzbar.
    if ! declare -F equip_combat_ready >/dev/null 2>&1 || ! equip_combat_ready; then
        play_sound error
        OUT+=("Ich brauche eine ausgerüstete Waffe, um einen Kampfbefehl zu benutzen.")
        OUT+=("Ohne Waffe kann ich nur reden, lesen und weglaufen.")
        return
    fi

    local -a args=() targets=()
    local a np type cat seen=" " molerats=0 exp_gain=0
    read -ra args <<< "$1"
    for a in "${args[@]}"; do
        [ -n "$a" ] || continue
        np="$(resolve_path "$a" "$CWD")"
        zone_denied rm "$a" "$np" && continue
        district_ensure "$np"
        if ! gegner_is_enemy_path "$np"; then
            play_sound error
            OUT+=("rm: ${a}: Das ist kein Gegner.")
            continue
        fi
        case "$seen" in *" $np "*) continue ;; esac
        type="${GEGNER_AT[$np]:-}"
        cat="$(gegner_category_of "$np")"
        if ! equip_combat_can_destroy "$cat"; then
            play_sound error
            OUT+=("rm: ${a}: Diese Waffe kann keine $(gegner_cat_plural "$cat") löschen.")
            continue
        fi
        [ "$(gegner_type_label "$type")" = "Molerat" ] && molerats=1
        seen+="$np "
        targets+=("$np")
    done

    if [ "${#targets[@]}" -eq 0 ]; then
        play_sound error
        OUT+=("rm: Kein gültiges Ziel.")
        return
    fi

    # Die EXP wurden in TerminalShell.sh bereits vor dem Befehl gutgeschrieben
    # (1 EXP je 5 bezahlte Tokens inkl. Grundkosten). Hier denselben Betrag
    # ausrechnen, solange die Ziele noch existieren, und im Dialog anzeigen.
    if [ "$molerats" = "1" ]; then
        exp_gain="$(token_exp_of rm "$1")"
        case "$exp_gain" in ''|*[!0-9]*) exp_gain=0 ;; esac
    fi

    local p
    for p in "${targets[@]}"; do
        gegner_kill "$p"
    done

    if [ "$molerats" = "1" ] && [ "$exp_gain" -gt 0 ]; then
        OUT+=("")
        OUT+=("[ EXP ]  +${exp_gain} EXP für die besiegten Molerats erhalten.")
    fi

    # Wenn der letzte Gegner gefallen ist, kommt Guy Sus in die Höhle.
    if declare -F guy_sus_maybe_cave_clear >/dev/null 2>&1; then
        guy_sus_maybe_cave_clear
    fi
}
