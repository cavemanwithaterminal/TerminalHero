# ============================================================
#  TerminalHero - Charakter: Familie Molerat (Farmland/Farm)
# ------------------------------------------------------------
#  Gregor (Vater), Marlene (Mutter) und Chantal (Tochter) leben
#  im Erdgeschoss des Anwesens auf der Farm im Farmland. Die
#  Dateien legt Orte/Anwesen.sh an; angesprochen werden sie mit
#  »touch <Name>«.
#
#  Jede Figur hat zwei Standard-Dialoge:
#    * vor Neks Beerdigung  (NEK_FUNERAL_DONE=0)
#    * nach Neks Beerdigung (NEK_FUNERAL_DONE=1)
#
#  Die Nach-Variante nimmt nur vage Bezug auf die Beerdigung. Sie
#  sagt nichts darüber, wie der Spieler mit Neks Leiche umgegangen
#  ist. Zusätzlich gibt es kurze Varianten für die Zeit vor der
#  ausdrücklichen Beerdigungsquest und für eine verpasste Feier.
# ============================================================

molerat_family_phase() {
    if [ "${NEK_FUNERAL_DONE:-0}" = "1" ]; then
        printf 'after'
    elif [ "${NEK_FUNERAL_FAILED:-0}" = "1" ]; then
        printf 'failed'
    elif [ "${NEK_FUNERAL_GIVEN:-0}" = "1" ]; then
        printf 'before'
    else
        printf 'normal'
    fi
}

molerat_family_begin() {   # <anzeigename> <rolle>
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ STEPPE · FARMLAND · ANWESEN ═════")
    OUT+=("Erdgeschoss")
    OUT+=("${1}    ${2}")
    OUT+=("")
    declare -F render >/dev/null 2>&1 && render
}

molerat_family_end() {
    declare -F dialog_pause >/dev/null 2>&1 && dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ------------------------------------------------------------
#  Gregor Molerat - Vater
# ------------------------------------------------------------
#  Neben dem Familienalltag hat Gregor zwei Anliegen:
#
#    1. »Kann ich helfen?« vergibt die Nebenquest »Von den
#       Molerats, für die Molerats«: Die Familie braucht 120
#       MoleratCode. Gregor zahlt den normalen Verkaufspreis
#       (2 Bits je Stück) und gibt 10 EXP je abgegebenem Stück;
#       für den Abschluss gibt es 1000 EXP.
#    2. Das »SchweinePriester's Tagebuch« kann ihm gezeigt werden.
#       Solange die MoleratCode-Quest nicht abgeschlossen ist,
#       stammerlt er nur und weiß nichts. Danach erkennt er das
#       Buch und ergänzt die Religion-Spur.
# ------------------------------------------------------------
dialog_farm_gregor() {
    local phase; phase="$(molerat_family_phase)"
    molerat_family_begin "Gregor Molerat" "Vater"

    case "$phase" in
        after)
            say "Gregor Molerat" "Du bist es."
            say "Gregor Molerat" "Die Beerdigung liegt hinter uns. Mehr sage ich dazu nicht."
            say "Gregor Molerat" "Die Felder warten. Sie haben keine Geduld mit Trauer."
            ;;
        failed)
            say "Gregor Molerat" "Du warst nicht da."
            say "Gregor Molerat" "Wir haben gewartet. Dann haben wir angefangen."
            say "Gregor Molerat" "Was danach kam, geht nur uns etwas an."
            ;;
        before)
            say "Gregor Molerat" "Du bist der Agent, der Nek gefunden hat."
            say "Gregor Molerat" "Die Beerdigung ist angesetzt. Bis dahin gibt es Arbeit."
            say "Gregor Molerat" "Trauer ist kein Grund, das Vieh hungern zu lassen."
            ;;
        *)
            say "-" "Der alte Molerat steht am Küchentisch und sieht auf das Feld hinaus. Er dreht sich langsam um."
            say "Gregor Molerat" "Du bist der Agent."
            say "Gregor Molerat" "Nek ist nicht hier. Er hat sich bei der Stadtwache verdingt."
            say "Gregor Molerat" "Er kommt selten. Aber er kommt."
            ;;
    esac

    gregor_dialog_menu
    molerat_family_end
}

