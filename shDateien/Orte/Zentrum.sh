# ============================================================
#  TerminalHero - Stadtteil: Zentrum
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Zentrum
#
#  Bisher steht hier der MARKTPLATZ: das Herz der Stadt und die Station
#  zwischen Börty Smiles und seiner Bierlieferung (Nebenquest »Bier für
#  Börty«, InGameBefehle/questlog.sh). Im Lager am Marktplatz arbeitet
#  der Lagermeister Samy Cage (Charakter/SamyCage.sh) - ein Mann, der
#  für alles außer Kisten keine Zeit hat.
#
#  Am Rand des Marktplatzes liegt der SURVIVALSHOP: Jack Bones (»Survival
#  Jack«) verkauft dort Fackeln und einfache Schlafsäcke
#  (Orte/SurvivalShop.sh, Charakter/JackBones.sh).
#
#  Daneben steht die SCHMIEDE von Bruno Amboss (Orte/Schmiede.sh,
#  Charakter/BrunoAmboss.sh). Er bietet das Einfache Set und das
#  schwerere Kampfset an; Letzteres gibt es nur bei ihm.
#
#  Geladen von district.sh, sobald der Spieler den Stadtteil betritt:
#     district_build_zentrum()   - Welt (Ordner/Dateien/Inhalte/Dialoge)
#     district_enter_zentrum()   - (optional) beim Betreten
#     district_leave_zentrum()   - (optional) beim Verlassen
# ============================================================

# Der Stadtteil
ZENTRUM_PREFIX="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Zentrum"

# --- Welt-Aufbau: Ordner & Dateien dieses Stadtteils -----------------
district_build_zentrum() {
    # Der Marktplatz: Stände, Kisten, und dahinter das Lager.
    local _mp="$ZENTRUM_PREFIX/Marktplatz"
    addp d "$_mp"

    # Der SurvivalShop am Rand des Marktplatzes: Jack Bones verkauft
    # Fackeln und einfache Schlafsäcke. Eigener Aufbau in Orte/SurvivalShop.sh.
    require_ort SurvivalShop
    survival_shop_build "$ZENTRUM_PREFIX/SurvivalShop"

    # Die Schmiede daneben: Bruno Amboss führt das Einfache Set und das
    # Kampfset. Eigener Aufbau in Orte/Schmiede.sh.
    require_ort Schmiede
    schmiede_build "$ZENTRUM_PREFIX/Schmiede"

    # Eine Sitzbank im Zentrum (Interior/Möbel/Sitzgelegenheiten/Sitzbank.sh).
    interior_place sitzbank "$ZENTRUM_PREFIX/Sitzbank"

    # Das Lager am Marktplatz (eigener Ordner). Hier arbeitet der
    # Lagermeister Samy Cage; angesprochen wird er mit »touch SamyCage«
    # (Charakter/SamyCage.sh).
    local _lager="$_mp/Lager"
    addp d "$_lager"
    addp f "$_lager/SamyCage"
    CONTENT["$_lager/SamyCage"]="========================================\n  MARKTPLATZ  //  LAGER\n========================================\nName   : Samy Cage\nRolle  : Lagermeister\nStatus : schwer beschäftigt\nOffen  : sechsundvierzig Kisten, drei Lieferungen -\n         und eine, auf die ein Wirt im Ostdistrikt\n         wartet.\n\nNotiz:\n  »Hier wird alles gezählt.\n   Auch das, was fehlt.«\n\nWer ihn berührt (touch SamyCage), wird gefragt,\nob es wichtig ist - oder ob er zur Seite gehen soll.\n(cat SamyCage · file SamyCage)"
    DIALOG["$_lager/SamyCage"]="dialog_samy"

    # Der DailyPulse-Zeitungskasten des Bezirks (Interior/Stadt/Zeitungskasten.sh).
    # Er steht am Marktplatz, zwischen den Ständen und dem Lager.
    zeitungskasten_place "$ZENTRUM_PREFIX"
}

# --- Betreten: kurze Ortsbeschreibung (nicht blockierend) -----------
district_enter_zentrum() {
    OUT+=("")
    OUT+=("── Zentrum ──  der Marktplatz der Stadt.")
    OUT+=("Stände, Kisten und der Geruch von Brei und Öl. Dahinter")
    OUT+=("das Lager: zwei Rampen, ein Tor - und ein Mann, der nie Zeit hat.")
    OUT+=("Am Rand: der SurvivalShop von Jack Bones. Daneben die Schmiede")
    OUT+=("von Bruno Amboss - Ruß, Eisen und ein zweites Sortiment.")
}

# --- Verlassen: zurück Richtung Haupttor (die Basis übernimmt wieder)
district_leave_zentrum() {
    OUT+=("")
    OUT+=("── Du verlässt das Zentrum und gehst zurück Richtung Haupttor. ──")
}
