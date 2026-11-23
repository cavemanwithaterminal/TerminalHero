# ============================================================
#  TerminalHero - Charakter: Jimmy Page
# ------------------------------------------------------------
#  Jimmy Page sitzt im Rollstuhl und hasst es, das Haus zu verlassen.
#  Er ist leidenschaftlicher Zeitungssammler; weil er aber nie an die
#  Zeitungskästen kommt, hat er mit Tracey Briggs einen Deal: Sie bringt
#  ihm die neueste DailyPulse-Ausgabe, er zahlt das Dreifache (30 Bits).
#
#  Für die aktuelle, langweilige Ausgabe »Die langweilige Stadttour von
#  Jack« hat Tracey diesmal 100 Bits verlangt - die Ausgabe soll aus dem
#  Verkehr gezogen werden, also ist sie für einen Sammler selten. Jimmy
#  hat sie gekauft und ärgert sich über den Preis.
#
#  Nachdem der Agent Tracey im Rahmen von Rachels Quest gefunden hat,
#  bietet Jimmy ihm 50 Bits pro neuer Ausgabe an. Daraus entsteht die
#  Nebenquest »Jimmys Zeitungsbote« (JIMMY_GIVEN). Zeitungen können danach
#  bei ihm verkauft werden.
#
#  Lazy geladen über DIALOG[] (kern/loader.sh), erst beim ersten »touch«.
# ============================================================

jimmy_current_edition() {
    local e="${ZEITUNG_EDITION:-bezirke}"
    if declare -F zeitung_current_edition >/dev/null 2>&1; then
        e="$(zeitung_current_edition)"
    fi
    item_exists "$e" || e="bezirke"
    item_exists "$e" && printf '%s' "$e"
}

# --- Vorstellung ohne Quest -------------------------------------------
jimmy_intro_scene() {
    if [ "${JIMMY_INTRO_DONE:-0}" != "1" ]; then
        JIMMY_INTRO_DONE=1
        say "-" "Im hinteren Zimmer sitzt ein schmaler Mann in einem Rollstuhl, einen Stapel Zeitungen auf den Knien. Er sieht nicht auf, als die Tür aufgeht."
        say "Jimmy" "Jimmy Page. Und nein, ich gehe nicht raus. Das Haus ist gut. Das Haus hat alles."
        say "Jimmy" "Zeitungen sind meine Fenster. Jede Ausgabe ist ein Tag, den ich mir ins Regal stelle."
        say "Jimmy" "Ich sammle sie. Alle. Seit Jahren."
        say "Jimmy" "Falls du eine seltene Ausgabe hast: Ich kaufe sie. Aber nicht für die Preise, die Tracey neuerdings verlangt."
        say "-" "Er klopft zweimal auf den Stapel, als würde er eine Tür abschließen."
    else
        say "Jimmy" "Du schon wieder. Das Haus ist immer noch gut, und ich bin immer noch nicht draußen."
        say "Jimmy" "Wenn du eine Ausgabe für mich hast: immer her damit."
    fi
}

