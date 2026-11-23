# ============================================================
#  TerminalHero - Charakter: Wirt Börty Smiles
#
#  Beseelte Datei: »touch« öffnet das Gespräch. Die Kneipe »Zum Goldenen
#  Lächeln« im Ostdistrikt gehört ihm (Orte/Ostdistrikt.sh) - »cat« zeigt
#  den Schankbetrieb, »file« die Metadaten.
#
#  Gespräche, in DIESER Reihenfolge geprüft:
#
#    0. GESCHEITERTE BIERLIEFERUNG - hat der Agent die Kiste verloren und
#       sind seitdem 24 Spielstunden vergangen (bier_loss_due in
#       Items/Quest/Bierlieferung.sh), rechnet Börty ab: »Du hast meine
#       Kiste nicht geliefert!« / »Wo ist mein Geld?«. Die Quest steht
#       danach auf »gescheitert«.
#
#    1. HOLMES-AUSKUNFT - nur wenn DREI Trigger zusammenkommen:
#       der Agent hat die Quest »Großer Ermittler« (PIXI_LETTER_DONE), Amanda
#       Nox hat ihm den Hinweis auf den Wirt gegeben (AMANDA_DONE) und Sherlock
#       Holmes ist noch NICHT angetroffen (SHERLOCK_DONE). Dazu kommt: die
#       Auskunft ist noch nicht GEKAUFT (BOERTY_INFO). Er erzählt von Holmes'
#       Spur (getarnter Virus, Ostdistrikt) und verkauft die Details für
#       BOERTY_PREIS Bits:
#       »Bezahlen« (kostet 10 Bits, setzt BOERTY_INFO und erweitert den
#       Questlog um Holmes' Nachtzeit) oder »Dankend ablehnen« (der Agent
#       kann später zurückkommen). Reicht das Geld nicht, sagt Börty »Du
#       hast nicht genug Bits.« und das Angebot bleibt bestehen. Flag
#       BOERTY_SH_DONE: die Geschichte kommt NUR EINMAL, danach nur noch
#       die Erinnerung + Auswahl.
#
#       Ganz am Anfang steht die Frage des Agenten (er kommt wegen des
#       Briefes) - Börty redet nie von selbst über Holmes.
#
#    2. VORSTELLUNG (einmalig) - für den Fall, dass der Agent Börty VOR
#       der Quest (oder bevor Amanda den Hinweis gegeben hat) kennenlernt:
#       kurze Vorstellung, die mit »Gib mir einen Moment, ich muss die
#       Gläser einräumen.« endet (BOERTY_INTRO_DONE).
#       Wer die Holmes-Geschichte schon gehört hat (BOERTY_SH_DONE),
#       wurde bereits vorgestellt - dann entfällt sie.
#
#    3. STANDARDGESPRÄCH (immer wieder): »Was darf sein?« mit drei bis
#       fünf Optionen. Hier landet auch, wer die Auskunft schon bezahlt hat
#       (BOERTY_INFO) - dann taucht das Bezahl-Angebot nicht mehr auf.
#       Trinken und Erzählen sind inhaltlich folgenlos (später ausgebaut).
#
#       Eine Option ist »Handeln.«: Sie öffnet das Handelsfenster
#       (shDateien/Handelsfenster.sh) mit Börtys Lager. Den Befehl »trade«
#       lernt der Agent hier NICHT - den bringt später ein Lehrer bei
#       (aktuell lehrt ihn noch niemand). Handeln geht trotzdem: wer den
#       Wirt anspricht, steht vor ihm.
#
#       Ist die Hauptquest »Vermisste Bewohner« bekannt (VERMISSTE_GIVEN),
#       steht außerdem »Vermisste Bewohner?« zur Wahl - Börty fasst die
#       Lage zusammen und verweist auf Sherlock Holmes, der an dem Fall
#       arbeitet (boerty_vermisste_scene, Flag BOERTY_VERMISSTE_INFO).
#
#       Sobald der Agent Mitch im Restaurant getroffen hat (MITCH_TALKED),
#       steht außerdem »Wegen Mitch...« zur Wahl. Börty erfährt, dass Mitch
#       nicht zurückkommt - und die Mitch-Quest endet mit 250 EXP, 20 Bits
#       und der neuen Nebenquest »Ein neuer Gehilfe für Börty«
#       (boerty_mitch_return_scene).
#
#       Die Bitte-Option kommt erst nach der abgeschlossenen Hauptquest
#       »Großer Ermittler« (ERMITTLER_DONE) dazu: »Kann ich dir irgendwie
#       behilflich sein?« - Börtys Bitte (Michael Mitch, die Vermissten,
#       die Bierlieferung vom Marktplatz). Siehe boerty_favor_scene unten.
#       Trägt der Agent die Lieferung mit sich, heißt dieselbe Option
#       »Hier ist dein Bier.« - dann läuft boerty_beer_return: Kiste weg,
#       Nebenquest »Bier für Börty« abgeschlossen, 100 EXP + 30 Bits -
#       und der Agent fragt nach Mitch (boerty_mitch_scene), woraus die
#       Nebenquest »Michael Mitch. Vermisst« entsteht (MITCH_GIVEN).
#       Ist die Lieferung gescheitert (BIER_FAILED), entfällt die Bitte-
#       Option; Börty erinnert dann nur noch an die verpasste Lieferung.
#
#  Optionen werden als Paar geführt (opts/acts): das case wertet die
#  Aktion aus, nicht die gedrückte Ziffer - so kann jede Option dazukommen
#  oder entfallen, ohne dass die Nummern verrutschen.
#
#  Lazy geladen über DIALOG[] (kern/loader.sh), erst beim ersten »touch«.
# ============================================================

