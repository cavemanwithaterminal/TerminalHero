# ============================================================
#  TerminalHero - Item: Kopf einer Molerat Königin
#
#  Kategorie: Plunder. Beute der MoleratKönigin in der
#  KöniginnenKammer (Gegner/MoleratKoenigin.sh). Die Königin
#  respawnt nicht – der Kopf ist damit einmalig pro Spielstand,
#  aber nicht als »unique« markiert: Wer ihn verkauft, kann ihn
#  nicht erneut finden.
#
#  Wert: 200 Bits. Der Wert ist der KAUFPREIS beim Händler; beim
#  Verkauf zahlt der Händler den halben Wert (100 Bits).
# ============================================================

item_define kopf_moleratkoenigin plunder \
    "Kopf einer Molerat Königin" \
    "Der massive Schädel der MoleratKönigin, sauber abgetrennt und noch immer von einer trockenen, ledrigen Haut überzogen. Die Nagezähne sind so lang wie ein Finger, die Augenhöhlen leer und schwarz. Für einen Sammler oder einen eitlen Jäger ist er ein Vermögen – für jeden anderen nur ein schwerer, unangenehmer Klumpen.\n\nBeute der MoleratKönigin in der KöniginnenKammer." \
    200

item_flag kopf_moleratkoenigin sellable 1
