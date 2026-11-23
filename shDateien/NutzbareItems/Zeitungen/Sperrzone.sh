# ============================================================
#  TerminalHero - Lesbares Item: DailyPulse-Ausgabe »Sperrzone«
#
#  Kategorie: Quest. Die zweite Ausgabe der letzten Zeitung der Stadt.
#  Geschrieben hat sie Pixi Nullpunkt, Rachels Tochter und Jack
#  Nullpunkts Schwester. Sie berichtet darin, was sie im Root gesehen
#  hat: den Kern, die Hunter und die Wahrheit hinter der Sperrzone.
#
#  Die Ausgabe erscheint am Ende des Stadtrundgangs mit Pixi. Rachel
#  lässt sie drucken und gibt dem Agenten fünf Bündel für die fünf
#  Zeitungskästen (Charakter/verlag.sh). Danach ist sie an den Kästen
#  und bei Tracey Briggs für 10 Bits zu kaufen.
#
#  Lesen: Im Inventar wählen -> Enter/e -> »benutzen«. Der vollständige
#  Artikel steht in InGameBefehle/Lesen.sh; die kurze item_define-
#  Beschreibung bleibt für die Detailspalte des Inventars.
#
#  Nicht einmalig (mehrere Exemplare möglich) und unverkäuflich.
#  Jimmy Page kauft sie im Rahmen von »Jimmys Zeitungsbote« zu einem
#  vom Spieler gewählten Preis (Charakter/JimmyPage.sh).
# ============================================================

item_define sperrzone quest \
    "Die Sperrzone" \
    "DailyPulse · Ausgabe 2 · »Sperrzone«\nVon Pixi Nullpunkt.\n\nPixis Bericht über den Root: kein Lageplan, kein Straßenverzeichnis. Ein Artikel über den Kern, der Befehle frisst, über Hunter, die wie systemd-journal aussehen, und über eine Stadt, die lieber nicht wissen will, was hinter ihrem Tor liegt.\n\nAuf Seite 1 steht ein Satz, der in der Redaktion lange diskutiert wurde:\n»Die Sperrzone ist kein Ort. Sie ist das, was übrig bleibt, wenn jemand beschließt, dass Wahrheit ein Risiko ist.«\n\nRachel hat die Ausgabe gedruckt. Die Stadt wird sie lesen – ob sie will oder nicht." \
    10

# Mehrere Exemplare sind möglich (Kästen und Tracey verkaufen mehrfach),
# aber eine Zeitung ist kein Handelsgut.
item_flag sperrzone unique   0
item_flag sperrzone sellable 0

item_readable sperrzone "$(cat <<'ARTIKEL'
DAILYPULSE · AUSGABE 2 · 10 BITS
DIE SPERRZONE
Was ich im Root gesehen habe
Von Pixi Nullpunkt

Seite 1 · Der Satz
Die Sperrzone ist kein Ort. Sie ist das, was übrig bleibt, wenn jemand beschließt, dass Wahrheit ein Risiko ist.

Ich war dort. Nicht lange. Lange genug, um zu sehen, dass der Root kein Stadtteil ist, den man auf einer Karte einzeichnen kann. Es gibt keine Straßen, keine Hausnummern, keine Laternen. Es gibt nur Strukturen, die sich bewegen, wenn niemand hinsieht, und Namen, die verschwinden, sobald man sie ausspricht.

Seite 2 · Was ich gesehen habe
Der Kern ist kein Prozess. Er ist ein Muster.

Ich habe ihn nicht angefasst. Ich habe ihn nicht einmal lange angesehen. Aber ich habe gesehen, wie Befehle in seiner Nähe dünner wurden, als würde jemand die Buchstaben von innen heraus abnagen. Ein `ls` blieb ein `ls`, aber es zeigte weniger. Ein `pwd` gab einen Pfad zurück, den es nicht mehr gab. Ein `cat` öffnete eine Datei, die leer war, obwohl ich kurz zuvor noch ihren Inhalt gelesen hatte.

Der Kern frisst keine Dateien. Er frisst die Erinnerung daran, dass es sie gab.

Seite 3 · Die Hunter
Dann hat mich einer angepingt.

Es war ein Hunter-Killer-Daemon, getarnt als systemd-journal. Ich habe das erst gemerkt, als die Logzeilen anfingen, mich anzusehen. Nicht metaphorisch. Die Zeilen standen still, während der Rest des Systems weiterlief. Dann bewegte sich eine Zeile nach links, obwohl niemand eine Taste gedrückt hatte.

