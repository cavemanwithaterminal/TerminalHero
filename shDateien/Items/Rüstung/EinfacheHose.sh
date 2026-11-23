# ============================================================
#  TerminalHero - Item: Einfache Hose
#
#  Kategorie: Rüstung. Teil des Einfachen Sets.
#  Eine abgewetzte Arbeitshose mit verstärkten Knien. Für einen
#  Agenten, der viel läuft und noch mehr einstecken muss.
#
#  Werte: +4 maximale Tokens, Kaufpreis 40 Bits.
# ============================================================

item_define einfachehose ruestung \
    "Einfache Hose" \
    "Eine dunkle Arbeitshose mit verstärkten Knien und einer Tasche, die schon einmal besser geschlossen hat. Der Stoff ist zäh, die Farbe längst nicht mehr.\n\nTeil des Einfachen Sets.\nWerte: +4 maximale Tokens.\nSet-Bonus (vollständig): +25 maximale Tokens." \
    40

item_flag einfachehose unique   1
item_flag einfachehose sellable 1

equip_define_item einfachehose beine
equip_effect_tokens_max einfachehose 4
