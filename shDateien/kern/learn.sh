# ============================================================
#  TerminalHero - Erlente Befehle
#
#  Der Virus hat dem Agenten fast alle Befehle genommen (Amnesie). LEARNED
#  hält, was wieder da ist. knows <cmd> prüft das. general_teach_meta (beim
#  General-Gespräch) und meta_learn_silently (bei Spielstand/ohne Tutorial)
#  ergänzen die Menü-Befehle; learn_cmd lernt EINZELNE Befehle (z. B. »grep«,
#  das die Armbanduhr erinnert). LEARNED lebt in kern/state.sh.
# ============================================================

# Die Menü-Befehle, die der General (README) beibringt.
META_CMDS=(help character questlog inventar)

knows() {
    local c="$1" x
    for x in "${LEARNED[@]}"; do [ "$x" = "$c" ] && return 0; done
    return 1
}

# Einen einzelnen Befehl (wieder) erlernen: learn_cmd <befehl>
# Legt ihn in LEARNED und meldet es im Ausgabefenster.
# Rückgabe 0 = neu gelernt, 1 = war schon bekannt.
learn_cmd() {
    local c="$1"
    [ -n "$c" ] || return 1
    knows "$c" && return 1
    LEARNED+=("$c")
    OUT+=("   [ Neuer Befehl erlernt: ${c} ]")
    play_sound select
    return 0
}
general_teach_meta() {
    local c n=0
    for c in "${META_CMDS[@]}"; do
        knows "$c" && continue
        LEARNED+=("$c")
        OUT+=("   [ Neuer Befehl erlernt: ${c} ]")
        n=$(( n + 1 ))
    done
    [ "$n" -gt 0 ] && play_sound select
    return 0
}
meta_learn_silently() {
    local c
    for c in "${META_CMDS[@]}"; do
        knows "$c" || LEARNED+=("$c")
    done
}
