# ============================================================
#  TerminalHero - Item: Einfaches Schwert
#
#  Kategorie: Waffen. Teil des Einfachen Sets.
#  Eine schlichte Klinge für den ersten Kampf. Sie passt in beide
#  Hand-Slots und darf nur Viren löschen - freundliche Dateien
#  (Kategorie »datei«) bleiben unberührt.
#
#  Werte: +5 maximale Tokens, Kaufpreis 50 Bits.
# ============================================================

item_define einfachesschwert waffen \
    "Einfaches Schwert" \
    "Eine kurze, geradlinige Klinge mit abgenutztem Griff. Kein Schmuckstück, sondern ein Werkzeug: gemacht, um Viren aus dem Dateisystem zu schneiden. Freundliche Dateien lässt sie in Ruhe.\n\nTeil des Einfachen Sets.\nWerte: +5 maximale Tokens; kann nur Viren löschen.\nSet-Bonus (vollständig): +25 maximale Tokens." \
    50

item_flag einfachesschwert unique   1
item_flag einfachesschwert sellable 1

equip_define_item einfachesschwert rechte_hand linke_hand
equip_effect_tokens_max einfachesschwert 5
equip_effect_combat einfachesschwert virus
