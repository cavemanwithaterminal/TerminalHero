# ============================================================
#  TerminalHero - Lesbares Item: DailyPulse-Ausgabe »Bezirke der Stadt«
#
#  Kategorie: Quest. Die erste Ausgabe der letzten Zeitung der Stadt.
#  Geschrieben hat sie Jack Nullpunkt, Pixis Bruder - ein Mann, der
#  lieber zweimal rechnet als einmal zu hoffen, aber offenbar auch
#  lieber jede Straße einzeln aufzählt, als eine Geschichte zu erzählen.
#
#  Gekauft wird die Ausgabe an den fünf Zeitungskästen in den Bezirken
#  (Interior/Stadt/Zeitungskasten.sh) für 10 Bits. Mehrfachkauf ist
#  ausdrücklich erlaubt: Der Kasten füllt sich nicht leer, solange die
#  aktuelle Ausgabe läuft. Erst Jacks Quest (Charakter/verlag.sh) lässt
#  die Kästen leeren.
#
#  Lesen: Im Inventar wählen -> Enter/e -> »benutzen«. Der vollständige
#  Artikel steht in InGameBefehle/Lesen.sh; die kurze item_define-
#  Beschreibung bleibt für die Detailspalte des Inventars.
#
#  Nicht einmalig (mehrere Exemplare möglich) und unverkäuflich.
# ============================================================

item_define bezirke quest \
    "Bezirke der Stadt" \
    "DailyPulse · Ausgabe 1 · »Bezirke der Stadt«\nVon Jack Nullpunkt.\n\nEine saubere Aufstellung aller fünf Bezirke: Nord, Süd, West, Ost und Zentrum. Mit Einwohnerzahlen, Straßenverzeichnis, einer Karte und einem Vorwort, in dem Jack erklärt, warum er die Karte für zu ungenau hält.\n\nSeite 7 beginnt mit dem Satz: »Der Norddistrikt liegt im Norden.«\nEs folgen elf Absätze, die diesen Befund vertiefen.\n\nGut recherchiert. Gründlich. Und ungefähr so spannend wie ein Verzeichnis von Verzeichnissen." \
    10

# Mehrere Exemplare sind möglich (der Kasten verkauft mehrfach), aber
# eine Zeitung ist kein Handelsgut.
item_flag bezirke unique   0
item_flag bezirke sellable 0

item_readable bezirke "$(cat <<'ARTIKEL'
DAILYPULSE · AUSGABE 1 · 10 BITS
DIE BEZIRKE DER STADT
Von Jack Nullpunkt

Seite 1 · Die Nordfrage
Der Norddistrikt liegt im Norden.

Diese Feststellung ist das Ergebnis einer dreiwöchigen Untersuchung. Ich habe die Karte dreimal neu gezeichnet, die Himmelsrichtungen mit einem Kompass verglichen und die Aussage eines Straßenhändlers überprüft, der behauptete, der Norden liege »eher hinten links«. Er lag falsch.

Der Norddistrikt grenzt im Süden an das Zentrum, im Westen an den Westdistrikt und im Osten an den Ostdistrikt. Im Norden grenzt er an nichts. Das ist bemerkenswert, weil dort auch die Stadtgrenze liegt. Ich habe beides notiert.

Seite 2 · Der Süden
Der Süddistrikt liegt im Süden.

Hier stehen der DailyPulse-Verlag, vier alte Wohnhäuser und die eingestürzte Baracke. Wer im Süden wohnt, hat es nicht weit zur Arbeit und noch weniger weit zum Lärm. Der Zeitungskasten vor dem Verlag ist der erste Kasten der Stadt, wenn man durch das Tor kommt. Das ist keine politische Aussage, sondern eine Beobachtung.

Seite 3 · Das Zentrum
Das Zentrum liegt in der Mitte.

Das ist die einzige Lage, die sich ohne Kompass überprüfen lässt: Geht man in irgendeine Richtung lange genug weiter, kommt man irgendwann in einen anderen Bezirk. Im Zentrum stehen der Marktplatz, die Stände, der SurvivalShop und eine Sitzbank. Der Marktplatz ist laut. Die Sitzbank ist auch laut, aber nur, wenn jemand darauf sitzt.

