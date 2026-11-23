# ============================================================
#  TerminalHero - Charakter: Novize Bill
#
#  Bill sitzt in der Kneipe »Zum Goldenen Lächeln« im Ostdistrikt
#  (Orte/Ostdistrikt.sh) in der Ecke am Fass und trinkt. Sein Standard-
#  gespräch verrät nur wenig: Er gehört einer seltenen Religion an,
#  nennt sie aber nicht, spricht gläubig und trauert um seinen »Meister«,
#  einen Priester, der verschwunden ist.
#
#  Quest »Seltsame Religion« (RELIGION_GIVEN, von Sherlock Holmes):
#  Dann bietet Bill die Gesprächsoption »Molerat Religion«. Er wird
#  nervös, sieht sich um und will nichts sagen. Der Agent kann es gut
#  sein lassen oder ihm ein Bier ausgeben (LightBeer, Items/Plunder/
#  LightBeer.sh). Mit Bier gesteht Bill angetrunken, dass er zu den
#  MoleratAnhängern gehört: Die Religion dreht sich um eine Molerat-
#  Königin und einen Priester, der mit ihr sprechen kann. Der Priester
#  ist verschwunden; um mehr zu erfahren, muss der Agent den Molerats
#  folgen. Bill bittet um Nachricht, falls der Agent etwas herausfindet
#  (Questlog-Update, BILL_TOLD). Danach hat Bill einen neuen
#  Standarddialog.
#
#  Lazy geladen über DIALOG[] (kern/loader.sh), erst beim ersten »touch«.
# ============================================================

# --- Standardgespräch (vor dem Geständnis) ---------------------------
dialog_novize_bill() {
    # Nach dem Bier gibt es einen neuen Standarddialog.
    if [ "${BILL_TOLD:-0}" = "1" ]; then
        novize_bill_after_scene
        return 0
    fi

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ KNEIPE »ZUM GOLDENEN LÄCHELN« · ECKE AM FASS ═════")
    OUT+=("Gast : Novize Bill    Zustand : angeheitert")
    OUT+=("")
    render

    BILL_MET=1

    say "-" "In der Ecke neben dem Fass sitzt ein hagerer Mann mit einem Glas, das er seit einer Weile nicht mehr abstellt. Er trägt einfache Kleidung, aber sorgfältig gefaltet."
    say "Bill" "Oh. Du bist nicht von hier, oder? Man sieht es an der Art, wie du schaust."
    say "Bill" "Ich bin … sagen wir, ich gehöre zu einer seltenen Gemeinde. Mehr muss ich darüber nicht sagen."
    say "-" "Er dreht das Glas zwischen den Fingern und lächelt, als wäre das Lächeln irgendwo eingeübt worden."
    say "Bill" "Sie hat uns gelehrt, dass Schweigen auch eine Form des Betens ist. Und dass man nicht jedem erzählt, was man glaubt."
    OUT+=("")
    say "$AGENT_NAME" "Und was glaubst du?"
    say "Bill" "Dass unter allem, was wir sehen, noch etwas anderes liegt. Etwas, das wartet."
    say "-" "Er nimmt einen Schluck. Dann noch einen, als müsste er etwas hinunterspülen."
    say "Bill" "Aber das ist nicht, warum ich hier bin. Ich trinke, weil ich meinen Meister verloren habe."
    say "Bill" "Einen Priester. Er war … er war der Einzige, der wirklich zugehört hat. Und jetzt ist er fort."
    say "Bill" "Ich weiß nicht, wohin er gegangen ist. Ich weiß nicht einmal, ob er noch lebt."
    OUT+=("")

    # Ohne die Quest von Holmes und ohne das Tagebuch gibt es hier nichts
    # weiter zu erfahren - Bill bleibt bei seinem Standardgespräch.
    local opts=() acts=()
    if [ "${RELIGION_GIVEN:-0}" = "1" ]; then
        opts+=("Molerat Religion"); acts+=("molerat")
    fi
    if novize_bill_book_available; then
        opts+=("Ich habe dieses Buch gefunden."); acts+=("buch")
    fi
    if [ "${#opts[@]}" -eq 0 ]; then
        say "-" "Er hebt das Glas, als hätte er damit alles gesagt, und sieht wieder in die Ecke."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return 0
    fi

    opts+=("Es gut sein lassen."); acts+=("lassen")
    OUT+=("")
    ask "${opts[@]}"
    case "${acts[$((CHOICE - 1))]}" in
        molerat) novize_bill_religion_scene ;;
        buch)    novize_bill_book_scene ;;
        lassen)  say "Bill" "Warum fragst du eigentlich? Nein - vergiss es. Es ist besser so."
                 say "-" "Er winkt ab und starrt wieder in sein Glas." ;;
    esac
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Hat der Agent das Tagebuch dabei und Bill hat es noch nicht gesehen?
novize_bill_book_available() {
    [ "${BILL_BOOK_DONE:-0}" = "1" ] && return 1
    inv_has schweinepriesters_tagebuch
}

