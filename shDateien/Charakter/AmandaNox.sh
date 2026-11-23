# ============================================================
#  TerminalHero - Charakter: Amanda Nox
#
#  Assistentin & Sekretärin in der Detektei Holmes (Ostdistrikt). Sherlock
#  Holmes selbst ist dort nicht anzutreffen - sie führt das Büro.
#
#  Beseelte Datei: »touch« öffnet das Gespräch, »cat« zeigt den Inhalt,
#  »file« die Metadaten (sofern der Befehl schon erlernt ist).
#
#  Vor Pixis Brief (PIXI_LETTER_DONE=0) führt sie ein normales
#  Bürogespräch ohne jeden Sherlock-Hinweis. Erst im Rahmen der Quest
#  »Großer Ermittler« verweist sie auf die Kneipe von Börty Smiles
#  (»Zum Goldenen Lächeln«, Ostdistrikt) und setzt AMANDA_DONE. Ihr
#  Hinweis: Holmes ist oft nachts in der Stadt unterwegs - hier im
#  Ostdistrikt.
#
#  Lazy geladen über DIALOG[] (kern/loader.sh), erst beim ersten »touch«.
# ============================================================

# --- Nach »Großer Ermittler«: Unterstützung für Amanda ----------------
# Amanda bekommt eine eigene Nebenquest: Sie ertrinkt in Akten und sucht
# jemanden, der ihr bei der Abarbeitung hilft. Die Quest nennt bewusst
# keine Kandidaten - den passenden Helfer muss der Spieler selbst finden
# (Jack Nullpunkt im DailyPulse-Verlag).
amanda_help_header() {
    OUT=()
    OUT+=("═════ DETEKTEI HOLMES · VORZIMMER ═════")
    OUT+=("Ort : Ostdistrikt    Amanda Nox : Assistentin & Sekretärin")
    OUT+=("")
}

amanda_help_offer() {
    local action
    local -a opts=() actions=()

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    amanda_help_header
    render

    say "-" "Amanda sitzt hinter einem Stapel Akten, der höher ist als der Bildschirm. Die Kaffeetasse am Rand ist längst kalt."
    say "Amanda" "Sie wollen mir helfen?"
    say "Amanda" "Nett gemeint. Aber ich wüsste nicht, womit."

    while true; do
        opts=(); actions=()
        if [ "${AMANDA_HELP_GIVEN:-0}" != "1" ]; then
            opts+=("Kann ich dir helfen?"); actions+=("help")
        else
            opts+=("Worum ging es noch?"); actions+=("remind")
        fi
        opts+=("Nichts weiter."); actions+=("leave")

        OUT+=("")
        OUT+=("Was möchtest du?")
        render
        ask "${opts[@]}"
        action="${actions[$((CHOICE - 1))]}"

        case "$action" in
            help)
                say "Amanda" "Wirklich? Dann sehen Sie sich das hier an."
                say "-" "Sie deutet auf drei Stapel: einer nach Datum, einer nach Fall und einer ohne erkennbare Ordnung."
                say "Amanda" "Ich führe das Vorzimmer, die Termine und die Akten von Mr. Holmes. Wenn er nachts unterwegs ist, muss hier alles weiterlaufen."
                say "$AGENT_NAME" "Das klingt, als bräuchten Sie nicht nur eine gute Idee, sondern jemanden, der mit anpackt."
                say "Amanda" "Das klingt vor allem nach jemandem, der die Arbeit nicht nach einer Woche hinschmeißt."
                say "Amanda" "Diese Arbeit ist nicht für jeden. Zu viel Papier, zu wenig Applaus. Die meisten unterschätzen, wie viel Geduld in einer einzigen Akte steckt."
                say "-" "Sie legt eine Seite beiseite, dann noch eine. Ihre Finger sind schnell, ihr Blick müde."
                say "Amanda" "Ich komme morgens, sortiere, telefoniere, beruhige Zeugen und schreibe mit, was Mr. Holmes für wichtig hält. Abends liegt hier mehr Arbeit als morgens."
                say "$AGENT_NAME" "Dann brauchen Sie jemanden, der Ihnen bei den angestauten Akten hilft. Nicht als Ersatz für Mr. Holmes. Als zweite Hand."
                say "-" "Amanda hält inne. Zum ersten Mal sieht sie nicht an dir vorbei auf die Papiere."
                say "Amanda" "Das ist eine gute Idee."
                say "Amanda" "Aber wer kommt dafür in Frage? Die halbe Stadt kennt mich nur als die Frau an Holmes' Tür. Die andere Hälfte weiß nicht einmal, dass es dieses Büro gibt."
                say "$AGENT_NAME" "Ich halte die Augen offen. Vielleicht finde ich jemanden."
                say "Amanda" "Wenn Sie wirklich jemanden finden, schicken Sie ihn vorbei. Ich bringe ihm bei, was er wissen muss."
                say "Amanda" "Und wenn es nur für ein paar Stunden am Tag ist. Hauptsache, der Berg wird kleiner."
                say "-" "Sie schiebt den obersten Stapel ein Stück zur Seite. Darunter kommt ein zweiter zum Vorschein."
                say "Amanda" "Danke. Allein die Frage tut gut."

                quest_gain_once amanda
                AMANDA_HELP_GIVEN=1
                quest_note "Amanda Nox sucht jemanden, der ihr bei den angestauten Akten in der Detektei hilft."
                OUT+=("")
                OUT+=("[ NEUES ZIEL ]  Finde jemanden, der Amanda bei den Akten unterstützen kann.")
                dialog_pause
                ;;
            remind)
                say "Amanda" "Der Stapel ist nicht kleiner geworden. Aber ich halte die Augen offen, wenn Sie es auch tun."
                say "Amanda" "Falls Sie jemanden finden: Er muss nicht perfekt sein. Nur zuverlässig."
                dialog_pause
                ;;
            leave)
                break
                ;;
        esac
    done

    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

