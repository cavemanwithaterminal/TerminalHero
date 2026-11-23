# ============================================================
#  TerminalHero - Item: Kampfschwert
#
#  Kategorie: Waffen. Teil des Kampfsets.
#  Eine breitere, schwerere Klinge als das Einfache Schwert. Sie
#  passt in beide Hand-Slots und darf nur Viren löschen -
#  freundliche Dateien bleiben unberührt.
#
#  Werte: +10 maximale Tokens, Kaufpreis 80 Bits.
# ============================================================

item_define kampfschwert waffen \
    "Kampfschwert" \
    "Eine breite Klinge aus dunklem Stahl, mit einer schmalen Blutrinne und einem Griff, der schon viele Hände gesehen hat. Kein Prunkstück - ein Werkzeug für Leute, die wissen, dass ein Kampf selten fair beginnt.\n\nTeil des Kampfsets.\nWerte: +10 maximale Tokens; kann nur Viren löschen.\nSet-Bonus (vollständig): +35 maximale Tokens, +1 Token/60 s, −1 eingehender Schaden." \
    80

item_flag kampfschwert unique   1
item_flag kampfschwert sellable 1

equip_define_item kampfschwert rechte_hand linke_hand
equip_effect_tokens_max kampfschwert 10
equip_effect_combat kampfschwert virus
