# ============================================================
#  TerminalHero - Nutzbares Item: Token Fill
# ------------------------------------------------------------
#  Kategorie: Plunder. Ein mittlerer Energiebehälter, der den
#  Token-Vorrat des Agenten auffüllt.
#
#  BENUTZEN (Inventar -> benutzen): Ein Exemplar wird verbraucht
#  und regeneriert 600 Tokens (nie über das Maximum). Bei vollem
#  Tokenvorrat wird nichts verbraucht.
#
#  Erhältlich bei: Survival Jack (Jack Bones), 10× pro Tag,
#  erst ab Spielerlevel 10. Einkaufspreis: 110 Bits.
# ============================================================

item_define token_fill plunder \
    "Token Fill" \
    "Ein solider Energiebehälter mit stabiler Ladung. Deutlich stärker als die kleine Variante – gemacht für längere Einsätze.\n\nIm Inventar benutzen, um 600 Tokens aufzufüllen." \
    110

item_flag token_fill sellable 1

# BENUTZEN: EIN Stück verbrauchen und 600 Tokens regenerieren.
item_use_token_fill() {
    if [ "${TOKENS_CUR:-0}" -ge "${TOKENS_MAX:-0}" ] 2>/dev/null; then
        OUT+=("")
        OUT+=("Token Fill jetzt zu benutzen wäre Verschwendung – die Tokens sind voll.")
        return 0
    fi
    inv_remove token_fill 1
    tokens_gain 600
    play_sound select
    OUT+=("")
    OUT+=("» Token Fill benutzt. Frische Energie strömt in den Speicher.")
    OUT+=("   [ Tokens ]  +600 Tokens (${TOKENS_CUR}/${TOKENS_MAX})")
    return 0
}
