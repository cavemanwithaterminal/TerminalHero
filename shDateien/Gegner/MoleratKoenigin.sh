# ============================================================
#  TerminalHero - Gegnerart: MoleratKönigin
# ------------------------------------------------------------
#  Die MoleratKönigin lebt in der KöniginnenKammer am Ende des
#  Breiten Tunnels (Orte/KöniginnenKammer.sh). Sie ist ein
#  riesiges, massiges Schwein und der Mittelpunkt des Nestes.
#
#  Werte:
#    * Angriff nach 3 Sekunden
#    * 50 Tokens Schaden pro Sekunde
#    * 500 zusätzliche rm-Kosten (Grundkosten kommen dazu)
#    * Beute: 20 MoleratCode und der Kopf der Königin
#      (Items/Plunder/KopfMoleratKoenigin.sh, Verkauf 100 Bits)
#    * EXP: 50 Grundkosten + 500 Gegnerkosten = 550 Tokens;
#      1 EXP je 5 Tokens = 110 EXP (100 + 10).
#
#  Die Königin respawnt NICHT: MOLERAT_KOENIGIN_DEAD hält ihren
#  endgültigen Tod im Spielstand fest.
#
#  Um sie herum halten bis zu drei MoleratKrieger Wache. Die
#  Krieger gehören zur bestehenden Art moleratkrieger
#  (Gegner/Molerats.sh), haben hier aber einen eigenen Zähler
#  (KoeniginnenKammer) und kommen alle 48 Ingame-Stunden einzeln
#  nach, maximal drei.
#
#  Am Rand des Nestes liegt das Questitem
#  »SchweinePriester's Tagebuch« (Items/Quest/
#  SchweinePriesterTagebuch.sh). Der Fundort wird hier registriert.
# ============================================================

molerat_koenigin_dir() { molerats_koenigin_dir; }

molerat_koenigin_path() {
    printf '%s/MoleratKönigin' "$(molerat_koenigin_dir)"
}

molerat_koenigin_define_type() {
    gegner_define_type moleratkoenigin virus "MoleratKönigin" \
        3 50 500 moleratcode 20 molerat_koenigin_on_kill \
        "Ein massiger Schatten hebt sich aus dem Nest. Die MoleratKönigin ist erwacht."
}

molerat_koenigin_on_kill() {
    MOLERAT_KOENIGIN_DEAD=1
    # Zweite Beute zusätzlich zum MoleratCode: Der Schädel der Königin.
    if declare -F inv_add >/dev/null 2>&1 \
       && inv_add kopf_moleratkoenigin 1; then
        OUT+=("[ LOOT ] $(item_name kopf_moleratkoenigin)")
    fi
    return 0
}

# Fundort des Tagebuchs genau einmal pro Sitzung anmelden. Der
# eigentliche Aufbau passiert danach über items_world_refresh.
declare -g _MOLERAT_KOENIGIN_ITEM_REG=0
molerat_koenigin_register_item() {
    [ "${_MOLERAT_KOENIGIN_ITEM_REG:-0}" = "1" ] && return 0
    _MOLERAT_KOENIGIN_ITEM_REG=1
    world_item_place schweinepriesters_tagebuch \
        "$(molerat_koenigin_dir)/SchweinePriesterTagebuch"
    return 0
}

# Beim Start/Laden: Königin entfernen oder aufbauen, drei Krieger
# aufstellen und das Tagebuch als Fundort anmelden.
molerat_koenigin_apply_state() {
    molerat_koenigin_define_type
    case "${MOLERAT_KOENIGIN_DEAD:-0}" in
        ''|*[!0-9]*) MOLERAT_KOENIGIN_DEAD=0 ;;
    esac
    [ "$MOLERAT_KOENIGIN_DEAD" -ne 0 ] && MOLERAT_KOENIGIN_DEAD=1

    local p
    p="$(molerat_koenigin_path)"
    if [ "$MOLERAT_KOENIGIN_DEAD" = "1" ]; then
        gegner_remove_path "$p"
    else
        gegner_place moleratkoenigin "$p"
    fi

    # Krieger der KöniginnenKammer (eigener Zähler, 48h-Takt).
    molerats_krieger_define_type
    molerats_krieger_normalize_state KoeniginnenKammer
    molerats_krieger_place KoeniginnenKammer \
        $(( $(molerats_krieger_max KoeniginnenKammer) \
            - $(molerats_krieger_dead KoeniginnenKammer) ))

    molerat_koenigin_register_item
    return 0
}
