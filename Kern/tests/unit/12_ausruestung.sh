# ============================================================
#  Unit-Test-Teil: Einfaches Ausrüstungs-Set
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================
# ==================================================================
section "Einfaches Set: Items, Slots, Boni & Speichern"
# ==================================================================
# Alle sieben Teile und die Set-Anmeldung laden. Die Dateien sind
# idempotent, dürfen also auch von anderen Testteilen schon geladen sein.
. "$SCRIPT_DIR/Items/Waffen/EinfachesSchwert.sh"
. "$SCRIPT_DIR/Items/Rüstung/EinfacheMütze.sh"
. "$SCRIPT_DIR/Items/Rüstung/EinfachesHemd.sh"
. "$SCRIPT_DIR/Items/Rüstung/EinfacheHose.sh"
. "$SCRIPT_DIR/Items/Rüstung/EinfachesSchild.sh"
. "$SCRIPT_DIR/Items/Schmuck/EinfacherRing.sh"
. "$SCRIPT_DIR/Items/Schmuck/EinfachesAmulett.sh"
. "$SCRIPT_DIR/Items/Rüstung/EinfachesSet.sh"

# --- Kategorien & Metadaten ---------------------------------------
chk "Waffen-Reiter ist der fünfte Reiter" "waffen" "${ITEM_CATS[4]:-}"
chk "Rüstungs-Reiter ist der sechste Reiter" "ruestung" "${ITEM_CATS[5]:-}"
chk "Waffen-Reiter heißt Waffen" "Waffen" "$(item_cat_label waffen)"
chk "Rüstungs-Reiter heißt Rüstung" "Rüstung" "$(item_cat_label ruestung)"

chk "Schwert ist eine Waffe" "waffen" "$(item_cat einfachesschwert)"
chk "Mütze ist Rüstung" "ruestung" "$(item_cat einfachemuetze)"
chk "Hemd ist Rüstung" "ruestung" "$(item_cat einfacheshemd)"
chk "Hose ist Rüstung" "ruestung" "$(item_cat einfachehose)"
chk "Schild ist Rüstung" "ruestung" "$(item_cat einfachesschild)"
chk "Ring ist Schmuck" "schmuck" "$(item_cat einfacherring)"
chk "Amulett ist Schmuck" "schmuck" "$(item_cat einfachesamulett)"

chk "Schwert kostet 50 Bits" "50" "$(item_value einfachesschwert)"
chk "Mütze kostet 25 Bits" "25" "$(item_value einfachemuetze)"
chk "Hemd kostet 50 Bits" "50" "$(item_value einfacheshemd)"
chk "Hose kostet 40 Bits" "40" "$(item_value einfachehose)"
chk "Schild kostet 50 Bits" "50" "$(item_value einfachesschild)"
chk "Ring kostet 50 Bits" "50" "$(item_value einfacherring)"
chk "Amulett kostet 50 Bits" "50" "$(item_value einfachesamulett)"

# --- Slots & Kampf-Metadaten ---------------------------------------
chk "Schwert passt in die linke Hand" "0" \
    "$(equip_item_allowed einfachesschwert linke_hand; echo $?)"
chk "Schwert passt in die rechte Hand" "0" \
    "$(equip_item_allowed einfachesschwert rechte_hand; echo $?)"
chk "Schild passt in die linke Hand" "0" \
    "$(equip_item_allowed einfachesschild linke_hand; echo $?)"
chk "Schild passt in die rechte Hand" "0" \
    "$(equip_item_allowed einfachesschild rechte_hand; echo $?)"
chk "Mütze passt auf den Kopf" "0" \
    "$(equip_item_allowed einfachemuetze kopf; echo $?)"
chk "Hemd passt auf den Oberkörper" "0" \
    "$(equip_item_allowed einfacheshemd oberkoerper; echo $?)"
chk "Hose passt an die Beine" "0" \
    "$(equip_item_allowed einfachehose beine; echo $?)"
chk "Ring passt in Ring1" "0" \
    "$(equip_item_allowed einfacherring ring1; echo $?)"