# --- Nach dem Fund von Tracey: der Ärger und das Angebot --------------
jimmy_after_tracey_scene() {
    if [ "${JIMMY_INTRO_DONE:-0}" != "1" ]; then
        JIMMY_INTRO_DONE=1
        say "-" "Im hinteren Zimmer sitzt ein schmaler Mann in einem Rollstuhl, einen Stapel Zeitungen auf den Knien."
        say "Jimmy" "Jimmy Page. Ich gehe nicht raus – aber ich lese alles, was hereinkommt."
    fi
    say "-" "Jimmy blättert wütend in einer Ausgabe, die er schon gelesen hat."
    say "Jimmy" "Diese Tracey! Ich habe ihr gerade 100 Bits für die aktuelle Ausgabe gegeben. Einhundert!"
    say "$AGENT_NAME" "Was ist passiert?"
    say "Jimmy" "Sie hat mir die neue DailyPulse gebracht. Die langweilige Stadttour von Jack."
    say "Jimmy" "Sie wusste, dass die Ausgabe wieder aus dem Verkehr gezogen wird. Für einen Sammler ist sie damit selten."
    say "Jimmy" "Also habe ich bezahlt. Natürlich habe ich bezahlt. Ich bin Sammler, kein Vernunftmensch."
    say "Jimmy" "Aber 100 Bits für eine Zeitung, die ich in zehn Minuten durch habe? Das ist Wucher."
    say "Jimmy" "Normalerweise zahle ich ihr 30 Bits. Dreifacher Preis, weil sie den Weg hierher macht."
    say "Jimmy" "Diesmal hat sie einfach noch mal dreißig draufgelegt. Und ich Idiot habe es ihr gegeben."
    say "-" "Er legt die Ausgabe auf den Stapel. Vorsichtig, trotz allem."
    say "Jimmy" "Ich biete dir 50 Bits pro neuer Ausgabe. Bring mir, was du findest – bevor Tracey es tut."
    OUT+=("")
    OUT+=("[ NEUES ZIEL ]  Bringe Jimmy Page neue DailyPulse-Ausgaben:   JimmysHaus (Ostdistrikt)")
    quest_gain_once jimmy
    JIMMY_GIVEN=1
    JIMMY_TRACEY_DONE=1
}

# --- Eine Ausgabe verkaufen -------------------------------------------
jimmy_sell_scene() {
    local eid
    eid="$(jimmy_current_edition)"
    if [ -z "$eid" ]; then
        say "Jimmy" "Für diese Ausgabe habe ich im Moment keinen Bedarf."
        return 0
    fi
    if ! inv_has "$eid"; then
        say "Jimmy" "Du hast gar keine Ausgabe für mich dabei."
        return 0
    fi

    inv_remove "$eid" 1
    bits_add 50
    JIMMY_LAST_SOLD="$eid"
    JIMMY_FIRST_SALE=1
    play_sound cmd_touch
    OUT+=("")
    OUT+=("   [ Zeitung ]  \"$(item_name "$eid")\" verkauft")
    OUT+=("   [ Bits ]     +50   (noch $(bits_text "$(bits_count)"))")
    OUT+=("   [ Inventar ] Noch $(inv_count "$eid") Ausgabe(n) dieser Edition.")
    say "Jimmy" "Endlich. Danke. Genau so etwas brauche ich."
}

# --- Sonderausgaben: der Spieler macht den Preis ---------------------
# Die Sperrzone-Ausgabe und die Extra-Ausgabe nach Neks Beerdigung
# werden nicht für die üblichen 50 Bits verkauft: Der Agent verlangt
# selbst. Je günstiger der Preis, desto mehr Erfahrung gibt es - Jimmy
# belohnt Fairness, nicht Profit. Beide Ausgaben haben dieselben drei
# Preise und dieselben EXP-Stufen.
jimmy_sperrzone_exp() {   # $1 = Preis in Bits
    case "$1" in
        50)  printf '250' ;;
        75)  printf '100' ;;
        100) printf '0' ;;
        *)   printf '0' ;;
    esac
}

jimmy_special_intro() {   # $1 = Item-ID
    case "$1" in
        extraausgabe)
            say "Jimmy" "Die Extra-Ausgabe. Der Nachruf auf Nek Molerat."
            say "Jimmy" "Ich habe Nek nicht gekannt. Aber ich habe seinen Namen gelesen, und jetzt vergesse ich ihn nicht so schnell."
            ;;
        *)
            say "Jimmy" "Die Sperrzone-Ausgabe. Du hast sie wirklich."
            ;;
    esac
}

