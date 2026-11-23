# ============================================================
#  Unit-Test-Teil: Archiv, Token-Fills, Shops & Save-Slots
#  Wird von Kern/tests/unit.sh in fester Reihenfolge geladen.
# ============================================================

section "Archiv & Freischaltungen"

# Archive-Befehlsmodul laden (idempotent genug für Tests)
. "$SCRIPT_DIR/InGameBefehle/archive.sh"
. "$SCRIPT_DIR/Handelsfenster.sh"
. "$SCRIPT_DIR/kern/save.sh"

# Fallback-Stubs, falls Zeitfunktionen im Unit-Kontext fehlen
uhrzeit_day() { printf '%s' "${UHR_DAY:-0}"; }

ARCHIVE_KAP1=0
ARCHIVE_ORT_DESKTOPCITY=0
chk "Kapitel 1 anfangs gesperrt" "1" "$(archive_is_unlocked 1; echo $?)"
chk "Desktop City anfangs gesperrt" "1" "$(archive_ort_is_unlocked desktopcity; echo $?)"
archive_unlock 1
archive_ort_unlock desktopcity
chk "Kapitel 1 freigeschaltet" "0" "$(archive_is_unlocked 1; echo $?)"
chk "Desktop City freigeschaltet" "0" "$(archive_ort_is_unlocked desktopcity; echo $?)"
chk "Archivtitel Kapitel 1" "Kapitel 1 — Ein neuer Agent" "$(archive_chapter_title 1)"
chk "Archivtitel Desktop City" "Desktop City" "$(archive_ort_title desktopcity)"

# Save-Serialisierung: Archiv-Flags müssen persistiert werden
ARCHIVE_KAP1=1
ARCHIVE_ORT_DESKTOPCITY=1
_ARCH_SAVE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/th-arch.XXXXXX")"
TH_SAVES_DIR="$_ARCH_SAVE_DIR"
th_save manual1 >/dev/null 2>&1; _arc_rc=$?
chk_rc "Save mit Archiv-Flags klappt" "$_arc_rc" 0
chk "Save enthält ARCHIVE_KAP1=1" "1" \
    "$(grep -c '^ARCHIVE_KAP1=1' "$_ARCH_SAVE_DIR/manual1.save" 2>/dev/null)"
chk "Save enthält ARCHIVE_ORT_DESKTOPCITY=1" "1" \
    "$(grep -c '^ARCHIVE_ORT_DESKTOPCITY=1' "$_ARCH_SAVE_DIR/manual1.save" 2>/dev/null)"

# Legacy-Fallback: manual1 liest altes manual.save, wenn manual1 fehlt
rm -f "$_ARCH_SAVE_DIR/manual1.save"
cat > "$_ARCH_SAVE_DIR/manual.save" <<'SAVE'
#TH_SAVE_INFO|2026-01-01 00:00:00|benutzer@testhost|Neugier|manual
TH_SAVE_VERSION=1
TH_SAVE_TYPE=manual
ARCHIVE_KAP1=1
SAVE
chk "th_read_save_file manual1 fällt auf manual.save zurück" \
    "$_ARCH_SAVE_DIR/manual.save" "$(th_read_save_file manual1)"
chk "th_have_save manual1 erkennt Legacy-Save" "0" "$(th_have_save manual1; echo $?)"
rm -rf "$_ARCH_SAVE_DIR"
unset TH_SAVES_DIR

# Save-Slot-Normalisierung
chk "th_norm_type manual -> manual1" "manual1" "$(th_norm_type manual)"
chk "th_norm_type manual2 -> manual2" "manual2" "$(th_norm_type manual2)"
chk "th_norm_type slot3 -> manual3" "manual3" "$(th_norm_type slot3)"
chk "th_norm_type quicksave -> quick" "quick" "$(th_norm_type quicksave)"


section "Token-Fill-Items"

# Neue nutzbare Items laden
. "$SCRIPT_DIR/NutzbareItems/KlTokenFill.sh"
. "$SCRIPT_DIR/NutzbareItems/TokenFill.sh"
. "$SCRIPT_DIR/NutzbareItems/GrTokenFill.sh"
. "$SCRIPT_DIR/NutzbareItems/RTokenFill.sh"
. "$SCRIPT_DIR/GegnerLoot/MoleratCode.sh"

chk "Kl. Token Fill existiert" "0" "$(item_exists kl_token_fill; echo $?)"
chk "Token Fill existiert" "0" "$(item_exists token_fill; echo $?)"
chk "Gr. Token Fill existiert" "0" "$(item_exists gr_token_fill; echo $?)"
chk "R. Token Fill existiert" "0" "$(item_exists r_token_fill; echo $?)"

chk "Kl. Token Fill ist Plunder" "plunder" "$(item_cat kl_token_fill)"
chk "Token Fill ist Plunder" "plunder" "$(item_cat token_fill)"
chk "Gr. Token Fill ist Plunder" "plunder" "$(item_cat gr_token_fill)"
chk "R. Token Fill ist Plunder" "plunder" "$(item_cat r_token_fill)"

chk "Kl. Token Fill kostet 50 Bits" "50" "$(handel_buy_price kl_token_fill)"
chk "Token Fill kostet 110 Bits" "110" "$(handel_buy_price token_fill)"
chk "Gr. Token Fill kostet 230 Bits" "230" "$(handel_buy_price gr_token_fill)"
chk "R. Token Fill kostet 500 Bits" "500" "$(handel_buy_price r_token_fill)"