# Laufendes Gesprächsmenü. Die Optionen wachsen mit dem Queststand.
gregor_dialog_menu() {
    local opts=() acts=()
    while true; do
        opts=(); acts=()
        opts+=("Kann ich helfen?");                  acts+=("helfen")
        if [ "${GREGOR_CODE_GIVEN:-0}" = "1" ] \
           && [ "${GREGOR_CODE_DONE:-0}" != "1" ]; then
            opts+=("Fleisch abgeben");               acts+=("abgeben")
        fi
        if declare -F inv_has >/dev/null 2>&1 \
           && inv_has schweinepriesters_tagebuch \
           && [ "${GREGOR_BOOK_DONE:-0}" != "1" ]; then
            opts+=("Ich habe dieses Buch gefunden.");      acts+=("buch")
        fi
        opts+=("Nichts weiter.");                    acts+=("ende")
        OUT+=("")
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            helfen)
                gregor_help_scene ;;
            abgeben)
                gregor_code_delivery ;;
            buch)
                gregor_book_scene ;;
            ende)
                say "Gregor Molerat" "Dann geh. Die Felder warten nicht."
                break ;;
        esac
    done
    return 0
}

# --- Die MoleratCode-Quest -----------------------------------------
gregor_code_required() { printf '120'; }

gregor_code_remaining() {
    local d="${GREGOR_CODE_DELIVERED:-0}" r
    case "$d" in ''|*[!0-9]*) d=0 ;; esac
    r=$(( $(gregor_code_required) - d ))
    [ "$r" -lt 0 ] && r=0
    printf '%s' "$r"
}

# Normaler Verkaufspreis für MoleratCode (2 Bits). Das Handelsfenster
# ist nicht immer geladen - daher derselbe Fallback wie dort.
gregor_code_sell_price() {
    if declare -F handel_sell_price >/dev/null 2>&1; then
        handel_sell_price moleratcode
        return 0
    fi
    local v
    v="$(item_value moleratcode 2>/dev/null || printf '0')"
    case "$v" in ''|*[!0-9]*) v=0 ;; esac
    if [ "$v" -le 0 ]; then
        printf '1'
    else
        local h=$(( v / 2 ))
        [ "$h" -lt 1 ] && h=1
        printf '%s' "$h"
    fi
}

# »Kann ich helfen?« - vergibt die Quest und erklärt den Preis.
gregor_help_scene() {
    local remaining
    say "$AGENT_NAME" "Kann ich helfen?"

    if [ "${GREGOR_CODE_GIVEN:-0}" = "1" ]; then
        if [ "${GREGOR_CODE_DONE:-0}" = "1" ]; then
            say "Gregor Molerat" "Du hast uns schon geholfen. Das reicht für eine Weile."
            say "Gregor Molerat" "Wenn du wieder etwas brauchst: frag."
        else
            remaining="$(gregor_code_remaining)"
            say "Gregor Molerat" "Du hilfst doch schon."
            say "Gregor Molerat" "Es fehlen noch ${remaining} Stück MoleratCode."
        fi
        return 0
    fi

    say "Gregor Molerat" "Helfen? Vielleicht."
    say "Gregor Molerat" "Wir haben immer Bedarf an MoleratCode."
    say "Gregor Molerat" "Aktuell brauchen wir 120 Stück davon."
    OUT+=("")
    say "$AGENT_NAME" "Und bekomme ich dafür einen besseren Preis?"
    say "-" "Gregor lacht. Es ist ein kurzes, trockenes Lachen, das nicht lange bleibt."
    say "Gregor Molerat" "Natürlich nicht, ich muss ja selbst daran verdienen."
    say "Gregor Molerat" "Aber du hättest dann was Gut bei mir."
    say "Gregor Molerat" "Wir sind eine einflussreiche Familie."

    if declare -F quest_gain_once >/dev/null 2>&1; then
        quest_gain_once moleratcode || true
    elif declare -F quest_gained >/dev/null 2>&1; then
        quest_gained moleratcode
    fi
    GREGOR_CODE_GIVEN=1
    if declare -F quest_note >/dev/null 2>&1; then
        quest_note "Gregor zahlt den normalen Verkaufspreis – dafür 10 EXP pro abgegebenem MoleratCode."
    fi
    OUT+=("")
    OUT+=("   [ ZIEL ]  Bringe Gregor 120 MoleratCode ins Anwesen (Erdgeschoss).")
    return 0
}

