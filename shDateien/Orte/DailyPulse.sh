# ============================================================
#  TerminalHero - Ort: DailyPulse (Süddistrikt)
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse
#
#  Der DailyPulse-Verlag ist Redaktion UND Zuhause der Familie
#  Nullpunkt. Der Ordner wird von Süddistrikt.sh über daily_pulse_build
#  aufgebaut; die Geschichte um Rachel, Jack, Pixi und Tracey steht in
#  Charakter/verlag.sh bzw. Charakter/TraceyBriggs.sh.
#
#  Hier stehen die festen Bewohner des Verlags:
#     Rachel      - Besitzerin & Chefredakteurin (touch Rachel)
#     Jack        - Bruder, Rechner, Papierhändler (touch Jack); wechselt
#                   nach Abschluss der Amanda-Nebenquest in die Detektei
#     Stuhl       - Sitzgelegenheit im Verlagsraum (use Stuhl)
#
#  Der Zeitungskasten steht davor im Süddistrikt (nicht im Verlag);
#  er wird von Süddistrikt.sh über zeitungskasten_place aufgestellt.
# ============================================================

daily_pulse_build() {   # $1 = voller Pfad des DailyPulse-Ordners
    [ -n "${1:-}" ] || return 0
    local _v="${1%/}"

    addp d "$_v"

    # Die Familie steht mit im Verlag. Pixi selbst legt sich je nach
    # Quest-Stand dorthin (Charakter/pixi.sh); Rachel steht fest hier.
    # Jack wechselt mit der Nebenquest »Unterstützung für Amanda« in die
    # Detektei Holmes (Charakter/verlag.sh, jack_apply_state).
    addp f "$_v/Rachel"
    CONTENT["$_v/Rachel"]="========================================\n  REDAKTION  //  RACHEL NULLPUNKT\n========================================\nRolle  : Besitzerin & Chefredakteurin\nBlatt  : /var/log/daily-pulse\nStatus : im Dienst. Immer.\n\nNotiz:\n  »Eine Ausgabe ist ein Beweis.\n   Alles andere ist eine Meinung.«\n\nWer sie berührt (touch Rachel), wird geprüft –\nfreundlich, aber geprüft."
    DIALOG["$_v/Rachel"]="verlag_gespraech_rachel"

    if [ "${AMANDA_HELP_JACK:-0}" != "1" ]; then
        addp f "$_v/Jack"
        CONTENT["$_v/Jack"]="========================================\n  REDAKTION  //  JACK NULLPUNKT\n========================================\nRolle  : Bruder. Zuhörer. Rechner.\nStatus : wachsam.\n\nNotiz:\n  »Ich rechne lieber zweimal,\n   als einmal zu hoffen.«\n\nWer ihn berührt (touch Jack), wird gewarnt –\nleise, aber gewarnt."
        DIALOG["$_v/Jack"]="dialog_jack"
    fi

    # Eine Sitzgelegenheit im Verlagsraum (Interior/Möbel/Sitzgelegenheiten/Stuhl.sh).
    # Sitzen ist eine eigene Mechanik (kern/sitzen.sh) mit eigenem Tagesbudget.
    interior_place stuhl "$_v/Stuhl"
}
