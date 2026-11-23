# ============================================================
#  TerminalHero - Item: Beschützerklinge
#
#  Kategorie: Waffen. Teil des Beschützersets.
#
#  Werte: +15 maximale Tokens, Kaufpreis 150 Bits.
# ============================================================

item_define beschützerklinge waffen \
    "Beschützerklinge" \
    "Eine schlanke, gut ausgewogene Klinge aus gehärtetem Stahl. Sie ist auf Präzision ausgelegt und durchdringt Viren mit besonderer Effizienz.\n\nTeil des Beschützersets.\nWerte: +15 maximale Tokens; kann nur Viren löschen.\nSet-Bonus (vollständig): +50 maximale Tokens, +2 Schadensreduktion." \
    150

item_flag beschützerklinge sellable 1

equip_define_item beschützerklinge rechte_hand linke_hand
equip_effect_tokens_max beschützerklinge 15
equip_effect_combat beschützerklinge virus