# »Fleisch abgeben«: 10 Stück oder alles, nie mehr als noch nötig.
gregor_code_delivery() {
    local have remaining amount10 amountall opts acts n
    while true; do
        remaining="$(gregor_code_remaining)"
        if [ "$remaining" -le 0 ]; then
            gregor_code_complete
            return 0
        fi

        have="$(inv_count moleratcode 2>/dev/null || printf '0')"
        if [ "$have" -le 0 ]; then
            say "-" "Du hast kein MoleratCode dabei."
            say "Gregor Molerat" "Ohne Fleisch kein Geschäft. Komm wieder, wenn du etwas hast."
            return 0
        fi

        amount10="$have"
        [ "$amount10" -gt 10 ] && amount10=10
        [ "$amount10" -gt "$remaining" ] && amount10="$remaining"

        amountall="$have"
        [ "$amountall" -gt "$remaining" ] && amountall="$remaining"

        opts=(); acts=()
        opts+=("${amount10} Stück abgeben"); acts+=("small")
        if [ "$amountall" -gt "$amount10" ]; then
            opts+=("Alles abgeben (${amountall} Stück)"); acts+=("all")
        fi
        opts+=("Zurück"); acts+=("zurueck")

        OUT+=("")
        say "Gregor Molerat" "Wie viel hast du?"
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            small)   n="$amount10" ;;
            all)     n="$amountall" ;;
            zurueck) say "Gregor Molerat" "Dann eben später."
                     return 0 ;;
            *)       n=0 ;;
        esac
        [ "$n" -gt 0 ] && gregor_code_hand_over "$n"
        [ "${GREGOR_CODE_DONE:-0}" = "1" ] && return 0
    done
}

# Eine Abgabe verbuchen: Inventar, Bits, EXP, Fortschritt.
gregor_code_hand_over() {
    local n="${1:-0}" price gained remaining
    [ "$n" -gt 0 ] || return 0
    inv_remove moleratcode "$n"
    GREGOR_CODE_DELIVERED=$(( ${GREGOR_CODE_DELIVERED:-0} + n ))
    price="$(gregor_code_sell_price)"
    gained=$(( n * price ))
    bits_add "$gained"

    OUT+=("")
    OUT+=("   [ Abgabe ]  ${n}× MoleratCode an Gregor Molerat.")
    OUT+=("   [ Bits ]  +${gained} Bits (normaler Verkaufspreis)")
    OUT+=("   [ EXP ]  +$(( n * 10 )) EXP")
    char_gain_exp $(( n * 10 ))

    remaining="$(gregor_code_remaining)"
    if [ "$remaining" -le 0 ]; then
        gregor_code_complete
    else
        say "Gregor Molerat" "Gut. ${remaining} Stück fehlen noch."
    fi
    return 0
}

