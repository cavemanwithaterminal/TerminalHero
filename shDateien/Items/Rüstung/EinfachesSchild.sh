# ============================================================
#  TerminalHero - Item: Einfaches Schild
#
#  Kategorie: Rüstung. Teil des Einfachen Sets.
#  Ein kleiner, schwerer Schild aus zusammengenieteten Platten.
#  Er passt in beide Hand-Slots und senkt eingehenden Gegnerschaden
#  um 1. Zusätzlich besteht eine 5-%-Chance, einen Angriff komplett
#  zu blocken.
#
#  Werte: +5 maximale Tokens, Kaufpreis 50 Bits.
# ============================================================

item_define einfachesschild ruestung \
    "Einfaches Schild" \
    "Ein kleiner Schild aus drei zusammengenieteten Metallplatten. Die Kanten sind ausgebeult, die Nieten halten trotzdem. Er ist schwer genug, um einen Treffer abzufangen - wenn man ihn rechtzeitig hochbekommt.\n\nTeil des Einfachen Sets.\nWerte: +5 maximale Tokens, −1 eingehender Schaden, 5 % Blockchance.\nSet-Bonus (vollständig): +25 maximale Tokens." \
    50

item_flag einfachesschild unique   1
item_flag einfachesschild sellable 1

equip_define_item einfachesschild linke_hand rechte_hand
equip_effect_tokens_max einfachesschild 5
equip_effect_damage_reduction einfachesschild 1
equip_effect_block_chance einfachesschild 5
