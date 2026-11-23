# ============================================================
#  TerminalHero - Item: Kampfamulett
#
#  Kategorie: Schmuck. Teil des Kampfsets.
#  Ein Amulett aus geschwärztem Metall mit einem roten Glasstein.
#  Es speichert keinen Zauber, nur Energie - und gibt sie langsam
#  wieder ab.
#
#  Werte: +30 maximale Tokens, Kaufpreis 100 Bits.
# ============================================================

item_define kampfamulett schmuck \
    "Kampfamulett" \
    "Ein flacher Anhänger aus geschwärztem Metall, in dessen Mitte ein roter Glasstein sitzt. Das Glas ist trüb und von feinen Rissen durchzogen. Wer es länger trägt, spürt ein gleichmäßiges Pulsieren - kein Herzschlag, sondern etwas, das nur darauf wartet, gebraucht zu werden.\n\nTeil des Kampfsets.\nWerte: +30 maximale Tokens.\nSet-Bonus (vollständig): +35 maximale Tokens, +1 Token/60 s, −1 eingehender Schaden." \
    100

item_flag kampfamulett unique   1
item_flag kampfamulett sellable 1

equip_define_item kampfamulett amulett
equip_effect_tokens_max kampfamulett 30
