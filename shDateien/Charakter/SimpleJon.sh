# ============================================================
#  TerminalHero - Charakter: Simple Jon
# ------------------------------------------------------------
#  Eine der Stadtwachen und der feste Bewohner des Wachhauses im
#  Haupteingang - jener Pausen- und Schlafraum, in dem die Wache
#  zwischen zwei Diensten verschwindet.
#
#  Simple Jon ist ein einfacher Kerl: nüchtern, knapp, nicht sehr
#  interessant. Sein Humor ist trocken, und meistens merkt er selbst
#  nicht, dass er gerade einen gemacht hat.
#
#  Beseelte Datei: »touch SimpleJon« öffnet das Gespräch. Wird bei
#  Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#
#  Mit der Nebenquest »Wo ist Nek Molerat?« (NEK_GIVEN) kommt die
#  Option »Nek Molerat?« dazu. Jon weiß nur, dass Nek ein Kollege
#  und mit Simon Guard befreundet ist - und dass er die Stadt
#  verlassen hat, um etwas zu erledigen. Das aktualisiert NUR den
#  Verlauf der Nek-Quest, nicht die Hauptquest.
# ============================================================

dialog_simple_jon() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ WACHHAUS · PAUSENRAUM ═════")
    OUT+=("Simple Jon    Posten: Stadtwache    Status: Pause")
    OUT+=("")
    render

    say "Simple Jon" "Ich bin Simple Jon. Stadtwache."
    say "Simple Jon" "Das hier ist das Wachhaus. Pausenraum, Schlafraum, und der einzige Ort in der Stadt, an dem ich nicht draußen stehen muss."
    say "Simple Jon" "Der Stuhl ist frei. Das Bett auch. Der Kaffee ist älter als ich. Das ist kein Vergleich. Das ist eine Feststellung."
    say "-" "Er sagt es, ohne eine Miene zu verziehen."
    say "Simple Jon" "Wenn du Ärger hast: draußen. Wenn du Pause hast: setz dich. Wenn du beides hast: setz dich draußen."
    OUT+=("")

    # Nach dem Fund von Neks Leiche reagiert Jon einmalig. Der Fund kann
    # auch vor Simons Quest passieren; deshalb hängt der Dialog nur an
    # NEK_FOUND, nicht an NEK_GIVEN.
    if [ "${NEK_FOUND:-0}" = "1" ] \
       && [ "${JON_NEK_FOUND_INFO:-0}" != "1" ]; then
        say "-" "Jon sieht auf, bevor du etwas sagst. Sein Blick bleibt an deinen Schuhen hängen."
        say "Simple Jon" "Du hast ihn gefunden. Nek."
        say "Simple Jon" "Ich hab es an deinem Gesicht gesehen. So sieht keiner aus, der nur eine Tür aufgehalten hat."
        say "Simple Jon" "Danke. Und ... sag Simon, dass ich es weiß. Er soll nicht denken, ich wäre der Letzte, der es erfährt."
        JON_NEK_FOUND_INFO=1
    fi

    if [ "${NEK_GIVEN:-0}" = "1" ]; then
        local opts=() acts=()
        opts+=("Nek Molerat?"); acts+=("nek")
        opts+=("Sonst nichts."); acts+=("anders")
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            nek)    simple_jon_nek_scene ;;
            anders) say "Simple Jon" "Gut. Der Stuhl bleibt frei." ;;
        esac
    fi

    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

# ============================================================
#  Was Simple Jon über Nek weiß
# ------------------------------------------------------------
#  Nek ist sein Kollege und mit Simon Guard befreundet. Jon hat
#  nicht gefragt, was Nek in der Stadt draußen erledigen wollte -
#  er dachte, Nek kommt zurück. Beim ersten Gespräch wird JON_NEK_INFO
#  gesetzt und der Verlauf der Nek-Quest ergänzt. Die Hauptquest
#  »Vermisste Bewohner« bleibt ausdrücklich unberührt.
# ============================================================
simple_jon_nek_scene() {
    if [ "${JON_NEK_INFO:-0}" = "1" ]; then
        say "Simple Jon" "Nek Molerat. Ich habe dir schon alles gesagt, was ich weiß."
        say "Simple Jon" "Er ist aus der Stadt gegangen, um etwas zu erledigen. Seitdem ist er nicht wieder aufgetaucht."
        return 0
    fi

    say "Simple Jon" "Nek Molerat. Ja. Er ist einer von uns. Stadtwache."
    say "Simple Jon" "Er und Simon Guard sind befreundet. Die beiden haben früher zusammen Dienst gemacht."
    say "Simple Jon" "Alles, was ich weiß: Nek ist aus der Stadt gegangen, um etwas zu erledigen."
    say "Simple Jon" "Seitdem ist er nicht wieder aufgetaucht."
    say "$AGENT_NAME" "Hat er gesagt, was er erledigen wollte?"
    say "Simple Jon" "Nein. Ich habe nicht gefragt. Ich dachte, er kommt zurück."
    say "-" "Er sieht kurz auf den leeren Stuhl neben sich. Dann wieder dich an."
    say "Simple Jon" "Wenn du ihn findest, sag Simon Bescheid. Und mir. In der Reihenfolge."

    JON_NEK_INFO=1
    quest_note "Simple Jon: Nek hat die Stadt verlassen, um etwas zu erledigen."
}