# Preis für eine Holmes-Auskunft in Bits (Währung, kern/items.sh).
declare -g BOERTY_PREIS=10

# ============================================================
#  Börtys Lager (Handelsfenster.sh)
# ------------------------------------------------------------
#  Die Funktion meldet Börty als Händler an; der Name »handel_lager_boerty«
#  ist Konvention: »trade <wort>« sucht über den Funktionsindex
#  (kern/loader.sh) genau solche Funktionen und lädt die Datei erst dann.
#  Der Grundbestand frischt sich jeden neuen Spieltag wieder auf
#  (handel_day_sync in Handelsfenster.sh): 10 Flaschen LightBeer.
#  Ausrüstung wie Fackeln und Schlafsäcke führt Börty NICHT - dafür
#  gibt es Jack Bones und den SurvivalShop im Zentrum.
#  Idempotent - die Anmeldung darf mehrfach laufen.
# ============================================================
handel_lager_boerty() {
    th_source_if_fn handel_define           # Handelsfenster nachladen
    declare -F handel_define >/dev/null 2>&1 || return 1
    handel_define boerty "Börty Smiles"
    handel_alias  boerty "Börty" "Börtys" "Wirt"
    handel_stock  boerty lightbeer 10
    handel_stock  boerty moleratcode 10
    return 0
}
handel_lager_boerty