chk "Ring passt in Ring2" "0" \
    "$(equip_item_allowed einfacherring ring2; echo $?)"
chk "Amulett passt an den Amulett-Slot" "0" \
    "$(equip_item_allowed einfachesamulett amulett; echo $?)"

chk "Schwert darf Viren löschen" "0" \
    "$(equip_item_can_destroy einfachesschwert virus; echo $?)"
chk "Schwert darf keine freundlichen Dateien löschen" "1" \
    "$(equip_item_can_destroy einfachesschwert datei; echo $?)"
chk "Schild senkt eingehenden Schaden um 1" "1" \
    "$(equip_item_damage_reduction einfachesschild)"
chk "Schild hat 5 % Blockchance" "5" \
    "$(equip_item_block_chance einfachesschild)"

# --- Beschreibungen: Werte & echte Zeilenumbrüche -------------------
while IFS='|' read -r _id _want; do
    chk "$_id: Beschreibung nennt Werte" "1" \
        "$(item_desc "$_id" | grep -Fc 'Werte:')"
    chk "$_id: Beschreibung nennt $_want" "1" \
        "$(item_desc "$_id" | grep -Fc "$_want")"
    chk "$_id: kein literales \\n" "0" \
        "$(item_desc "$_id" | grep -Fc '\n')"
done <<'EOF'
einfachesschwert|+5 maximale Tokens
einfachemuetze|+3 maximale Tokens
einfacheshemd|+5 maximale Tokens
einfachehose|+4 maximale Tokens
einfachesschild|−1 eingehender Schaden
einfacherring|+10 maximale Tokens
einfachesamulett|+13 maximale Tokens
EOF
chk "Alle sieben Teile nennen den Set-Bonus" "7" \
    "$(for _id in einfachesschwert einfachemuetze einfacheshemd einfachehose \
               einfachesschild einfacherring einfachesamulett; do
           item_desc "$_id"
       done | grep -Fc 'Set-Bonus (vollständig): +25 maximale Tokens')"

# --- Volles Set: +45 aus Teilen, +25 Set-Bonus ----------------------
TOKENS_MAX=1000
TOKENS_CUR=1000
equip_reset
inv_reset
for _id in einfachesschwert einfachemuetze einfacheshemd einfachehose \
           einfachesschild einfacherring einfachesamulett; do
    inv_add "$_id"
done
chk "Set ist am Anfang unvollständig" "1" \
    "$(equip_set_complete einfaches_set; echo $?)"

equip_wear einfachesschwert
equip_wear einfachemuetze
equip_wear einfacheshemd
equip_wear einfachehose
equip_wear einfachesschild
equip_wear einfacherring
chk "Sechs Teile: Set noch unvollständig" "1" \
    "$(equip_set_complete einfaches_set; echo $?)"
chk "Sechs Teile: Max-Tokens 1032" "1032" "$TOKENS_MAX"
chk "Sechs Teile: kein Set-Bonus" "0" "$(equip_set_bonus_total)"

equip_wear einfachesamulett
chk "Alle sieben Teile: Set vollständig" "0" \
    "$(equip_set_complete einfaches_set; echo $?)"
chk "Volles Set: Max-Tokens 1070" "1070" "$TOKENS_MAX"
chk "Volles Set: Token-Bonus insgesamt 70" "70" "$(equip_tokens_bonus_total)"
chk "Volles Set: Set-Bonus 25" "25" "$(equip_set_bonus_total)"
chk "Volles Set: Bonus ist als angewendet markiert" "1" \
    "${EQUIP_SET_APPLIED[einfaches_set]:-0}"

chk "Schwert liegt in der linken Hand" "einfachesschwert" \
    "${EQUIP_SLOT_ITEM[linke_hand]:-}"
chk "Schild liegt in der rechten Hand" "einfachesschild" \
    "${EQUIP_SLOT_ITEM[rechte_hand]:-}"
