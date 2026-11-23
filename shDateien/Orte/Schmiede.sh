# ============================================================
#  TerminalHero - Ort: Schmiede (Zentrum)
# ------------------------------------------------------------
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Zentrum/Schmiede
#
#  Eine kleine Schmiede am Rand des Marktplatzes. Drinnen steht
#  Bruno Amboss an der Esse. Er verkauft das Einfache Set und das
#  schwerere Kampfset - Letzteres gibt es nur bei ihm, nicht bei
#  Jack Bones im SurvivalShop.
#
#  Der Ordner wird von Orte/Zentrum.sh über schmiede_build
#  aufgebaut. Der Schmied selbst meldet sich in
#  Charakter/BrunoAmboss.sh an (handel_lager_brunoamboss); sein
#  Dialog läuft über DIALOG[.../BrunoAmboss] = dialog_brunoamboss.
# ============================================================

schmiede_build() {   # $1 = voller Pfad des Schmiede-Ordners
    [ -n "${1:-}" ] || return 0
    local _s="${1%/}"

    addp d "$_s"

    # Bruno Amboss steht an der Esse. Angesprochen wird er mit
    # »touch BrunoAmboss« (Charakter/BrunoAmboss.sh).
    addp f "$_s/BrunoAmboss"
    CONTENT["$_s/BrunoAmboss"]="========================================\n  SCHMIEDE  //  BRUNO AMBOSS\n========================================\nName   : Bruno Amboss\nRolle  : Schmied & Ausrüster\nStatus : die Esse ist heiß\n\nSortiment:\n  Einfaches Set für den Anfang,\n  Kampfset für die Nacht -\n  Klingen, Ketten und ein Ring,\n  der die Tokens schneller fließen lässt.\n\nNotiz:\n  »Eisen lügt nicht. Entweder es hält,\n   oder du merkst es zu spät.«\n\nWer ihn berührt (touch BrunoAmboss), bekommt\neinen prüfenden Blick und ein ehrliches Angebot.\n(cat BrunoAmboss · file BrunoAmboss)"
    DIALOG["$_s/BrunoAmboss"]="dialog_brunoamboss"

    # Ein Amboss als feste Einrichtung. Kein Dialog, nur Weltflavor.
    addp f "$_s/Amboss"
    CONTENT["$_s/Amboss"]="========================================\n  SCHMIEDE  //  AMBOSS\n========================================\nEin massiver Amboss aus dunklem Eisen.\nDie Bahn ist blank gearbeitet, die Kanten\nsind voller Kerben. Jemand hat hier schon\nsehr lange nicht mehr nur Hufeisen repariert.\n\n(cat Amboss · file Amboss)"
}
