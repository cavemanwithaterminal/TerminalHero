# ============================================================
#  TerminalHero - Gegner-Beute: MoleratCode
#
#  Kategorie: Plunder (Beute). Jeder gelöschte Molerat hinterlässt
#  zwei Stück MoleratCode, ein MoleratKrieger drei. Der Loader lädt
#  GegnerLoot/**/*.sh zusammen mit Items/ und NutzbareItems/
#  (kern/loader.sh).
#
#  Handelswert: Kauf 4 Bits, Verkauf 2 Bits (halber Wert).
#  Es ist kein Quest-Gegenstand und nicht einzigartig – drei Molerats
#  ergeben also bis zu sechs Stück.
#
#  ESSEN (Inventar -> »benutzen«): Ein Stück roher Code stillt den
#  Hunger des Agenten und regeneriert 25 Tokens (nie über das Maximum).
#  Bei vollem Tokenvorrat wird nichts verbraucht.
# ============================================================

item_define moleratcode plunder \
    "MoleratCode" \
    "Ein zäher, feuchter Brocken roher Code. Er riecht nach Schwein, Fels und etwas, das man besser nicht untersucht. Für einen Sammler ist er ein paar Bits wert – und für einen hungrigen Agenten ein schneller Happen.\n\nIm Inventar benutzen, um ihn zu essen: Er regeneriert 25 Tokens." \
    4

item_flag moleratcode sellable 1

# BENUTZEN = ESSEN: EIN Stück verbrauchen und 25 Tokens regenerieren.
item_use_moleratcode() {
    if [ "${TOKENS_CUR:-0}" -ge "${TOKENS_MAX:-0}" ] 2>/dev/null; then
        OUT+=("")
        OUT+=("MoleratCode jetzt zu essen wäre Verschwendung – die Tokens sind voll.")
        return 0
    fi
    inv_remove moleratcode 1
    tokens_gain 25
    play_sound select
    OUT+=("")
    OUT+=("» Ein Stück MoleratCode gegessen. Es schmeckt nach Fels und Regen.")
    OUT+=("   [ Tokens ]  +25 Tokens (${TOKENS_CUR}/${TOKENS_MAX})")
    return 0
}
