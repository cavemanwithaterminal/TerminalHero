# ============================================================
#  TerminalHero - Item: Zeitungsbündel
#
#  Kategorie: Quest. Fünf Bündel sind nötig, um Jacks Quest
#  »Die langweiligste Ausgabe« abzuschließen. Jedes Bündel kommt aus
#  einem geleerten Zeitungskasten (Interior/Stadt/Zeitungskasten.sh);
#  Jack will das Papier wiederverwenden.
#
#  Nicht einmalig (bis zu fünf Exemplare), unverkäuflich. Abgegeben
#  werden die Bündel bei Jack im DailyPulse-Verlag (Charakter/verlag.sh).
# ============================================================

item_define zeitungsbuendel quest \
    "Zeitungsbündel" \
    "Ein straff verschnürtes Paket alter DailyPulse-Ausgaben: »Bezirke der Stadt«, sauber gefaltet, mit einem Knoten, der sich nur widerwillig öffnen lässt.\n\nDas Papier ist noch gut. Der Inhalt ist es nicht. Jack will beides voneinander trennen: den Inhalt löschen, das Papier behalten.\n\nFünf dieser Bündel braucht er, eines aus jedem Bezirk." \
    0

item_flag zeitungsbuendel unique   0
item_flag zeitungsbuendel sellable 0
