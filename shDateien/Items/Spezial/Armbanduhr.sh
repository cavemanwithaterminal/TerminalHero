# ============================================================
#  TerminalHero - Item: Armbanduhr
#
#  Kategorie: Spezial. EINMALIG (nur ein Exemplar) und UNVERKÄUFLICH.
#  Kein Startitem: Die Uhr liegt in der Welt (erster Fundort: die Baracke
#  EingestürzteBaracke im Süddistrikt, siehe Orte/Süddistrikt.sh) und
#  wird mit »grep« herausgezogen.
#
#  Die Uhr ist BESEELT (item_talk): »touch Armbanduhr« startet ein kurzes
#  Gespräch - die Uhr stellt sich vor und wundert sich, angesprochen zu
#  werden. Sie misst die Spielzeit - erst mit ihr wird die In-Game-Uhr
#  im GUI sichtbar (kern/Uhrzeit.sh).
#
#  Angemeldet wird das Item über item_define (siehe kern/items.sh).
# ============================================================

item_define armbanduhr spezial \
    "Armbanduhr" \
    "Eine alte, mechanische Armbanduhr mit gesprungenem Glas. Sie tickt noch immer – leise, gleichmäßig, unbeirrt. Woher sie stammt, kann der Agent nicht mehr sagen. Er trägt sie, als hätte sie schon vor dem Virus zu ihm gehört."

# Einmalig und unverkäuflich: Der Agent kann nur EINE Armbanduhr besitzen.
item_flag armbanduhr unique   1
item_flag armbanduhr sellable 0

# --- Ansprechen (»touch«) --------------------------------------------
# Niemand spricht je eine Uhr an – deshalb ist sie ehrlich überrascht.
# Sie stellt sich kurz vor und wundert sich. Sie lehrt NICHTS.
armbanduhr_gespraech() {
    DIALOG_ACTIVE=1
    OUT=(); WRAP_KEY=""
    OUT+=("═════ ARM BANDUHR · ANGESPROCHEN ═════")
    OUT+=("Gang : ruhig, mechanisch    Zustand : intakt")
    OUT+=("")
    render

    if [ "${ARMBANDUHR_TALKED:-0}" = "1" ]; then
        say "Armbanduhr" "Du schon wieder. Ich habe nichts Neues zu berichten. Ich ticke."
        dialog_pause
        DIALOG_ACTIVE=0; DIALOG_HINT=""
        return
    fi
    ARMBANDUHR_TALKED=1

    say "Armbanduhr" "…du sprichst mit MIR?"
    say "Armbanduhr" "Das hat noch niemand getan. Man liest mich. Man legt mich ab. Man vergisst mich."
    say "-" "Ein feines Ticken – einen Hauch schneller als vorher."
    say "Armbanduhr" "Angesprochen zu werden: Das wäre sonst nie passiert."
    say "Armbanduhr" "Ich bin nichts als eine Uhr. Ich habe keine Geschichte für dich. Nur Zeit."
    OUT+=("")
    say "-" "Die Uhr wartet. Sie hat Zeit. Sie misst sie sogar."
    dialog_pause
    DIALOG_ACTIVE=0; DIALOG_HINT=""
}

item_talk armbanduhr armbanduhr_gespraech

# --- Aufheben (»grep Armbanduhr«) -------------------------------------
# Die Uhr ist das erste Item, das etwas freischaltet: erst mit ihr zeigt
# die Randzeile die Uhrzeit an (kern/Uhrzeit.sh / kern/render.sh). Der
# Hinweis gehört direkt an die Aufnahme - der Haken item_on_take_<id>
# wird in kern/items.sh (world_item_pickup) aufgerufen.
item_on_take_armbanduhr() {
    OUT+=("   [ Armbanduhr ]  Von jetzt an wird die Uhrzeit angezeigt:")
    OUT+=("     ◷ HH:MM  – in der Randzeile des PFAD-Fensters.")
}
