# ============================================================
#  TerminalHero - Ort: Wachhaus (Haupteingang)
# ------------------------------------------------------------
#  In-Game-Ordner:
#     ~/Schreibtisch/DesktopCity/Haupteingang/Wachhaus
#
#  Das Wachhaus ist einer der Schlaf- und Pausenräume der Stadtwache.
#  Es liegt nicht in einem der fünf Distrikte, sondern direkt im
#  Haupteingang - zwischen Tor und Stadt.
#
#  Hier steht Simple Jon (Charakter/SimpleJon.sh), eine der Wachen.
#  Außerdem gibt es ein Bett und einen Stuhl: Der Raum ist zum Schlafen
#  und zum Durchatmen gedacht. Beides sind Interior-Objekte, also mit
#  »use Bett« bzw. »use Stuhl« benutzbar.
#
#  Der Ordner und die Datei »SimpleJon« gehören zum statischen
#  Grundgerüst (kern/fs.sh). Diese Datei setzt nur die Inhalte und
#  den Dialog; sie wird in TerminalShell.sh nach load_contents
#  aufgerufen, damit ein geladener Spielstand die Room-Daten nicht
#  wieder verliert.
# ============================================================

wachhaus_prefix() {
    printf '%s/Schreibtisch/DesktopCity/Haupteingang/Wachhaus' "$HOME_DIR"
}

wachhaus_build() {
    local _w _jon
    _w="$(wachhaus_prefix)"
    _jon="$_w/SimpleJon"

    CONTENT["$_jon"]="========================================\n  STADTWACHE  //  SIMPLE JON\n========================================\nPosten : Wachhaus (Pausen- und Schlafraum)\nRang   : Stadtwache, einfacher Dienst\nStatus : Pause. Wach.\n\nNotiz:\n  »Ich bin Simple Jon. Nicht Jon Simple.\n   Die Verwechslung passiert öfter.\n   Ich korrigiere sie meistens.«\n\nWer ihn berührt (touch SimpleJon), bekommt ein Gespräch."
    DIALOG["$_jon"]="dialog_simple_jon"

    # Der Raum ist zum Schlafen und Pausenmachen da. Die eigentlichen
    # Möbelmechaniken (Schlafen/Sitzen) stecken in Interior/ und kern/.
    interior_place bett "$_w/Bett"
    interior_place stuhl "$_w/Stuhl"
}
