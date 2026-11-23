# ============================================================
#  TerminalHero - Interior: Sitzbank (Möbel / Sitzgelegenheit)
# ------------------------------------------------------------
#  Eine breite Holzbank. Man kann sich darauf setzen - nicht schlafen.
#  Wie alle Interior-Objekte ist sie KEIN Item, sondern wird benutzt.
#
#  »use Sitzbank« öffnet das Sitz-Fenster (kern/sitzen.sh).
#  »touch Sitzbank« mustert sie, »cat Sitzbank« liest den Text,
#  »file Sitzbank« zeigt (sobald gelernt) die Metadaten.
#
#  SITZWERT: 5 Tokens je Sitzstunde.
#  Alle Sitzgelegenheiten teilen sich die 12 Stunden pro Spieltag
#  (SIT_HOURS_TODAY + SIT_DAY in kern/state.sh). Schlafen und Sitzen
#  sind getrennte Mechaniken: 12 Stunden schlafen UND 12 Stunden
#  sitzen pro Tag sind möglich.
#
#  Angemeldet wird das Objekt über interior_define (kern/interior.sh).
# ============================================================

interior_define sitzbank möbel \
    "Sitzbank" \
    "Eine breite Holzbank mit abgerundeter Kante. Die Beine stehen fest auf dem Boden, die Sitzfläche ist glatt gescheuert. Hier finden zwei Personen nebeneinander Platz - oder eine Person und ein Korb."

interior_talk sitzbank sitzbank_gespraech
interior_use  sitzbank sitzen_start

# SITZWERT: 5 Tokens je Sitzstunde.
interior_sit_rate sitzbank 5

interior_file_text sitzbank \
    "Ein Stück Einrichtung - kein gewöhnlicher Text.\nBreite Holzbank, abgerundete Kante, fester Stand.\nSitzen mit »use Sitzbank« - jede Stunde bringt Tokens zurück."

# --- Ansehen (»touch«) ------------------------------------------------
sitzbank_gespraech() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ SITZBANK · ANGESEHEN ═════")
    OUT+=("Zustand : fest    Fläche : glatt gescheuert")
    OUT+=("")
    render

    say "-" "Die Bank ist breit genug für zwei. Die Kante ist abgerundet, damit sich niemand daran stößt."
    say "-" "Kein Polster, keine Lehne - aber sie steht ruhig und gibt nicht nach."
    say "$AGENT_NAME" "Setzen: »use Sitzbank«."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
