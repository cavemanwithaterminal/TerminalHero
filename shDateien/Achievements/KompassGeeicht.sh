# ============================================================
#  TerminalHero - Achievement: Kompass Geeicht
# ------------------------------------------------------------
#  Das erste Achievement der Welt.
#
#  Freischalten: Der Agent gelangt zum ersten Mal in den Downloads-
#  Ordner - also mit »cd ..« hinaus aus seinem engen Startversteck.
#  Im selben Moment wird auch der Befehl »achievements« gelernt.
#  Die Freischaltung gibt 50 EXP; die Meldung samt Belohnung steht
#  im Dialogfenster.
#
#  Das ASCII-Bild zeigt einen kleinen Kompass. Es wird im Achievement-
#  Fenster links neben dem Text angezeigt.
# ============================================================

achievement_define "kompass_geeicht" \
    "Kompass Geeicht" \
    "Jetzt weiß ich worum es hier geht" \
'      .-"""-.
     /   N   \
    | W  +  E |
     \   S   /
      `-...-`'

achievement_reward_exp "kompass_geeicht" 50

achievement_check_kompass_geeicht() {   # $1=alter Pfad $2=neuer Pfad
    local to="$2"
    [ "${README_DONE:-0}" = "1" ] || return 0
    [ "$to" = "$HOME_DIR/Downloads" ] || return 0
    achievement_unlock "kompass_geeicht"
}

achievement_check_register achievement_check_kompass_geeicht
