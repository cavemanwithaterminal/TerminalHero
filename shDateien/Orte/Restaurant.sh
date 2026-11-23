# ============================================================
#  TerminalHero - Ort: Restaurant (Westdistrikt)
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Westdistrikt/Restaurant
#
#  Der Ordner wird von Westdistrikt.sh über restaurant_build aufgebaut.
#  Hier arbeitet Michael Mitch (Charakter/MichaelMitch.sh) - Börtys
#  früherer Lagergehilfe. Angesprochen wird er mit
#  »touch MichaelMitch«.
# ============================================================

restaurant_build() {   # $1 = voller Pfad des Restaurant-Ordners
    [ -n "${1:-}" ] || return 0
    local _r="${1%/}"

    addp d "$_r"

    addp f "$_r/MichaelMitch"
    CONTENT["$_r/MichaelMitch"]="========================================\n  RESTAURANT  //  MICHAEL MITCH\n========================================\nRolle  : Service & Küche\nFrüher : Lagergehilfe bei Börty Smiles\nStatus : angekommen. Zum ersten Mal seit\n         Langem nicht auf der Durchreise.\n\nNotiz:\n  »Kisten zählen kann jeder.\n   Zu wissen, wann man aufhört,\n   ist die eigentliche Arbeit.«\n\nWer ihn berührt (touch MichaelMitch), wird\nfreundlich begrüßt. (cat MichaelMitch · file MichaelMitch)"
    DIALOG["$_r/MichaelMitch"]="dialog_michael"
}
