# ============================================================
#  TerminalHero - Item: Bündel Leeres Papier
#
#  Kategorie: Plunder. Ein verschnürtes Bündel aus 100 leeren
#  DailyPulse-Blättern - dasselbe Papier wie das einzelne Blatt,
#  nur in der Menge, die Jack für eine neue Ausgabe braucht.
#
#  Wert: 200 Bits. Der Wert ist der KAUFPREIS beim Händler
#  (Handelsfenster.sh). Verkauft der Agent das Bündel wieder, zahlt
#  der Händler den halben Wert (100 Bits).
#
#  Anmeldung über item_define (siehe kern/items.sh). Jack bietet
#  pro Spieltag genau EIN Bündel an (Charakter/verlag.sh, »Handeln.«).
# ============================================================

item_define papierbuendel plunder \
    "Bündel Leeres Papier" \
    "Ein fest verschnürtes Bündel aus hundert leeren DailyPulse-Blättern. Jack hat die Kanten zweimal ausgerichtet und den Knoten so gezogen, dass er sich mit zwei Fingern löst. Genug Papier für eine ganze Ausgabe – oder für hundert sehr kurze Briefe." \
    200
