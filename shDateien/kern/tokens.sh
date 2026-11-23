# ============================================================
#  TerminalHero - Token-Wirtschaft
#
#  Der Agent läuft auf begrenzter Energie: Jede Eingabe eines
#  Grundbefehls (cd, ls, pwd, cat, touch) kostet Tokens - »grep«
#  (Gegenstände herausziehen) kostet mehr, der Kalender »cal«
#  kostet 50 Tokens und gibt 10 EXP. Über die
#  Zeit laden sie sich wieder auf - regelmäßig ein Prozent des
#  Maximums. Ausrüstung wie der Kampfring kann zusätzlich flache
#  Tokens pro Intervall liefern. Die Anzeige sitzt zwischen
#  Dialog- und CLI-Fenster.
#  Kampfbefehle geben 1 EXP je 5 bezahlte Tokens (Grund- + Gegnerkosten).
#
#  Nur Funktionsdefinitionen + Standardwerte; die UI-Primitive
#  (put_text, repeat, clrline) kommen aus ui.sh.
# ============================================================

# --- Standardwerte (frischer Start) ----------------------------------
TOKENS_MAX=1000          # maximale Tokens
TOKENS_CUR=1000          # aktuell verfügbare Tokens
TOKENS_REGEN_PCT=1       # Regeneration je Intervall (in % vom Maximum)
TOKEN_COST_CMD=5         # Kosten je eingegebenem Grundbefehl
TOKENS_REGEN_SECS=60     # Intervall der Regeneration in Sekunden

# Dev-/Test-Haken: Regenerations-Intervall überschreiben (sonst 60 s).
[ -n "${TH_TOKEN_REGEN_SECS:-}" ] && TOKENS_REGEN_SECS=$TH_TOKEN_REGEN_SECS

# Setzt die Token-Wirtschaft auf den Startzustand zurück.
# Dev-/Test-Haken: TH_TOKENS / TH_TOKENS_MAX überschreiben die Startwerte.
tokens_reset() {
    TOKENS_MAX="${TH_TOKENS_MAX:-1000}"
    TOKENS_CUR="${TH_TOKENS:-$TOKENS_MAX}"
    TOKENS_REGEN_PCT=1
    TOKEN_COST_CMD=5
}

# Tokens sofort auffüllen (z. B. MoleratCode essen), nie über das Maximum.
# Rückgabe 0, wenn tatsächlich etwas dazukam.
tokens_gain() {   # $1 = Menge
    local n="${1:-0}"
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    [ "$n" -gt 0 ] || return 1
    [ "${TOKENS_CUR:-0}" -lt "${TOKENS_MAX:-0}" ] || return 1
    TOKENS_CUR=$(( TOKENS_CUR + n ))
    [ "$TOKENS_CUR" -gt "$TOKENS_MAX" ] && TOKENS_CUR=$TOKENS_MAX
    return 0
}

# Regeneration je Intervall (mindestens 1 Token, nie 0). Ausrüstung
# kann einen flachen Zusatz liefern, z. B. Kampfring +1 pro Intervall.
tokens_step() {
    local step=$(( TOKENS_MAX * TOKENS_REGEN_PCT / 100 ))
    [ "$step" -lt 1 ] && step=1
    if declare -F equip_token_regen_total >/dev/null 2>&1; then
        step=$(( step + $(equip_token_regen_total) ))
    fi
    printf '%s' "$step"
}

# Wendet fällige Regeneration an (zeitbasiert, idempotent).
# Rückgabe 0, wenn sich der Wert geändert hat (=> Neuzeichnen nötig).
tokens_tick() {
    local now next step changed=1
    now="$(date +%s)"
    next="${TH_NEXT_REGEN:-0}"
    [ "$now" -ge "$next" ] || return 1
    step="$(tokens_step)"
    while [ "$now" -ge "$next" ]; do
        next=$(( next + TOKENS_REGEN_SECS ))
        if [ "${TOKENS_CUR:-0}" -lt "${TOKENS_MAX:-0}" ]; then
            TOKENS_CUR=$(( TOKENS_CUR + step ))
            [ "$TOKENS_CUR" -gt "$TOKENS_MAX" ] && TOKENS_CUR=$TOKENS_MAX
            changed=0
        fi
    done
    TH_NEXT_REGEN=$next
    return $changed
}

# Tokens-Kosten eines Befehls (0 = kostenlos). Grundbefehl = TOKEN_COST_CMD.
# »grep« ist die harte Arbeit: Es zieht einen Gegenstand aus der Welt.
# Auf eine Leiche angewendet ist es doppelt so teuer (Ziehen UND Ablegen):
# 20 Tokens statt 10. Das optionale zweite Argument ist der Befehlsrest
# (z. B. »NeksLeiche«) und wird nur für diese Unterscheidung gebraucht.
# »cal« kostet 50 Tokens - aber erst, wenn der Agent ihn wieder kennt;
# vorher bleibt die Virus-Absage kostenlos.
# »rm« ist ein Kampfbefehl: 50 Grundkosten plus die Gegnerkosten je
# gültigem, eindeutigem Ziel (Molerat: 50). Ohne erlerntes rm bleibt
# die Absage ebenfalls kostenlos.
# Allgemein gilt: Ein Befehl, den der Agent (noch) nicht erlernt hat,
# kostet NICHTS. Es erscheint nur die jeweilige Virus-/Sperrmeldung.
token_cost_of() {
    local cmd="$1" arg="${2:-}" canon
    if declare -F th_canon_cmd >/dev/null 2>&1; then
        canon="$(th_canon_cmd "$cmd")"
    else
        canon="${cmd,,}"
        case "$canon" in cd..|cd.) canon=cd ;; esac
    fi
    # Terminal- und Spiel-Befehle kosten nur, wenn der Agent sie kennt.
    # »exit« bleibt absichtlich frei: Das Spiel muss sich immer verlassen
    # lassen, auch wenn keine Tokens mehr übrig sind.
    case "$canon" in
        cd|ls|pwd|cat|touch|grep|cal|rm|\
        help|character|questlog|inventar|statistics|achievements|\
        trade|save|use|search)
            if declare -F knows >/dev/null 2>&1 && ! knows "$canon"; then
                printf '0'
                return
            fi ;;
    esac
    case "$canon" in
        cd|ls|pwd|cat|touch) printf '%s' "$TOKEN_COST_CMD" ;;
        grep)
            if declare -F neks_leiche_is_corpse_target >/dev/null 2>&1 \
               && neks_leiche_is_corpse_target "$arg"; then
                printf '20'
            else
                printf '10'
            fi ;;
        cal)  printf '50' ;;
        rm)
            if declare -F gegner_rm_cost_of_args >/dev/null 2>&1; then
                gegner_rm_cost_of_args "$arg"
            else
                printf '50'
            fi ;;
        help|character|questlog|inventar|statistics|achievements|\
        trade|save|use|search)
            printf '%s' "$TOKEN_COST_CMD" ;;
        *)                            printf '0' ;;
    esac
}

