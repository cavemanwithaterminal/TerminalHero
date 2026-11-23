# ============================================================
#  TerminalHero - Stadtteil: Süddistrikt
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt
#
#  Der Süddistrikt liegt "geografisch" am nächsten zum Haupttor: Wer den
#  Haupteingang durchquert, steht zuerst hier. Die Welt dieses Stadtteils
#  (Ordner, Dateien, Inhalte, Dialoge) steht in dieser Datei; der
#  DailyPulse-Verlag hat mit Orte/DailyPulse.sh eine eigene Ortsdatei.
#  TerminalShell.sh hält dafür keinen Code mehr vor.
#
#  Geladen wird sie von district.sh, sobald der Spieler den
#  Süddistrikt betritt (datei per "source", also im selben Prozess -
#  Token-Wirtschaft, Speichern/Laden und alle Befehle gelten unverändert).
# ============================================================

# Der Stadtteil und seine Nachbarschaft
SUED_PREFIX="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt"

# --- Welt-Aufbau: Ordner & Dateien dieses Stadtteils ----------------
# Wird beim ersten Betreten einmalig aufgerufen (siehe district.sh).
district_build_sued() {
    # Die eingestürzte Baracke direkt am Haupttor (Wahrzeichen des Bezirks).
    addp d "$SUED_PREFIX/EingestürzteBaracke"
    # Die vier Wohnhäuser.
    addp d "$SUED_PREFIX/Haus1"
    addp d "$SUED_PREFIX/Haus2"
    addp d "$SUED_PREFIX/Haus3"
    addp d "$SUED_PREFIX/Haus4"

    # Der Zeitungsverlag – Redaktion UND Zuhause von Pixis Familie.
    # Eigener Ordner, eigener Aufbau in Orte/DailyPulse.sh.
    require_ort DailyPulse
    daily_pulse_build "$SUED_PREFIX/DailyPulse"

    # --- Fundorte: was in diesem Stadtteil in der Welt liegt -------------
    # In der Baracke liegt die Armbanduhr (einmalig – ist sie schon im
    # Inventar, liegt sie hier NICHT).
    world_item_place armbanduhr "$SUED_PREFIX/EingestürzteBaracke/Armbanduhr"

    # Daneben ein Häufchen Bits (die Währung): Es wird wie jeder Fundort
    # mit »grep Bits« herausgezogen und bringt 10 Bits. Die Menge steht HIER
    # am Fundort – das Item selbst hat keinen Wert (Items/Spezial/Bits.sh).
    world_item_place bits "$SUED_PREFIX/EingestürzteBaracke/Bits" 10

    # Vor dem Verlag liegt noch ein kleiner Haufen (3 Bits). Diesen nimmt
    # der Agent mit »grep Bits« auf - der Befehl muss also erlernt sein.
    world_item_place bits "$SUED_PREFIX/Bits" 3

    # Und ein einzelnes LightBeer (Items/Plunder/LightBeer.sh): Ware, die der
    # Agent bei Börty verkaufen kann (Handelsfenster.sh). KEIN Kasten, nur
    # diese eine Flasche - aufgehoben wird sie wie jeder andere Fundort, mit
    # »grep LightBeer« (sofern »grep« im Spielverlauf erlernt wurde).
    world_item_place lightbeer "$SUED_PREFIX/EingestürzteBaracke/LightBeer" 1

    # Eine einfache Fackel liegt in der Baracke (NutzbareItems/EinfacheFackel.sh).
    # Sie ist ein normaler Fundort: »grep EinfacheFackel« nimmt sie mit ins
    # Inventar. Der Dateiname ist der volle Gegenstandsname (wie beim Ablegen).
    world_item_place fackel "$SUED_PREFIX/EingestürzteBaracke/EinfacheFackel"

    # --- Einrichtung: benutzbare Objekte (Interior) ----------------------
    # In der Baracke steht eine Matratze – ein Schlafplatz. Sie ist KEIN
    # Fundort (nicht aufhebbar), sondern wird mit »use« benutzt. Angemeldet
    # wird sie in Interior/Möbel/Schlafgelegenheiten/Matratze.sh
    # (inkl. Tokens je Schlafstunde).
    interior_place matratze "$SUED_PREFIX/EingestürzteBaracke/Matratze"

    # Daneben steht ein Stuhl – eine Sitzgelegenheit (kern/sitzen.sh).
    interior_place stuhl "$SUED_PREFIX/EingestürzteBaracke/Stuhl"

    # Eine Sitzbank im Bezirk (Interior/Möbel/Sitzgelegenheiten/Sitzbank.sh).
    interior_place sitzbank "$SUED_PREFIX/Sitzbank"

    # Der DailyPulse-Zeitungskasten des Bezirks (Interior/Stadt/Zeitungskasten.sh).
    # Er steht vor dem Verlag und verkauft die aktuelle Ausgabe für 10 Bits.
    zeitungskasten_place "$SUED_PREFIX"

    # Tracey Briggs ist nach dem Fund wieder im Verlag - bis Rachel die
    # Sperrzone-Bündel übergibt. Der Aufruf ist idempotent und hält ihren
    # Stand auch beim Laden eines Spielstands aktuell
    # (Charakter/TraceyBriggs.sh).
    declare -F tracey_apply_state >/dev/null 2>&1 && tracey_apply_state
}

# --- Betreten: kurze Ortsbeschreibung (nicht blockierend) -----------
district_enter_sued() {
    OUT+=("")
    OUT+=("── Süddistrikt ──  der Bezirk gleich hinter dem Haupttor.")
    OUT+=("Nasses Pflaster, flackernde Laternen: die eingestürzte Baracke")
    OUT+=("und vier Wohnhäuser. Am Ende der Gasse der DailyPulse-Verlag.")
}

# --- Verlassen: zurück Richtung Haupttor (die Basis übernimmt wieder)
district_leave_sued() {
    OUT+=("")
    OUT+=("── Du verlässt den Süddistrikt und gehst zurück Richtung Haupttor. ──")
}
