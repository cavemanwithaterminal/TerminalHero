# ============================================================
#  TerminalHero - Charakter: Simon Guard
# ------------------------------------------------------------
#  Der Mann am Haupttor. In der Stadt kennt man ihn als Torwache;
#  sein Name ist Simon Guard. Die Datei im Spiel heißt weiterhin
#  »Torwächter«, weil das sein Posten ist.
#
#  Beseelte Datei: »touch« öffnet das Gespräch. Wird bei Bedarf vom
#  .sh-Manager (kern/loader.sh) geladen, erst wenn der Spieler sie berührt.
#
#  Zwei Zustände:
#    1) Erstkontakt (TORWAEHTER_DONE=0): das ausführliche Gespräch
#       am Tor (»Ich hoffe, ich bereue es nicht …«).
#    2) Danach (TORWAEHTER_DONE=1): der kurze Standard-Dialog
#       (»Bisher kein Ärger …«).
#
#  Mit der Hauptquest »Vermisste Bewohner« (VERMISSTE_GIVEN) kommt
#  im Standardgespräch die Option »Vermisste Bewohner?« dazu. Simon
#  erzählt von den Verschwundenen und von seinem Freund Nek Molerat;
#  daraus entsteht die Nebenquest »Wo ist Nek Molerat?« (NEK_GIVEN).
#  Der Hinweis auf Simple Jon im Wachhaus führt in den Haupteingang.
#
#  Nek-Abschluss (NEK_FOUND/NEK_DONE): Sobald der Agent Nek gefunden
#  hat, startet das Gespräch direkt mit dem Fund. Es gibt vier Wege:
#    - ohne Leiche und ohne Amulett: Simon schickt zurück zum Suchen
#    - mit Amulett: Kaufangebot (150 Bits) oder Behalten (500 EXP)
#    - mit Leiche: Schock, Trauer; Simon sucht ggf. selbst (150 Bits/750 EXP)
#    - Leiche + Amulett: dasselbe Kaufgespräch wie beim Amulett allein
#  Die Friedhofs-/Begräbnisvariante folgt, sobald es einen Friedhof gibt.
#
#  dialog_torwaechter bleibt als alter Name erhalten - die
#  Spielmechanik (DIALOG, Tests, Szenen) kennt ihn noch.
# ============================================================

# Liegt Neks Leiche gerade im aktuellen Ordner (also bei Simon)?
simon_nek_corpse_here() {
    declare -F neks_leiche_here >/dev/null 2>&1 && neks_leiche_here
}

# Ist das Amulett im Inventar? (Egal, ob getragen oder nur dabei.)
simon_nek_has_amulet() {
    declare -F inv_has >/dev/null 2>&1 && inv_has neksamulett
}

