# ============================================================
#  TerminalHero - Nutzbares Item: R. Token Fill
# ------------------------------------------------------------
#  Kategorie: Plunder. Ein riesiger Energiebehälter, der den
#  Token-Vorrat des Agenten massiv auffüllt.
#
#  BENUTZEN (Inventar -> benutzen): Ein Exemplar wird verbraucht
#  und regeneriert 2500 Tokens (nie über das Maximum). Bei vollem
#  Tokenvorrat wird nichts verbraucht.
#
#  Erhältlich bei: Survival Jack (Jack Bones), 10× pro Tag,
#  erst ab Spielerlevel 30. Einkaufspreis: 500 Bits.
# ============================================================

item_define r_token_fill plunder \
    "R. Token Fill" \
    "Ein riesiger Hochkapazitäts-Energiebehälter, schwer in der Hand und voll bis zum Rand. Für kritische Momente, wenn nichts weniger reicht.\n\nIm Inventar benutzen, um 2500 Tokens aufzufüllen." \
    500

item_flag r_token_fill sellable 1

# BENUTZEN: EIN Stück verbrauchen und 2500 Tokens regenerieren.
item_use_r_token_fill() {
    if [ "${TOKENS_CUR:-0}" -ge "${TOKENS_MAX:-0}" ] 2>/dev/null; then
        OUT+=("")
        OUT+=("R. Token Fill jetzt zu benutzen wäre Verschwendung – die Tokens sind voll.")
        return 0
    fi
    inv_remove r_token_fill 1
    tokens_gain 2500
    play_sound select
    OUT+=("")
    OUT+=("» R. Token Fill benutzt. Eine gewaltige Energiewelle durchflutet das System.")
    OUT+=("   [ Tokens ]  +2500 Tokens (${TOKENS_CUR}/${TOKENS_MAX})")
    return 0
}
