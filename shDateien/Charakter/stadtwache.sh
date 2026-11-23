# ============================================================
#  TerminalHero - Charakter: Stadtwachen
#
#  Beseelte Datei: »touch« öffnet das Gespräch. Wird bei Bedarf vom
#  .sh-Manager (kern/loader.sh) geladen, erst wenn der Spieler sie berührt.
#  Vier Wachen, je eine kurze Wortmeldung (touch).
# ============================================================

dialog_wache_1() { OUT+=("Stadtwache: Stör mich nicht."); }
dialog_wache_2() { OUT+=("Stadtwache: Siehst du nicht, dass ich zu tun habe?"); }
dialog_wache_3() { OUT+=("Stadtwache: Kein Zutritt. Basta."); }
dialog_wache_4() { OUT+=("Stadtwache: Beweg dich weiter, ja?"); }