# EXP, die ein bezahlter Befehl einbringt. »grep« zählt doppelt (2),
# auf einer Leiche sogar vierfach (4), der Kalender »cal« gibt 10 EXP.
# Kampfbefehle wie »rm« geben 1 EXP je 5 bezahlte Tokens - inklusive
# der Gegnerkosten: 50 Grundkosten = 10 EXP, ein Molerat (100 Tokens
# gesamt) = 20 EXP, drei Molerats (200 Tokens) = 40 EXP.
token_exp_of() {
    local cmd="$1" arg="${2:-}" cost canon
    if declare -F th_canon_cmd >/dev/null 2>&1; then
        canon="$(th_canon_cmd "$cmd")"
    else
        canon="${cmd,,}"
        case "$canon" in cd..|cd.) canon=cd ;; esac
    fi
    case "$canon" in
        cd|ls|pwd|cat|touch|grep|cal|rm|\
        help|character|questlog|inventar|statistics|achievements|\
        trade|save|use|search)
            if declare -F knows >/dev/null 2>&1 && ! knows "$canon"; then
                printf '0'
                return
            fi ;;
    esac
    case "$canon" in
        grep)
            if declare -F neks_leiche_is_corpse_target >/dev/null 2>&1 \
               && neks_leiche_is_corpse_target "$arg"; then
                printf '4'
            else
                printf '2'
            fi ;;
        cal)  printf '10' ;;
        rm)
            cost="$(token_cost_of rm "$arg")"
            case "$cost" in ''|*[!0-9]*) cost=0 ;; esac
            printf '%s' "$(( cost / 5 ))" ;;
        cd|ls|pwd|cat|touch|help|character|questlog|inventar|\
        statistics|achievements|trade|save|use|search)
            printf '1' ;;
        *)    printf '0' ;;
    esac
}

# Bucht $1 Tokens ab (Standard: Kosten eines Grundbefehls).
# Rückgabe 1, wenn zu wenig vorhanden ist - es wird dann nichts abgebucht.
tokens_spend() {
    local cost="${1:-$TOKEN_COST_CMD}"
    [ "${TOKENS_CUR:-0}" -ge "$cost" ] || return 1
    TOKENS_CUR=$(( TOKENS_CUR - cost ))
    return 0
}

# --- Anzeige: Leiste zwischen Dialog- und Kommandozeile --------------
draw_token_bar() {
    local row="$TOKEN_ROW"
    clrline "$row"

    local cur="${TOKENS_CUR:-0}" max="${TOKENS_MAX:-1}"
    [ "$max" -lt 1 ] && max=1
    [ "$cur" -gt "$max" ] && cur=$max
    [ "$cur" -lt 0 ] && cur=0

    local pct=$(( cur * 100 / max ))
    local col="$GOOD"
    [ "$pct" -lt 50 ] && col="$TITLE"
    [ "$pct" -lt 20 ] && col="$DANGER"

    local label="◈ TOKENS"
    local val="${cur} / ${max}"
    local rate="+$(tokens_step)/${TOKENS_REGEN_SECS}s"

    # Balkenbreite aus dem freien Platz der Zeile ableiten (8 … 32 Zellen).
    # TOKEN_BAR_RIGHT hält rechts Platz für den Scroll-Hinweis des LS-Fensters.
    local used=$(( ${#label} + ${#val} + ${#rate} + 8 ))
    local reserve="${TOKEN_BAR_RIGHT:-0}"
    local barw=$(( COLS - used - reserve ))
    [ "$barw" -lt 8 ]  && barw=8
    [ "$barw" -gt 32 ] && barw=32
    local fill=$(( pct * barw / 100 ))
    local empty=$(( barw - fill ))

    local x=2
    put_text "$row" "$x" "${#label}" "$label" "$ACCENT$BOLD"
    x=$(( x + ${#label} + 1 ))
    [ "$fill" -gt 0 ]  && put_text "$row" "$x" "$fill" "$(repeat '█' "$fill")" "$col"
    x=$(( x + fill ))
    [ "$empty" -gt 0 ] && put_text "$row" "$x" "$empty" "$(repeat '▒' "$empty")" "$MUTED"
    x=$(( x + empty ))
    put_text "$row" "$x" "$(( ${#val} + 2 ))" "  ${val}" "$FG"
    x=$(( x + ${#val} + 2 ))
    put_text "$row" "$x" "$(( ${#rate} + 2 ))" "  ${rate}" "$MUTED"
}
