# ============================================================
#  TerminalHero - gemeinsame Farbpalette (dystopisch, 256 Farben)
#
#  Wird von TerminalHero.sh (Startbildschirm) UND von
#  TerminalShell.sh (Spiel) geladen, damit beide exakt gleich
#  aussehen. Nur Variablen-Zuweisungen - keine Logik.
# ============================================================

UI_BG=$'\033[48;5;233m'          # Grundfläche (bleibt "sticky" aktiv)
FG=$'\033[38;5;252m'             # Grundtext (kaltes Weiß)
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

FRAME=$'\033[38;5;30m'           # dunkles Türkis (Rahmen, Tristesse)
FRAME_HI=$'\033[1;38;5;44m'      # helles Cyan (aktiv / Fokus)
TITLE=$'\033[1;38;5;214m'        # Amber (Überschriften, Warnlichter)
ACCENT=$'\033[1;38;5;169m'       # Neon-Magenta (Dialog / Funk)
GOOD=$'\033[1;38;5;112m'         # Phosphor-Grün (ok / erlernt)
WARN=$'\033[1;38;5;208m'         # Orange (Warnung)
DANGER=$'\033[1;38;5;203m'       # Giftrot (Fehler, Virus)
AGENT_C=$'\033[38;5;80m'         # Agenten-Stimme
GENERAL_C=$'\033[38;5;179m'      # README / General
PIXI_C=$'\033[1;38;5;213m'       # Pixi (Reporterin, /var/log/daily-pulse)
TORW_C=$'\033[38;5;184m'         # Torwache / Simon Guard (Stadtwache)
JON_C=$'\033[38;5;186m'          # Simple Jon (Stadtwache, Simons Freund)
RAT_C=$'\033[1;38;5;174m'        # Kriegsrat
ERM_C=$'\033[1;38;5;111m'        # Chefermittler (»Ermittler«)
RACHEL_C=$'\033[1;38;5;180m'     # Rachel (Chefredakteurin, DailyPulse)
JACK_C=$'\033[38;5;109m'         # Jack (der ruhige Bruder)
AMANDA_C=$'\033[38;5;152m'       # Amanda Nox (Vorzimmer der Detektei Holmes)
BOERTY_C=$'\033[38;5;222m'       # Börty Smiles (Wirt KneipeZumGoldenenLächeln)
SHERLOCK_C=$'\033[1;38;5;110m'   # Sherlock Holmes (Detektiv, nachts im Ostdistrikt)
MICHAEL_C=$'\033[38;5;108m'      # Michael Mitch (Restaurant, Westdistrikt)
TRACEY_C=$'\033[38;5;215m'       # Tracey Briggs (Zeitungsausträgerin)
JIMMY_C=$'\033[38;5;144m'        # Jimmy Page (Zeitungssammler, Ostdistrikt)
GUY_C=$'\033[38;5;137m'          # Guy Sus (Informant, Höhleneingang)
FRANCESCO_C=$'\033[38;5;187m'    # Francesco Dellamorte (Totengräber, Friedhof)
SAMY_C=$'\033[1;38;5;220m'       # Samy Cage (Lagermeister, Zentrum)
BRUNO_C=$'\033[1;38;5;166m'      # Bruno Amboss (Schmied)
JACK_BONES_C=$'\033[1;38;5;155m' # Jack Bones (SurvivalShop)
ARMBANDUHR_C=$'\033[38;5;81m'    # Armbanduhr (sprechender Gegenstand)
GREGOR_C=$'\033[1;38;5;131m'     # Gregor Molerat (Vater)
MARLENE_C=$'\033[38;5;181m'      # Marlene Molerat (Mutter)
CHANTAL_C=$'\033[1;38;5;218m'    # Chantal Molerat (Schwester)
NARR_C=$'\033[3;38;5;245m'       # Erzählerstimme (kursiv, blass)
MENU_C=$'\033[38;5;117m'         # Menüoptionen / Auswahl
DIR_C=$'\033[1;38;5;74m'         # Verzeichnisse
FILE_C=$'\033[38;5;223m'         # Dateien
IMG_C=$'\033[1;38;5;176m'        # Bilder
AUD_C=$'\033[38;5;150m'          # Audio
VID_C=$'\033[38;5;180m'          # Video
CFG_C=$'\033[38;5;109m'          # Konfiguration
LOG_C=$'\033[38;5;102m'          # Protokolle
MUTED=$'\033[38;5;240m'          # Nebensächliches

# Kompatibilitätsnamen (ältere Aufrufe in beiden Skripten)
BLUE=$FRAME
CYAN=$FRAME_HI
GREEN=$GOOD
YELLOW=$TITLE
RED=$DANGER
MAGENTA=$ACCENT
WHITE=$FG
GREY=$MUTED
ORANGE=$WARN

# Sprecherfarben für Charakter-Dialoge (kern/render.sh, line_color).
# Wichtig: Charaktere bekommen nie MUTED/GREY - Grau bleibt neutralen
# System-, Erzähl- und Hinweistexten vorbehalten.
declare -gA SPEAKER_COLOR=(
    ["README"]="$GENERAL_C"
    ["Pixi"]="$PIXI_C"
    ["Pixi Nullpunkt"]="$PIXI_C"
    ["Rachel"]="$RACHEL_C"
    ["Rachel Nullpunkt"]="$RACHEL_C"
    ["Jack"]="$JACK_C"
    ["Jack Nullpunkt"]="$JACK_C"
    ["Amanda"]="$AMANDA_C"
    ["Börty"]="$BOERTY_C"
    ["Börty Smiles"]="$BOERTY_C"
    ["Sherlock"]="$SHERLOCK_C"
    ["Sherlock Holmes"]="$SHERLOCK_C"
    ["Michael"]="$MICHAEL_C"
    ["Tracey"]="$TRACEY_C"
    ["Jimmy"]="$JIMMY_C"
    ["Guy Sus"]="$GUY_C"
    ["Torwächter"]="$TORW_C"
    ["Simon Guard"]="$TORW_C"
    ["Simple Jon"]="$JON_C"
    ["Kriegsrat"]="$RAT_C"
    ["Ermittler"]="$ERM_C"
    ["Francesco"]="$FRANCESCO_C"
    ["Samy"]="$SAMY_C"
    ["Bruno"]="$BRUNO_C"
    ["Jack Bones"]="$JACK_BONES_C"
    ["Armbanduhr"]="$ARMBANDUHR_C"
    ["Gregor Molerat"]="$GREGOR_C"
    ["Marlene Molerat"]="$MARLENE_C"
    ["Chantal Molerat"]="$CHANTAL_C"
)

BORDER="$FRAME"