dialog_boerty() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ KNEIPE »ZUM GOLDENEN LÄCHELN« · THEKE ═════")
    OUT+=("Haus : seit drei Generationen    Wirt : Börty Smiles")
    OUT+=("Status : geöffnet. Immer.")
    OUT+=("")
    render

    # ---- 0) Die Bierkiste ist verschwunden und die Frist ist abgelaufen.
    # Das Event läuft VOR allen anderen Gesprächen - Börty hat 24
    # Spielstunden gewartet, jetzt rechnet er ab.
    if bier_loss_due; then
        boerty_beer_failed_scene
        return
    fi

    # ---- 1) Holmes-Auskunft (Quest da, Amanda-Hinweis da, Sherlock noch
    # nicht angetroffen) ---------------------------------------------------
    # Drei Trigger müssen zusammenkommen: die Quest »Großer Ermittler«
    # (PIXI_LETTER_DONE), Amandas Hinweis auf den Wirt (AMANDA_DONE) und
    # »Holmes noch nicht gefunden« (SHERLOCK_DONE). Zusätzlich darf die
    # Auskunft noch nicht GEKAUFT sein (BOERTY_INFO) - danach läuft das
    # Standardgespräch.
    if [ "${PIXI_LETTER_DONE:-0}" = "1" ] && [ "${AMANDA_DONE:-0}" = "1" ] \
       && [ "${SHERLOCK_DONE:-0}" != "1" ] \
       && [ "${BOERTY_INFO:-0}" != "1" ]; then
        local preis="${BOERTY_PREIS:-10}"
        # Der Agent fragt - Börty redet nicht von selbst über Holmes.
        say "$AGENT_NAME" "Sie kennen doch Sherlock Holmes? Ich habe einen Brief für ihn."
        if [ "${BOERTY_SH_DONE:-0}" = "1" ]; then
            # Schon gefragt, aber (noch) nicht bezahlt: er erinnert nur.
            say "Börty" "Wegen Holmes? Meine Infos kosten ${preis} Bits, das habe ich dir schon gesagt."
            say "Börty" "Du kannst es dir ja noch mal überlegen."
        else
            say "Börty" "Sherlock Holmes? Der Detektiv? Setz dich."
            say "-" "Er stellt ein Glas hin, das niemand bestellt hat, und lehnt sich über die Theke."
            say "Börty" "Ja, der war hier. Vorgestern, oder drei Uhr nachts – bei mir ist das ungefähr dasselbe."
            say "Börty" "Und er hat gefaselt. Von einem Virus, der hier in der Stadt läuft. Getarnt, hat er gesagt."
            say "Börty" "Im Ostdistrikt wolle er ihn verfolgen. Mit Akten, Kaffee und so."
            say "-" "Börty tippt sich mit zwei Fingern an die Schläfe."
            say "Börty" "Aber Details? Details sind mein zweites Geschäft."
            say "Börty" "Was Genaueres kostet ${preis} Bits. Der Rest deines Lebens bleibt gratis."
            BOERTY_SH_DONE=1
        fi
        OUT+=("")
        ask "Bezahlen (${preis} Bits)" "Dankend ablehnen"
        case "$CHOICE" in
            1) # Bezahlen: kostet BOERTY_PREIS Bits (Währung, kern/items.sh).
               # Reicht das Geld nicht, sagt er es - und das Angebot bleibt
               # bestehen: beim nächsten Gespräch stehen die Optionen wieder da.
               if bits_take "$preis"; then
                   BOERTY_INFO=1
                   play_sound select
                   say "Börty" "Gut. ${preis} Bits – und der Laden schweigt dazu."
                   say "-" "Er lässt die Bits in einer Schublade unter der Theke verschwinden, ohne hinzusehen."
                   say "Börty" "Holmes ist ein Nachttier. Zwischen zehn Uhr abends und vier Uhr morgens treibt er sich draußen herum – im Ostdistrikt, immer auf den Straßen."
                   say "Börty" "Wer ihn finden will, muss nachts raus. Und besser allein: der Mann hasst Publikum."
                   quest_note "»Großer Ermittler«: Holmes nachts (22:00–04:00) im Ostdistrikt"
               else
                   play_sound error
                   say "Börty" "Du hast nicht genug Bits."
                   say "-" "Er zuckt mit den Schultern – freundlich – und wischt weiter am Tresen."
                   say "Börty" "Komm wieder, wenn du ${preis} beisammen hast. Ich laufe nicht weg. Meistens."
               fi ;;
            2) say "Börty" "Klar. Denk in Ruhe drüber nach."
               say "Börty" "Ich bin hier. Immer. Du kannst es dir ja noch mal überlegen."
               dialog_pause
               DIALOG_ACTIVE=0; DIALOG_HINT=""
               return ;;
        esac
        dialog_pause
    fi

    # ---- 2) Einmalige Vorstellung (Börty vor der Quest kennengelernt) -----
    if [ "${BOERTY_INTRO_DONE:-0}" != "1" ] && [ "${BOERTY_SH_DONE:-0}" != "1" ]; then
        BOERTY_INTRO_DONE=1
        say "Börty" "Na sieh an, ein frisches Gesicht. Setz dich, das kostet nichts."
        say "Börty" "Börty Smiles. Wirt dieses Ladens – und der, der zuhört, wenn alle reden."
        say "-" "Er wischt ein Glas trocken, das längst trocken ist, und lächelt breit."
        say "Börty" "Gib mir einen Moment, ich muss die Gläser einräumen."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- 3) Standardgespräch (immer wieder): »Was darf sein?« -------------
    say "Börty" "Was darf sein?"
    # Die Auswahl wächst mit dem Spielverlauf. Damit die Nummern der Antworten
    # nicht verrutschen, laufen Option und Aktion parallel (opts/acts): case
    # wertet die AKTION aus, nicht die gedrückte Ziffer.
    #
    #   - Nach der abgeschlossenen Quest »Großer Ermittler« (ERMITTLER_DONE)
    #     kommt Börtys Bitte dazu (boerty_favor_scene). Trägt der Agent die
    #     Bierlieferung mit sich, heißt dieselbe Option »Hier ist dein Bier.«
    #   - Ist die Hauptquest »Vermisste Bewohner« bekannt (VERMISSTE_GIVEN),
    #     fragt der Agent »Vermisste Bewohner?« - Börty verweist dann auf
    #     Sherlock Holmes (boerty_vermisste_scene).
    #   - Der Abschied (»Ich hab es mir anders überlegt.«) steht bei allen
    #     NPCs ganz unten - nach allen inhaltlichen Optionen.
    local opts=() acts=() bitte
    while true; do
        opts=(); acts=()
        opts+=("Gib mir was zu trinken.");         acts+=("trinken")
        opts+=("Erzähl mir über ...");             acts+=("erzaehlen")
        opts+=("Handeln.");                        acts+=("handeln")
        bitte="Kann ich dir irgendwie behilflich sein?"
        if [ "${ERMITTLER_DONE:-0}" = "1" ] && [ "${BIER_FAILED:-0}" != "1" ]; then
            if [ "${BIER_DONE:-0}" != "1" ] && [ "$(inv_count bierlieferung)" -gt 0 ]; then
                bitte="Hier ist dein Bier."
            fi
            opts+=("$bitte");                      acts+=("bitte")
        fi
        if [ "${VERMISSTE_GIVEN:-0}" = "1" ]; then
            opts+=("Vermisste Bewohner?");         acts+=("vermisste")
        fi
        if [ "${MITCH_TALKED:-0}" = "1" ] && [ "${MITCH_DONE:-0}" != "1" ]; then
            opts+=("Wegen Mitch...");              acts+=("mitch")
        fi
        opts+=("Ich hab es mir anders überlegt."); acts+=("anders")
        ask "${opts[@]}"
        case "${acts[$((CHOICE - 1))]}" in
            # Die ersten drei Antworten sind absichtlich inhaltslos - Trinken,
            # Themen und alles Weitere werden später ausgebaut.
            trinken)   say "Börty" "Trinken gibt es später – ich habe noch Gläser einzuräumen."
                       dialog_pause ;;
            erzaehlen) say "Börty" "Über wen? Frag mich später noch mal – dann nenne ich Namen."
                       dialog_pause ;;
            anders)    say "Börty" "Alles klar. Du weißt, wo ich stehe."
                       break ;;
            vermisste) # Die Hauptquest »Vermisste Bewohner« (VERMISSTE_GIVEN).
                       boerty_vermisste_scene
                       DIALOG_ACTIVE=1 ;;
            mitch)     # MITCH_TALKED: Der Agent hat Mitch gefunden.
                       boerty_mitch_return_scene
                       DIALOG_ACTIVE=1 ;;
            handeln)   # HANDELN - öffnet das Handelsfenster (shDateien/Handelsfenster.sh).
                       # Den Befehl »trade« lernt der Agent hier NICHT - den bringt
                       # später ein Lehrer bei. Handeln geht trotzdem: wer den Wirt
                       # anspricht, steht vor ihm.
                       handel_lager_boerty
                       say "Börty" "Immer. Leg los."
                       handel_start boerty
                       DIALOG_ACTIVE=1 ;;
            bitte)     # BÖRTYS BITTE (Michael Mitch, Vermisste, Bierlieferung).
                       boerty_favor_scene
                       DIALOG_ACTIVE=1 ;;
        esac
    done
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  Börtys Bitte (Neben dem Standardgespräch, nach »Großer Ermittler«)
# ------------------------------------------------------------
#  Der Agent fragt, ob er helfen kann - Börty sagt ja:
#
#    1. ERZÄHLUNG (einmalig, BOERTY_FAVOR_DONE): Sein Lagergehilfe
#       Michael Mitch (Charakter/MichaelMitch.sh) ist seit Tagen
#       verschwunden - und seit Monaten werden in der Stadt immer wieder
#       Leute vermisst gemeldet, spurlos. An dieser Stelle wird die
#       Hauptquest »Vermisste Bewohner« vergeben - über quest_gain_once,
#       denn sie soll später AUCH ANDERS zu bekommen sein.
#    2. BITTE: Börtys Bierlieferung steht im Lager am Marktplatz im
#       Zentrum (Lagermeister Samy Cage, Charakter/SamyCage.sh). Er kann
#       den Laden nicht verlassen und gibt dem Agenten 250 Bits direkt mit
#       - normalerweise vertraut er niemandem, aber Pixi vertraut dem
#       Agenten. »Auftrag annehmen« gibt die 250 Bits und die Nebenquest
#       »Bier für Börty« (BIER_GIVEN); »Auftrag ablehnen« lässt alles, wie
#       es war - die Option steht beim nächsten Besuch wieder da.
# ============================================================
boerty_favor_scene() {
    local betrag=250 wieder=0
    [ "${BOERTY_FAVOR_DONE:-0}" = "1" ] && wieder=1

    # ---- Quest ist gescheitert: keine Lieferung mehr --------------------
    if [ "${BIER_FAILED:-0}" = "1" ]; then
        say "Börty" "Du hast meine Kiste nicht geliefert!"
        say "Börty" "Wo ist mein Geld?"
        say "-" "Er sieht dich an, als wäre die Theke zwischen euch plötzlich breiter geworden."
        say "Börty" "Vierundzwanzig Stunden. Ich habe gewartet. Jetzt ist es zu spät."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- Die Lieferung ist da: abgeben (hat Vorrang vor allem anderen) ---
    if [ "${BIER_DONE:-0}" != "1" ] && [ "$(inv_count bierlieferung)" -gt 0 ]; then
        boerty_beer_return
        return
    fi

    # ---- Quest ist durch: nur noch die Nachbetrachtung ------------------
    if [ "${BIER_DONE:-0}" = "1" ]; then
        # Sicherheitsnetz für alte Spielstände: Wer die Lieferung abgegeben
        # hat, aber noch nichts von Mitch gehört hat, bekommt hier dasselbe
        # Gespräch wie am Ende von boerty_beer_return.
        if [ "${MITCH_GIVEN:-0}" != "1" ]; then
            boerty_mitch_scene
            return
        fi
        say "Börty" "Das Bier steht hinter der Theke, die Gläser sind voll."
        if [ "${MITCH_DONE:-0}" = "1" ]; then
            say "Börty" "Mitch kommt nicht zurück. Jetzt brauche ich einen neuen Gehilfen."
            [ "${GEHILFE_GIVEN:-0}" = "1" ] && \
                say "Börty" "Halt die Augen offen. Ich komm hier nicht weg."
        elif [ "${MITCH_TALKED:-0}" = "1" ]; then
            say "Börty" "Und? Hast du was von Mitch gehört?"
        else
            say "Börty" "Ein Problem gelöst. Bleibt nur noch herauszufinden, wo Mitch abgeblieben ist."
        fi
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- Angenommen, aber noch nicht geliefert: Erinnerung -------------
    if [ "${BIER_GIVEN:-0}" = "1" ]; then
        say "Börty" "Und? Warst du beim Samy?"
        say "Börty" "Lager am Marktplatz, im Zentrum. Mein Bier steht da und wartet – und ich warte mit."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi

    # ---- 1) Erzählung (einmalig) --------------------------------------
    # »wieder« heißt nur: Die Geschichte wurde schon erzählt. Der Auftrag
    # kann beim letzten Mal abgelehnt worden sein – dann wurde kein Geld
    # übergeben und es darf hier auch nicht so klingen.
    if [ "$wieder" = "1" ]; then
        say "Börty" "Also? Bier. Marktplatz. Samy Cage. Im Zentrum."
        say "-" "Er legt eine Hand auf den Beutel unter der Theke, zieht sie aber noch nicht weg."
        say "Börty" "Wenn du den Auftrag annimmst, sind die ${betrag} Bits für die Lieferung dabei."
    else
        say "Börty" "Ja, da gäbe es schon was."
        say "-" "Er wirft das Tuch über die Schulter und wird leiser."
        say "Börty" "Ich hab hier mehr zu tun, als in diesen Laden passt. Und mir fehlt genau der, der mir das Abräumen abnimmt."
        say "$AGENT_NAME" "Wer fehlt dir?"
        say "Börty" "Michael Mitch. Mein Lagergehilfe. Ein großer, ruhiger Kerl – einer, der Kisten so einsortiert, wie sie heißen."
        say "Börty" "Seit Tagen nicht aufgetaucht. Kein Wort, keine Nachricht, keine Spur."
        OUT+=("")
        say "Börty" "Und wenn ich ehrlich bin: Ich habe das Gefühl, er ist nicht der Erste."
        say "Börty" "In dieser Stadt werden seit Monaten immer wieder Leute vermisst gemeldet. Die Wache schreibt die Namen auf eine Liste – und legt die Liste dann weg."
        say "Börty" "Sie verschwinden einfach. Spurlos. Kein Kampf, kein Abschied, keine Nachricht – als hätte jemand sie aus der Datei gelöscht."
        OUT+=("")
        say "-" "Er stellt das Glas hin, das er die ganze Zeit geputzt hat, ohne dass es je schmutzig war."
        say "Börty" "Ich bin Wirt. An meiner Theke wird alles geredet – meistens über Bier. Aber nicht nur."
        say "Börty" "Niemand weiß, was hier los ist. Und irgendwem muss das auffallen."
        BOERTY_FAVOR_DONE=1
        # Hauptquest, aber nur einmal: quest_gain_once prüft den Status
        # (verborgene Quest), VERMISSTE_GIVEN hält das Ergebnis fest - so
        # kann dieselbe Quest später auch ANDERS vergeben werden, ohne dass
        # sie doppelt im Log landet.
        if quest_gain_once vermisste; then VERMISSTE_GIVEN=1; fi

        OUT+=("")
        say "Börty" "Soweit die Liste. Und jetzt das, wofür ich dich wirklich brauche – das ist einfacher."
        say "Börty" "Könntest du mir einen Gefallen tun und zum Marktplatz im Zentrum der Stadt gehen? Dort findest du den Lagermeister Samy Cage. Er hat eine Lieferung Bier für mich. Die bräuchte ich hier dringend."
        say "-" "Er greift unter die Theke und schiebt einen prallen Beutel über den Tresen."
        say "Börty" "Ich geb dir das Geld direkt mit."
        say "$AGENT_NAME" "Du vertraust mir einfach so deine Bits an?"
        say "Börty" "Normalerweise nicht."
        say "-" "Kurz bleibt seine Hand auf dem Beutel liegen."
        say "Börty" "Aber du hast Eindruck bei Pixi hinterlassen. Sie vertraut dir. Also scheinst du in Ordnung zu sein."
        say "-" "Er schiebt den Beutel zu dir herüber. Er ist schwerer, als er aussieht."
        say "Börty" "Und das sage ich dir als Wirt: Wenn ich nicht bald Nachschub bekomme, nehmen mir die Suffköpfe hier die Theke auseinander. Streitwert: alles."
    fi

    # ---- 2) Die Bitte: annehmen oder ablehnen -------------------------
    OUT+=("")
    say "Börty" "Nimmst du den Auftrag an?"
    ask "Auftrag annehmen" "Auftrag ablehnen"
    case "$CHOICE" in
        1) play_sound select
           say "$AGENT_NAME" "In Ordnung. Ich hol dir dein Bier."
           say "Börty" "Gut. ${betrag} Bits – die Lieferung ist bezahlt, du musst nur das Fass in Bewegung bringen."
           say "Börty" "Aber hör zu: Wenn die Kiste verloren geht, hast du 24 Stunden, um Ersatz zu besorgen."
           say "Börty" "Danach ist die Lieferung geplatzt – und ich will mein Geld sehen."
           say "-" "Er lässt den Beutel los, bevor du zugreifst, und dreht sich schon wieder zum Tresen."
           bits_add "$betrag"
           OUT+=("   [ Bits ]  +${betrag} Bits für die Bierlieferung.")
           quest_gain_once bier        # Nebenquest (nur, wenn noch unbekannt)
           BIER_GIVEN=1
           OUT+=("   [ FRIST ]  Geht die Kiste verloren: 24 Spielstunden für Ersatz.")
           OUT+=("[ NEUES ZIEL ]  Marktplatz im Zentrum:   cd Zentrum   →   cd Marktplatz")
           OUT+=("                 Im Lager: Lagermeister Samy Cage ansprechen (touch SamyCage).") ;;
        2) play_sound error
           say "Börty" "Verdammt! Ich komm hier nicht weg!"
           say "-" "Er knallt das Tuch auf die Theke und stützt sich mit beiden Händen ab."
           say "Börty" "Überleg es dir noch mal. Ich brauche deine Hilfe – und mein Bier brauche ich noch dringender." ;;
    esac
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  Die Bierlieferung ist gescheitert (24 Spielstunden ohne Kiste)
# ------------------------------------------------------------
#  Wird aus dialog_boerty aufgerufen, sobald bier_loss_due (Items/Quest/
#  Bierlieferung.sh) anschlägt: Der Agent hat die Kiste verkauft oder
#  anderweitig verloren und sie nicht rechtzeitig ersetzt. Börty rechnet
#  ab, die Quest wandert in den Reiter »Gescheitert«.
# ============================================================
boerty_beer_failed_scene() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ KNEIPE »ZUM GOLDENEN LÄCHELN« · THEKE ═════")
    OUT+=("Haus : seit drei Generationen    Wirt : Börty Smiles")
    OUT+=("Status : die Lieferung ist überfällig")
    OUT+=("")
    render

    play_sound error
    say "-" "Börty steht hinter der Theke, die Arme verschränkt. Das Tuch liegt unbenutzt neben ihm."
    say "Börty" "Du hast meine Kiste nicht geliefert!"
    say "Börty" "Wo ist mein Geld?"
    say "$AGENT_NAME" "Ich …"
    say "Börty" "Vierundzwanzig Stunden. Ich habe gewartet, wie ein Idiot."
    say "Börty" "Und jetzt steht hier jemand ohne Bier und ohne Kiste."
    say "-" "Er nimmt das Tuch, legt es wieder hin und sieht dich nicht dabei an."
    say "Börty" "Ich will keine Ausreden. Ich will mein Bier."
    OUT+=("")
    quest_failed bier
    BIER_FAILED=1
    BIER_LOST_AT=-1
    say "-" "Das Gespräch ist vorbei, bevor du etwas erwidern kannst."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  Die Lieferung abgeben (Nebenquest »Bier für Börty« abschließen)
