# ============================================================
#  TerminalHero - Interior: Doppelbett (Möbel / Schlafgelegenheit)
# ------------------------------------------------------------
#  Ein breites Doppelbett mit zwei Kopfkissen und einer Decke, die
#  tatsächlich für zwei Personen reichen würde. Es ist KEIN Item,
#  sondern ein benutzbares Objekt.
#
#  »use Doppelbett« öffnet das Schlaf-Fenster (kern/schlafen.sh).
#  »touch Doppelbett« mustert es, »cat Doppelbett« liest den Text,
#  »file Doppelbett« zeigt (sobald gelernt) die Metadaten.
#
#  SCHLAFWERT: 50 Tokens je geschlafener Stunde.
#  Der Tageszähler ist derselbe wie bei Matratze und Bett:
#  Alle Schlafgelegenheiten teilen sich die 12 Stunden pro Spieltag
#  (SLEEP_HOURS_TODAY + SLEEP_DAY in kern/state.sh).
#
#  Angemeldet wird das Objekt über interior_define (kern/interior.sh).
# ============================================================

interior_define doppelbett möbel \
    "Doppelbett" \
    "Ein breites Doppelbett mit zwei Kissen und einer dicken Decke. Der Rahmen ist dunkel lackiert, die Matratze gibt gleichmäßig nach. Wer hier liegt, hat Platz und muss sich nicht an der Wand festhalten."

interior_talk doppelbett doppelbett_gespraech
interior_use  doppelbett schlafen_start

# SCHLAFWERT: 50 Tokens je geschlafener Stunde.
interior_sleep_rate doppelbett 50

interior_file_text doppelbett \
    "Ein Stück Einrichtung - kein gewöhnlicher Text.\nBreiter Rahmen, zwei Kissen, dicke Decke.\nBenutzen mit »use Doppelbett« - jede Stunde Schlaf bringt Tokens zurück."

# --- Ansehen (»touch«) ------------------------------------------------
doppelbett_gespraech() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DOPPELBETT · ANGESEHEN ═════")
    OUT+=("Zustand : breit    Decke : warm")
    OUT+=("")
    render

    say "-" "Zwei Kissen, ordentlich aufgeschüttelt. Die Decke ist schwer genug für eine kalte Nacht."
    say "-" "Der Rahmen knarzt nicht einmal, als du dich dagegen lehnst."
    say "$AGENT_NAME" "Das ist kein Notlager. Das ist ein Bett. »use Doppelbett«."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
