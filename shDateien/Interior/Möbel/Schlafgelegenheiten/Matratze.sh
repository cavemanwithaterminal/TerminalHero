# ============================================================
#  TerminalHero - Interior: Matratze (Möbel)
# ------------------------------------------------------------
#  Ein Schlafplatz in der eingestürzten Baracke: durchgelegen, feucht,
#  mit Stockflecken - aber unter Dach. Sie ist KEIN Item: Der Agent
#  kann sie nicht aufheben, nur BENUTZEN.
#
#  »use Matratze« öffnet das Schlaf-Fenster (kern/schlafen.sh).
#  »touch Matratze« mustert sie, »cat Matratze« liest ihren Text,
#  »file Matratze« zeigt (sobald gelernt) ihre Metadaten.
#
#  Diese Datei hält ALLES, was die Matratze ausmacht - auch ihren
#  SCHLAFWERT: Wie viele Tokens EINE geschlafene Stunde hier einbringt.
#  Die Schlaf-Mechanik (kern/schlafen.sh) liest diesen Wert über
#  interior_sleep_rate_of - sie kennt selbst keine Zahlenwerte.
#
#  Angemeldet wird das Objekt über interior_define (kern/interior.sh);
#  aufgestellt wird es in Orte/Süddistrikt.sh (interior_place).
#  Alle Schlafgelegenheiten (Matratze, Bett, Doppelbett) teilen sich
#  die 12 Schlafstunden pro Spieltag (SLEEP_HOURS_TODAY/SLEEP_DAY).
# ============================================================

interior_define matratze möbel \
    "Matratze" \
    "Eine durchgelegene Matratze, halb unter Schutt hervorgezogen. Wasserflecken, Stockflecken, ein Sprung in der Federung. Sie riecht nach altem Putz und nach Regen. Ein Bett ist das nicht - aber ein Platz, um sich hinzulegen."

# »touch« mustert sie; »use« öffnet das Schlaf-Fenster.
interior_talk matratze matratze_gespraech
interior_use  matratze schlafen_start

# SCHLAFWERT: 20 Tokens je geschlafener Stunde (Matratze).
# Bett (35) und Doppelbett (50) stehen in eigenen Dateien im selben Ordner.
interior_sleep_rate matratze 20

# Zusatztext für »file Matratze« (das Objekt ist kein gewöhnlicher Text).
interior_file_text matratze \
    "Ein Stück Einrichtung - kein gewöhnlicher Text.\nDurchgelegen, feucht, unter Dach. Ein Schlafplatz.\nBenutzen mit »use Matratze« - jede Stunde Schlaf bringt Tokens zurück."

# --- Ansehen (»touch«) ------------------------------------------------
# Die Matratze ist nicht beseelt: sie ANTWORTET nicht. Der Agent
# mustert sie und denkt sich seinen Teil.
matratze_gespraech() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ MATRATZE · ANGESEHEN ═════")
    OUT+=("Zustand : durchgelegen    Geruch : altes Wasser")
    OUT+=("")
    render

    say "-" "Wollig-feucht, voller Stockflecken, und irgendwo in der Mitte ein Sprung in der Federung."
    say "-" "Hier hat schon mal jemand gelegen. Vielleicht das Wasser."
    say "-" "Sie sagt nichts. Sie ist eine Matratze. Aber sie hält."
    say "$AGENT_NAME" "Wenn ich müde bin: »use Matratze«."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