# ------------------------------------------------------------
#  Läuft, wenn der Agent »Börtys Bierlieferung« (Items/Quest/
#  Bierlieferung.sh) dabeihat - dann heißt Börtys fünfte Option »Hier ist
#  dein Bier.«
#
#    1. Die Kiste verschwindet aus dem Inventar (inv_remove).
#    2. Die Nebenquest ist durch (BIER_DONE): quest_reward bier 100
#       (100 EXP über char_gain_exp) und 30 Bits Belohnung (bits_add).
#    3. Börty bedankt sich - und bleibt beim Eigentlichen: Mitch.
# ============================================================
boerty_beer_return() {
    say "Börty" "Da ist sie ja!"
    say "-" "Er nimmt die Kiste, als wäre sie ein Korb Eier, und wuchtet sie hinter sich auf die Ablage."
    say "Börty" "Der Samy lässt einen warten, bis das Bier warm wird. Aber er liefert."
    say "-" "Börty hat den Lederriemen schon offen und sieht nach: Flaschen an Flaschen, kein Klirren."
    say "Börty" "Unversehrt. Sehr gut."
    # Erst als abgeschlossen markieren, dann entfernen: Der generische
    # item_on_remove-Haken darf die Übergabe nicht als Verlust werten.
    BIER_DONE=1
    BIER_LOST_AT=-1
    inv_remove bierlieferung
    play_sound select
    OUT+=("")
    OUT+=("   [ Inventar ]  »Börtys Bierlieferung« abgegeben.")
    say "Börty" "Dann bedank ich mich mal. Ehrlich, nicht mit der Wirtsschleife."
    say "-" "Er greift in die Kasse und zählt ein paar Bits ab."
    bits_add 30
    OUT+=("   [ Bits ]  +30 Bits Belohnung.")
    quest_reward bier 100
    say "Börty" "Und jetzt trinke ich einen auf dich – es ist ja wieder welches da."
    OUT+=("")
    say "-" "Dann wird er wieder der Wirt: Blick über den Tresen, in die Ecke, in der jemand fehlt."
    say "Börty" "Ein Problem gelöst."
    say "Börty" "Bleibt nur noch herauszufinden, wo Mitch abgeblieben ist."
    # Der Agent hakt nach - und aus dem offenen Thema wird die eigene Quest.
    boerty_mitch_scene
}