Seite 4 · Der Osten
Der Ostdistrikt liegt im Osten.

Dort befinden sich die Detektei Holmes, die Kneipe »Zum Goldenen Lächeln« und Jimmys Haus. Die Straßen sind schmaler als im Zentrum. Das liegt nicht an der Planung, sondern an den Häusern, die zuerst da waren. Wer nachts unterwegs ist, sollte wissen, dass Holmes dann draußen ist. Er glaubt, die Stadt gehöre ihm. Die Stadt hat dazu keine Stellungnahme abgegeben.

Seite 5 · Der Westen
Der Westdistrikt liegt im Westen.

Die Straßen sind breiter, die Fenster höher, und im Restaurant stehen abends Stühle draußen. Das Restaurant ist ein guter Ort, um jemanden zu finden. Es ist ein noch besserer Ort, um jemanden nicht zu finden, der nicht gefunden werden will. Michael Mitch arbeitet dort. Ich habe ihn nicht gefragt, warum. Das gehört nicht in einen Lagebericht.

Seite 6 · Einwohnerzahlen
Für die Einwohnerzahlen habe ich die Fenster gezählt, in denen abends Licht brennt, und die Namen, die ich auf Klingelschildern lesen konnte. Beides ergibt keine exakte Zahl. Ich habe trotzdem eine Tabelle angelegt. Die Tabelle hat fünf Zeilen und eine Fußnote. Die Fußnote lautet: »Nicht alle Einwohner haben ein Klingelschild.«

Seite 7 · Straßenverzeichnis
Der Norddistrikt liegt im Norden.
Der Süddistrikt liegt im Süden.
Das Zentrum liegt in der Mitte.
Der Ostdistrikt liegt im Osten.
Der Westdistrikt liegt im Westen.

Wer diese sieben Zeilen auswendig lernt, kann sich in der Stadt nicht mehr verlaufen. Wer sie rückwärts aufsagt, kann sich vielleicht noch an den Wortlaut erinnern. Mehr verspricht dieses Verzeichnis nicht.

Seite 8 · Karte
Die Karte auf dieser Seite ist maßstabsgetreu, bis auf die Straßen, die ich weggelassen habe, weil sie zu schmal zum Einzeichnen waren. Der Maßstab steht unten rechts. Er ist falsch, weil ich ihn nach dem Zeichnen geändert habe. Die Karte bleibt trotzdem nützlich: Sie zeigt, dass alle fünf Bezirke nebeneinander liegen.

Seite 9 · Wetter
Im Norden ist es still. Im Süden riecht es nach Druckfarbe. Im Zentrum riecht es nach Brot. Im Osten riecht es nach Regen, der nicht fällt. Im Westen riecht es nach Kaffee. Das ist keine Wettervorhersage. Das ist eine Beobachtung aus vier Tagen.

Seite 10 · Anzeigen
Suche eine Karte, die stimmt. Zahle nicht mehr als zehn Bits. Frage nicht, warum.
Verkaufe einen Kompass. Zeigt ungefähr Norden. Preis verhandelbar.
Biete Nachhilfe in Himmelsrichtungen. Nur für Anfänger. Fortgeschrittene lernen es sowieso nicht mehr.

Seite 11 · Impressum
DailyPulse. Chefredaktion: Rachel Nullpunkt.
Redaktion, Satz und Karte: Jack Nullpunkt.
Druck: DailyPulse-Verlag, Süddistrikt.
Erscheinungsweise: so oft, wie Rachel es für nötig hält.

Schlussbemerkung
Ich habe diese Ausgabe geschrieben, damit die Stadt weiß, wo sie liegt. Ich habe sie nicht geschrieben, damit sie sich dabei wohlfühlt. Das ist ein Unterschied, den man auf Seite 7 nachlesen kann.
ARTIKEL
)"