gregor_code_complete() {
    [ "${GREGOR_CODE_DONE:-0}" = "1" ] && return 0
    GREGOR_CODE_DONE=1
    say "-" "Gregor zählt die letzten Stücke. Dann legt er sie in die Kiste und richtet sich auf."
    say "Gregor Molerat" "120 Stück. Du hast Wort gehalten."
    say "Gregor Molerat" "Danke. Die Familie vergisst so etwas nicht."
    say "Gregor Molerat" "Wenn du mal Hilfe brauchst: Wir sind eine einflussreiche Familie."
    if declare -F quest_reward >/dev/null 2>&1; then
        quest_reward moleratcode 1000
    else
        char_gain_exp 1000
    fi
    return 0
}

# --- Das SchweinePriester-Tagebuch ---------------------------------
# Vor dem Abschluss der MoleratCode-Quest weicht Gregor aus. Danach
# erkennt er das Buch und ergänzt die Spur zur seltenen Religion.
gregor_book_scene() {
    say "$AGENT_NAME" "Ich habe dieses Buch gefunden."

    if [ "${GREGOR_CODE_DONE:-0}" != "1" ]; then
        say "-" "Gregor wird mitten in der Bewegung starr. Sein Blick bleibt an dem speckigen Leder hängen."
        say "Gregor Molerat" "Ich ... ich weiß nichts dazu."
        say "Gregor Molerat" "Wirklich. Das ist nicht ... ich kann dir da nicht helfen."
        say "-" "Er weicht deinem Blick aus und schiebt die Kiste auf dem Tisch ein Stück beiseite."
        say "Gregor Molerat" "Frag jemand anderen."
        return 0
    fi

    if [ "${GREGOR_BOOK_DONE:-0}" = "1" ]; then
        say "Gregor Molerat" "Ich habe dir alles gesagt, was ich weiß."
        return 0
    fi

    say "-" "Gregor sieht das Buch an. Sein Gesicht wird hart."
    say "Gregor Molerat" "Das Buch. Ich weiß nicht viel darüber."
    say "Gregor Molerat" "Und ich rede nicht gern darüber."
    say "Gregor Molerat" "Die Leute sehen es und denken sofort an die seltsame Religion."
    say "Gregor Molerat" "Als hätte meine Familie etwas damit zu tun. Hat sie nicht."
    say "Gregor Molerat" "Wir sind Molerats. Wir züchten sie, wir essen sie, wir verkaufen sie. Das ist alles."
    say "Gregor Molerat" "Was ich weiß: In DesktopCity soll es Vertreter dieser Religion geben."
    say "Gregor Molerat" "Sie beten Molerats an. Mehr weiß ich nicht."
    GREGOR_BOOK_DONE=1
    if declare -F quest_note >/dev/null 2>&1; then
        quest_note "Gregor Molerat weiß nur wenig über das Tagebuch und redet ungern darüber: Seine Familie hat nichts mit der seltsamen Religion zu tun. In DesktopCity soll es Vertreter geben, die Molerats anbeten."
    fi
    OUT+=("")
    OUT+=("   [ EXP ]  +100 EXP")
    char_gain_exp 100
    return 0
}

