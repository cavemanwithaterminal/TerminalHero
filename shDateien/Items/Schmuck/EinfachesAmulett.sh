# ============================================================
#  TerminalHero - Item: Einfaches Amulett
#
#  Kategorie: Schmuck. Teil des Einfachen Sets.
#  Eine kurze Kette mit einem matt polierten Anhänger. Kein
#  Zauber, kein Fluch - nur ein Stück Metall, das den Agenten
#  ein wenig zäher macht.
#
#  Werte: +13 maximale Tokens, Kaufpreis 50 Bits.
# ============================================================

item_define einfachesamulett schmuck \
    "Einfaches Amulett" \
    "Eine kurze Kette mit einem flachen, matt polierten Metallanhänger. Auf der Rückseite ist eine kleine Kerbe, als hätte jemand ein Zeichen hineingekratzt und es später wieder wegpoliert.\n\nTeil des Einfachen Sets.\nWerte: +13 maximale Tokens.\nSet-Bonus (vollständig): +25 maximale Tokens." \
    50

item_flag einfachesamulett unique   1
item_flag einfachesamulett sellable 1

equip_define_item einfachesamulett amulett
equip_effect_tokens_max einfachesamulett 13
