# ============================================================
#  TerminalHero - Item: Kettenhose
#
#  Kategorie: Rüstung. Teil des Kampfsets.
#  Eine schwere Hose aus demselben Ringgeflecht wie das Kettenhemd.
#  Sie ist unbequem und macht jedes Treppenhaus zur Aufgabe.
#
#  Werte: +8 maximale Tokens, −1 eingehender Schaden,
#  Kaufpreis 80 Bits.
# ============================================================

item_define kettenhose ruestung \
    "Kettenhose" \
    "Eine dunkle Hose aus engem Kettengeflecht, mit Lederriemen an den Knien und einem Futter aus grobem Stoff. Sie ist schwer, unbequem und genau deshalb an den Beinen, wo ein Treffer sonst am schnellsten durchgeht.\n\nTeil des Kampfsets.\nWerte: +8 maximale Tokens, −1 eingehender Schaden.\nSet-Bonus (vollständig): +35 maximale Tokens, +1 Token/60 s, −1 eingehender Schaden." \
    80

item_flag kettenhose unique   1
item_flag kettenhose sellable 1

equip_define_item kettenhose beine
equip_effect_tokens_max kettenhose 8
equip_effect_damage_reduction kettenhose 1
