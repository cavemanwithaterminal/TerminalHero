# ============================================================
#  TerminalHero - Nutzbares Item: Gr. Token Fill
# ------------------------------------------------------------
#  Kategorie: Plunder. Ein großer Energiebehälter, der den
#  Token-Vorrat des Agenten kräftig auffüllt.
#
#  BENUTZEN (Inventar -> benutzen): Ein Exemplar wird verbraucht
#  und regeneriert 1200 Tokens (nie über das Maximum). Bei vollem
#  Tokenvorrat wird nichts verbraucht.
#
#  Erhältlich bei: Survival Jack (Jack Bones), 10× pro Tag,
#  erst ab Spielerlevel 20. Einkaufspreis: 230 Bits.
# ============================================================

item_define gr_token_fill plunder \
    "Gr. Token Fill" \
    "Ein großer, schwerer Energiebehälter mit dichter Ladung. Wenn die Reserven ernsthaft knapp werden, ist das die richtige Wahl.\n\nIm Inventar benutzen, um 1200 Tokens aufzufüllen." \
    230

item_flag gr_token_fill sellable 1

# BENUTZEN: EIN Stück verbrauchen und 1200 Tokens regenerieren.
item_use_gr_token_fill() {
    if [ "${TOKENS_CUR:-0}" -ge "${TOKENS_MAX:-0}" ] 2>/dev/null; then
        OUT+=("")
        OUT+=("Gr. Token Fill jetzt zu benutzen wäre Verschwendung – die Tokens sind voll.")
        return 0
    fi
    inv_remove gr_token_fill 1
    tokens_gain 1200
    play_sound select
    OUT+=("")
    OUT+=("» Gr. Token Fill benutzt. Ein mächtiger Energiestoß füllt die Reserven.")
    OUT+=("   [ Tokens ]  +1200 Tokens (${TOKENS_CUR}/${TOKENS_MAX})")
    return 0
}
