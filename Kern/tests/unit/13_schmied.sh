# ============================================================
#  Unit-Test-Teil: Schmiede Bruno Amboss & Kampfset
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Schmiede, Kampfset & Tokenregeneration"
# ==================================================================
# Die sieben Kampfset-Teile, die Set-Definition und die beiden
# Händlerdateien laden. Die Dateien sind idempotent.
. "$SCRIPT_DIR/Items/Waffen/Kampfschwert.sh"
. "$SCRIPT_DIR/Items/Rüstung/Kampfhaube.sh"
. "$SCRIPT_DIR/Items/Rüstung/Kettenhemd.sh"
. "$SCRIPT_DIR/Items/Rüstung/Kettenhose.sh"
. "$SCRIPT_DIR/Items/Rüstung/Kampfschild.sh"
. "$SCRIPT_DIR/Items/Schmuck/Kampfring.sh"
. "$SCRIPT_DIR/Items/Schmuck/Kampfamulett.sh"
. "$SCRIPT_DIR/Items/Rüstung/KampfSet.sh"
. "$SCRIPT_DIR/Items/Rüstung/EinfachesSet.sh"
. "$SCRIPT_DIR/Charakter/BrunoAmboss.sh"
. "$SCRIPT_DIR/Charakter/JackBones.sh"
. "$SCRIPT_DIR/Orte/Schmiede.sh"

# --- Kategorien, Preise & Slots ------------------------------------
chk "Kampfschwert ist eine Waffe" "waffen" "$(item_cat kampfschwert)"
chk "Kampfhaube ist Rüstung" "ruestung" "$(item_cat kampfhaube)"
chk "Kettenhemd ist Rüstung" "ruestung" "$(item_cat kettenhemd)"
chk "Kettenhose ist Rüstung" "ruestung" "$(item_cat kettenhose)"
chk "Kampfschild ist Rüstung" "ruestung" "$(item_cat kampfschild)"
chk "Kampfring ist Schmuck" "schmuck" "$(item_cat kampfring)"
chk "Kampfamulett ist Schmuck" "schmuck" "$(item_cat kampfamulett)"

chk "Kampfschwert kostet 80 Bits" "80" "$(item_value kampfschwert)"
chk "Kampfhaube kostet 40 Bits" "40" "$(item_value kampfhaube)"
chk "Kettenhemd kostet 90 Bits" "90" "$(item_value kettenhemd)"
chk "Kettenhose kostet 80 Bits" "80" "$(item_value kettenhose)"
chk "Kampfschild kostet 90 Bits" "90" "$(item_value kampfschild)"
chk "Kampfring kostet 100 Bits" "100" "$(item_value kampfring)"
chk "Kampfamulett kostet 100 Bits" "100" "$(item_value kampfamulett)"

chk "Kampfschwert passt in die linke Hand" "0" \
    "$(equip_item_allowed kampfschwert linke_hand; echo $?)"
chk "Kampfschild passt in die rechte Hand" "0" \
    "$(equip_item_allowed kampfschild rechte_hand; echo $?)"
chk "Kampfhaube passt auf den Kopf" "0" \
    "$(equip_item_allowed kampfhaube kopf; echo $?)"
chk "Kettenhemd passt auf den Oberkörper" "0" \
    "$(equip_item_allowed kettenhemd oberkoerper; echo $?)"
chk "Kettenhose passt an die Beine" "0" \
    "$(equip_item_allowed kettenhose beine; echo $?)"
chk "Kampfring passt in Ring1" "0" \
    "$(equip_item_allowed kampfring ring1; echo $?)"
chk "Kampfring passt in Ring2" "0" \
    "$(equip_item_allowed kampfring ring2; echo $?)"
chk "Kampfamulett passt an den Amulett-Slot" "0" \
    "$(equip_item_allowed kampfamulett amulett; echo $?)"

chk "Kampfschwert darf Viren löschen" "0" \
    "$(equip_item_can_destroy kampfschwert virus; echo $?)"
chk "Kampfschwert darf keine freundlichen Dateien löschen" "1" \
    "$(equip_item_can_destroy kampfschwert datei; echo $?)"
chk "Kettenhemd senkt Schaden um 1" "1" \
    "$(equip_item_damage_reduction kettenhemd)"
chk "Kettenhose senkt Schaden um 1" "1" \
    "$(equip_item_damage_reduction kettenhose)"
chk "Kampfschild senkt Schaden um 2" "2" \
    "$(equip_item_damage_reduction kampfschild)"
chk "Kampfschild blockt mit 6 %" "6" \
    "$(equip_item_block_chance kampfschild)"
chk "Kampfring gibt +1 Token pro Intervall" "1" \
    "$(equip_item_token_regen kampfring)"

# --- Beschreibungen: Werte & echte Zeilenumbrüche -------------------
while IFS='|' read -r _id _want; do
    chk "$_id: Beschreibung nennt Werte" "1" \
        "$(item_desc "$_id" | grep -Fc 'Werte:')"
    chk "$_id: Beschreibung nennt $_want" "1" \
        "$(item_desc "$_id" | grep -Fc "$_want")"
    chk "$_id: kein literales \\n" "0" \
        "$(item_desc "$_id" | grep -Fc '\n')"
