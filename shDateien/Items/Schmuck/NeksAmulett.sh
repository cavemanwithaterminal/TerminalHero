# ============================================================
#  TerminalHero - Item: Neks Amulett
#
#  Kategorie: Schmuck. EINMALIG, aber VERKÄUFLICH.
#  Kein Fundort im üblichen Sinn: Das Amulett steckt an der Leiche von
#  Nek Molerat in der Molerathöhle. Wer »search« gelernt hat, findet es
#  mit »search NeksLeiche« (Charakter/NeksLeiche.sh) und nimmt es auf.
#
#  Obwohl es zur Nek-Quest gehört, liegt es NICHT im Quest-Reiter: Es
#  ist ein tragbares Schmuckstück und kann im Inventar angelegt werden.
#  Solange es getragen wird, gibt es +50 maximale Tokens und −1
#  eingehenden Schaden. Gegnerangriffe ziehen trotzdem mindestens
#  1 Token ab; ein vollständiger Schutz ist nicht möglich.
#
#  Handelswert: Kauf 300 Bits, Verkauf die Hälfte (150 Bits). Simon
#  Guard bietet im Quest-Abschluss genau diese 150 Bits für das Amulett.
# ============================================================

item_define neksamulett schmuck \
    "Neks Amulett" \
    "Eine dünne Kette mit einem kalten, dunklen Stein. Der Stein ist abgeschliffen, als wäre er jahrelang unter Stoff getragen worden. Auf der Rückseite sind zwei Buchstaben eingeritzt: N. M.\n\nEs gehörte Nek Molerat. Jetzt gehört es dir – und Simon Guard sollte davon erfahren.\nWerte: +50 maximale Tokens, −1 eingehender Schaden. Gegnerangriffe ziehen mindestens 1 Token ab." \
    300

item_flag neksamulett unique   1
item_flag neksamulett sellable 1

# Ausrüstung: passt in den Amulett-Slot und wirkt, solange es getragen wird.
equip_define_item neksamulett amulett
equip_effect_tokens_max neksamulett 50
equip_effect_damage_reduction neksamulett 1

# Wird das Amulett abgelegt, verkauft oder verschenkt, verschwindet es
# automatisch aus dem Amulett-Slot (und der Token-Bonus fällt weg).
item_on_remove_neksamulett() {
    declare -F equip_unwear >/dev/null 2>&1 && equip_unwear neksamulett
    return 0
}
