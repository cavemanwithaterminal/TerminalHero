# ============================================================
#  TerminalHero - Item: Beschützerhose
#
#  Kategorie: Rüstung. Teil des Beschützersets.
#
#  Werte: +16 maximale Tokens, +1 Schadensreduktion, Kaufpreis 130 Bits.
# ============================================================

item_define beschützerhose ruestung \
    "Beschützerhose" \
    "Eine robuste Beinharnisch aus verstärktem Kettengeflecht und Leder. Schützt gut, ohne die Beweglichkeit zu sehr einzuschränken.\n\nTeil des Beschützersets.\nWerte: +16 maximale Tokens, −1 eingehender Schaden.\nSet-Bonus (vollständig): +50 maximale Tokens, +2 Schadensreduktion." \
    130

item_flag beschützerhose sellable 1

equip_define_item beschützerhose beine
equip_effect_tokens_max beschützerhose 16
equip_effect_damage_reduction beschützerhose 1