done <<'EOF'
kampfschwert|+10 maximale Tokens
kampfhaube|+5 maximale Tokens
kettenhemd|+9 maximale Tokens
kettenhose|+8 maximale Tokens
kampfschild|−2 eingehender Schaden
kampfring|+1 Token pro Regenerationsintervall
kampfamulett|+30 maximale Tokens
EOF
chk "Alle sieben Kampfset-Teile nennen den Set-Bonus" "7" \
    "$(for _id in kampfschwert kampfhaube kettenhemd kettenhose \
               kampfschild kampfring kampfamulett; do
           item_desc "$_id"
       done | grep -Fc 'Set-Bonus (vollständig): +35 maximale Tokens')"

# --- Jack Bones: Befehle lernen & Preise ---------------------------
LEARNED=()
SKILL_POINTS=6
BITS=200
OUT=()
jackbones_teach_cmd grep 1 25
chk_rc "Jack: grep-Unterricht klappt" "$?" 0
chk "Jack: grep ist gelernt" "1" "$(knows grep && echo 1 || echo 0)"
chk "Jack: 1 Skillpunkt bezahlt" "5" "$SKILL_POINTS"
chk "Jack: 25 Bits bezahlt" "175" "$BITS"

jackbones_teach_cmd search 2 50
chk_rc "Jack: search-Unterricht klappt" "$?" 0
chk "Jack: search ist gelernt" "1" "$(knows search && echo 1 || echo 0)"
chk "Jack: 2 weitere Skillpunkte bezahlt" "3" "$SKILL_POINTS"
chk "Jack: 50 weitere Bits bezahlt" "125" "$BITS"

jackbones_teach_cmd rm 3 100
chk_rc "Jack: rm-Unterricht klappt" "$?" 0
chk "Jack: rm ist gelernt" "1" "$(knows rm && echo 1 || echo 0)"
chk "Jack: 3 weitere Skillpunkte bezahlt" "0" "$SKILL_POINTS"
chk "Jack: 100 weitere Bits bezahlt" "25" "$BITS"

LEARNED=()
SKILL_POINTS=0
BITS=0
OUT=()
jackbones_teach_cmd grep 1 25
chk_rc "Jack: zu wenig Punkte/Bits scheitert" "$?" 1
chk "Jack: keine Punkte abgebucht" "0" "$SKILL_POINTS"
chk "Jack: keine Bits abgebucht" "0" "$BITS"
chk "Jack: grep bleibt gesperrt" "1" "$(knows grep && echo 0 || echo 1)"
chk "Jack: Preis wird genannt" "1" \
    "$(printf '%s\n' "${OUT[@]}" "${SAY_LOG[@]}" | grep -Fc '1 Skillpunkt und 25 Bits')"

# --- Volles Kampfset: 86 Item-Tokens + 35 Set-Tokens = 121 ----------
#     4 Item-Schadenresistenz + 1 Set-Resistenz = 5
#     Ring +1 Regen + Set +1 Regen = 2
TOKENS_MAX=1000
TOKENS_CUR=1000
equip_reset
inv_reset
for _id in kampfschwert kampfhaube kettenhemd kettenhose \
           kampfschild kampfring kampfamulett; do
    inv_add "$_id"
done
chk "Kampfset ist am Anfang unvollständig" "1" \
    "$(equip_set_complete kampf_set; echo $?)"

for _id in kampfschwert kampfhaube kettenhemd kettenhose \
           kampfschild kampfring kampfamulett; do
    equip_wear "$_id"
done
chk "Kampfset ist mit sieben Teilen vollständig" "0" \
    "$(equip_set_complete kampf_set; echo $?)"
chk "Kampfset: Max-Tokens 1121" "1121" "$TOKENS_MAX"
chk "Kampfset: Token-Bonus insgesamt 121" "121" \
    "$(equip_tokens_bonus_total)"
chk "Kampfset: Set-Token-Bonus 35" "35" \
    "$(equip_set_bonus_total)"
chk "Kampfset: Set-Tokenregen 1" "1" \
    "$(equip_set_token_regen_total)"
chk "Kampfset: Set-Schadensreduktion 1" "1" \
    "$(equip_set_damage_reduction_total)"
chk "Kampfset: Schadensreduktion 5" "5" \
    "$(equip_damage_reduction_total)"
chk "Kampfset: Blockchance 6" "6" \
    "$(equip_block_chance_total)"
chk "Kampfset: Tokenregeneration 2" "2" \
    "$(equip_token_regen_total)"
chk "Kampfset: Regeneration 13 Tokens pro Intervall" "13" \
    "$(tokens_step)"
chk "Kampfset ist nicht das Einfache Set" "1" \
    "$(equip_set_complete einfaches_set; echo $?)"

SUMMARY="$(equip_bonus_summary)"
chk "Bonuszeile nennt 121 Max-Tokens" "1" \
    "$(printf '%s\n' "$SUMMARY" | grep -c '+121 max. Tokens')"
