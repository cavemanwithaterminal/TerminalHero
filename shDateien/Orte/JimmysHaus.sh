# ============================================================
#  TerminalHero - Ort: Jimmys Haus (Ostdistrikt)
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/JimmysHaus
#
#  Der Ordner wird von Ostdistrikt.sh über jimmys_haus_build aufgebaut.
#  Drinnen wohnt Jimmy Page (Charakter/JimmyPage.sh), ein leidenschaftlicher
#  Zeitungssammler im Rollstuhl. Angesprochen wird er mit
#  »touch JimmyPage«. Außerdem steht ein Stuhl im Raum.
# ============================================================

jimmys_haus_build() {   # $1 = voller Pfad des JimmysHaus-Ordners
    [ -n "${1:-}" ] || return 0
    local _h="${1%/}"

    addp d "$_h"
    addp f "$_h/JimmyPage"
    CONTENT["$_h/JimmyPage"]="========================================\n  JIMMYS HAUS  //  JIMMY PAGE\n========================================\nName   : Jimmy Page\nRolle  : Zeitungssammler\nStatus : zu Hause. Und das bleibt so.\n\nNotiz:\n  »Das Haus ist gut. Das Haus hat alles.\n   Nur die Welt draußen hat manchmal\n   eine neue Ausgabe, die mir fehlt.«\n\nWer ihn berührt (touch JimmyPage), wird in\nsein Reich gelassen – solange er nicht\nnach draußen muss. (cat JimmyPage · file JimmyPage)"
    DIALOG["$_h/JimmyPage"]="dialog_jimmy"

    # Eine Sitzgelegenheit für Besuch (Interior/Möbel/Sitzgelegenheiten/Stuhl.sh).
    interior_place stuhl "$_h/Stuhl"
}
