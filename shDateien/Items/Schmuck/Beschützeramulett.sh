# ============================================================
#  TerminalHero - Item: Beschützeramulett
#
#  Kategorie: Schmuck. Teil des Beschützersets.
#
#  Werte: +35 maximale Tokens, +1 Schadensreduktion, Kaufpreis 150 Bits.
# ============================================================

item_define beschützeramulett schmuck \
    "Beschützeramulett" \
    "Ein robustes Amulett an schwerer Kette. Ein in den Anhänger eingelassener Kristall pulsiert schützend im Takt des Trägers.\n\nTeil des Beschützersets.\nWerte: +35 maximale Tokens, +1 Schadensreduktion.\nSet-Bonus (vollständig): +50 maximale Tokens, +2 Schadensreduktion." \
    150

item_flag beschützeramulett sellable 1

equip_define_item beschützeramulett amulett
equip_effect_tokens_max beschützeramulett 35
equip_effect_damage_reduction beschützeramulett 1
