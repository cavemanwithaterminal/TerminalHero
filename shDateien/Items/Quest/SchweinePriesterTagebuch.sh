# ============================================================
#  TerminalHero - Item: SchweinePriester's Tagebuch
#
#  Kategorie: Quest. EINMALIG, aber VERKÄUFLICH: Wert 250 Bits im
#  Einkauf, Verkauf bringt 125 Bits (halber Wert). Damit ist es ein
#  Questgegenstand, den der Agent im Notfall versetzen kann.
#
#  Fundort: KöniginnenKammer (Orte/KöniginnenKammer.sh), am Rand des
#  Nestes der MoleratKönigin. Der Fundort wird von
#  Gegner/MoleratKoenigin.sh registriert; aufgenommen wird das Buch
#  mit »grep SchweinePriesterTagebuch«.
#
#  Quest »Seltsame Religion«:
#    * Wer das Buch aufsammelt und die Quest schon hat, bekommt eine
#      Questlog-Aktualisierung (TAGEBUCH_FOUND).
#    * Wer die Quest noch nicht hat, bekommt sie beim ersten Lesen –
#      einmalig und mit einem anderen ersten Log-Eintrag als bei
#      Sherlock (RELIGION_BOOK_FIRST).
#    * Der SchweinePriester bezeichnet sich selbst als Forscher und
#      spricht von einer verlorenen Molerat-Zivilisation, die den
#      Menschen (Dateien) ebenbürtig gewesen sein soll.
#
#  Gelesen wird das Buch über das Inventar (»benutzen«); der Text
#  steht in item_readable. Der Haken item_on_read_<id> wird vom
#  Lesefenster (InGameBefehle/Lesen.sh) nach dem Schließen gerufen.
# ============================================================

item_define schweinepriesters_tagebuch quest \
    "SchweinePriester's Tagebuch" \
    "Ein in speckiges Leder gebundenes Buch, dessen Seiten nach feuchter Erde und altem Rauch riechen. Auf dem Vorsatz steht in krakeliger Schrift: »SchweinePriester«.\n\nEs ist kein Gebetbuch. Es ist ein Forschungsbuch – voller Beobachtungen über Molerats, ihre Gänge und eine Zivilisation, die es angeblich einmal gegeben hat.\n\nAm Rand des Nestes der MoleratKönigin gefunden." \
    250

# Einmalig, aber ausdrücklich handelbar: Verkauf 125 Bits.
item_flag schweinepriesters_tagebuch unique   1
item_flag schweinepriesters_tagebuch sellable 1

item_readable schweinepriesters_tagebuch "$(cat <<'TAGEBUCH'
SCHWEINEPRIESTER'S TAGEBUCH
Aufzeichnungen eines Forschers, der zu lange zugehört hat.

Erster Eintrag
Ich nenne mich den SchweinePriester, weil die anderen keinen besseren Namen für mich haben. Ich bin kein Priester. Ich bin Forscher. Aber wer mit Molerats spricht, wird in dieser Stadt schnell zu etwas, das einen Namen braucht.

Die Königin hat mich geduldet. Das ist mehr, als die meisten sagen können. Sie duldet niemanden lange.

Zweiter Eintrag · Über die Molerats
Molerats sind keine Tiere. Jedenfalls nicht nur. Wer sie nur als Schweine sieht, sieht das Loch nicht, in das sie führen.

Ihre Gänge sind älter als die Stadt. Sie folgen keinem Zufall. Sie folgen einem Muster, das man erst erkennt, wenn man drei Nächte lang still in einem Tunnel sitzt und zuhört. Ich habe vier gebraucht.

Dritter Eintrag · Die Königin
Die Königin ist alt. Älter als die Tunnel, älter als die Stadt, vielleicht älter als das, was wir Dateien nennen.

Sie spricht nicht mit Worten. Sie spricht in Bewegungen, in Gerüchen, in dem Zittern des Gesteins. Ich habe gelernt, sie zu verstehen. Nicht alles. Genug, um zu wissen, dass sie wartet.

Vierter Eintrag · Die verlorene Zivilisation
Hier beginnt der Teil, für den mich die anderen für verrückt halten.

Unter der Stadt hat es eine Molerat-Zivilisation gegeben. Keine Höhlen mit Knochen und Kot. Eine echte Zivilisation: Gänge wie Straßen, Kammern wie Häuser, Zeichen an den Wänden, die mehr sind als Kratzspuren.

Sie war den Dateien ebenbürtig. Den Menschen. Uns. Vielleicht war sie älter. Vielleicht war sie klüger. Und dann war sie fort – spurlos verschwunden.

