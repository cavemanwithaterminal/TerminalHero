# ============================================================
#  TerminalHero - Item: Pixis Brief
#
#  Kategorie: Quest. EINMALIG und UNVERKÄUFLICH - der Brief wird nicht
#  gehandelt, er wird abgegeben (an Sherlock Holmes, Detektei Holmes im
#  Ostdistrikt).
#
#  Der Agent bekommt ihn im Verlag von Pixi (Charakter/pixi.sh,
#  pixi_letter_scene) - zusammen mit der Hauptquest »Großer Ermittler«.
#  Der Brief liegt NICHT in der Welt herum; er ist von Anfang an im
#  Inventar. Den Text der Seite zeigt das Inventar-Fenster (Beschreibung).
# ============================================================

item_define pixisbrief quest \
    "Pixis Brief" \
    "Ein fest zusammengefalteter Bogen in einem Umschlag, mit Klebeband gegen Feuchtigkeit und neugierige Hände versiegelt.\nAbsender: Pixi Nullpunkt, /var/log/daily-pulse.\nEmpfänger: Sherlock Holmes, Detektei Holmes, Ostdistrikt.\n\n»Mr. Holmes,\nich war in der Sperrzone – kurz, ohne Erlaubnis und ohne Kamera. Was ich gesehen habe, passt in keinen Artikel: ein Muster, das sich bewegt, ohne einen Namen zu haben. Ich habe es aufgeschrieben, so gut ich konnte. Der Rest ist ein Verdacht, und Verdachtsstücke schreibe ich nicht.\n\nWenn jemand aus einem Verdacht einen Beweis machen kann, dann Sie.\nP. Nullpunkt«"

# Einmalig und unverkäuflich.
item_flag pixisbrief unique   1
item_flag pixisbrief sellable 0