chk "Bonuszeile nennt 5 Schadensresistenz" "1" \
    "$(printf '%s\n' "$SUMMARY" | grep -c '−5 eingehender Schaden')"
chk "Bonuszeile nennt 6 % Blockchance" "1" \
    "$(printf '%s\n' "$SUMMARY" | grep -c '6 % Blockchance')"
chk "Bonuszeile nennt 2 Token Regeneration" "1" \
    "$(printf '%s\n' "$SUMMARY" | grep -c '+2 Token/60 s')"

# --- Set unvollständig: alle Set-Boni fallen wieder weg -------------
equip_unwear kampfschild
chk "Ohne Schild ist das Kampfset unvollständig" "1" \
    "$(equip_set_complete kampf_set; echo $?)"
chk "Ohne Schild: Max-Tokens 1077" "1077" "$TOKENS_MAX"
chk "Ohne Schild: Set-Token-Bonus 0" "0" \
    "$(equip_set_bonus_total)"
chk "Ohne Schild: Set-Tokenregen 0" "0" \
    "$(equip_set_token_regen_total)"
chk "Ohne Schild: Set-Schadensreduktion 0" "0" \
    "$(equip_set_damage_reduction_total)"
chk "Ohne Schild: Schadensreduktion 2" "2" \
    "$(equip_damage_reduction_total)"
chk "Ohne Schild: Blockchance 0" "0" \
    "$(equip_block_chance_total)"
chk "Ohne Schild: Tokenregeneration 1" "1" \
    "$(equip_token_regen_total)"
chk "Ohne Schild: Regeneration 11 Tokens pro Intervall" "11" \
    "$(tokens_step)"

# --- Ring allein: +15 Max-Tokens und +1 Regen -----------------------
equip_reset
TOKENS_MAX=1000
TOKENS_CUR=1000
equip_wear kampfring
chk "Kampfring allein: Max-Tokens 1015" "1015" "$TOKENS_MAX"
chk "Kampfring allein: Regen 1" "1" "$(equip_token_regen_total)"
chk "Kampfring allein: 11 Tokens pro Intervall" "11" "$(tokens_step)"
equip_unwear kampfring
chk "Kampfring abgelegt: Max-Tokens 1000" "1000" "$TOKENS_MAX"
chk "Kampfring abgelegt: Regen 0" "0" "$(equip_token_regen_total)"
chk "Kampfring abgelegt: 10 Tokens pro Intervall" "10" "$(tokens_step)"

# --- Bruno führt beide Sets, Jack nur das Einfache ------------------
chk "Bruno ist als Händler angemeldet" "Bruno Amboss" \
    "$(handel_name brunoamboss)"
chk "Bruno über »Schmied« gefunden" "brunoamboss" \
    "$(handel_find "Schmied")"
for _id in einfachesschwert einfachemuetze einfacheshemd einfachehose \
           einfachesschild einfacherring einfachesamulett \
           kampfschwert kampfhaube kettenhemd kettenhose \
           kampfschild kampfring kampfamulett; do
    chk "Bruno hat $_id" "1" "$(handel_stock_count brunoamboss "$_id")"
done
chk "Bruno verkauft das Kampfschwert für 80 Bits" "80" \
    "$(handel_buy_price kampfschwert)"
chk "Bruno verkauft das Kampfamulett für 100 Bits" "100" \
    "$(handel_buy_price kampfamulett)"
for _id in kampfschwert kampfhaube kettenhemd kettenhose \
           kampfschild kampfring kampfamulett; do
    chk "Jack führt $_id nicht" "0" \
        "$(handel_stock_count jackbones "$_id")"
done

# --- Schmiede-Ordner, Datei & Dialog -------------------------------
BASE="$(district_base)"
SCHMIEDE="$BASE/Zentrum/Schmiede"
schmiede_build "$SCHMIEDE"
chk "Schmiede wird als Ordner registriert" "d" "${TYPE[$SCHMIEDE]:-}"
chk "BrunoAmboss wird als Datei registriert" "f" \
    "${TYPE[$SCHMIEDE/BrunoAmboss]:-}"
chk "Amboss wird als Datei registriert" "f" \
    "${TYPE[$SCHMIEDE/Amboss]:-}"
chk "Bruno-Dialog ist verknüpft" "dialog_brunoamboss" \
    "${DIALOG[$SCHMIEDE/BrunoAmboss]:-}"
chk "Bruno-Datei nennt das Kampfset" "1" \
    "$(printf '%s\n' "${CONTENT[$SCHMIEDE/BrunoAmboss]:-}" | grep -c 'Kampfset')"
chk "Schmiede-Ortsdatei existiert" "1" \
    "$([ -f "$SCRIPT_DIR/Orte/Schmiede.sh" ] && echo 1 || echo 0)"
chk "Bruno-Charakterdatei existiert" "1" \
    "$([ -f "$SCRIPT_DIR/Charakter/BrunoAmboss.sh" ] && echo 1 || echo 0)"

# --- Aufräumen ------------------------------------------------------
equip_reset
inv_reset
LEARNED=()
SKILL_POINTS=0
BITS=0
OUT=()
TOKENS_MAX=1000
TOKENS_CUR=1000
