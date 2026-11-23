# ============================================================
#  TerminalHero - Item: Trainingsklinge
#
#  Kategorie: Spezial. Eine einfache Übungswaffe aus der
#  Trainingsroutine des Agenten. Sie ist noch an keinem Fundort
#  platziert – sie dient als erste ausgerüstete Waffe für Tests und
#  als Vorlage für spätere echte Waffen.
#
#  Kampf-Metadaten: passt in beide Hand-Slots und darf nur Viren
#  löschen. Freundliche Dateien (Kategorie »datei«) bleiben unberührt.
#  Damit lässt sich die Unterscheidung der Waffen prüfen, ohne dass
#  die Trainingsklinge im normalen Spiel auftaucht.
# ============================================================

item_define trainingsklinge spezial \
    "Trainingsklinge" \
    "Eine stumpfe Klinge aus der Trainingsroutine. Sie kann Viren löschen, aber keine befreundeten Dateien. Wer sie trägt, hat wenigstens etwas in der Hand."

item_flag trainingsklinge unique   1
item_flag trainingsklinge sellable 0

equip_define_item trainingsklinge rechte_hand linke_hand
equip_effect_combat trainingsklinge virus