dialog_simon_guard() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ HAUPTTOR · SIMON GUARD ═════")
    OUT+=("Posten : Torwache    Status : im Dienst")
    OUT+=("Stimmung : angespannt")
    OUT+=("")
    render

    if [ "${TORWAEHTER_DONE:-0}" = "1" ]; then
        say "-" "Simon Guard lehnt an seinem Posten und nickt dir knapp zu."
        say "Simon Guard" "Ah, du bist das. Bisher kein Ärger – bleib dabei, dann bleiben wir Freunde."
        say "Simon Guard" "Fällt dir was Verdächtiges auf, weißt du, wo ich stehe."
    else
        TORWAEHTER_DONE=1
        say "Simon Guard" "Ich hoffe, ich bereue es nicht, euch reingelassen zu haben."
        say "Simon Guard" "Macht bloß keinen Ärger. Mein Job ist mir wichtig."
        say "-" "Er mustert dich noch einmal, von oben bis unten. Dann nickt er – kaum sichtbar."
        say "Simon Guard" "Wenn dir was auffällt, was hier nicht hingehört: sag's mir. Bevor es jemand merkt."
        OUT+=("")
        say "-" "Kein Held, kein Chef der Wache. Nur der Mann an der Tür."
    fi

    # --- Nek-Fund: Das Gespräch beginnt direkt mit der Meldung ---------
    # Die Leiche beim Tor und das Amulett im Inventar sind eindeutige
    # Beweise; dann braucht es keine Menüauswahl mehr. Ohne beides wird
    # nur beim ERSTEN Bericht automatisch nachgefragt.
    local nek_handled=0
    if [ "${NEK_GIVEN:-0}" = "1" ] && [ "${NEK_DONE:-0}" != "1" ]; then
        if simon_nek_corpse_here; then
            simon_nek_corpse_scene
            nek_handled=1
        elif simon_nek_has_amulet; then
            simon_nek_amulet_scene
            nek_handled=1
        elif [ "${NEK_FOUND:-0}" = "1" ] \
             && [ "${NEK_REPORTED:-0}" != "1" ]; then
            simon_nek_no_loot_scene
            nek_handled=1
        fi
    fi

    # Nach dem Nek-Abschluss darf der Agent nach dem Namen fragen. Das
    # passiert direkt im selben Gespräch, sobald die Abschlussszene durch
    # ist – und später erneut über »Vermisste Bewohner?«.
    if [ "$nek_handled" = "1" ] && [ "${NEK_DONE:-0}" = "1" ]; then
        simon_nek_family_offer
    fi

    # Die Hauptquest öffnet die Frage nach den Vermissten. Option und
    # Aktion laufen getrennt, damit später weitere Fragen dazukommen
    # können, ohne dass sich die Nummern verschieben.
    if [ "$nek_handled" = "0" ] && [ "${VERMISSTE_GIVEN:-0}" = "1" ]; then
        local opts=() acts=()
        opts+=("Vermisste Bewohner?"); acts+=("vermisste")
        opts+=("Sonst nichts.");       acts+=("anders")
        OUT+=("")
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            vermisste) simon_nek_scene ;;
            anders)    say "Simon Guard" "Dann geh. Und halt die Augen offen." ;;
        esac
    fi

    dialog_pause
    DIALOG_ACTIVE=0
    DIALOG_HINT=""
}

# Alte Schnittstelle: Die Szene am Tor und bestehende Tests sprechen
# den Torwächter weiterhin über diesen Namen an.
dialog_torwaechter() { dialog_simon_guard "$@"; }

# ============================================================
#  Simons Geschichte: Nek Molerat
# ------------------------------------------------------------
#  Wird aus dem Standardgespräch gewählt, sobald die Hauptquest
#  »Vermisste Bewohner« bekannt ist. Beim ersten Mal wird die
#  Nebenquest »Wo ist Nek Molerat?« vergeben. Simon nennt nur, was
#  er weiß: Nek ist seit Tagen verschwunden, niemand weiß wohin.
#  Simple Jon im Wachhaus ist der nächste Anlaufpunkt.
# ============================================================
simon_nek_scene() {
    SIMON_NEK_INFO=1

    if [ "${NEK_DONE:-0}" = "1" ]; then
        say "Simon Guard" "Nek. Du hast ihn gefunden. Das lässt mich nicht mehr los."
        if [ "${NEK_AMULET_SOLD:-0}" = "1" ]; then
            say "Simon Guard" "Ich trage sein Amulett jetzt. Es ist nicht viel – aber es ist ein Stück von ihm."
        elif [ "${NEK_AMULET_KEPT:-0}" = "1" ]; then
            say "Simon Guard" "Du hast sein Amulett behalten. Ich verstehe das. Wirklich."
        else
            say "Simon Guard" "Er ist nicht allein geblieben. Dafür danke ich dir."
        fi
        simon_nek_family_offer
        return 0
    fi

    if [ "${NEK_GIVEN:-0}" = "1" ]; then
        say "Simon Guard" "Nek. Seit Tagen keine Spur."
        if [ "${NEK_FOUND:-0}" = "1" ]; then
            # Falls der Fund vor der Questvergabe lag: jetzt direkt melden.
            simon_nek_report_router
            return 0
        fi
        if [ "${JON_NEK_INFO:-0}" = "1" ]; then
            say "Simon Guard" "Jon sagt, er hat die Stadt verlassen, um etwas zu erledigen. Das klingt nach Nek. Und es klingt nicht gut."
        else
            say "Simon Guard" "Simple Jon im Wachhaus war mit ihm zusammen im Dienst. Vielleicht weiß er mehr."
        fi
        say "Simon Guard" "Wenn du etwas hörst, sag es mir. Bevor du es irgendwem sonst sagst."
        return 0
    fi

    say "Simon Guard" "Nek Molerat. Ja. Er ist einer von uns."
    say "Simon Guard" "Seit Monaten verschwinden Leute. Kein Kampf, keine Spur, kein Abschied. Die Wache schreibt es in eine Liste und legt sie weg."
    say "Simon Guard" "Nek ist seit Tagen nicht aufgetaucht. Niemand weiß, wo er ist."
    say "Simon Guard" "Er ist mein Freund. Wenn du ihn findest – oder erfährst, was mit ihm passiert ist –, sag mir Bescheid. Bitte."
    say "$AGENT_NAME" "Ich halte die Augen offen. Wenn ich etwas finde, erfährst du es."
    say "Simon Guard" "Gut. Das ist mehr, als die Liste hergibt."

    # quest_gain_once prüft den Status, deshalb erst vergeben, dann
    # NEK_GIVEN setzen. Der Hauptquest-Eintrag hängt an SIMON_NEK_INFO.
    quest_gain_once nek
    NEK_GIVEN=1
    quest_note "Simon Guard: Nek Molerat ist seit Tagen verschwunden."
    OUT+=("")
    OUT+=("[ HINWEIS ]  Simple Jon im Wachhaus (Haupteingang) könnte mehr wissen.")
}

