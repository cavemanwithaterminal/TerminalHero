# ============================================================
#  TerminalHero - Nutzbares Item: Kl. Token Fill
# ------------------------------------------------------------
#  Kategorie: Plunder. Ein kleiner Energiebehälter, der den
#  Token-Vorrat des Agenten auffüllt.
#
#  BENUTZEN (Inventar -> benutzen): Ein Exemplar wird verbraucht
#  und regeneriert 250 Tokens (nie über das Maximum). Bei vollem
#  Tokenvorrat wird nichts verbraucht.
#
#  Erhältlich bei: Schmied (Bruno Amboss) und Survival Jack
#  (Jack Bones), je 10× pro Tag. Einkaufspreis: 50 Bits.
# ============================================================

item_define kl_token_fill plunder \
    "Kl. Token Fill" \
    "Ein kleiner, handlicher Energiebehälter mit flackernder Füllanzeige. Reicht für einen kurzen Schub, wenn die Tokens zur Neige gehen.\n\nIm Inventar benutzen, um 250 Tokens aufzufüllen." \
    50

item_flag kl_token_fill sellable 1

# BENUTZEN: EIN Stück verbrauchen und 250 Tokens regenerieren.
item_use_kl_token_fill() {
    if [ "${TOKENS_CUR:-0}" -ge "${TOKENS_MAX:-0}" ] 2>/dev/null; then
        OUT+=("")
        OUT+=("Kl. Token Fill jetzt zu benutzen wäre Verschwendung – die Tokens sind voll.")
        return 0
    fi
    inv_remove kl_token_fill 1
    tokens_gain 250
    play_sound select
    OUT+=("")
    OUT+=("» Kl. Token Fill benutzt. Ein kleiner Energieschub fließt durch das System.")
    OUT+=("   [ Tokens ]  +250 Tokens (${TOKENS_CUR}/${TOKENS_MAX})")
    return 0
}