amanda_help_reminder() {
    local action
    local -a opts=() actions=()

    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    amanda_help_header
    render

    if [ "${AMANDA_HELP_ASKED:-0}" = "1" ] && [ "${ZEITUNG_DONE:-0}" != "1" ]; then
        say "Amanda" "Sie haben also jemanden im Blick?"
        say "Amanda" "Dann lassen Sie sich Zeit. Ich weiß, wie es ist, wenn noch etwas Dringendes dazwischenkommt."
    else
        say "Amanda" "Schon jemand gefunden, der sich durch diesen Stapel arbeiten würde?"
        say "$AGENT_NAME" "Noch nicht. Ich bin dran."
        say "Amanda" "Kein Druck. Der Stapel hat auch keinen."
    fi

    while true; do
        opts=("Worum ging es noch?"); actions=("remind")
        opts+=("Nichts weiter."); actions+=("leave")

        OUT+=("")
        OUT+=("Was möchtest du?")
        render
        ask "${opts[@]}"
        action="${actions[$((CHOICE - 1))]}"

        case "$action" in
            remind)
                say "Amanda" "Jemand, der Akten ernst nimmt, Termine nicht vergisst und nicht nach Ruhm fragt. Der Rest lässt sich lernen."
                say "-" "Sie klopft zweimal auf den Stapel, als wäre er ein müder Kollege."
                dialog_pause
                ;;
            leave)
                break
                ;;
        esac
    done

    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Jack hat den Weg in die Detektei gefunden: Amanda bedankt sich und
# schließt die Nebenquest ab (200 EXP).
amanda_help_complete() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    amanda_help_header
    render

    say "-" "Im Vorzimmer steht jetzt ein zweiter Stuhl. Jack sitzt daran, die Ärmel hochgekrempelt, und sortiert Akten in zwei Stapel – schneller, als Amanda sie ihm reicht."
    say "Amanda" "Sie haben ihn wirklich hergebracht."
    say "Amanda" "Jack Nullpunkt. Ich muss zugeben: Ich hätte nicht gedacht, dass ausgerechnet der ruhige Bruder der Reporterin hier auftaucht."
    say "Jack" "Ich rechne lieber zweimal. Das hilft bei Akten."
    say "Amanda" "Er ist eine gute Wahl. Wirklich."
    say "Amanda" "In der ersten Stunde hat er mehr sortiert als ich in den letzten drei Tagen. Und er stellt die richtigen Fragen."
    say "Amanda" "Zum ersten Mal seit Wochen sieht dieser Schreibtisch aus, als könnten wir ihn noch heute abarbeiten. Es gibt jetzt Hoffnung, dass wir den Berg kleiner bekommen."
    say "Amanda" "Danke. Das meine ich ernst."

    AMANDA_HELP_DONE=1
    quest_reward amanda 200
    quest_note "Jack Nullpunkt arbeitet jetzt in der Detektei Holmes. Amanda hat sich bedankt."

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Neuer Standard-Dialog nach dem Abschluss: der Berg wird kleiner.
amanda_help_done_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    amanda_help_header
    render

    say "Amanda" "Wir kommen hier gut voran mit den Akten."
    say "Amanda" "Jack hat seinen Rhythmus gefunden. Zwischendurch fragt er sogar nach dem Kaffee."
    say "-" "Sie zieht eine Akte heraus – diesmal nicht, um sie wegzulegen, sondern um sie abzuschließen."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# Die Vorstellung gibt es nur einmal - unabhängig davon, ob der Agent
# gerade wegen der Sherlock-Quest hier ist oder nur zufällig vorbeikommt.
amanda_intro_once() {
    [ "${AMANDA_INTRO_DONE:-0}" = "1" ] && return 0
    AMANDA_INTRO_DONE=1
    say "-" "Das Vorzimmer ist ordentlicher als die Straße davor: ein Schreibtisch, zwei Stühle, Akten nach Datum sortiert. Dahinter eine Frau, die den Agenten mustert, bevor er ein Wort sagt."
    say "Amanda" "Amanda Nox. Ich führe dieses Büro."
    say "Amanda" "Ich nehme Aufträge an, sortiere Akten und halte den Kaffee warm."
    say "Amanda" "Mr. Holmes ist nicht zu sprechen. Das ist keine Ausnahme, das ist der Normalfall."
    return 0
}

