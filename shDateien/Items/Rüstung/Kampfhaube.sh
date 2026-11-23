# ============================================================
#  TerminalHero - Item: Kampfhaube
#
#  Kategorie: Rüstung. Teil des Kampfsets.
#  Eine lederne Haube mit aufgenieteten Metallplatten. Sie schützt
#  den Kopf, ohne die Sicht zu nehmen.
#
#  Werte: +5 maximale Tokens, Kaufpreis 40 Bits.
# ============================================================

item_define kampfhaube ruestung \
    "Kampfhaube" \
    "Eine feste Lederhaube mit drei aufgenieteten Metallplatten über Stirn und Schläfen. Sie riecht nach Gerbstoff und kaltem Eisen. Nicht elegant, aber sie sitzt dort, wo ein Schlag sonst wehtut.\n\nTeil des Kampfsets.\nWerte: +5 maximale Tokens.\nSet-Bonus (vollständig): +35 maximale Tokens, +1 Token/60 s, −1 eingehender Schaden." \
    40

item_flag kampfhaube unique   1
item_flag kampfhaube sellable 1

equip_define_item kampfhaube kopf
equip_effect_tokens_max kampfhaube 5