jimmy_special_price_scene() {   # $1 = Item-ID
    local eid="${1:-sperrzone}" price exp
    jimmy_special_intro "$eid"
    say "Jimmy" "Also – was willst du dafür?"
    ask "50 Bits." "75 Bits." "100 Bits." "Doch nicht verkaufen."

    case "$CHOICE" in
        1)
            price=50
            say "Jimmy" "50 Bits? Das ist fair. Danke. Genau so etwas will ich lesen."
            ;;
        2)
            price=75
            say "Jimmy" "75 Bits? Du bist ja fast wie Tracey. Aber gut, ich nehme sie."
            ;;
        3)
            price=100
            say "Jimmy" "100 Bits? Du bist genauso ein Halsabschneider wie Tracey. Aber ich nehme sie. Ich bin Sammler, kein Vernunftmensch."
            ;;
        *)
            say "Jimmy" "Dann behalte sie. Aber wehe, du bringst sie doch noch Tracey."
            return 0
            ;;
    esac

    if ! inv_has "$eid"; then
        say "Jimmy" "Du hast sie gar nicht dabei. Bring sie mir erst, dann reden wir über den Preis."
        return 0
    fi

    exp="$(jimmy_sperrzone_exp "$price")"
    inv_remove "$eid" 1
    bits_add "$price"
    JIMMY_LAST_SOLD="$eid"
    JIMMY_FIRST_SALE=1
    [ "$exp" -gt 0 ] 2>/dev/null && char_gain_exp "$exp"
    play_sound cmd_touch

    OUT+=("")
    OUT+=("   [ Zeitung ]  \"$(item_name "$eid")\" verkauft")
    OUT+=("   [ Bits ]     +$(bits_text "$price")   (noch $(bits_text "$(bits_count)"))")
    if [ "$exp" -gt 0 ] 2>/dev/null; then
        OUT+=("   [ EXP ]      +${exp}")
    else
        OUT+=("   [ EXP ]      ±0")
    fi
    say "Jimmy" "Ab damit in die Sammlung. Die nächste Ausgabe bringst du mir wieder, ja?"
}

# Rückwärtskompatibler Name für die Sperrzone-Verhandlung.
jimmy_sperrzone_price_scene() {
    jimmy_special_price_scene sperrzone
}

# --- Kalender-Unterricht nach dem ersten Verkauf -----------------------
# Jimmy ist Zeitungssammler; wer ihm eine Ausgabe verkauft hat, kann bei
# ihm den In-Game-Kalender lernen. Der Unterricht ist nicht kostenlos:
# 2 Skillpunkte + 50 Bits - genau wie bei Jack Nullpunkt im Verlag.
jimmy_cal_offer() {
    [ "${JIMMY_FIRST_SALE:-0}" = "1" ] || return 0
    declare -F knows >/dev/null 2>&1 && knows cal && return 0

    OUT+=("")
    say "Jimmy" "Du hast mir eine Ausgabe verkauft. Dann sollst du auch wissen, wann die nächste kommt."
    say "Jimmy" "»cal« ist kein Geschenk. Zwei Skillpunkte und 50 Bits, dann zeige ich es dir."
    ask "cal lernen (2 Skillpunkte, 50 Bits)" "Nichts weiter."
    if [ "$CHOICE" = "1" ]; then
        if [ "${SKILL_POINTS:-0}" -lt 2 ] 2>/dev/null || ! bits_has 50; then
            play_sound error
            say "Jimmy" "Ohne 2 Skillpunkte und 50 Bits wird das nichts. Ich bin Sammler, kein Wohltäter."
            return 0
        fi
        SKILL_POINTS=$(( ${SKILL_POINTS:-0} - 2 ))
        bits_take 50 || true
        OUT+=("   [ Skillpunkte ]  -2   ·   [ Bits ]  -$(bits_text 50)")
        learn_cmd cal
        say "Jimmy" "»cal« zeigt dir das Datum. Oben im PFAD-Fenster, vierundzwanzig Spielstunden lang."
    else
        say "Jimmy" "Deine Entscheidung. Das Angebot bleibt stehen."
    fi
}