chk "Mütze liegt auf dem Kopf" "einfachemuetze" "${EQUIP_SLOT_ITEM[kopf]:-}"
chk "Hemd liegt auf dem Oberkörper" "einfacheshemd" \
    "${EQUIP_SLOT_ITEM[oberkoerper]:-}"
chk "Hose liegt an den Beinen" "einfachehose" "${EQUIP_SLOT_ITEM[beine]:-}"
chk "Ring liegt in Ring1" "einfacherring" "${EQUIP_SLOT_ITEM[ring1]:-}"
chk "Ring2 bleibt leer" "" "${EQUIP_SLOT_ITEM[ring2]:-}"
chk "Amulett liegt am Amulett-Slot" "einfachesamulett" \
    "${EQUIP_SLOT_ITEM[amulett]:-}"

equip_wear einfacherring
chk_rc "Ein Ring wird nicht doppelt getragen" "$?" 2
chk "Set bleibt mit einem Ring vollständig" "0" \
    "$(equip_set_complete einfaches_set; echo $?)"
chk "Ring2 bleibt auch nach dem zweiten Versuch leer" "" \
    "${EQUIP_SLOT_ITEM[ring2]:-}"

chk "Schadensreduktion des Sets" "1" "$(equip_damage_reduction_total)"
chk "Blockchance des Sets" "5" "$(equip_block_chance_total)"
SUMMARY="$(equip_bonus_summary)"
chk "Bonuszeile nennt 70 Max-Tokens" "1" \
    "$(printf '%s\n' "$SUMMARY" | grep -c '+70 max. Tokens')"
chk "Bonuszeile nennt die Schadensreduktion" "1" \
    "$(printf '%s\n' "$SUMMARY" | grep -c '−1 eingehender Schaden')"
chk "Bonuszeile nennt die Blockchance" "1" \
    "$(printf '%s\n' "$SUMMARY" | grep -c '5 % Blockchance')"

# --- Set-Bonus fällt beim Ablegen wieder weg ------------------------
equip_unwear einfachesamulett
chk "Amulett abgelegt: Set unvollständig" "1" \
    "$(equip_set_complete einfaches_set; echo $?)"
chk "Amulett abgelegt: Set-Bonus entfernt" "0" \
    "${EQUIP_SET_APPLIED[einfaches_set]:-0}"
chk "Amulett abgelegt: Max-Tokens 1032" "1032" "$TOKENS_MAX"
chk "Amulett abgelegt: Token-Bonus nur noch Teile" "32" \
    "$(equip_tokens_bonus_total)"
equip_wear einfachesamulett
chk "Amulett wieder angelegt: Max-Tokens 1070" "1070" "$TOKENS_MAX"

# --- Inventar-Entfernen legt Ausrüstung automatisch ab -------------
inv_remove einfachesamulett 1
chk "Verkauf/Entfernen legt das Amulett automatisch ab" "0" \
    "$(equip_item_worn einfachesamulett && echo 1 || echo 0)"
chk "Entfernen senkt die Max-Tokens wieder" "1032" "$TOKENS_MAX"
chk "Entfernen entfernt den Set-Bonus" "0" \
    "${EQUIP_SET_APPLIED[einfaches_set]:-0}"
inv_add einfachesamulett
equip_wear einfachesamulett
chk "Neu angelegtes Amulett stellt den Set-Bonus wieder her" "1070" "$TOKENS_MAX"

