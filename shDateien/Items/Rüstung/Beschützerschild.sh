# ============================================================
#  TerminalHero - Item: Beschützerschild
#
#  Kategorie: Rüstung. Teil des Beschützersets.
#
#  Werte: +12 maximale Tokens, +3 Schadensreduktion, 9 % Blockchance, Kaufpreis 150 Bits.
# ============================================================

item_define beschützerschild ruestung \
    "Beschützerschild" \
    "Ein schwerer Turmschild aus verstärktem Stahl. Er bietet exzellenten Schutz und kann Angriffe zuverlässig abblocken.\n\nTeil des Beschützersets.\nWerte: +12 maximale Tokens, −3 eingehender Schaden, 9 % Blockchance.\nSet-Bonus (vollständig): +50 maximale Tokens, +2 Schadensreduktion." \
    150

item_flag beschützerschild sellable 1

equip_define_item beschützerschild linke_hand rechte_hand
equip_effect_tokens_max beschützerschild 12
equip_effect_damage_reduction beschützerschild 3
equip_effect_block_chance beschützerschild 9
