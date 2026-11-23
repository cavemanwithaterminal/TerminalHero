# ============================================================
#  TerminalHero - Item: Zeitungskastenschlüssel
#
#  Kategorie: Quest. EINMALIG und unverkäuflich. Jack gibt ihn dem
#  Agenten, wenn er dessen Hilfe bei der Aktion »Die langweiligste
#  Ausgabe« annimmt (Charakter/verlag.sh). Für Rachels Verteilung der
#  neuen Ausgabe bekommt der Agent ihn später erneut.
#
#  Mit dem Schlüssel bietet jeder Zeitungskasten die Optionen
#  »Zeitungskasten leeren« (Jacks Quest) und »Zeitungskasten befüllen«
#  (Rachels Auflage) an (Interior/Stadt/Zeitungskasten.sh).
#  Der Schlüssel bleibt danach im Inventar - er gehört zur Redaktion
#  und wird für die nächste Ausgabe wieder gebraucht.
# ============================================================

item_define zeitungsschluessel quest \
    "Zeitungskastenschlüssel" \
    "Ein kleiner, abgegriffener Schlüssel mit einem ovalen Schild aus Messing. Auf dem Schild steht in winzigen Buchstaben: »DAILYPULSE · ALLE BEZIRKE«.\n\nJack hat ihn dir zuerst in die Hand gedrückt, ohne lange zu erklären, wie er funktioniert. Später legt Rachel ihn wieder auf den Tisch: Für die neue Ausgabe braucht sie jemanden, der alle fünf Kästen öffnen kann. Der Schlüssel passt zu den grauen Zeitungskästen in der ganzen Stadt." \
    0

item_flag zeitungsschluessel unique   1
item_flag zeitungsschluessel sellable 0