# ------------------------------------------------------------
#  Marlene Molerat - Mutter
# ------------------------------------------------------------
dialog_farm_marlene() {
    local phase; phase="$(molerat_family_phase)"
    molerat_family_begin "Marlene Molerat" "Mutter"

    case "$phase" in
        after)
            say "-" "Sie steht in der Küchentür, ein Tuch zwischen den Händen."
            say "Marlene Molerat" "Ich habe heute Morgen für vier gedeckt."
            say "Marlene Molerat" "Dann habe ich einen Teller wieder weggenommen."
            say "Marlene Molerat" "Es war gut, dass du da warst. Wir waren nicht allein."
            say "Marlene Molerat" "Es ist still im Haus. Aber die Stille geht vorbei. Irgendwann."
            ;;
        failed)
            say "-" "Sie steht in der Küchentür, ein Tuch zwischen den Händen."
            say "Marlene Molerat" "Ich habe gewartet. Den ganzen Nachmittag."
            say "Marlene Molerat" "Dann habe ich das Essen warm gehalten. Für niemanden."
            say "Marlene Molerat" "Es ist nicht deine Schuld. Aber es tut trotzdem weh."
            say "Marlene Molerat" "Setz dich, wenn du magst. Es ist genug da."
            ;;
        before)
            say "-" "Sie steht in der Küchentür, ein Tuch zwischen den Händen."
            say "Marlene Molerat" "Du hast ihn gefunden."
            say "-" "Sie hält inne, als wäre der Satz schon zu viel."
            say "Marlene Molerat" "Ich habe seine Uniform gebügelt. Für den Tag."
            say "Marlene Molerat" "Ich weiß nicht, ob ich stehen kann. Aber ich werde stehen."
            say "Marlene Molerat" "Setz dich, wenn du magst. Es ist genug da."
            ;;
        *)
            say "-" "Sie steht in der Küchentür, ein Tuch zwischen den Händen."
            say "Marlene Molerat" "Oh. Du bist der Agent."
            say "Marlene Molerat" "Nek hat von dir erzählt. Ich habe ihm nicht geglaubt, dass er Freunde findet."
            say "Marlene Molerat" "Wenn du hungrig bist, setz dich. Es ist genug da."
            say "Marlene Molerat" "Er kommt nicht oft zum Essen. Aber sein Teller steht immer mit auf dem Tisch."
            ;;
    esac

    molerat_family_end
}

# ------------------------------------------------------------
#  Chantal Molerat - Tochter
# ------------------------------------------------------------
dialog_farm_chantal() {
    local phase; phase="$(molerat_family_phase)"
    molerat_family_begin "Chantal Molerat" "Tochter"

    case "$phase" in
        after)
            say "-" "Sie lehnt am Traktor und tippt auf einem Handy herum, das kein Netz hat."
            say "Chantal Molerat" "Ich hasse diesen Ort. Ich hasse die Felder, den Traktor und die Stille."
            say "Chantal Molerat" "Aber ich bleibe noch. Bis die Sache vorbei ist."
            say "Chantal Molerat" "Danke, dass du gekommen bist. Das hat ... geholfen. Irgendwie."
            say "Chantal Molerat" "Und jetzt geh mir nicht auf die Nerven. Ich meine es nett."
            ;;
        failed)
            say "-" "Sie lehnt am Traktor und tippt auf einem Handy herum, das kein Netz hat."
            say "Chantal Molerat" "Du warst nicht da. Ich hasse es, wenn Leute nicht auftauchen."
            say "Chantal Molerat" "Papa sagt, wir machen weiter. Mama sagt nichts. Ich sage gar nichts mehr."
            say "Chantal Molerat" "Geh einfach. Oder bleib. Mir egal."
            say "Chantal Molerat" "Meine Eltern sind im Haus. Aber ich glaube, sie reden nicht miteinander."
            ;;
        before)
            say "-" "Sie lehnt am Traktor und tippt auf einem Handy herum, das kein Netz hat."
            say "Chantal Molerat" "Meine Eltern sind wegen der Beerdigung völlig durch."
            say "Chantal Molerat" "Ich auch. Aber ich zeig das nicht."
            say "Chantal Molerat" "Alle reden über den Nachmittag, als wäre es ein Termin. Als wäre danach alles vorbei."
            say "Chantal Molerat" "Falls du fragst: Ja, ich vermisse ihn. Nein, ich will nicht darüber reden."
            ;;
        *)
            say "-" "Sie lehnt am Traktor und tippt auf einem Handy herum, das kein Netz hat."
            say "Chantal Molerat" "Du bist der Agent, oder? Nek hat dich erwähnt."
            say "Chantal Molerat" "Wahnsinn, dass er überhaupt mit jemandem geredet hat. Zu Hause redet er nie."
            say "Chantal Molerat" "Falls du fragst: Nein, ich habe keine Ahnung, wo er steckt."
            say "Chantal Molerat" "Er taucht schon wieder auf. Er taucht immer wieder auf."
            ;;
    esac

    molerat_family_end
}
