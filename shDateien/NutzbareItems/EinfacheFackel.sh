# ============================================================
#  TerminalHero - Nutzbares Item: Einfache Fackel
# ------------------------------------------------------------
#  Kategorie: Plunder. Die Fackel ist ein tragbares Licht.
#
#  BENUTZEN (Inventar -> Enter/e -> »benutzen«):
#  Ein Exemplar wird verbraucht und angezündet. Es brennt FACKEL_HOURS
#  (3) SPIELSTUNDEN. Solange es brennt, zeigt das rechte Ordner-Fenster
#  den Inhalt des aktuellen Ordners automatisch an - ganz ohne »ls«.
#  Versteckte Dateien bleiben dabei verborgen; »ls -a« zeigt sie
#  weiterhin, wenn der Agent es ausdrücklich will.
#
#  Brennt bereits eine Fackel, wird keine weitere verbraucht: Der Agent
#  bekommt nur den Hinweis, dass es schon hell genug ist.
#
#  ABLEGEN: Die Fackel wird (wie jeder Inventar-Gegenstand) in den
#  aktuellen Ordner gelegt und kann dort mit »grep EinfacheFackel«
#  wieder aufgenommen werden. Ob sie dabei brennt oder nicht, ist
#  Sache des Agenten - die Brenndauer hängt an SEINEM Licht, nicht
#  am Gegenstand im Ordner (kern/fackel.sh).
#
#  Die Datei heißt EinfacheFackel.sh; der Item-Name ist »Einfache
#  Fackel«. Fackel.sh daneben ist nur ein Hinweis auf diese Datei.
# ============================================================

item_define fackel plunder \
    "Einfache Fackel" \
    "Ein kurzer Holzstab mit einem fest gewickelten Stoffkopf, getränkt mit etwas, das nach Teer und altem Öl riecht. Sie brennt nicht schön, aber sie brennt. Für drei Spielstunden reicht der Vorrat.\n\nIm Inventar benutzen, um sie anzuzünden. Solange sie brennt, zeigt das Ordner-Fenster den Inhalt automatisch an." \
    20

# BENUTZEN: Fackel verbrauchen und anzünden. Die Mechanik
# (Brenndauer, automatische Ordneransicht) steckt in kern/fackel.sh.
item_use_fackel() {
    fackel_use fackel 3
}
