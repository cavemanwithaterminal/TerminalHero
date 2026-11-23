# ============================================================
#  TerminalHero - Charakter: Michael Mitch
#
#  Börtys früherer Lagergehilfe - inzwischen arbeitet er im
#  Restaurant im Westdistrikt (Orte/Restaurant.sh). Dort steht er als
#  beseelte Datei »MichaelMitch« und wird mit »touch MichaelMitch«
#  angesprochen.
#
#  Gesprächsreihenfolge:
#    1. Die Suche nach Mitch (MITCH_GIVEN, noch nicht MITCH_TALKED):
#       Der Agent sagt, dass Börty ihn schickt. Mitch erklärt, warum er
#       gegangen ist, und bittet den Agenten, Börty Bescheid zu geben.
#       Danach führt die Quest zurück in die Kneipe.
#    2. Wiederholung, solange Börty noch nichts weiß.
#    3. Nach dem Abschluss (MITCH_DONE): kurze Anerkennung, dann normaler
#       Small Talk.
#    4. Standardgespräch: Vorstellung beim ersten Mal (MICHAEL_INTRO_DONE),
#       danach kurze, freundliche Wiedererkennung.
# ============================================================

dialog_michael() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ RESTAURANT · WESTDISTRIKT ═════")
    OUT+=("Michael Mitch    Rolle: Service & Küche")
    OUT+=("")
    render

    if [ "${MITCH_GIVEN:-0}" = "1" ] && [ "${MITCH_TALKED:-0}" != "1" ] \
       && [ "${MITCH_DONE:-0}" != "1" ]; then
        # --- 1) Die Suche: Börty hat den Agenten geschickt -------------
        MICHAEL_INTRO_DONE=1
        say "-" "Hinter der Theke hält ein großer, ruhiger Mann inne, als du auf ihn zukommst. Er stellt das Glas ab."
        say "Michael" "Michael Mitch."
        say "$AGENT_NAME" "Börty schickt mich. Er sucht dich."
        say "-" "Mitchs Blick geht kurz zur Tür. Dann wieder zu dir."
        say "Michael" "Börty."
        say "Michael" "Ich hatte gehofft, er würde nicht nach mir suchen lassen."
        say "$AGENT_NAME" "Er sagt, du bist einfach verschwunden."
        say "Michael" "Ja. Das war feige."
        say "-" "Er wischt sich die Hände an der Schürze ab, obwohl sie trocken sind."
        say "Michael" "Ich wollte nicht mehr für ihn arbeiten. Aber ich hatte zu viel Angst, es ihm ins Gesicht zu sagen."
        say "Michael" "Also bin ich gegangen. Ohne ein Wort."
        say "Michael" "Es tut mir leid. Wirklich. Aber ich komme nicht zurück."
        say "Michael" "Hier gefällt es mir besser. Ich mache mehr aus meinem Leben als Kisten zu zählen."
        say "Michael" "Und Börty zahlt einfach zu wenig. Das hat er schon immer."
        say "$AGENT_NAME" "Okay. Wie du möchtest. Ich werde es ihm überbringen."
        say "Michael" "Danke."
        say "Michael" "Sag ihm, dass es mir leid tut. Aber sag ihm auch: Ich arbeite nicht mehr für ihn."
        MITCH_TALKED=1
        quest_note "Mitch ist aufgetaucht. Er arbeitet jetzt im Restaurant im Westdistrikt und will nicht zu Börty zurück."
        OUT+=("")
        OUT+=("[ NEUES ZIEL ]  Geh zu Börty in die Kneipe (Ostdistrikt) und erzähle ihm von Mitch.")
    elif [ "${MITCH_TALKED:-0}" = "1" ] && [ "${MITCH_DONE:-0}" != "1" ]; then
        # --- 2) Erinnerung, solange Börty noch nichts weiß -------------
        say "Michael" "Hast du es Börty schon erzählt?"
        say "$AGENT_NAME" "Noch nicht. Ich gehe gleich zu ihm."
        say "Michael" "Gut. Je länger du wartest, desto schwerer wird es."
    elif [ "${MITCH_DONE:-0}" = "1" ]; then
        # --- 3) Börty weiß Bescheid -------------------------------------
        say "Michael" "Du hast es ihm also gesagt."
        say "$AGENT_NAME" "Ja. Er war nicht begeistert."
        say "Michael" "Das war zu erwarten. Danke, dass du es übernommen hast."
        say "-" "Er nickt dir zu und stellt ein frisches Glas auf die Theke."
        say "Michael" "Setz dich. Oder sag, was du brauchst."
    elif [ "${MICHAEL_INTRO_DONE:-0}" != "1" ]; then
        # --- 4) Erstes Kennenlernen ohne Quest --------------------------
        MICHAEL_INTRO_DONE=1
        say "-" "Hinter der Theke wischt ein großer, ruhiger Mann ein Glas trocken. Er stellt es ab, bevor er spricht."
        say "Michael" "Michael Mitch."
        say "Michael" "Ich war Börtys Lagergehilfe. Kisten, Listen, Lieferungen – das konnte ich."
        say "Michael" "Irgendwann war es genug. Jetzt arbeite ich hier: Tische, Bestellungen, und abends die Küche."
        say "Michael" "Wenn du etwas willst, sag es einfach. Ich höre besser zu als die meisten Kisten."
        say "-" "Er schiebt dir einen Stuhl zurecht und wartet, ohne dich anzustarren."
    else
        # --- 5) Normaler Small Talk -------------------------------------
        say "Michael" "Du schon wieder."
        say "-" "Er nickt dir zu und stellt ein frisches Glas auf die Theke."
        say "Michael" "Setz dich. Oder sag, was du brauchst."
    fi

    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}