# ============================================================
#  Nek-Abschluss: gemeinsame Helfer
# ============================================================
# Welche der drei Meldungen passt zum aktuellen Zustand?
simon_nek_report_router() {
    NEK_FOUND=1
    if simon_nek_corpse_here; then
        simon_nek_corpse_scene
    elif simon_nek_has_amulet; then
        simon_nek_amulet_scene
    else
        simon_nek_no_loot_scene
    fi
}

# Abschluss ohne Verkauf oder mit Verkauf. <exp> ist die Questbelohnung,
# <verkauft> = 1 nimmt das Amulett aus dem Inventar und zahlt 150 Bits.
simon_nek_complete() {   # <exp> <verkauft>
    local exp="${1:-500}" sold="${2:-0}"
    NEK_DONE=1
    NEK_MUST_SEARCH=0
    if [ "$sold" = "1" ]; then
        inv_remove neksamulett
        bits_add 150
        NEK_AMULET_SOLD=1
        NEK_AMULET_KEPT=0
        OUT+=("")
        OUT+=("   [ Bits ]  +150   (Stand: $(bits_text "$(bits_count)"))")
    else
        NEK_AMULET_KEPT=1
    fi
    quest_reward nek "$exp"
    # Liegt die Leiche beim Tor, ist sie jetzt bei Simon. Danach lässt sie
    # sich nicht mehr hinter dem Agenten herziehen.
    if [ "${NEK_CORPSE_BROUGHT:-0}" = "1" ] \
       && declare -F neks_leiche_remove >/dev/null 2>&1; then
        neks_leiche_remove
    fi
    simon_nek_funeral_start
    return 0
}

# Startet nach dem Nek-Abschluss die getimte Beerdigungsquest und lässt
# Simon sagen, was mit der Leiche passiert. Bei »cave« schickt er jemanden
# in die Höhle, bei »simon« übergibt er sie selbst dem Totengräber, bei
# »lost« muss sie erst gefunden werden.
simon_nek_funeral_start() {
    declare -F nek_funeral_start >/dev/null 2>&1 || return 0
    nek_funeral_start || return 0
    simon_nek_burial_words
    return 0
}

simon_nek_burial_words() {
    case "${NEK_FUNERAL_DISPOSITION:-}" in
        cave)
            say "Simon Guard" "Ich schicke jemanden in die Molerathöhle. Er holt Nek und übergibt ihn dem Totengräber."
            ;;
        simon)
            say "Simon Guard" "Ich übergebe Nek dem Totengräber. Er soll nicht allein bleiben."
            ;;
        lost)
            say "Simon Guard" "Dann schicke ich jemanden los, der ihn findet. Der Totengräber wird ihn beerdigen."
            ;;
    esac
    return 0
}

