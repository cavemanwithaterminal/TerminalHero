# ============================================================
#  TerminalHero - Charakter: Francesco Dellamorte
# ------------------------------------------------------------
#  Der Totengräber im Brachland-Friedhof. Er ist Italiener, kümmert
#  sich um die Bestattungen und hat eine sehr eigene Art, mit seinem
#  Beruf und den Dingen umzugehen: Er spricht mit den Steinen, achtet
#  auf die Reihenfolge der Gräber und nimmt den Tod persönlich – aber
#  nicht tragisch.
#
#  Erstes Treffen (FRANCESCO_MET=0): ein längeres, mysteriöses
#  Gespräch mit schwarzem Humor. Danach (FRANCESCO_MET=1) bleibt ein
#  kurzer Standard-Dialog.
#
#  Am Beerdigungstag vor 16:00 hat Francesco einen eigenen kurzen
#  Standard-Dialog zur anstehenden Trauerfeier (NeksBeerdigung.sh).
#  Der normale Erstkontakt bleibt für alle anderen Tage erhalten.
#
#  Sein Geheimnis: Gelegentlich erheben sich die Beerdigten wieder.
#  Dann ist es seine Aufgabe, sie endgültig zur Ruhe zu bringen.
#  Dieses Geheimnis wird im Spiel NIRGENDS ausgesprochen – weder im
#  cat-Text noch in einem Dialog oder Questlog. höchstens als leise,
#  mehrdeutige Andeutung.
#
#  Beseelte Datei: »touch FrancescoDellamorte« öffnet das Gespräch.
#  Lazy geladen über DIALOG[] (kern/loader.sh).
# ============================================================

# --- Erstes Treffen ------------------------------------------------
francesco_intro() {
    say "-" "Zwischen den Grabsteinen kniet ein Mann in einem dunklen Mantel. Er wischt Laub von einem Stein, als würde er ein Gesicht waschen."
    say "-" "Neben ihm lehnt eine Schaufel. Der Griff ist glatt, als hätte ihn jemand über Jahre im selben Rhythmus gehalten."
    say "Francesco" "Buongiorno. Du bist zu früh. Oder zu spät. Bei mir ist das schwer zu sagen."
    say "-" "Er steht auf, klopft sich die Erde von den Knien und mustert dich. Neugierig. Nicht misstrauisch."
    say "Francesco" "Francesco Dellamorte. Totengräber. Der einzige Mensch hier, der arbeitet, ohne dass ihn jemand darum bittet."
    say "$AGENT_NAME" "Ich bin $AGENT_NAME. Ich schaue mich nur um."
    say "Francesco" "Das sagen alle. Die einen suchen jemanden. Die anderen haben jemanden vergessen."
    say "-" "Er sagt es ohne Vorwurf. Fast freundlich."
    say "Francesco" "Ich grabe, ich schließe, ich höre zu. In dieser Reihenfolge. Meistens."
    say "Francesco" "Meine Kunden beschweren sich nie. Das ist einer der Gründe, warum ich den Job mag."
    say "Francesco" "Der andere ist die frische Luft."

    OUT+=("")
    ask "Du sprichst mit den Gräbern?" "Ist dir das nie unheimlich?" "Warum ausgerechnet hier?"
    case "${CHOICE:-0}" in
        1)
            say "Francesco" "Mit den Gräbern? Nein. Mit den Namen. Die Gräber hören nur zu."
            say "Francesco" "Und sie unterbrechen nie. Das ist mehr, als man von den meisten Lebenden behaupten kann."
            ;;
        2)
            say "Francesco" "Unheimlich? Nur wenn man vergisst, dass die Lebenden viel mehr Lärm machen."
            say "Francesco" "Die hier sind ruhig. Höflich. Und sie halten ihre Termine ein."
            ;;
        *)
            say "Francesco" "Weil hier niemand etwas von mir will. Außer einer ordentlichen Grabstelle."
            say "Francesco" "Das ist mehr, als man von den meisten Jobs sagen kann."
            ;;
    esac

    say "-" "Er legt die Hand auf den Stein. Eine kurze, beinahe zärtliche Geste."
    say "Francesco" "Weißt du, was die Leute am meisten unterschätzen?"
    say "Francesco" "Nicht den Tod. Die Reihenfolge."
    say "Francesco" "Ein Name an der falschen Stelle, ein Grab zu weit links, und plötzlich ist niemand mehr da, wo er hingehört."
    say "Francesco" "Ordnung ist eine Form von Respekt. Vielleicht die letzte, die man noch zeigen kann."
    say "-" "Er sieht dich an. Zum ersten Mal richtig."
    say "Francesco" "Manchmal habe ich mehr zu tun, als auf dem Plan steht."
    say "Francesco" "Aber das gehört nicht auf einen Grabstein."
    say "-" "Er lächelt. Es ist ein müdes Lächeln, aber kein trauriges."
    say "Francesco" "Kaffee? Er ist stark genug, um einen Trauerzug zu beleben."

    OUT+=("")
    ask "Ja, danke." "Nein, danke."
    case "${CHOICE:-0}" in
        1)
            say "-" "Er schenkt aus einer verbeulten Thermoskanne in einen Becher, der schon bessere Tage gesehen hat."
            say "Francesco" "Nicht gut. Aber stark. Wie die meisten von uns."
            ;;
        *)
            say "Francesco" "Vernünftig. Ich trinke ihn auch nur, weil die Alternative Schlaf ist."
            ;;
    esac

    say "Francesco" "Komm wieder, wenn du reden willst. Oder wenn du schaufeln kannst. Reden ist billiger."
    say "-" "Er nimmt die Schaufel und wendet sich wieder dem nächsten Grab zu."
    say "Francesco" "Und wenn du nachts hier bist: Grüß die Steine. Manche sind empfindlich."
}

