# ============================================================
#  TerminalHero - Interior: Stuhl (Möbel / Sitzgelegenheit)
# ------------------------------------------------------------
#  Ein einfacher Stuhl. Man kann sich darauf setzen - nicht schlafen.
#  Wie alle Interior-Objekte ist er KEIN Item, sondern wird benutzt.
#
#  »use Stuhl« öffnet das Sitz-Fenster (kern/sitzen.sh).
#  »touch Stuhl« mustert ihn, »cat Stuhl« liest den Text,
#  »file Stuhl« zeigt (sobald gelernt) die Metadaten.
#
#  SITZWERT: 5 Tokens je Sitzstunde.
#  Alle Sitzgelegenheiten teilen sich die 12 Stunden pro Spieltag
#  (SIT_HOURS_TODAY + SIT_DAY in kern/state.sh). Schlafen und Sitzen
#  sind getrennte Mechaniken: 12 Stunden schlafen UND 12 Stunden
#  sitzen pro Tag sind möglich.
#
#  Angemeldet wird das Objekt über interior_define (kern/interior.sh).
# ============================================================

interior_define stuhl möbel \
    "Stuhl" \
    "Ein einfacher Holzstuhl mit einer leicht ausgesessenen Sitzfläche. Eine Lehne hat er, ein Wackeln auch. Für ein Nickerchen ist er zu unbequem, aber zum Sitzen und Durchatmen reicht er."

interior_talk stuhl stuhl_gespraech
interior_use  stuhl sitzen_start

# SITZWERT: 5 Tokens je Sitzstunde.
interior_sit_rate stuhl 5

interior_file_text stuhl \
    "Ein Stück Einrichtung - kein gewöhnlicher Text.\nHolzstuhl, ausgesessene Sitzfläche, wackelt leicht.\nSitzen mit »use Stuhl« - jede Stunde bringt Tokens zurück."

# --- Ansehen (»touch«) ------------------------------------------------
stuhl_gespraech() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ STUHL · ANGESEHEN ═════")
    OUT+=("Zustand : benutzt    Beine : vier, davon drei sicher")
    OUT+=("")
    render

    say "-" "Ein Holzstuhl, wie er in jeder Küche steht. Die Sitzfläche ist in der Mitte etwas dunkler."
    say "-" "Er wackelt, wenn man sich zu weit nach hinten lehnt. Zum Sitzen reicht er."
    say "$AGENT_NAME" "Setzen: »use Stuhl«."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
