# ============================================================
#  TerminalHero - Item: Beschützerring
#
#  Kategorie: Schmuck. Teil des Beschützersets.
#
#  Werte: +20 maximale Tokens, +1 Schadensreduktion, Kaufpreis 160 Bits.
# ============================================================

item_define beschützerring schmuck \
    "Beschützerring" \
    "Ein massiver Ring aus poliertem Stahl mit eingravierten Abwehrmustern. Er verstärkt die Abwehr des Trägers spürbar.\n\nTeil des Beschützersets.\nWerte: +20 maximale Tokens, +1 Schadensreduktion.\nSet-Bonus (vollständig): +50 maximale Tokens, +2 Schadensreduktion." \
    160

item_flag beschützerring sellable 1

equip_define_item beschützerring ring1 ring2
equip_effect_tokens_max beschützerring 20
equip_effect_damage_reduction beschützerring 1
