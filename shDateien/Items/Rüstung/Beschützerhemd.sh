# ============================================================
#  TerminalHero - Item: Beschützerhemd
#
#  Kategorie: Rüstung. Teil des Beschützersets.
#
#  Werte: +14 maximale Tokens, +2 Schadensreduktion, Kaufpreis 150 Bits.
# ============================================================

item_define beschützerhemd ruestung \
    "Beschützerhemd" \
    "Ein schweres Kettenhemd aus fein geschmiedeten Ringen, verstärkt an kritischen Stellen. Bietet hervorragenden Schutz.\n\nTeil des Beschützersets.\nWerte: +14 maximale Tokens, −2 eingehender Schaden.\nSet-Bonus (vollständig): +50 maximale Tokens, +2 Schadensreduktion." \
    150

item_flag beschützerhemd sellable 1

equip_define_item beschützerhemd oberkoerper
equip_effect_tokens_max beschützerhemd 14
equip_effect_damage_reduction beschützerhemd 2
