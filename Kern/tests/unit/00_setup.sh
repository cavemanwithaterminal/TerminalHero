# ============================================================
#  Unit-Test-Teil: Setup: Stubs, Hilfsfunktionen und echte Module
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# Kein "set -u": das Spiel selbst läuft ohne -u (Arrays werden
# absichtlich ungeprüft gelesen), die Tests sollen das nachbilden.

SCRIPT_DIR="$(cd "$(dirname "$0")/../../shDateien" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export TH_SOUND=0

PASS=0; FAIL=0
chk() {   # chk <was> <erwartet> <ist>
    if [ "$2" = "$3" ]; then PASS=$((PASS+1)); printf 'OK   %s\n' "$1"
    else FAIL=$((FAIL+1)); printf 'FAIL %s\n     erwartet: %s\n     ist:      %s\n' "$1" "$2" "$3"; fi
}
chk_rc() {   # chk_rc <was> <rc> <erwartet>
    if [ "$2" = "$3" ]; then PASS=$((PASS+1)); printf 'OK   %s\n' "$1"
    else FAIL=$((FAIL+1)); printf 'FAIL %s  (rc=%s, erwartet %s)\n' "$1" "$2" "$3"; fi
}
section() { printf '\n--- %s ---\n' "$1"; }

# ---- Stubs & Umgebung --------------------------------------------
play_sound() { :; }
OUT=()
HOME_DIR="/home/benutzer"
AGENT_DIR="$HOME_DIR/Downloads/Neugier"
HOSTNAME_="testhost"
USERNAME_="benutzer"
AGENT_NAME="Neugier"

# ---- Echte Module laden ------------------------------------------
. "$SCRIPT_DIR/kern/state.sh"
. "$SCRIPT_DIR/kern/equipment.sh"
. "$SCRIPT_DIR/kern/theme.sh"
. "$SCRIPT_DIR/kern/ui.sh"
. "$SCRIPT_DIR/kern/loader.sh"
. "$SCRIPT_DIR/kern/playtime.sh"
. "$SCRIPT_DIR/kern/tokens.sh"
. "$SCRIPT_DIR/kern/leben.sh"
. "$SCRIPT_DIR/kern/learn.sh"
. "$SCRIPT_DIR/kern/fs.sh"
. "$SCRIPT_DIR/kern/path.sh"
. "$SCRIPT_DIR/kern/items.sh"
. "$SCRIPT_DIR/kern/search.sh"
. "$SCRIPT_DIR/kern/interior.sh"
. "$SCRIPT_DIR/kern/district.sh"
. "$SCRIPT_DIR/InGameBefehle/character.sh"
. "$SCRIPT_DIR/InGameBefehle/questlog.sh"
. "$SCRIPT_DIR/Charakter/NeksBeerdigung.sh"
. "$SCRIPT_DIR/InGameBefehle/help.sh"
. "$SCRIPT_DIR/InGameBefehle/Statistics.sh"
. "$SCRIPT_DIR/InGameBefehle/Achievements.sh"
. "$SCRIPT_DIR/Achievements/KompassGeeicht.sh"

