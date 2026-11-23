# ============================================================
#  TerminalHero - Item: Beschützerhelm
#
#  Kategorie: Rüstung. Teil des Beschützersets.
#
#  Werte: +8 maximale Tokens, +1 Schadensreduktion, Kaufpreis 80 Bits.
# ============================================================

item_define beschützerhelm ruestung \
    "Beschützerhelm" \
    "Ein stabiler Helm aus gehärtetem Stahl mit verstärktem Nackenbereich. Solide Verteidigung für den Kopf.\n\nTeil des Beschützersets.\nWerte: +8 maximale Tokens, −1 eingehender Schaden.\nSet-Bonus (vollständig): +50 maximale Tokens, +2 Schadensreduktion." \
    80

item_flag beschützerhelm sellable 1

equip_define_item beschützerhelm kopf
equip_effect_tokens_max beschützerhelm 8
equip_effect_damage_reduction beschützerhelm 1
