# ============================================================
#  TerminalHero - Interior: Bett (Möbel / Schlafgelegenheit)
# ------------------------------------------------------------
#  Ein richtiges Bett: schmal, aber trocken und mit einer Matratze,
#  die nicht schon beim Ansehen auseinanderfällt. Wie die Matratze
#  ist es KEIN Item, sondern ein benutzbares Objekt.
#
#  »use Bett« öffnet das Schlaf-Fenster (kern/schlafen.sh).
#  »touch Bett« mustert es, »cat Bett« liest den Text,
#  »file Bett« zeigt (sobald gelernt) die Metadaten.
#
#  SCHLAFWERT: 35 Tokens je geschlafener Stunde.
#  Der Tageszähler ist derselbe wie bei Matratze und Doppelbett:
#  Alle Schlafgelegenheiten teilen sich die 12 Stunden pro Spieltag
#  (SLEEP_HOURS_TODAY + SLEEP_DAY in kern/state.sh).
#
#  Angemeldet wird das Objekt über interior_define (kern/interior.sh).
# ============================================================

interior_define bett möbel \
    "Bett" \
    "Ein schmales Bett mit einem stabilen Holzrahmen. Die Matratze ist fest, das Laken sauber und die Decke liegt ordentlich gefaltet am Fußende. Kein Palast, aber etwas, in dem man tatsächlich durchschlafen kann."

interior_talk bett bett_gespraech
interior_use  bett schlafen_start

# SCHLAFWERT: 35 Tokens je geschlafener Stunde.
interior_sleep_rate bett 35

interior_file_text bett \
    "Ein Stück Einrichtung - kein gewöhnlicher Text.\nStabiler Rahmen, feste Matratze, sauberes Laken.\nBenutzen mit »use Bett« - jede Stunde Schlaf bringt Tokens zurück."

# --- Ansehen (»touch«) ------------------------------------------------
bett_gespraech() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ BETT · ANGESEHEN ═════")
    OUT+=("Zustand : stabil    Laken : sauber")
    OUT+=("")
    render

    say "-" "Der Rahmen ist einfach, aber solide. Kein Knarren, keine weiche Stelle."
    say "-" "Die Matratze gibt nur so viel nach, wie sie soll."
    say "$AGENT_NAME" "Deutlich besser als der Boden. »use Bett«."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
