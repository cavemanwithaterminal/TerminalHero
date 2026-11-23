# ============================================================
#  TerminalHero - Item: Leeres Blatt Papier
#
#  Kategorie: Plunder. Ein einzelnes, unbeschriebenes Blatt aus
#  dem DailyPulse-Verlag. Jack verkauft es für 2 Bits; das Bündel
#  mit 100 Blättern gibt es separat (Items/Plunder/BuendelLeeresPapier.sh).
#
#  Wert: 2 Bits. Der Wert ist der KAUFPREIS beim Händler
#  (Handelsfenster.sh). Verkauft der Agent das Blatt wieder, zahlt
#  der Händler den halben Wert (1 Bit).
#
#  Anmeldung über item_define (siehe kern/items.sh). Zu kaufen gibt
#  es das Papier bei Jack im DailyPulse-Verlag (Charakter/verlag.sh,
#  »Handeln.«), 100 Blätter pro Spieltag.
# ============================================================

item_define leeresblatt plunder \
    "Leeres Blatt Papier" \
    "Ein sauberes, unbeschriebenes Blatt DailyPulse-Papier. Die Ränder sind gerade, die Rückseite glatt, der Geruch nach Druckerschwärze ist nur noch eine Andeutung. Jack würde sagen: Papier ist teurer als seine Zeit. Bei zwei Bits pro Blatt hat er vermutlich recht." \
    2