# Nach dem Abschluss kann der Agent nach Neks Nachnamen fragen. Simon
# verweist auf die Familie und ihre Farm im Farmland der Steppe.
simon_nek_family_offer() {
    [ "${NEK_DONE:-0}" = "1" ] || return 0
    [ "${NEK_FAMILY_GIVEN:-0}" = "1" ] && return 0

    OUT+=("")
    ask 'Warum heißt Nek eigentlich "Molerat" mit Nachnamen?' "Sonst nichts."

    if [ "${CHOICE:-0}" = "1" ]; then
        say "$AGENT_NAME" 'Warum heißt Nek eigentlich "Molerat" mit Nachnamen?'
        say "Simon Guard" "Ist halt sein Nachname. Hat aber auch mit der Familiengeschichte zu tun."
        say "Simon Guard" "Wenn du mehr erfahren willst, such die Familie auf."
        say "Simon Guard" "Ihre Farm liegt im Farmland, draußen in der Steppe."
        say "Simon Guard" "Die Molerats sind im großen Stil in der Fleischerei und Metzgerei tätig. Besonders die Molerats gehören zu ihrem Handwerk."
        declare -F quest_gain_once >/dev/null 2>&1 && quest_gain_once nek_familie
        NEK_FAMILY_GIVEN=1
    else
        say "Simon Guard" "Dann geh. Und halt die Augen offen."
    fi
    return 0
}

# Abschluss, wenn Simon die unversehrte Leiche selbst durchsucht und
# dabei das Amulett findet. Der Agent bekommt 150 Bits + 750 EXP; das
# Amulett bleibt bei Simon.
simon_nek_corpse_reward() {
    NEK_DONE=1
    NEK_MUST_SEARCH=0
    NEK_CORPSE_BROUGHT=1
    bits_add 150
    OUT+=("")
    OUT+=("   [ Bits ]  +150   (Stand: $(bits_text "$(bits_count)"))")
    quest_reward nek 750
    # Simon hat die Leiche übernommen: aus dem Dateisystem entfernen und
    # das Ziehen beenden.
    declare -F neks_leiche_remove >/dev/null 2>&1 && neks_leiche_remove
    simon_nek_funeral_start
    return 0
}

# Simons Kaufangebot. <exp> ist die Belohnung für den Abschluss.
simon_nek_amulet_offer() {   # <exp>
    local exp="${1:-500}"
    say "Simon Guard" "Ich gebe dir 150 Bits dafür. Es gehört zu ihm – und ich will es nicht in fremden Händen wissen."
    ask "Verkaufen (150 Bits)." "Nicht verkaufen."

    if [ "${CHOICE:-0}" = "1" ]; then
        say "Simon Guard" "Danke. Wirklich. Das bedeutet mir mehr, als du weißt."
        simon_nek_complete "$exp" 1
        return 0
    fi

    say "Simon Guard" "Verdammt. Bist du dir sicher?"
    ask "Ja, ich behalte es." "Nein, ich verkaufe es doch."

    if [ "${CHOICE:-0}" = "1" ]; then
        say "Simon Guard" "Verdammt. Aber gut. Ich akzeptiere es. Zumindest weiß ich jetzt, was mit meinem Freund passiert ist."
        simon_nek_complete "$exp" 0
    else
        say "Simon Guard" "Gut. Ich wusste doch, dass du Vernunft annimmst. Danke."
        simon_nek_complete "$exp" 1
    fi
    return 0
}

# ============================================================
#  Variante 1: Kein Amulett und keine Leiche dabei
# ============================================================
simon_nek_no_loot_scene() {
    NEK_FOUND=1
    NEK_REPORTED=1
    say "Simon Guard" "Du hast Nek gefunden? Wo?"
    say "$AGENT_NAME" "In der Molerathöhle. Er lag einfach da. Tot."
    say "-" "Simon wird blass. Für einen Moment sagt er nichts."
    say "Simon Guard" "Nek … mein Freund. Seit Tagen habe ich gehofft, dass er einfach irgendwo festsitzt."
    say "Simon Guard" "Hast du etwas bei ihm gefunden?"
    ask "Nein hab seine Leiche nicht angefasst."

    say "$AGENT_NAME" "Nein hab seine Leiche nicht angefasst."
    say "Simon Guard" "Geh zurück und durchsuch ihn. Komm dann wieder."
    say "Simon Guard" "Wenn er etwas bei sich hatte – einen Hinweis, etwas von ihm –, will ich es wissen."
    NEK_MUST_SEARCH=1
    quest_note "Simon Guard: Geh zurück und durchsuche Neks Leiche."
    return 0
}

