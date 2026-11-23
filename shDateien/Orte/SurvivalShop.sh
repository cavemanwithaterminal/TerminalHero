# ============================================================
#  TerminalHero - Ort: SurvivalShop (Zentrum)
# ------------------------------------------------------------
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Zentrum/SurvivalShop
#
#  Ein kleiner Laden am Rand des Marktplatzes. Drinnen steht Jack
#  Bones - Spitzname »Survival Jack« - hinter dem Tresen. Er verkauft
#  Ausrüstung für draußen: Fackeln, einfache Schlafsäcke und das
#  erste Einfache Ausrüstungs-Set.
#
#  Der Ordner wird von Orte/Zentrum.sh über survival_shop_build
#  aufgebaut. Der Händler selbst meldet sich in Charakter/JackBones.sh
#  an (handel_lager_jackbones); sein Dialog läuft über
#  DIALOG[.../JackBones] = dialog_jackbones.
# ============================================================

survival_shop_build() {   # $1 = voller Pfad des SurvivalShop-Ordners
    [ -n "${1:-}" ] || return 0
    local _s="${1%/}"

    addp d "$_s"

    # Jack Bones steht hinter dem Tresen. Angesprochen wird er mit
    # »touch JackBones« (Charakter/JackBones.sh).
    addp f "$_s/JackBones"
    CONTENT["$_s/JackBones"]="========================================\n  SURVIVALSHOP  //  JACK BONES\n========================================\nName   : Jack Bones\nRuf    : »Survival Jack«\nRolle  : Inhaber & Ausrüster\nStatus : bereit für draußen. Immer.\n\nSortiment:\n  Fackeln, einfache Schlafsäcke,\n  einfache Ausrüstung -\n  alles, was man nach Einbruch braucht.\n\nNotiz:\n  »Wer draußen nicht friert, hat\n   entweder Glück oder bei mir gekauft.«\n\nWer ihn berührt (touch JackBones), bekommt\neinen trockenen Blick und ein ehrliches Angebot.\n(cat JackBones · file JackBones)"
    DIALOG["$_s/JackBones"]="dialog_jackbones"
}