# --- Speichern/Laden: Set-Bonus wird nicht gedoppelt ----------------
SET_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-set.XXXXXX")"
TH_SAVES_DIR="$SET_SAVE_DIR"
th_save manual; chk_rc "Spielstand mit vollem Set speichern" "$?" 0
chk "Save enthält 1070 Max-Tokens" "1" \
    "$(grep -c '^TOKENS_MAX=1070' "$SET_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält den angewendeten Set-Bonus" "1" \
    "$(grep -c '\[einfaches_set\]=1' "$SET_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält das Amulett im Slot" "1" \
    "$(grep -c '\[amulett\]=einfachesamulett' "$SET_SAVE_DIR/manual1.save" 2>/dev/null)"

EQUIP_SLOT_ITEM=()
EQUIP_SET_APPLIED=()
TOKENS_MAX=1000
TOKENS_CUR=1000
th_load manual; chk_rc "Spielstand mit Set laden" "$?" 0
chk "Laden stellt die Max-Tokens her" "1070" "$TOKENS_MAX"
chk "Laden stellt das Amulett wieder her" "einfachesamulett" \
    "${EQUIP_SLOT_ITEM[amulett]:-}"
chk "Laden stellt den Set-Status wieder her" "1" \
    "${EQUIP_SET_APPLIED[einfaches_set]:-0}"
equip_set_refresh_all
chk "Set-Abgleich nach dem Laden doppelt nicht" "1070" "$TOKENS_MAX"
chk "Set-Status bleibt nach dem Abgleich 1" "1" \
    "${EQUIP_SET_APPLIED[einfaches_set]:-0}"
rm -rf "$SET_SAVE_DIR"
unset TH_SAVES_DIR

# --- Reiterzeile: sechs Kategorien passen nicht immer in eine Zeile ---
# Die Inventar-Reiter scrollen um den aktiven Reiter, wenn der Platz nicht
# reicht (80x24/60x24). put_text wird im Subshell durch einen Recorder
# ersetzt, damit der Test die tatsächlich gezeichneten Texte sieht.
. "$SCRIPT_DIR/InGameBefehle/Inventar.sh"
TAB_FULL="$( ( put_text() { printf '%s\n' "$4"; }
    inv_tab_row 1 1 0 0 99 Spezial Quest Plunder Schmuck Waffen Rüstung ) )"
chk "Breite Reiterzeile zeigt alle sechs Kategorien" "6" \
    "$(printf '%s\n' "$TAB_FULL" | wc -l | tr -d ' ')"
TAB_START="$( ( put_text() { printf '%s\n' "$4"; }
    inv_tab_row 1 1 0 0 51 Spezial Quest Plunder Schmuck Waffen Rüstung ) )"
chk "Schmale Reiterzeile zeigt den rechten Pfeil" "1" \
    "$(printf '%s\n' "$TAB_START" | grep -c '^›$')"
chk "Schmale Reiterzeile blendet Rüstung zunächst aus" "0" \
    "$(printf '%s\n' "$TAB_START" | grep -c 'Rüstung')"
TAB_END="$( ( put_text() { printf '%s\n' "$4"; }
    inv_tab_row 1 1 0 5 51 Spezial Quest Plunder Schmuck Waffen Rüstung ) )"
chk "Aktiver Reiter Rüstung wird im Ausschnitt gezeigt" "1" \
    "$(printf '%s\n' "$TAB_END" | grep -c 'Rüstung')"
chk "Aktiver Reiter Rüstung bekommt den linken Pfeil" "1" \
    "$(printf '%s\n' "$TAB_END" | grep -c '^‹$')"

# --- Jack Bones führt das Set --------------------------------------
. "$SCRIPT_DIR/Charakter/JackBones.sh"
chk "Jack hat das Schwert" "1" "$(handel_stock_count jackbones einfachesschwert)"
chk "Jack hat die Mütze" "1" "$(handel_stock_count jackbones einfachemuetze)"
chk "Jack hat das Hemd" "1" "$(handel_stock_count jackbones einfacheshemd)"
chk "Jack hat die Hose" "1" "$(handel_stock_count jackbones einfachehose)"
chk "Jack hat das Schild" "1" "$(handel_stock_count jackbones einfachesschild)"
chk "Jack hat den Ring" "1" "$(handel_stock_count jackbones einfacherring)"
chk "Jack hat das Amulett" "1" "$(handel_stock_count jackbones einfachesamulett)"
chk "Jack verkauft das Schwert für 50 Bits" "50" \
    "$(handel_buy_price einfachesschwert)"

# --- Aufräumen ------------------------------------------------------
equip_reset
inv_reset
TOKENS_MAX=1000
TOKENS_CUR=1000
