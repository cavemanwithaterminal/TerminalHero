# ============================================================
#  TerminalHero - Stadtteil: Norddistrikt
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Norddistrikt
#
#  Geladen von district.sh, sobald der Spieler den Stadtteil betritt:
#     district_build_nord()   - Welt (Ordner/Dateien/Inhalte/Dialoge)
#     district_enter_nord()   - (optional) beim Betreten
#     district_leave_nord()   - (optional) beim Verlassen
#  Die Welt dieses Stadtteils folgt später; hier stehen bisher nur der
#  Zeitungskasten (DailyPulse) und die Betreten-Meldung. Sherlock Holmes
#  hält sich hier während der Verfolgung auf (Charakter/SherlockHolmes.sh)
#  - er wird zur Laufzeit eingesetzt.
# ============================================================

# Der Stadtteil
NORD_PREFIX="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Norddistrikt"

# --- Welt-Aufbau: Ordner & Dateien dieses Stadtteils -----------------
district_build_nord() {
    # Eine Sitzbank im Bezirk (Interior/Möbel/Sitzgelegenheiten/Sitzbank.sh).
    interior_place sitzbank "$NORD_PREFIX/Sitzbank"

    # Der DailyPulse-Zeitungskasten des Bezirks (Interior/Stadt/Zeitungskasten.sh).
    zeitungskasten_place "$NORD_PREFIX"
}

# --- Betreten: kurze Ortsbeschreibung (nicht blockierend) -----------
district_enter_nord() {
    OUT+=("")
    OUT+=("── Norddistrikt ──  der stillste Teil der Stadt.")
    OUT+=("Leere Straßen, verhängte Fenster, Laternen mit kaltem Licht.")
    OUT+=("Hier hört man jeden Schritt – und jede Katze.")
}
