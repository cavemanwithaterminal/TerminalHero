# ============================================================
#  TerminalHero - Item: Einfache Mütze
#
#  Kategorie: Rüstung. Teil des Einfachen Sets.
#  Eine robuste Kopfbedeckung aus geflicktem Stoff. Sie schützt
#  nicht vor Viren, aber sie gibt dem Agenten etwas Halt.
#
#  Werte: +3 maximale Tokens, Kaufpreis 25 Bits.
# ============================================================

item_define einfachemuetze ruestung \
    "Einfache Mütze" \
    "Eine weiche Mütze aus dunklem, mehrfach geflicktem Stoff. Sie riecht nach Staub und altem Regen. Nicht schön, aber sie sitzt gut - und in dieser Stadt zählt jede kleine Rüstung.\n\nTeil des Einfachen Sets.\nWerte: +3 maximale Tokens.\nSet-Bonus (vollständig): +25 maximale Tokens." \
    25

item_flag einfachemuetze unique   1
item_flag einfachemuetze sellable 1

equip_define_item einfachemuetze kopf
equip_effect_tokens_max einfachemuetze 3
