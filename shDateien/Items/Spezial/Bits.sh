# ============================================================
#  TerminalHero - Item: Bits (Geld)
#
#  Kategorie: Spezial. Die Währung der Stadt heißt »Bit« (Einzahl) /
#  »Bits« (Mehrzahl); das Register dazu steht in kern/items.sh
#  (BITS, bits_add, bits_take, bits_text).
#
#  WICHTIG: Dieses Item wandert NICHT ins Inventar. Es steht nur für
#  Geld-Haufen in der Welt und wird wie jeder andere Fundort mit
#  »grep Bits« herausgezogen – der Haufen verschwindet, der Zähler BITS
#  steigt. Wie viel ein solcher Haufen bringt, steht NICHT hier, sondern
#  am Fundort (world_item_place bits <pfad> <menge>): Das Item selbst hat
#  also keinen festen Wert (item_define bleibt beim Standardwert 0).
#
#  Damit es nicht doch im Inventar landet, übernimmt es das Aufheben
#  selbst: Haken item_pickup_<id> (kern/items.sh, world_item_pickup).
#
#  Eingerichtet wird es am Fundort, nicht hier: in der eingestürzten
#  Baracke (Orte/Süddistrikt.sh), im Download-Ordner und in den
#  Basis-Orten (TerminalShell.sh, u. a. 15 Bits zu Hause, 50 Bits in
#  der KöniginnenKammer). Jeder weitere Ort ohne Haufen bekommt in
#  TerminalShell.sh einen kleinen Haufen (5–25 Bits).
# ============================================================

item_define bits spezial \
    "Bits" \
    "Die Währung der Stadt: ein abgegriffener Rechenstein, klein genug für jede Manteltasche – und überall gültig."

# --- Aufheben (»grep Bits«) -------------------------------------------
# Geld ist kein Inventar-Gegenstand: Statt inv_add landet die Menge auf
# dem Kontostand. $1 = id, $2 = Pfad des Fundorts, $3 = Anzahl (vom
# Fundort, nicht vom Item). Der Haufen verschwindet wie jeder Fundort
# (WORLD_TAKEN). Rückgabe 0 = Aufheben ist erledigt.
item_pickup_bits() {   # $1 = id, $2 = pfad, $3 = anzahl
    local p="$2" n="${3:-0}"
    WORLD_TAKEN["$p"]=1
    world_item_remove "$p"
    bits_add "$n"
    play_sound select
    OUT+=("")
    OUT+=("» $(bits_text "$n") aufgesammelt.")
    OUT+=("   [ Bits ]  Stand: $(bits_text "$(bits_count)")")
    return 0
}
