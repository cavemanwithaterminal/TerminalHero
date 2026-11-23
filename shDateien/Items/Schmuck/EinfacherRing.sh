# ============================================================
#  TerminalHero - Item: Einfacher Ring
#
#  Kategorie: Schmuck. Teil des Einfachen Sets.
#  Ein schmaler Ring aus stumpfem Metall. Er passt in Ring1 oder
#  Ring2; für das Set genügt EIN getragener Ring.
#
#  Werte: +10 maximale Tokens, Kaufpreis 50 Bits.
# ============================================================

item_define einfacherring schmuck \
    "Einfacher Ring" \
    "Ein schmaler Ring aus stumpfem, dunklem Metall. Keine Gravur, kein Stein, keine Geschichte. Nur ein sauberer Kreis, der sich warm anfühlt, wenn man ihn länger trägt.\n\nTeil des Einfachen Sets.\nWerte: +10 maximale Tokens.\nSet-Bonus (vollständig): +25 maximale Tokens." \
    50

item_flag einfacherring unique   1
item_flag einfacherring sellable 1

equip_define_item einfacherring ring1 ring2
equip_effect_tokens_max einfacherring 10
