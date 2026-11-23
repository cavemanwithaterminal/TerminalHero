# ============================================================
#  TerminalHero - Ausrüstungs-Set: Einfaches Set
#
#  Das erste vollständige Ausrüstungs-Set. Es besteht aus einer
#  Waffe, Kopfbedeckung, Brust, Beinen, einem Schild, EINEM Ring
#  und einem Amulett. Ringe müssen nicht doppelt getragen werden:
#  Ein Ring in Ring1 oder Ring2 genügt.
#
#  Sind alle sieben Teile gleichzeitig getragen, steigt TOKENS_MAX
#  zusätzlich um 25. Die einzelnen Token-Boni stehen in den
#  jeweiligen Item-Dateien; dieser Set-Bonus kommt obendrauf.
#
#  Die Datei meldet nur das Set an, kein eigenes Item. Sie wird wie
#  alle Dateien unter Items/ vom Loader geladen.
# ============================================================

equip_define_set einfaches_set 25 \
    einfachesschwert \
    einfachemuetze \
    einfacheshemd \
    einfachehose \
    einfachesschild \
    einfacherring \
    einfachesamulett
