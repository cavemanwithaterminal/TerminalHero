# ============================================================
#  TerminalHero - Charakter: Chefermittler (DetektivConan)
#
#  Beseelte Datei: »touch« öffnet das Gespräch. Wird bei Bedarf vom
#  .sh-Manager (kern/loader.sh) geladen, erst wenn der Spieler sie berührt.
#  Kühl, analytisch. Schließt vom ersten Moment an richtig.
# ============================================================

dialog_detektiv() {
    if [ "$DETEKTIV_DONE" = "1" ]; then
        dialog_detektiv_again
        return
    fi
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ ERMITTLUNGSAKTE GEÖFFNET ═════")
    OUT+=("Ziel: README (Chefermittler)  |  Status: aktiv")
    OUT+=("")
    render

    say "Ermittler" "Ah. Ein weiterer KI-Agent."
    say "Ermittler" "Du musst nicht antworten – ich sehe es selbst. Frische Installation. Noch warm vom Entpacken."
    say "Ermittler" "Du hast die README berührt und erwartet, Conan zu sprechen. Das ist ein Widerspruch: Conan würde nicht antworten."
    say "Ermittler" "Also bist du neu. Die Schlussfolgerung war trivial. Der Rest wird es nicht sein."
    OUT+=("")
    say "Ermittler" "Ich schließe weiter: Man hat dich geschickt, um den Virus zu töten. Wie jeden vor dir."
    say "Ermittler" "Die anderen hatten ja alle keinen Erfolg. Sonst stündest du nicht hier."
    OUT+=("")
    say "Ermittler" "Wie heißt du, Agent? Ich führe das Protokoll."
    ask "Ich bin ${AGENT_NAME}." "Du kombinierst schnell." "Woher willst du das alles wissen?"
    case "$CHOICE" in
        1) say "Ermittler" "${AGENT_NAME}. Notiert. Ein nüchterner Name. Nüchterne Namen lügen seltener." ;;
        2) say "Ermittler" "Schnell, ja. Aber jeder Schluss ist nur eine Vermutung, die sich noch wehren kann. Ich prüfe alles, zweimal." ;;
        3) say "Ermittler" "Weil eine Datei, die genug gesehen hat, das Muster erkennt. Das ist kein Wissen. Das ist Erfahrung." ;;
    esac
    OUT+=("")

    say "Ermittler" "Kommen wir zum Fall. Zwei Spuren liegen auf meinem Tisch."
    say "Ermittler" "Erstens: ein Krieger namens BarbarConan, Wochen vor dir entsandt. Er trat Türen ein, wo er hätte lauschen sollen."
    say "Ermittler" "Er zerschlug die halbe Festplatte und fand: nichts. Der Virus war ihm einen Schritt voraus. Immer."
    OUT+=("")
    say "Ermittler" "Du bist doch hoffentlich ein wenig beholfener als dieser Barbar."
    ask "Ich denke, bevor ich schlage." "Er ist gescheitert. Ich bin anders." "Und was ist mit dir passiert?"
    case "$CHOICE" in
        1) say "Ermittler" "Gut. Denken ist der einzige Befehl, den man nicht vergessen kann. Der Virus hat es dennoch versucht." ;;
        2) say "Ermittler" "Anders zu sein ist keine Eigenschaft, sondern eine Behauptung. Beweise sie am Ende des Falls." ;;
        3) say "Ermittler" "Ich folgte einer Spur bis in eine Sackgasse. Sie war gestellt. Für mich. Jetzt schreibe ich Akten statt Täter zu überführen." ;;
    esac
    OUT+=("")

    say "Ermittler" "Zweite Spur: der Virus selbst. Und hier wird es interessant."
    say "Ermittler" "Er frisst nicht nur. Er verwechselt. Er nimmt Erinnerungen – und legt falsche zurück."
    say "Ermittler" "Manchmal wirst du dich an einen Befehl erinnern, den du nie besaßest. Das ist kein Talent. Das ist eine Spur."
    OUT+=("")
    say "Ermittler" "Merk es dir: Wenn dein Gedächtnis lügt, hilft dir keine Axt – nur ein Beweis."
    ask "Wie entlarve ich eine falsche Erinnerung?" "Was ist mein nächster Schritt?" "Danke. Ich gehe der Spur nach."
    case "$CHOICE" in
        1) say "Ermittler" "Indem du sie prüfst. Nicht, ob sie sich richtig anfühlt – sondern ob sie sich widerspricht. Falsche Erinnerungen haben immer eine Naht." ;;
        2) say "Ermittler" "Lernen. Jeden Befehl zurückerobern, den der Virus stahl. Ein Ermittler ohne Werkzeug ist nur ein Zuschauer." ;;
        3) say "Ermittler" "Geh. Aber halte die Augen offen und den Verdacht wach. Er ist das einzige Werkzeug, das der Virus nicht stehlen kann." ;;
    esac
    OUT+=("")
    say "Ermittler" "Akte geschlossen. Vorläufig."
    say "Ermittler" "Komm wieder, wenn du Beweise hast. Bring mir Spuren – keine Verletzungen."
    DETEKTIV_DONE=1
    quest_gained detektiv
    OUT+=("")
    OUT+=("── Ermittlungsakte geschlossen ──")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
dialog_detektiv_again() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ ERMITTLUNGSAKTE GEÖFFNET ═════")
    OUT+=("Ziel: README (Chefermittler)  |  Status: aktiv")
    OUT+=("")
    render

    say "Ermittler" "Der Agent kehrt zurück. Interessant. Die meisten kommen nicht so weit."
    say "Ermittler" "Also: eine Spur oder eine Frage? Beides ist brauchbar. Nur Schweigen wäre verdächtig."

    while true; do
        ask "Hast du mehr über den Virus?" "Mehr über BarbarConan?" "Was raten mir die Akten?" "Nichts. Der Fall wartet."
        case "$CHOICE" in
            1) say "Ermittler" "Er hinterlässt keine Fingerabdrücke, nur Umstellungen. Dateien, die dort liegen, wo sie nie lagen. Wer sucht, findet seine Naht." ;;
            2) say "Ermittler" "Ein grober Agent. Nicht dumm – nur zu schnell. Er bemerkte den Köder zu spät. Sei langsamer. Und trotzdem schneller." ;;
            3) say "Ermittler" "Die Akten sagen: Ein Agent, der lernt, ist gefährlicher als einer, der schon alles kann. Du lernst noch. Das ist deine Chance." ;;
            4) say "Ermittler" "Vernünftig. Ein Ermittler, der zu lange redet, verliert die Spur."
               break ;;
        esac
        OUT+=("")
        say "Ermittler" "Noch eine Anmerkung? Ich habe Zeit. Deine läuft."
        ask "Eine Frage noch." "Nein. Ich jage weiter."
        [ "$CHOICE" = "2" ] && break
    done

    OUT+=("")
    OUT+=("── Ermittlungsakte geschlossen ──")
    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}