# --- Standard-Dialog ----------------------------------------------
francesco_standard() {
    say "-" "Francesco steht zwischen den Reihen, die Schaufel über der Schulter. Er hat dich kommen sehen."
    say "Francesco" "Ah. Der Agent. Der Friedhof ist heute ruhig."
    say "Francesco" "Zu ruhig, sagen die Leute. Ich nenne es Ordnung."
    say "Francesco" "Wenn du ein Grab suchst: von links nach rechts, dann die zweite Reihe. Wenn du mich suchst: Ich bin da, wo die Erde offen ist."
    say "Francesco" "Und wenn du nur reden willst: Setz dich nicht auf einen Stein. Sie mögen das nicht."
    say "-" "Er sagt es vollkommen ernst. Dann zwinkert er."
    say "Francesco" "Der Kaffee ist noch warm. Das ist mehr, als man von den meisten hier sagen kann."
}

# --- Einstieg über »touch FrancescoDellamorte« ----------------------
dialog_francesco_dellamorte() {
    # Beerdigungstag nach der Trauerfeier: kurzes Nachgespräch.
    if declare -F nek_funeral_after >/dev/null 2>&1 \
       && declare -F nek_funeral_francesco_after >/dev/null 2>&1 \
       && nek_funeral_after; then
        nek_funeral_francesco_after
        return 0
    fi

    # Beerdigungstag vor 16:00: eigener Dialog zur Trauerfeier.
    if declare -F nek_funeral_before_start >/dev/null 2>&1 \
       && declare -F nek_funeral_francesco_standard >/dev/null 2>&1 \
       && nek_funeral_before_start; then
        nek_funeral_francesco_standard
        return 0
    fi

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ BRACHLAND · FRIEDHOF ═════")
    OUT+=("Francesco Dellamorte    Totengräber")
    OUT+=("Herkunft: Italien       Stimmung: gelassen")
    OUT+=("")
    render

    if [ "${FRANCESCO_MET:-0}" = "1" ]; then
        francesco_standard
    else
        FRANCESCO_MET=1
        francesco_intro
    fi

    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