chk "Kl. Token Fill verkäuflich" "1" "${ITEM_SELLABLE[kl_token_fill]:-0}"
chk "Token Fill verkäuflich" "1" "${ITEM_SELLABLE[token_fill]:-0}"
chk "Gr. Token Fill verkäuflich" "1" "${ITEM_SELLABLE[gr_token_fill]:-0}"
chk "R. Token Fill verkäuflich" "1" "${ITEM_SELLABLE[r_token_fill]:-0}"

chk "MoleratCode Kaufpreis 4 Bits" "4" "$(handel_buy_price moleratcode)"

# Benutzung: Tokens auffüllen (bis max), Item verbrauchen
OUT=()
TOKENS_MAX=1000
TOKENS_CUR=100
inv_reset
inv_add kl_token_fill 1
item_use_kl_token_fill >/dev/null 2>&1 || true
chk "Kl. Token Fill gibt +250 Tokens" "350" "$TOKENS_CUR"
chk "Kl. Token Fill verbraucht 1 Stück" "0" "$(inv_count kl_token_fill)"

TOKENS_CUR=900
inv_add token_fill 1
item_use_token_fill >/dev/null 2>&1 || true
chk "Token Fill füllt bis Maximum (nicht darüber)" "1000" "$TOKENS_CUR"
chk "Token Fill verbraucht 1 Stück" "0" "$(inv_count token_fill)"

TOKENS_CUR=0
inv_add gr_token_fill 1
item_use_gr_token_fill >/dev/null 2>&1 || true
chk "Gr. Token Fill gibt +1200, begrenzt auf Max" "1000" "$TOKENS_CUR"
chk "Gr. Token Fill verbraucht 1 Stück" "0" "$(inv_count gr_token_fill)"

TOKENS_CUR=200
inv_add r_token_fill 1
item_use_r_token_fill >/dev/null 2>&1 || true
chk "R. Token Fill gibt +2500, begrenzt auf Max" "1000" "$TOKENS_CUR"
chk "R. Token Fill verbraucht 1 Stück" "0" "$(inv_count r_token_fill)"

# Keine Verschwendung bei vollen Tokens
TOKENS_CUR=1000
inv_add kl_token_fill 1
OUT=()
item_use_kl_token_fill >/dev/null 2>&1 || true
chk "Kl. Token Fill bei vollen Tokens nicht verbraucht" "1" "$(inv_count kl_token_fill)"
chk "Kl. Token Fill bei vollen Tokens keine Änderung" "1000" "$TOKENS_CUR"


section "Händler: MoleratCode & Token-Fills"

# Händler-Lagerfunktionen laden
. "$SCRIPT_DIR/Charakter/BörtySmiles.sh"
. "$SCRIPT_DIR/Charakter/BrunoAmboss.sh"
. "$SCRIPT_DIR/Charakter/JackBones.sh"

# Lager neu anmelden, um Basiswerte sicher zu setzen
LEVEL=0
handel_lager_boerty >/dev/null 2>&1 || true
handel_lager_brunoamboss >/dev/null 2>&1 || true
handel_lager_jackbones >/dev/null 2>&1 || true

chk "Börty führt MoleratCode (10/Tag)" "10" "${HANDEL_BASE[boerty/moleratcode]:-0}"
chk "Bruno führt Kl. Token Fill (10/Tag)" "10" "${HANDEL_BASE[brunoamboss/kl_token_fill]:-0}"
chk "Jack führt MoleratCode (10/Tag)" "10" "${HANDEL_BASE[jackbones/moleratcode]:-0}"
chk "Jack führt Kl. Token Fill (10/Tag)" "10" "${HANDEL_BASE[jackbones/kl_token_fill]:-0}"
chk "Jack <10: kein Token Fill" "0" "${HANDEL_BASE[jackbones/token_fill]:-0}"
chk "Jack <20: kein Gr. Token Fill" "0" "${HANDEL_BASE[jackbones/gr_token_fill]:-0}"
chk "Jack <30: kein R. Token Fill" "0" "${HANDEL_BASE[jackbones/r_token_fill]:-0}"

LEVEL=10
handel_lager_jackbones >/dev/null 2>&1 || true
chk "Jack ab Level 10: Token Fill (10/Tag)" "10" "${HANDEL_BASE[jackbones/token_fill]:-0}"
chk "Jack Level 10: noch kein Gr. Token Fill" "0" "${HANDEL_BASE[jackbones/gr_token_fill]:-0}"

LEVEL=20
handel_lager_jackbones >/dev/null 2>&1 || true
chk "Jack ab Level 20: Gr. Token Fill (10/Tag)" "10" "${HANDEL_BASE[jackbones/gr_token_fill]:-0}"
chk "Jack Level 20: noch kein R. Token Fill" "0" "${HANDEL_BASE[jackbones/r_token_fill]:-0}"

LEVEL=30
handel_lager_jackbones >/dev/null 2>&1 || true
chk "Jack ab Level 30: R. Token Fill (10/Tag)" "10" "${HANDEL_BASE[jackbones/r_token_fill]:-0}"
