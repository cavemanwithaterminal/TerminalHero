# ============================================================
#  TerminalHero - Item: Börtys Bierlieferung
#
#  Kategorie: Quest. EINMALIG - aber ausdrücklich HANDELBAR (sellable 1).
#  Das ist die Ausnahme von der Regel »Quest-Gegenstände werden nicht
#  gehandelt« (siehe Handelsfenster.sh / handel_tradable): Wer die Kiste
#  nicht ausliefert, KANN sie verkaufen - die Lieferung ist bezahlt, sie
#  gehört dem, der sie trägt. Der Handel nimmt dafür den üblichen Preis:
#  Kauf = voller Wert, Verkauf = halber Wert.
#
#  Wert 250 Bits = genau das Geld, das Börty mitgegeben hat. Der Agent
#  bekommt die Kiste bei Lagermeister Samy Cage im Lager am Marktplatz
#  (Zentrum, Charakter/SamyCage.sh) und gibt sie bei Börty Smiles ab
#  (Charakter/BörtySmiles.sh, boerty_beer_return -> Nebenquest
#  »Bier für Börty« abgeschlossen, 100 EXP + 30 Bits).
#
#  Geht die Kiste verloren (verkauft oder anderweitig entfernt), gibt es
#  bei Samy für erneute 250 Bits Ersatz - mehrfach, solange die Quest
#  offen ist. 24 Spielstunden nach dem Verlust rechnet Börty ab und die
#  Quest scheitert (siehe bier_loss_due unten).
#
#  Liegt NICHT in der Welt; es wandert beim Bezahlen ins Inventar.
# ============================================================

item_define bierlieferung quest \
    "Börtys Bierlieferung" \
    "Eine wuchtige Holzkiste, mit einem Lederriemen zugezurrt: Flaschen an Flaschen, kein Klirren – der Lagermeister hat ordentlich gepackt.\nAuf dem Deckel ein Kreidezeichen, das nur der Wirt am anderen Ende der Stadt lesen kann: B für Börty. Darunter, kleiner und schon fast verwischt: »Nicht fallen lassen.«\n\nBörty hat dir die 250 Bits dafür mitgegeben – die Lieferung ist also bezahlt, und rein formal gehört sie jetzt dir. Genau genommen könntest du sie verkaufen.\nTatsächlich aber würde Börty dann mit dem Rücken zur Wand stehen, und das weißt du." \
    250

# Einmalig – und trotz Quest-Kategorie handelbar (explizite Ausnahme).
item_flag bierlieferung unique   1
item_flag bierlieferung sellable 1

# ============================================================
#  Verlust der Kiste & Frist für die Lieferung
# ------------------------------------------------------------
#  Die Kiste kann verkauft oder anderweitig aus dem Inventar entfernt
#  werden. Solange die Quest läuft, merkt sich BIER_LOST_AT die
#  Spielminute des Verlusts. Beim Wirt schlägt nach 24 Spielstunden
#  (CLOCK_DAY_MIN Minuten) das Scheitern-Event zu.
#
#  Bei jedem Zugriff auf die Kiste (inv_add) wird die Frist aufgehoben:
#  Wer eine Ersatzkiste bei Samy holt oder seine verkaufte Kiste
#  zurückkauft, hat wieder eine Kiste und damit wieder Zeit.
# ============================================================

# Quest läuft noch (angenommen, weder abgeschlossen noch gescheitert)?
bier_quest_open() {
    [ "${BIER_GIVEN:-0}" = "1" ] \
       && [ "${BIER_DONE:-0}" != "1" ] \
       && [ "${BIER_FAILED:-0}" != "1" ]
}

# Spielminute des Verlusts festhalten. Wird über den generischen
# item_on_remove-Haken aus kern/items.sh aufgerufen.
bier_crate_lost() {
    bier_quest_open || return 0
    [ "$(inv_count bierlieferung)" -eq 0 ] || return 0
    if declare -F uhrzeit_minutes >/dev/null 2>&1; then
        BIER_LOST_AT="$(uhrzeit_minutes)"
    else
        BIER_LOST_AT=0
    fi
    return 0
}
item_on_remove_bierlieferung() { bier_crate_lost; }

# Eine (wieder) vorhandene Kiste hebt die Verlustfrist auf.
item_on_add_bierlieferung() {
    bier_quest_open && BIER_LOST_AT=-1
    return 0
}

# Sind seit dem Verlust mindestens 24 Spielstunden vergangen?
bier_loss_due() {
    bier_quest_open || return 1
    [ "$(inv_count bierlieferung)" -eq 0 ] || return 1
    [ "${BIER_LOST_AT:--1}" -ge 0 ] 2>/dev/null || return 1
    declare -F uhrzeit_minutes >/dev/null 2>&1 || return 1
    local now elapsed
    now="$(uhrzeit_minutes)"
    elapsed=$(( now - BIER_LOST_AT ))
    [ "$elapsed" -ge "${CLOCK_DAY_MIN:-1440}" ]
}
