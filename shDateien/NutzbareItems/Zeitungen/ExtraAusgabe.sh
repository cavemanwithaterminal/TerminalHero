# ============================================================
#  TerminalHero - Lesbares Item: DailyPulse-Extra-Ausgabe
#
#  Kategorie: Quest. Die zusätzliche Ausgabe nach Neks Beerdigung.
#  Sie erscheint am Tag nach der Trauerfeier und wird einige
#  Ingame-Tage lang neben der Hauptausgabe an den fünf Zeitungskästen
#  und bei Tracey Briggs verkauft.
#
#  Bei Jimmy Page löst sie eine eigene Preisverhandlung aus: dieselben
#  drei Preise und EXP-Stufen wie die Sperrzone-Ausgabe.
#
#  Lesen: Im Inventar wählen -> Enter/e -> »benutzen«.
#
#  Nicht einmalig (mehrere Exemplare möglich) und unverkäuflich.
# ============================================================

item_define extraausgabe quest \
    "Extra-Ausgabe: Nek Molerat" \
    "DailyPulse · Extra-Ausgabe · »Nek Molerat«\nVon Pixi Nullpunkt, gesetzt von Jack Nullpunkt.\n\nEin Nachruf ohne Schlagzeile: Nek Molerat, Stadtwache, Sohn, Freund. Die Redaktion schreibt über den Mann, der die Stadt beschützt hat, ohne dafür in der Zeitung zu stehen. Mit einem Foto, auf dem er wegsieht.\n\n»Ein Mensch ist nicht tot, solange jemand seinen Namen ausspricht.«" \
    10

item_flag extraausgabe unique   0
item_flag extraausgabe sellable 0

item_readable extraausgabe "$(cat <<'ARTIKEL'
DAILYPULSE · EXTRA-AUSGABE · 10 BITS
NEK MOLERAT
Ein Nachruf, keine Schlagzeile
Von Pixi Nullpunkt

Seite 1 · Der Name
Nek Molerat war eine Stadtwache.

Er war nicht der schnellste. Er war nicht der lauteste. Er stand am Tor, wenn es regnete, und er stand dort auch, wenn niemand durchwollte. Das ist keine Geschichte, die man normalerweise druckt. Heute schon.

Seite 2 · Der Stuhl
Im Wachhaus steht ein Stuhl, der noch nicht weggeräumt wurde.

Simple Jon hat ihn nicht verrückt. Simon Guard hat ihn nicht abgewischt. Beide sagen, sie warten noch ein bisschen. Ich habe den Stuhl gesehen. Er ist aus Holz, an einer Lehne ist ein Kratzer, und auf dem Sitz liegt eine Zeitung von vor zwei Wochen. Nek hat sie nicht zu Ende gelesen.

Seite 3 · Der Kaffee
Nek hat Kaffee gekocht, ohne die Maschine zu töten.

Das klingt nach einer kleinen Sache. Es war keine. Simple Jon sagt, er habe mehr Kaffee getrunken, als er zugeben wollte, und Nek habe nie darüber geredet. Er habe einfach den Becher hingestellt. Manchmal ist das die ganze Freundschaft: ein Becher, der dort steht, wo man ihn braucht.

Seite 4 · Die Familie
Gregor Molerat sagt, ein Molerat steht gerade und jammert nicht.

Marlene Molerat hat Neks Uniform gebügelt, bevor er ging. Sie weiß nicht, warum. Chantal Molerat sagt, sie sei nicht traurig, sondern genervt, und das sei auch ein Gefühl. Ich glaube ihr. Ich glaube auch, dass sie ihren Bruder vermisst, auch wenn sie es nicht so sagt.

Seite 5 · Das Tor
Simon Guard stand am Tor, als Nek verschwand.

Er sagt, er habe ihn nicht gefunden. Er sagt auch, seine Aufgabe sei nicht nur das Tor gewesen. Das ist ein Satz, den man nicht oft von einer Wache hört. Ich habe ihn so aufgeschrieben, wie er ihn gesagt hat. Es ist sein Satz, nicht meiner.

Seite 6 · Die Redaktion
Rachel hat gesagt: keine Tränen auf Seite eins.

Nur der Name. Und das Datum. Alles andere ist unsere Arbeit. Jack hat ein Foto ausgesucht, auf dem Nek wegsieht. Er sagt, es sei das richtige. Ich habe nicht gefragt, warum. Ich habe genickt.

Seite 7 · Der Abschied
Francesco Dellamorte hat die Gräber gerade gemacht.

Er hat gesagt, Nek sei pünktlich gewesen. Das ist mehr, als man von den meisten behaupten kann. Dann hat er den Sarg hinuntergelassen, und Simon Guard hat die erste Handvoll Erde geworfen. Seine Hand hat gezittert. Das steht nicht in den Berichten, die ich sonst schreibe. Hier steht es.

Seite 8 · Was bleibt
Nek Molerat ist nicht allein geblieben.

Auf dem Friedhof standen Menschen, die ihn kannten, und ein paar, die ihn nicht kannten. Sie sind geblieben, bis die Erde geschlossen war. Danach sind sie zurückgegangen – in die Redaktion, ans Tor, ins Wachhaus, in die Kneipe. Die Stadt läuft weiter. Aber der Stuhl im Wachhaus steht noch da.

Seite 9 · Impressum
DailyPulse. Chefredaktion: Rachel Nullpunkt.
Text: Pixi Nullpunkt.
Satz und Foto: Jack Nullpunkt.
Druck: DailyPulse-Verlag, Süddistrikt.
Erscheinungsweise: einmalig. Für Nek.
ARTIKEL
)"
