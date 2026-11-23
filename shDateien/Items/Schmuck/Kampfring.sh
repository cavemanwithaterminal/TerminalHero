# ============================================================
#  TerminalHero - Item: Kampfring
#
#  Kategorie: Schmuck. Teil des Kampfsets.
#  Ein schwerer Ring aus geschwärztem Eisen. Er sitzt kühl am
#  Finger und wird warm, sobald die Tokens wieder fließen.
#
#  Werte: +15 maximale Tokens, +1 Token pro Regenerationsintervall
#  (60 s), Kaufpreis 100 Bits.
# ============================================================

item_define kampfring schmuck \
    "Kampfring" \
    "Ein breiter Ring aus geschwärztem Eisen, ohne Stein und ohne Verzierung. Nur eine schmale Rille läuft um die Außenseite, als hätte jemand eine Kerbe hineingeschliffen. Er fühlt sich kühl an - bis die Energie wieder in die Finger zurückkehrt.\n\nTeil des Kampfsets.\nWerte: +15 maximale Tokens, +1 Token pro Regenerationsintervall (60 s).\nSet-Bonus (vollständig): +35 maximale Tokens, +1 Token/60 s, −1 eingehender Schaden." \
    100

item_flag kampfring unique   1
item_flag kampfring sellable 1

equip_define_item kampfring ring1 ring2
equip_effect_tokens_max kampfring 15
equip_effect_token_regen kampfring 1
