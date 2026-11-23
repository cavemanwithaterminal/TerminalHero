# ============================================================
#  TerminalHero - Item: Sperrzone-Bündel
#
#  Kategorie: Quest. Fünf verschnürte Pakete der zweiten DailyPulse-
#  Ausgabe »Sperrzone«. Rachel gibt sie dem Agenten zusammen mit dem
#  Zeitungskastenschlüssel (Charakter/verlag.sh); jedes Bündel füllt
#  genau einen der fünf Zeitungskästen (Interior/Stadt/Zeitungskasten.sh).
#
#  Nicht einmalig (fünf Exemplare), unverkäuflich. Nach dem Befüllen
#  aller Kästen bleibt kein Bündel übrig.
# ============================================================

item_define sperrzonebuendel quest \
    "Sperrzone-Bündel" \
    "Ein straff verschnürtes Paket frisch gedruckter DailyPulse-Ausgaben. Der Titel »Sperrzone« ist noch warm vom Druck, die Kanten sind sauber gefalzt.\n\nRachel hat fünf davon gepackt – eines für jeden Bezirk. Der Knoten sitzt fest; man braucht keine Schere, nur Geduld." \
    0

item_flag sperrzonebuendel unique   0
item_flag sperrzonebuendel sellable 0