# ============================================================
#  »Mitch ist also verschwunden?« (Ende der Bierlieferung)
# ------------------------------------------------------------
#  Der Agent fragt nach Börtys Lagergehilfen - Börty weiß nichts, hält
#  aber die Tür offen: wenn der Agent etwas hört, soll er sich melden.
#  Daraus entsteht die Nebenquest »Michael Mitch. Vermisst«
#  (MITCH_GIVEN, InGameBefehle/questlog.sh) - über quest_gain_once, denn
#  später soll es weitere Wege geben, dieselbe Quest zu bekommen.
#  Das Gespräch endet selbst (dialog_pause + Aufräumen).
# ============================================================
boerty_mitch_scene() {
    say "$AGENT_NAME" "Mitch ist also verschwunden?"
    say "-" "Er nickt langsam, ohne den Blick vom Tresen zu nehmen."
    say "Börty" "Ja, vor ein paar Tagen. Keine Ahnung, wo er sein könnte."
    say "Börty" "Wenn du was von ihm hören solltest, melde dich bei mir."
    if quest_gain_once mitch; then MITCH_GIVEN=1; fi
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  »Wegen Mitch...« (Option nach dem Treffen im Restaurant)
# ------------------------------------------------------------
#  Der Agent hat Mitch gefunden (MITCH_TALKED). Börty erfährt, dass sein
#  Lagergehilfe nicht zurückkommt. Er tobt, sieht aber ein, dass er einen
#  neuen Gehilfen braucht - und bittet den Agenten um einen letzten
#  Gefallen. Die Mitch-Quest endet (MITCH_DONE): 250 EXP, 20 Bits und die
#  neue Nebenquest »Ein neuer Gehilfe für Börty« (GEHILFE_GIVEN).
# ============================================================
boerty_mitch_return_scene() {
    say "$AGENT_NAME" "Wegen Mitch..."
    say "-" "Börty stellt das Glas ab. Sein Blick wird schmal."
    say "Börty" "Du hast ihn gefunden?"
    say "$AGENT_NAME" "Ja. Er arbeitet jetzt im Restaurant im Westdistrikt."
    say "Börty" "Im Restaurant."
    say "$AGENT_NAME" "Er will nicht mehr für dich arbeiten. Er sagt, du zahlst zu wenig."
    say "Börty" "Dieser Hund. Lässt mich einfach im Stich. Na warte, wenn ich den in die Finger bekomme..."
    say "$AGENT_NAME" "Vielleicht hättest du ihn zumindest besser bezahlen sollen."
    say "Börty" "Was? Ich? Ich habe ihm gegeben, was er braucht!"
    say "-" "Er knallt das Tuch auf die Theke. Ein Glas klirrt."
    say "Börty" "Verdammt, jetzt brauche ich einen neuen Gehilfen, aber ich komm hier nicht weg!"
    say "Börty" "Kann ich dich um noch einen Gefallen bitten?"
    say "$AGENT_NAME" "Ich soll jemand Neues für dich finden?"
    say "Börty" "Ja. Genau."
    say "$AGENT_NAME" "Ich verspreche nichts, aber wenn ich jemanden finde, denk ich an dich."
    say "Börty" "Mehr verlange ich nicht. Im Moment."
    say "-" "Er atmet aus, als hätte er die Theke erst jetzt wieder im Griff."

    MITCH_TALKED=1
    MITCH_DONE=1
    bits_add 20
    OUT+=("   [ Bits ]  +20 Bits Belohnung.")
    quest_reward mitch 250
    OUT+=("")
    if quest_gain_once gehilfe; then GEHILFE_GIVEN=1; fi
    OUT+=("[ NEUES ZIEL ]  Halte Ausschau nach einem neuen Gehilfen für Börty.")

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

# ============================================================
#  »Vermisste Bewohner?« (Option im Standardgespräch)
# ------------------------------------------------------------
#  Erscheint, sobald die Hauptquest »Vermisste Bewohner« bekannt ist
#  (VERMISSTE_GIVEN). Börty sagt in wenigen Sätzen, was er schon in
#  boerty_favor_scene erzählt hat - und nennt den, der dem wirklich
#  nachgeht: Sherlock Holmes. Flag BOERTY_VERMISSTE_INFO hält die Spur
#  für den Questlog-Verlauf fest (quest_entries_vermisste).
# ============================================================
boerty_vermisste_scene() {
    say "-" "Er schenkt ein, ohne zu fragen, und lehnt sich über die Theke."
    say "Börty" "Die Vermissten. Setz dich, das ist ein langes Glas."
    say "Börty" "Seit Monaten. Immer wieder ein Name auf der Liste. Und dann noch einer."
    say "Börty" "Niemand weiß, warum. Kein Kampf, kein Abschied. Die Leute sind einfach weg."
    say "$AGENT_NAME" "Und niemand geht dem nach?"
    say "Börty" "Einer schon. Sherlock Holmes – der Detektiv, im Ostdistrikt. Er arbeitet an dem Fall."
    say "Börty" "Wenn du mehr wissen willst als mein Thekengerede, sprich ihn an. Er weiß mehr als ich."
    BOERTY_VERMISSTE_INFO=1
    quest_note "Börty: Sherlock Holmes arbeitet am Fall der Vermissten (Ostdistrikt)"
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
