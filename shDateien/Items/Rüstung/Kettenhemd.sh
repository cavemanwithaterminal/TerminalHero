# ============================================================
#  TerminalHero - Item: Kettenhemd
#
#  Kategorie: Rüstung. Teil des Kampfsets.
#  Schwer, eng gewebt und an den Schultern verstärkt. Es schluckt
#  einen Teil des Aufpralls, bevor er die Tokens erreicht.
#
#  Werte: +9 maximale Tokens, −1 eingehender Schaden,
#  Kaufpreis 90 Bits.
# ============================================================

item_define kettenhemd ruestung \
    "Kettenhemd" \
    "Ein schweres Hemd aus tausenden kleinen Eisenringen, an den Schultern doppelt gewebt. Beim Gehen klirrt es leise. Bruno hat die Ringe selbst geschlossen und an den Stellen verstärkt, an denen ein Messer gern zuerst ansetzt.\n\nTeil des Kampfsets.\nWerte: +9 maximale Tokens, −1 eingehender Schaden.\nSet-Bonus (vollständig): +35 maximale Tokens, +1 Token/60 s, −1 eingehender Schaden." \
    90

item_flag kettenhemd unique   1
item_flag kettenhemd sellable 1

equip_define_item kettenhemd oberkoerper
equip_effect_tokens_max kettenhemd 9
equip_effect_damage_reduction kettenhemd 1
