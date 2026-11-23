# ============================================================
#  TerminalHero - Nutzbares Item: Fackel
# ------------------------------------------------------------
#  Kategorie: Plunder. Die große Fackel ist ein tragbares Licht.
#
#  BENUTZEN (Inventar -> Enter/e -> »benutzen«):
#  Ein Exemplar wird verbraucht und angezündet. Es brennt acht
#  Spielstunden. Solange es brennt, zeigt das rechte Ordner-Fenster
#  den Inhalt des aktuellen Ordners automatisch an - ganz ohne »ls«.
#  Versteckte Dateien bleiben dabei verborgen; »ls -a« zeigt sie
#  weiterhin, wenn der Agent es ausdrücklich will.
#
#  Brennt bereits eine Fackel, wird keine weitere verbraucht: Der
#  Agent bekommt nur den Hinweis, dass es schon hell genug ist.
#
#  ABLEGEN: Die Fackel wird (wie jeder Inventar-Gegenstand) in den
#  aktuellen Ordner gelegt und kann dort mit »grep Fackel« wieder
#  aufgenommen werden.
#
#  Die Datei heißt Fackel2.sh; der Item-Name ist »Fackel«.
#  Fackel.sh daneben ist nur ein Hinweis auf die Fackel-Dateien.
# ============================================================

item_define fackel2 plunder \
    "Fackel" \
    "Ein langer Holzstab mit einem dick gewickelten Stoffkopf, getränkt mit etwas, das nach Teer und altem Öl riecht. Sie brennt nicht schön, aber sie brennt - und gut acht Spielstunden lang.\n\nIm Inventar benutzen, um sie anzuzünden. Solange sie brennt, zeigt das Ordner-Fenster den Inhalt automatisch an." \
    35

# BENUTZEN: Fackel verbrauchen und acht Stunden brennen lassen.
# Die Mechanik (Brenndauer, automatische Ordneransicht) steckt in
# kern/fackel.sh.
item_use_fackel2() {
    fackel_use fackel2 8
}