Ich bin gerannt. Hardlink für Hardlink. Ich habe nicht nach hinten gesehen. Ich habe nur gezählt, wie viele Abzweigungen zwischen mir und dem Ausgang lagen. Als ich wieder auf der Straße stand, war die Abzweigung hinter mir verschwunden. Nicht zugemauert. Entfernt. Als hätte jemand den Pfad aus dem Verzeichnis gestrichen.

Seite 4 · Was die Stadt nicht sieht
Die Stadt sieht die Sperrzone als Mauer.

Das ist verständlich. Mauern sind einfach. Man kann sie ansehen, fotografieren, mit einem Stock dagegenklopfen. Die Sperrzone ist keine Mauer. Sie ist ein Zustand. Sie beginnt dort, wo jemand aufhört, Fragen zu stellen, und endet dort, wo die Antworten niemandem mehr gehören.

Wer sagt, hinter der Mauer sei nichts, hat entweder nie nachgesehen oder beschlossen, dass das, was er gesehen hat, nicht in seinen Alltag passt. Beides ist verständlich. Beides ist gefährlich.

Seite 5 · Was ich nicht weiß
Ich weiß nicht, wie groß der Root ist.

Ich weiß nicht, ob der Kern einen Namen hat, den man aussprechen kann, ohne dass er sich daran erinnert. Ich weiß nicht, ob die Hunter ihn beschützen oder ob sie nur das fressen, was ihm entkommt. Ich weiß nicht, ob es einen Weg hinein gibt, der nicht schon wieder verschwunden ist, wenn man zurückkommt.

Ich weiß, dass ich nicht die Einzige bin, die dort war. Auf dem Boden lagen Fußspuren, die nicht zu meinen Schuhen passten. Daneben lag ein Zettel mit einer Nummer, die ich nicht zuordnen konnte. Ich habe den Zettel nicht mitgenommen. Ich bereue es. Ich bereue auch, dass ich ihn nicht liegen gelassen habe, ohne ihn zu lesen.

Seite 6 · Was das für die Stadt bedeutet
Die Sperrzone wird nicht verschwinden, weil wir sie ignorieren.

Sie wird auch nicht verschwinden, weil wir sie fürchten. Sie reagiert nicht auf Angst. Sie reagiert auf Aufmerksamkeit. Je genauer wir hinsehen, desto mehr zeigt sie uns. Je mehr sie uns zeigt, desto weniger sind wir sicher, was wir vorher gesehen haben.

Das ist keine Einladung, blind hineinzulaufen. Es ist eine Warnung: Wer den Root betritt, bringt etwas mit zurück. Manchmal eine Antwort. Manchmal nur die Frage, ob man die Antwort überhaupt behalten darf.

Seite 7 · Ein Gespräch mit Rachel
»Bist du sicher, dass du das drucken willst?«, hat Rachel gefragt.

»Nein«, habe ich gesagt.

»Gut«, hat sie gesagt. »Dann drucken wir es.«

Sie hat nicht gefragt, ob ich Angst habe. Sie hat gefragt, ob ich die Sätze noch einmal lesen kann, ohne sie zu ändern. Ich konnte. Danach hat sie den Satz auf Seite 1 unterstrichen und gesagt: »Der bleibt.«

Seite 8 · Ein Gespräch mit Jack
Jack hat die Ausgabe dreimal gelesen.

Beim ersten Mal hat er die Karte korrigiert. Beim zweiten Mal hat er die Seitenzahlen kontrolliert. Beim dritten Mal hat er gefragt, ob ich sicher bin, dass der Hunter wirklich systemd-journal war.

»Er hat wie ein Log ausgesehen«, habe ich gesagt.

»Das ist keine Antwort«, hat er gesagt.

»Nein«, habe ich gesagt. »Aber es ist die Wahrheit.«

Er hat genickt und den Druck gestartet.

Seite 9 · Was bleibt
Ich habe nichts aus dem Root mitgebracht, was man in die Hand nehmen kann.

Kein Beweisstück. Keine Datei. Keine Karte. Nur diesen Artikel. Vielleicht ist das genug. Vielleicht ist es genau das, was die Sperrzone von uns will: dass wir anfangen, darüber zu sprechen, ohne so zu tun, als hätten wir alles verstanden.

Wenn du das hier liest, bist du Teil des Gesprächs. Das ist kein kleiner Satz. In dieser Stadt ist es oft der einzige Anfang, den es gibt.

Seite 10 · Impressum
DailyPulse. Chefredaktion: Rachel Nullpunkt.
Artikel, Recherche und Flucht: Pixi Nullpunkt.
Korrektur und Karte: Jack Nullpunkt.
Druck: DailyPulse-Verlag, Süddistrikt.
Erscheinungsweise: wenn die Stadt bereit ist. Oder wenn sie es nicht ist.
ARTIKEL
)"
