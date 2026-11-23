# ============================================================
#  TerminalHero - Stadtteil: Westdistrikt
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Westdistrikt
#
#  Geladen von district.sh, sobald der Spieler den Stadtteil betritt:
#     district_build_west()   - Welt (Ordner/Dateien/Inhalte/Dialoge)
#     district_enter_west()   - (optional) beim Betreten
#     district_leave_west()   - (optional) beim Verlassen
#  Noch kein großer Ausbau - die Welt dieses Stadtteils folgt später.
#  Das Restaurant (Orte/Restaurant.sh) mit Michael Mitch steht bereits,
#  und der DailyPulse-Zeitungskasten ist hier, damit die Rückholaktion
#  (Charakter/verlag.sh) in allen fünf Bezirken spielbar ist.
# ============================================================

# Der Stadtteil
WEST_PREFIX="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Westdistrikt"

# --- Welt-Aufbau: Ordner & Dateien dieses Stadtteils -----------------
district_build_west() {
    # Das Restaurant: eigener Ordner, eigener Aufbau in Orte/Restaurant.sh.
    require_ort Restaurant
    restaurant_build "$WEST_PREFIX/Restaurant"

    # Eine Sitzbank im Bezirk (Interior/Möbel/Sitzgelegenheiten/Sitzbank.sh).
    interior_place sitzbank "$WEST_PREFIX/Sitzbank"

    # Der DailyPulse-Zeitungskasten des Bezirks (Interior/Stadt/Zeitungskasten.sh).
    zeitungskasten_place "$WEST_PREFIX"
}