Fünfter Eintrag · Das Verschwinden
Es gibt keinen Krieg in den Aufzeichnungen. Keine Seuche. Keine Flut. Keine Spur von einem Ende.

Die Gänge sind leer, aber nicht zerstört. Die Kammern sind verlassen, aber nicht geplündert. Es ist, als hätte jemand eine ganze Zivilisation aus der Datei gelöscht und vergessen, die Ordner mitzunehmen.

Die Königin erinnert sich. Ich bin sicher. Aber sie sagt es nicht. Sie wartet.

Sechster Eintrag · Was ich nicht weiß
Ich weiß nicht, wohin sie gegangen sind.

Ich weiß nicht, ob sie gegangen sind oder geholt wurden. Ich weiß nicht, ob die Königin die Letzte ist oder nur die Einzige, die noch spricht. Ich weiß nicht, ob die Molerats ihre Nachfahren sind oder ihre Wächter.

Ich weiß nur, dass die Tunnel tiefer sind, als sie sein dürften. Und dass jemand sie vor langer Zeit gebaut hat.

Siebter Eintrag · An den, der das liest
Wenn du das hier findest, bist du näher gekommen als die meisten.

Vielleicht bist du ein Dieb. Vielleicht ein Forscher. Vielleicht nur verloren. Das ist nicht wichtig. Wichtig ist, dass du der Königin nicht mit Gewalt begegnest. Sie vergisst nicht.

Und wenn du den Priester suchst: Ich bin nicht verschwunden. Ich bin nur dort, wo die Tunnel aufhören, Straßen zu sein.

Achter Eintrag · Letzte Notiz
Die Königin hat heute Nacht zweimal auf den Boden geschlagen.

Das bedeutet: Besuch.

Ich lege das Buch hier ab. Wer es findet, soll wissen, dass die Molerats keine Tiere sind. Und dass diese Stadt auf etwas gebaut wurde, das älter ist als ihre Mauern.
TAGEBUCH
)"

# ============================================================
#  Quest-Anbindung
# ============================================================

# Quest »Seltsame Religion« sicherstellen. Wird beim ersten Lesen (und
# als Sicherheitsnetz beim Zeigen des Buchs) gerufen. Ist die Quest
# schon aktiv, passiert nichts.
tagebuch_ensure_religion_quest() {
    [ "${RELIGION_GIVEN:-0}" = "1" ] && return 0
    if declare -F quest_gain_once >/dev/null 2>&1; then
        if quest_gain_once religion; then
            RELIGION_GIVEN=1
            RELIGION_BOOK_FIRST=1
            if declare -F quest_note >/dev/null 2>&1; then
                quest_note "In der KöniginnenKammer habe ich das Tagebuch eines SchweinePriesters gefunden."
            fi
            OUT+=("[ NEUES ZIEL ]  Lies das Tagebuch und erkundige dich bei Novize Bill (Kneipe, Ostdistrikt).")
            return 0
        fi
        # Quest war bereits bekannt (z. B. von Sherlock): nichts vergeben.
        RELIGION_GIVEN=1
        return 0
    fi
    RELIGION_GIVEN=1
    RELIGION_BOOK_FIRST=1
    return 0
}

# --- Aufheben (»grep SchweinePriesterTagebuch«) --------------------
item_on_take_schweinepriesters_tagebuch() {
    TAGEBUCH_FOUND=1
    if [ "${RELIGION_GIVEN:-0}" = "1" ]; then
        if declare -F quest_note >/dev/null 2>&1; then
            quest_note "Ich habe das »SchweinePriester's Tagebuch« in der KöniginnenKammer gefunden."
        fi
        OUT+=("   [ QUESTLOG ]  »Seltsame Religion«: Das Tagebuch ist eine neue Spur.")
    fi
    OUT+=("   [ Tagebuch ]  Im Inventar lesbar – Benutzen öffnet die Aufzeichnungen.")
}

# --- Lesen (Haken aus InGameBefehle/Lesen.sh) ----------------------
item_on_read_schweinepriesters_tagebuch() {
    local first=0
    [ "${TAGEBUCH_READ:-0}" = "1" ] || first=1
    TAGEBUCH_READ=1
    TAGEBUCH_FOUND=1

    tagebuch_ensure_religion_quest
    if [ "$first" = "1" ] && declare -F quest_note >/dev/null 2>&1; then
        quest_note "Im Tagebuch beschreibt der SchweinePriester eine verlorene Molerat-Zivilisation, die den Dateien ebenbürtig war – und spurlos verschwand."
    fi
    return 0
}