# --- Quest-Option »Molerat Religion« --------------------------------
# Bill reagiert nervös und schweigt. Zwei Wege: es gut sein lassen oder
# ihm ein Bier ausgeben. Mit Bier erzählt er von den MoleratAnhängern.
novize_bill_religion_scene() {
    say "$AGENT_NAME" "Molerat Religion."
    say "-" "Bill hält mitten in der Bewegung inne. Sein Blick springt zur Tür, dann zur Theke – und bleibt einen Herzschlag zu lange an einem der Gäste hängen."
    say "Bill" "Nicht so laut."
    say "Bill" "Ich weiß nicht, was du meinst. Und ich glaube, du solltest diese Worte nicht in meiner Nähe sagen."
    say "-" "Er stellt das Glas ab, ohne zu trinken. Seine Hand liegt flach auf dem Tisch, als würde er sich daran festhalten."
    say "Bill" "Ich sage nichts dazu. Verstehst du? Ich sage nichts."

    local opts=() acts=()
    opts+=("Es gut sein lassen.")
    if inv_has lightbeer; then
        opts+=("Bier ausgeben."); acts+=("bier")
    else
        opts+=("Ich habe leider kein Bier dabei."); acts+=("keinbier")
    fi
    # Erste Option ist immer das Ausweichen.
    acts=("lassen" "${acts[@]}")
    OUT+=("")
    ask "${opts[@]}"
    case "${acts[$((CHOICE - 1))]}" in
        lassen)
            say "$AGENT_NAME" "Schon gut. Ich lasse es."
            say "Bill" "Danke."
            say "-" "Er atmet aus, nimmt das Glas wieder auf und trinkt. Das Gespräch ist vorbei." ;;
        keinbier)
            say "$AGENT_NAME" "Ich habe leider kein Bier dabei."
            say "Bill" "Bier öffnet keine Türen. Aber es macht das Schweigen erträglicher."
            say "-" "Er sieht wieder in sein Glas. Was immer er hätte sagen können, behält er für sich." ;;
        bier)
            novize_bill_beer_confession ;;
    esac
    return 0
}

# --- Bier ausgeben: das Geständnis ----------------------------------
novize_bill_beer_confession() {
    inv_remove lightbeer
    say "$AGENT_NAME" "Dann trinken wir einen zusammen. Das hier geht auf mich."
    say "-" "Du stellst eine Flasche LightBeer auf den Tisch. Bill starrt sie an, als hätte sie sich bekreuzigt."
    say "Bill" "Das … das ist nett. Wirklich."
    say "-" "Er öffnet sie mit dem Daumen, trinkt, und was in seinem Gesicht gefroren war, taut langsam auf."
    say "Bill" "Also gut. Aber wenn jemand fragt: Du hast mich betrunken gemacht."
    OUT+=("")
    say "Bill" "Ja. Ich bin einer von ihnen. Ein MoleratAnhänger."
    say "$AGENT_NAME" "MoleratAnhänger?"
    say "Bill" "So nennen wir uns. Nicht wegen ihres Fleisches. Wegen ihres Reiches."
    say "Bill" "Es gibt eine Königin. Unter der Stadt. In den Tunneln, in denen die Molerats leben. Sie ist alt und sie ist geduldig, und sie hört jedes Wort, das über sie gesprochen wird."
    say "Bill" "Und es gibt einen Priester, der mit ihr sprechen kann."
    OUT+=("")
    say "$AGENT_NAME" "Der Priester, den du verloren hast?"
    say "Bill" "Ja."
    say "-" "Er nimmt einen zweiten Schluck, größer als der erste."
    say "Bill" "Er war der Einzige, der die Stimme der Königin verstand. Ohne ihn sind wir nur Leute, die in einen dunklen Gang starren und hoffen."
    say "Bill" "Er ist vor einiger Zeit verschwunden. Nicht gegangen - verschwunden. Ohne Abschied, ohne Nachricht."
    say "Bill" "Wir haben die Tempel durchsucht, die Gänge, die alten Eingänge. Nichts."
    OUT+=("")
    say "$AGENT_NAME" "Und was soll ich tun?"
    say "Bill" "Wenn du es wirklich wissen willst: Folge den Molerats."
    say "Bill" "Sie führen dich in die Tiefe. Nicht alle Wege sind menschlich. Und nicht alle Molerats sind nur Tiere."
    say "-" "Er sieht dich zum ersten Mal direkt an, ohne auszuweichen."
    say "Bill" "Und wenn du etwas über den Priester erfährst - egal was -, dann sag es mir. Bitte."
    say "Bill" "Ich bin hier. Ich gehe nicht fort, solange ich warte."

    BILL_TOLD=1
    if declare -F quest_note >/dev/null 2>&1; then
        quest_note "Novize Bill ist Teil der MoleratAnhänger. Der Priester, der mit der Molerat-Königin spricht, ist verschwunden. Ich soll den Molerats folgen."
    fi
    return 0
}

