# ============================================================
#  TerminalHero - Nutzbares Item: Einfacher Schlafsack
# ------------------------------------------------------------
#  Kategorie: Plunder. Kein Einzelstück: Der Agent kann mehrere
#  Schlafsäcke besitzen und einen nach dem anderen ablegen.
#
#  Im Spielstand liegt der Schlafsack NICHT automatisch im Inventar.
#  Er wird - wie jeder andere Gegenstand - mit »grep« von einem
#  Fundort aufgehoben oder bei Jack Bones im SurvivalShop gekauft (200 Bits).
#
#  BENUTZEN (Inventar -> Enter/e -> »benutzen«):
#  Genau wie »ablegen«: EIN Exemplar wandert in den aktuellen Ordner.
#  Dort liegt es wieder als Fundort und kann mit
#  »grep EinfacherSchlafsack« erneut aufgenommen werden. Das ist der
#  Unterschied zu den festen Interior-Schlafplätzen (Matratze, Bett,
#  Doppelbett): Der Schlafsack ist ein Item, kein Möbelstück.
#
#  Zum Schlafen muss der Schlafsack NICHT benutzt werden. Er ist ein
#  Gegenstand zum Mitnehmen; die Schlaf-Mechanik bleibt bei den
#  Interior-Objekten (»use Matratze« / »use Bett« / ...).
#
#  Angemeldet über item_define (kern/items.sh); die Benutzung läuft
#  über den optionalen Haken item_use_<id> (InGameBefehle/Inventar.sh).
# ============================================================

item_define einfacherschlafsack plunder \
    "Einfacher Schlafsack" \
    "Ein dünner, zusammengerollter Schlafsack aus abgewetztem olivgrünem Stoff. Der Reißverschluss klemmt an einer Stelle, dafür ist der Stoff trocken und die Naht am Fußende hält. Zusammengeschnürt passt er fast in eine Manteltasche.\n\nIm Inventar benutzen, um ihn im aktuellen Ordner abzulegen. Dort kann er mit »grep EinfacherSchlafsack« wieder aufgenommen werden." \
    200

# BENUTZEN = ABLEGEN: Ein Exemplar in den aktuellen Ordner.
item_use_einfacherschlafsack() {
    world_item_drop einfacherschlafsack 1
}