# ============================================================
#  Variante 2: Das Amulett ist da, die Leiche nicht
# ============================================================
simon_nek_amulet_scene() {
    NEK_FOUND=1
    NEK_REPORTED=1
    say "Simon Guard" "Du hast Nek gefunden? Wo?"
    say "$AGENT_NAME" "In der Molerathöhle. Er lag einfach da. Tot."
    say "-" "Simon starrt auf deine Hände, als könnte er dort seinen Freund sehen."
    say "Simon Guard" "Nek … mein Freund. Seit Tagen habe ich gehofft, dass er einfach irgendwo festsitzt."
    say "Simon Guard" "Hast du etwas bei ihm gefunden?"
    ask "Ja. Dieses Amulett" "Nein, da war nichts"

    if [ "${CHOICE:-0}" = "2" ]; then
        say "$AGENT_NAME" "Nein, da war nichts."
        say "Simon Guard" "Dann weiß ich jetzt wenigstens, was mit ihm passiert ist. Das ist mehr, als die Liste hergibt."
        simon_nek_complete 500 0
        return 0
    fi

    say "$AGENT_NAME" "Ja. Dieses Amulett."
    say "-" "Simon erkennt die dünne Kette sofort. Seine Hand zittert, als er sie ansieht."
    say "Simon Guard" "Das ist seins. Ich habe es ihm vor Jahren gegeben. Er hat es nie abgelegt."
    simon_nek_amulet_offer 500
    return 0
}

# ============================================================
#  Variante 3/4: Der Agent bringt die Leiche zum Tor
# ============================================================
simon_nek_corpse_scene() {
    NEK_FOUND=1
    NEK_REPORTED=1
    NEK_CORPSE_BROUGHT=1
    say "Simon Guard" "Heilige Scheiße! Was stimmt nicht mit dir!"
    say "-" "Simon starrt auf die Leiche hinter dir. Sein Griff um die Waffe lockert sich nicht."
    say "$AGENT_NAME" "Ich dachte, du solltest ihn sehen."
    say "Simon Guard" "Du hast ihn … einfach mitgebracht. Durch die ganze Stadt."
    say "-" "Er geht in die Knie. Einen Moment lang ist er nur ein Mann, der um seinen Freund trauert."
    say "Simon Guard" "Nek. Verdammt. Du wolltest doch nur die Stadt schützen."
    say "-" "Dann rappelt er sich auf und mustert die Leiche."

    # Das Amulett ist bereits gefunden: gleiches Verkaufsgespräch wie oben.
    if simon_nek_has_amulet; then
        say "Simon Guard" "Du hast ihn durchsucht. Und du hast sein Amulett."
        simon_nek_amulet_offer 500
        return 0
    fi

    say "Simon Guard" "Hast du ihn durchsucht?"
    ask "Nein, ich habe ihn nicht angefasst." "Ja, ich habe ihn durchsucht."

    if [ "${CHOICE:-0}" = "1" ]; then
        say "$AGENT_NAME" "Nein, ich habe ihn nicht angefasst."
        say "Simon Guard" "Dann muss ich es tun. Verzeih mir, Nek."
        say "-" "Simon kniet neben seinem Freund und durchsucht die Taschen der Uniform."
        say "-" "Dann hält er inne. Zwischen seinen Fingern baumelt eine dünne Kette."
        say "Simon Guard" "Da ist es. Sein Amulett. Er hat es nie abgelegt."
        NEKS_LEICHE_SEARCHED=1
        NEK_SIMON_SEARCHED=1
        say "Simon Guard" "Danke, dass du ihn zurückgebracht hast. Das war nicht leicht – für keinen von uns."
        simon_nek_corpse_reward
        return 0
    fi

    say "$AGENT_NAME" "Ja, ich habe ihn durchsucht."
    say "Simon Guard" "Dann hast du etwas bei ihm gefunden?"
    say "$AGENT_NAME" "Nein, da war nichts."
    say "Simon Guard" "Dann war da nichts. Aber du hast ihn zurückgebracht. Das zählt."
    simon_nek_corpse_reward
    return 0
}
