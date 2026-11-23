# ============================================================
#  TerminalHero - Stadtteil: Ostdistrikt
#
#  In-Game-Ordner: ~/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt
#
#  Heimat der Detektei »Holmes« (Detektiv Sherlock Holmes, nachts im Bezirk
#  unterwegs – Charakter/SherlockHolmes.sh; seine Assistentin Amanda Nox im
#  Vorzimmer – Charakter/AmandaNox.sh), der Kneipe »Zum Goldenen Lächeln«
#  (Wirt Börty Smiles – Charakter/BörtySmiles.sh; Novize Bill –
#  Charakter/NovizeBill.sh) und Jimmys Haus
#  (Zeitungssammler Jimmy Page – Charakter/JimmyPage.sh).
#
#  Geladen von district.sh, sobald der Spieler den Stadtteil betritt:
#     district_build_ost()    - Welt (Ordner/Dateien/Inhalte/Dialoge)
#     district_enter_ost()    - (optional) beim Betreten
#     district_leave_ost()    - (optional) beim Verlassen
# ============================================================

# Der Stadtteil
OST_PREFIX="$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt"

# --- Welt-Aufbau: Ordner & Dateien dieses Stadtteils -----------------
district_build_ost() {
    # Die Detektei »Holmes« – Büro des Detektivs, geführt von Amanda Nox.
    # Der Ordner wird ohne Leerzeichen geschrieben (DetekteiHolmes).
    local _det="$OST_PREFIX/DetekteiHolmes"
    addp d "$_det"
    addp f "$_det/Amanda"
    CONTENT["$_det/Amanda"]="========================================\n  DETEKTEI HOLMES  //  VORZIMMER\n========================================\nName   : Amanda Nox\nRolle  : Assistentin & Sekretärin\nStatus : im Dienst. Immer.\nOffen  : drei Akten, zwei Termine - und ein Auftrag,\n         von dem sie nichts weiß.\n\nNotiz:\n  »Mr. Holmes sieht den Beweis, bevor er ihn sucht.\n   Ich sehe höchstens, dass der Kaffee kalt wird.«\n\nWer sie berührt (touch Amanda), wird höflich befragt -\nund höflich abgewiesen. (cat Amanda · file Amanda)"
    DIALOG["$_det/Amanda"]="dialog_amanda"

    # Die Kneipe »Zum Goldenen Lächeln« (Wirt Börty Smiles) ---------------
    # Der Ordner wird ohne Leerzeichen geschrieben (KneipeZumGoldenenLächeln).
    # Börty steht als beseelte Datei an der Theke und wird mit »touch Börty«
    # angesprochen (Charakter/BörtySmiles.sh).
    local _kneipe="$OST_PREFIX/KneipeZumGoldenenLächeln"
    addp d "$_kneipe"
    addp f "$_kneipe/Börty"
    CONTENT["$_kneipe/Börty"]="========================================\n  SCHANKBETRIEB  //  ZUM GOLDENEN LÄCHELN\n========================================\nWirt   : Börty Smiles\nHaus   : seit drei Generationen. Angeblich.\nStatus : geöffnet. Immer.\nOffen  : die Theke, das Ohr und ein Fass ohne Boden.\n\nNotiz:\n  »Ein Lächeln kostet nichts – deshalb hat es\n   fast jeder. Verkaufen lässt es sich trotzdem.«\n\nWer ihn berührt (touch Börty), bekommt ein Lächeln\nund einen Satz, der länger hält als der Abend."
    DIALOG["$_kneipe/Börty"]="dialog_boerty"

    # Novize Bill sitzt in der Ecke am Fass. Er gehört zu einer seltenen
    # Religion und wird erst im Rahmen der Quest »Seltsame Religion«
    # gesprächig (Charakter/NovizeBill.sh).
    addp f "$_kneipe/NovizeBill"
    CONTENT["$_kneipe/NovizeBill"]="========================================\n  GAST  //  NOVIZE BILL\n========================================\nRolle  : Gast. Angeblich nur Gast.\nZustand: angeheitert, seit einer Weile.\nOffen  : ein leeres Glas und ein Name,\n         den er nicht nennt.\n\nNotiz:\n  »Schweigen ist auch eine Form des Betens.\n   Aber Bier macht das Schweigen erträglicher.«\n\nWer ihn berührt (touch NovizeBill), hört von einer\nseltenen Gemeinde - und von einem verlorenen Meister."
    DIALOG["$_kneipe/NovizeBill"]="dialog_novize_bill"

    # Jimmys Haus: eigener Ordner, eigener Aufbau in Orte/JimmysHaus.sh.
    # Drinnen sitzt der Zeitungssammler Jimmy Page (Charakter/JimmyPage.sh).
    require_ort JimmysHaus
    jimmys_haus_build "$OST_PREFIX/JimmysHaus"

    # Sherlock Holmes selbst liegt NICHT im Büro: er ist nur nachts draußen
    # im Bezirk zu finden. Das regelt Charakter/SherlockHolmes.sh (nach Zeit).
    sherlock_schedule_apply

    # Tracey Briggs steht zuerst vor Jimmys Haus. Nach Rachels Auftrag und
    # dem Fund wechselt sie in den DailyPulse-Verlag; sobald Rachel die
    # Sperrzone-Bündel übergibt, ist sie wieder hier
    # (Charakter/TraceyBriggs.sh).
    # Der Guard hält die Stadtteil-Datei auch ohne das Charakter-Modul nutzbar
    # (z. B. in den Unit-Tests).
    declare -F tracey_apply_state >/dev/null 2>&1 && tracey_apply_state

    # Jack Nullpunkt wechselt mit der Nebenquest »Unterstützung für Amanda«
    # aus dem DailyPulse-Verlag in die Detektei Holmes (Charakter/verlag.sh).
    declare -F jack_apply_state >/dev/null 2>&1 && jack_apply_state

    # Ein Bits-Haufen zwischen Detektei und Kneipe (12 Bits). Aufgenommen
    # wird er mit »grep Bits« - der Befehl muss dafür erlernt sein.
    world_item_place bits "$OST_PREFIX/Bits" 12

    # Eine Sitzbank im Bezirk (Interior/Möbel/Sitzgelegenheiten/Sitzbank.sh).
    interior_place sitzbank "$OST_PREFIX/Sitzbank"

    # Der DailyPulse-Zeitungskasten des Bezirks (Interior/Stadt/Zeitungskasten.sh).
    zeitungskasten_place "$OST_PREFIX"
}

# --- Betreten: kurze Ortsbeschreibung (nicht blockierend) -----------
district_enter_ost() {
    OUT+=("")
    OUT+=("── Ostdistrikt ──  der Bezirk, in dem die Detektei Holmes liegt.")
    OUT+=("Graue Fassaden, Aktenkeller, Laternen, die erst spät angehen.")
    OUT+=("In der Gasse: die Kneipe »Zum Goldenen Lächeln« von Börty Smiles.")
    OUT+=("Weiter hinten steht Jimmys Haus – und davor oft Tracey mit ihrem Zeitungskorb.")
    OUT+=("Tagsüber ist hier nicht viel los – nachts ist Holmes selbst unterwegs.")
}

# --- Verlassen: zurück Richtung Haupttor (die Basis übernimmt wieder)
district_leave_ost() {
    OUT+=("")
    OUT+=("── Du verlässt den Ostdistrikt und gehst zurück Richtung Haupttor. ──")
}
