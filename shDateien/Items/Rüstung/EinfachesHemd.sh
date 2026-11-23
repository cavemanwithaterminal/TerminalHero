# ============================================================
#  TerminalHero - Item: Einfaches Hemd
#
#  Kategorie: Rüstung. Teil des Einfachen Sets.
#  Ein festes Hemd mit doppelt genähten Nähten. Es ist kein Panzer,
#  aber es hält den Agenten länger auf den Beinen.
#
#  Werte: +5 maximale Tokens, Kaufpreis 50 Bits.
# ============================================================

item_define einfacheshemd ruestung \
    "Einfaches Hemd" \
    "Ein grobes Hemd aus festem Stoff, an den Schultern doppelt vernäht. Die Ärmel sind hochgekrempelt, als hätte der Vorbesitzer nie vorgehabt, sie wieder herunterzulassen.\n\nTeil des Einfachen Sets.\nWerte: +5 maximale Tokens.\nSet-Bonus (vollständig): +25 maximale Tokens." \
    50

item_flag einfacheshemd unique   1
item_flag einfacheshemd sellable 1

equip_define_item einfacheshemd oberkoerper
equip_effect_tokens_max einfacheshemd 5