dialog_amanda() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ DETEKTEI HOLMES · VORZIMMER ═════")
    OUT+=("Ort : Ostdistrikt    Amanda Nox : Assistentin & Sekretärin")
    OUT+=("")
    render

    # ---- Nach der Hauptquest »Großer Ermittler« -----------------------
    # Amanda hat jetzt eine eigene Nebenquest. Vor dem Abschluss von
    # »Großer Ermittler« bleibt ihr Dialog unverändert.
    if [ "${AMANDA_HELP_DONE:-0}" = "1" ]; then
        amanda_help_done_scene
        return
    fi
    if [ "${AMANDA_HELP_GIVEN:-0}" = "1" ] && [ "${AMANDA_HELP_JACK:-0}" = "1" ]; then
        amanda_help_complete
        return
    fi
    if [ "${AMANDA_HELP_GIVEN:-0}" = "1" ]; then
        amanda_help_reminder
        return
    fi
    if [ "${ERMITTLER_DONE:-0}" = "1" ]; then
        amanda_help_offer
        return
    fi

    if [ "${SHERLOCK_BRIEF:-0}" = "1" ]; then
        say "-" "Amanda blickt von ihren Akten auf. Über dem Schreibtisch brennt noch dieselbe Lampe wie in der Nacht, in der Holmes zurückkam."
        say "Amanda" "Mr. Holmes ist im Büro. Zum ersten Mal seit Tagen."
        say "Amanda" "Er tut so, als wäre nichts gewesen. Aber ich habe die Akte gesehen – und die Katze."
        say "Amanda" "Ja. Die Katze. Er wird es abstreiten, wenn Sie ihn fragen."
        say "Amanda" "Wenn Sie mit ihm sprechen wollen: klopfen Sie. Er hört es sowieso."
        say "-" "Sie zieht die nächste Akte heran, als hätte sie nie etwas anderes getan."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- Quest-Hinweis: nur im Zusammenhang mit »Großer Ermittler« -----
    # Vor Pixis Brief ist Amanda nur die Sekretärin; sie gibt keine Spur
    # und setzt auch kein AMANDA_DONE. Wer Holmes schon nachts getroffen
    # hat, braucht ihren Hinweis auf Börty nicht mehr.
    if [ "${PIXI_LETTER_DONE:-0}" = "1" ] && [ "${AMANDA_DONE:-0}" != "1" ] \
       && [ "${SHERLOCK_DONE:-0}" != "1" ]; then
        amanda_intro_once
        OUT+=("")
        say "$AGENT_NAME" "Ich suche Sherlock Holmes."
        say "Amanda" "Das tun die meisten, die hier hereinkommen."
        say "Amanda" "Er ist nicht da. Und bevor Sie fragen: genau weiß ich es nicht."
        say "-" "Sie legt eine Akte weg, ohne den Blick von dir zu nehmen."
        say "Amanda" "Er kommt und geht, wie es der Fall verlangt. Gestern war er hier. Vielleicht auch vorgestern – er rechnet nicht in Tagen, er rechnet in Spuren."
        OUT+=("")
        say "Amanda" "Eins kann ich Ihnen sagen: Mr. Holmes ist oft nachts in der Stadt unterwegs. Hier im Ostdistrikt. Wenn Sie ihn suchen wollen, suchen Sie ihn, wenn es dunkel ist."
        say "Amanda" "Und wenn Sie nicht warten wollen: versuchen Sie es in der Kneipe."
        say "Amanda" "»Zum Goldenen Lächeln«, im Ostdistrikt – ein paar Straßen weiter. Der Wirt heißt Börty Smiles."
        say "Amanda" "Wir Sekretärinnen notieren, was gesagt wird. Wirte hören alles, was gesagt wird."
        OUT+=("")
        AMANDA_DONE=1
        say "-" "Sie zieht die nächste Akte heran. Das Gespräch ist beendet – höflich, gründlich, ohne Umweg."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    if [ "${AMANDA_DONE:-0}" = "1" ]; then
        if [ "${SHERLOCK_DONE:-0}" = "1" ]; then
            say "Amanda" "Sie haben ihn also gefunden."
            say "Amanda" "Dann brauchen Sie mich nicht mehr. Mr. Holmes kommt und geht, wie er will."
        else
            say "Amanda" "Mr. Holmes ist noch nicht zurück."
            say "Amanda" "Versuchen Sie es in der Kneipe »Zum Goldenen Lächeln« bei Börty Smiles – oder draußen, wenn es dunkel ist."
        fi
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- Standardgespräch ohne Questbezug ------------------------------
    amanda_intro_once
    say "Amanda" "Bürozeiten sind Bürozeiten. Auch für Agenten ohne Termin."
    say "-" "Sie schiebt eine Akte gerade, mustert dich kurz und schreibt weiter."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
