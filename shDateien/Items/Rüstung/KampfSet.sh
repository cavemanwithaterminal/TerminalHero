# ============================================================
#  TerminalHero - Ausrüstungs-Set: Kampfset
#
#  Das zweite vollständige Ausrüstungs-Set. Es besteht aus einer
#  Waffe, Kopfbedeckung, Brust, Beinen, einem Schild, EINEM Ring
#  und einem Amulett. Ringe müssen nicht doppelt getragen werden:
#  Ein Ring in Ring1 oder Ring2 genügt.
#
#  Set-Bonus bei vollständiger Ausrüstung:
#     +35 maximale Tokens
#     +1 Token pro Regenerationsintervall (60 s)
#     +1 eingehender Schaden weniger
#
#  Die Datei meldet nur das Set an, kein eigenes Item. Sie wird wie
#  alle Dateien unter Items/ vom Loader geladen.
# ============================================================

equip_define_set kampf_set 35 \
    kampfschwert \
    kampfhaube \
    kettenhemd \
    kettenhose \
    kampfschild \
    kampfring \
    kampfamulett

equip_set_effect_token_regen kampf_set 1
equip_set_effect_damage_reduction kampf_set 1