# --- Das Tagebuch zeigen --------------------------------------------
# Bill erkennt das Buch sofort: ein heiliges Buch der MoleratAnhänger,
# geschrieben vom SchweinePriester. Er flippt fast aus, erzählt ein
# bisschen von der verlorenen Molerat-Zivilisation und verweist für
# mehr auf den Meister. Einmalig +300 EXP.
novize_bill_book_scene() {
    if [ "${BILL_BOOK_DONE:-0}" = "1" ]; then
        say "Bill" "Das Buch … ich habe es schon gesehen. Ich werde es nicht noch einmal aufschlagen."
        say "Bill" "Aber wenn du etwas über den Meister erfährst: Sag es mir."
        return 0
    fi

    # Sicherheitsnetz: Wer das Buch zeigt, ohne es gelesen zu haben, hat
    # die Spur trotzdem gefunden. Die Quest kommt dann über das Buch.
    if declare -F tagebuch_ensure_religion_quest >/dev/null 2>&1; then
        tagebuch_ensure_religion_quest
    fi

    say "$AGENT_NAME" "Ich habe dieses Buch gefunden."
    say "-" "Bill sieht das Leder. Dann die Schrift auf dem Vorsatz. Sein Glas entgleitet ihm fast, er fängt es im letzten Moment."
    say "Bill" "Wo … wo hast du DAS her?!"
    say "-" "Er springt halb auf, sieht zur Tür, dann wieder auf das Buch. Seine Hände zittern, als er danach greift – und es dann doch nicht anfasst."
    say "Bill" "Das ist ein heiliges Buch. Das Tagebuch des SchweinePriesters. Unseres Meisters."
    OUT+=("")
    say "$AGENT_NAME" "Der SchweinePriester hat das geschrieben?"
    say "Bill" "Ja. Er hat über uns geschrieben. Über die Königin. Über die Tunnel."
    say "Bill" "Und über die alte Zeit."
    say "-" "Er beugt sich vor und senkt die Stimme so weit, dass sie fast im Lärm der Kneipe verschwindet."
    say "Bill" "Es heißt, vor langer Zeit hätte es eine Molerat-Zivilisation gegeben. Keine Tiere in Höhlen – ein Volk. Mit Gängen wie Straßen und Kammern wie Häusern."
    say "Bill" "Man sagt, sie seien den Menschen ebenbürtig gewesen. Den Dateien. Vielleicht sogar älter."
    say "Bill" "Und dann … sind sie verschwunden. Einfach so. Ohne Krieg, ohne Spur."
    OUT+=("")
    say "$AGENT_NAME" "Und der Priester?"
    say "Bill" "Wenn jemand weiß, was damals passiert ist, dann er."
    say "Bill" "Der Meister hat die Königin verstanden. Er hat zugehört, wenn die Tunnel gesprochen haben."
    say "Bill" "Ich weiß nur Bruchstücke. Ich bin Novize, kein Forscher. Für den Rest musst du ihn finden."
    say "-" "Er schiebt das Buch vorsichtig zu dir zurück, als wäre es plötzlich schwerer geworden."
    say "Bill" "Aber bitte – wenn du ihn findest, sag es mir. Egal, was du von ihm hörst."

    BILL_BOOK_DONE=1
    if declare -F quest_note >/dev/null 2>&1; then
        quest_note "Bill: Das Tagebuch ist ein heiliges Buch der MoleratAnhänger. Der SchweinePriester könnte noch am Leben sein."
    fi
    play_sound select
    OUT+=("")
    OUT+=("   [ Belohnung ]  300 EXP")
    char_gain_exp 300
    return 0
}

# --- Neuer Standarddialog nach dem Geständnis -----------------------
novize_bill_after_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ KNEIPE »ZUM GOLDENEN LÄCHELN« · ECKE AM FASS ═════")
    OUT+=("Gast : Novize Bill    Zustand : angeheitert")
    OUT+=("")
    render

    say "-" "Bill sitzt noch in derselben Ecke, die Flasche LightBeer inzwischen leer. Er nickt dir zu, als wärt ihr nicht mehr nur Fremde."
    say "Bill" "Du schon wieder. Setz dich, wenn du magst."
    say "Bill" "Ich habe dir neulich zu viel erzählt. Aber ich bereue es nicht - noch nicht."
    say "-" "Er schiebt das leere Glas von sich weg und wird leiser."
    say "Bill" "Hast du die Molerats gefunden? Oder etwas über ihn? Über den Priester?"
    say "Bill" "Wenn nicht, dann geh in die Tiefe. Sie werden dich führen. So oder so."
    OUT+=("")
    say "Bill" "Und egal, was du findest: Sag mir Bescheid. Bitte."

    # Wer das Tagebuch dabeihat, kann es Bill auch nach dem Geständnis
    # noch zeigen (einmalig, +300 EXP).
    if novize_bill_book_available; then
        OUT+=("")
        ask "Ich habe dieses Buch gefunden." "Später."
        if [ "${CHOICE:-0}" = "1" ]; then
            novize_bill_book_scene
        fi
    fi
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