# --- Standardgespräch nach der Quest ----------------------------------
jimmy_collector_loop() {
    local eid special=""
    eid="$(jimmy_current_edition)"
    while true; do
        OUT+=("")

        # Sonderausgaben zuerst: Die Extra-Ausgabe ist die neueste, danach
        # kommt die Sperrzone-Ausgabe. Beide werden verhandelt, nicht für
        # die üblichen 50 Bits angekauft.
        if inv_has extraausgabe \
           && [ "${JIMMY_LAST_SOLD:-}" != "extraausgabe" ]; then
            special="extraausgabe"
        elif inv_has sperrzone \
           && [ "${JIMMY_LAST_SOLD:-}" != "sperrzone" ]; then
            special="sperrzone"
        fi
        if [ -n "$special" ]; then
            if [ "$special" = "extraausgabe" ]; then
                say "Jimmy" "Hast du die Extra-Ausgabe? Die mit Neks Nachruf?"
                ask "Extra-Ausgabe verkaufen." "Nichts weiter."
            else
                say "Jimmy" "Hast du die neue Ausgabe? Die über die Sperrzone?"
                ask "Neuste Ausgabe." "Nichts weiter."
            fi
            if [ "$CHOICE" = "1" ]; then
                jimmy_special_price_scene "$special"
            fi
            break
        fi

        # Nach der Extra-Ausgabe reagiert Jimmy einmalig auf den Nachruf.
        if [ "${JIMMY_LAST_SOLD:-}" = "extraausgabe" ] \
           && ! inv_has extraausgabe && [ "$eid" != "sperrzone" ]; then
            say "Jimmy" "Die Extra-Ausgabe. Ich habe sie gelesen. Der Nachruf auf Nek ist... anständig."
            say "Jimmy" "Keine Schlagzeile. Nur ein Name und ein Datum. Manchmal reicht das."
        fi

        # Sonderfall Sperrzone: eigener Dialog mit Preisverhandlung.
        if [ "$eid" = "sperrzone" ]; then
            if [ "${JIMMY_LAST_SOLD:-}" = "sperrzone" ]; then
                say "Jimmy" "Die Sperrzone-Ausgabe. Ich habe sie gelesen. Zweimal."
                say "Jimmy" "Beim ersten Mal war ich wütend. Beim zweiten Mal habe ich verstanden, warum Rachel sie druckt."
                say "Jimmy" "Sag ihr, sie soll mir die nächste auch bringen. Aber zu einem anständigen Preis."
                ask "Nichts weiter."
            else
                say "Jimmy" "Hast du die neue Ausgabe? Die über die Sperrzone?"
                ask "Neuste Ausgabe." "Nichts weiter."
                if [ "$CHOICE" = "1" ]; then
                    if inv_has sperrzone; then
                        jimmy_sperrzone_price_scene
                    else
                        say "Jimmy" "Du hast sie nicht dabei. Bring mir ein Exemplar, dann reden wir über den Preis."
                    fi
                fi
            fi
            break
        fi

        if [ -n "$eid" ] && inv_has "$eid" \
           && [ "${JIMMY_LAST_SOLD:-}" != "$eid" ]; then
            say "Jimmy" "Hast du eine Ausgabe für mich? Ich zahle 50 Bits."
            ask "Zeitungsausgabe verkaufen (50 Bits)" "Nichts weiter."
            if [ "$CHOICE" = "1" ]; then
                jimmy_sell_scene
                continue
            fi
        elif [ -n "$eid" ] && [ "${JIMMY_LAST_SOLD:-}" = "$eid" ]; then
            say "Jimmy" "Diese Ausgabe habe ich schon. Bring mir die nächste, dann reden wir wieder."
            ask "Nichts weiter."
        else
            say "Jimmy" "Hast du eine neue Ausgabe für mich? Im Moment sehe ich keine."
            ask "Nichts weiter."
        fi
        break
    done
    jimmy_cal_offer
}

# --- Gespräch (»touch JimmyPage«) -------------------------------------
dialog_jimmy() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ JIMMYS HAUS · OSTDISTRIKT ═════")
    OUT+=("Jimmy Page    Rolle: Zeitungssammler")
    OUT+=("")
    render

    if [ "${JIMMY_GIVEN:-0}" = "1" ]; then
        say "Jimmy" "Das Haus ist gut. Das Haus hat alles – außer einer vollständigen Sammlung."
        jimmy_collector_loop
    elif [ "${TRACEY_FOUND:-0}" = "1" ] && [ "${JIMMY_TRACEY_DONE:-0}" != "1" ]; then
        jimmy_after_tracey_scene
    else
        jimmy_intro_scene
    fi

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
