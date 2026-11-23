# ============================================================
#  TerminalHero - Item: Kampfschild
#
#  Kategorie: Rüstung. Teil des Kampfsets.
#  Ein schwerer Schild aus genieteten Stahlplatten. Er passt in
#  beide Hand-Slots, reduziert eingehenden Schaden deutlich und
#  blockt gelegentlich einen ganzen Angriff.
#
#  Werte: +9 maximale Tokens, −2 eingehender Schaden,
#  6 % Blockchance, Kaufpreis 90 Bits.
# ============================================================

item_define kampfschild ruestung \
    "Kampfschild" \
    "Ein rechteckiger Schild aus drei genieteten Stahlplatten, mit einem abgeschliffenen Rand und einem Lederriemen, der schon bessere Tage gesehen hat. Bruno hat ihn so gebaut, dass man ihn auch dann noch festhält, wenn die Hand längst müde ist.\n\nTeil des Kampfsets.\nWerte: +9 maximale Tokens, −2 eingehender Schaden, 6 % Blockchance.\nSet-Bonus (vollständig): +35 maximale Tokens, +1 Token/60 s, −1 eingehender Schaden." \
    90

item_flag kampfschild unique   1
item_flag kampfschild sellable 1

equip_define_item kampfschild linke_hand rechte_hand
equip_effect_tokens_max kampfschild 9
equip_effect_damage_reduction kampfschild 2
equip_effect_block_chance kampfschild 6
