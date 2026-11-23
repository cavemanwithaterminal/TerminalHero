# ============================================================
#  TerminalHero - Terminal-Befehl: grep
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#
#  »grep« sucht ein Muster. Sein eigentlicher Zweck in dieser Welt:
#  Es ZIEHT WELT-GEGENSTÄNDE HERAUS - ein Fundort (world_item_place)
#  wandert damit ins Inventar. Daneben funktioniert es wie das echte
#  grep: es zeigt die passenden Zeilen aus Dateien.
#
#  Sonderfall Leiche (Charakter/NeksLeiche.sh): »grep NeksLeiche« zieht
#  die Leiche hinter dem Agenten her, ein zweites »grep« legt sie ab.
#  Das kostet doppelt so viele Tokens und gibt doppelt so viele EXP
#  (20/4 statt 10/2, siehe kern/tokens.sh).
#
#  Zu Spielbeginn GESPERRT (Amnesie): Der Virus hat den Befehl
#  mitgenommen. Erst wer ihn wieder erlernt (knows grep), kann ihn
#  benutzen - die Armbanduhr erinnert ihn (Items/Spezial/Armbanduhr.sh).
#
#  Aufruf:  grep <muster>            -> Muster in allen Dateien des Ordners
#           grep <muster> <datei>    -> Muster in dieser Datei
#           grep <gegenstand>        -> Fundort herausziehen (ins Inventar)
#           grep NeksLeiche          -> Leiche ziehen bzw. ablegen
# ============================================================

builtin_grep() {
    if ! knows grep; then
        play_sound error
        OUT+=("»grep« …? Diesen Befehl hat der Virus mir genommen.")
        OUT+=("Ich höre das Wort, aber ich finde die Bedeutung nicht mehr.")
        return
    fi
    if [ -z "$1" ]; then
        play_sound error
        OUT+=("grep: Wonach soll ich suchen?")
        OUT+=("Verwendung: grep <muster> [datei]")
        return
    fi

    local all="$1" np
    np="$(resolve_path "$all" "$CWD")"
    zone_denied grep "$all" "$np" && return
    district_ensure "$np"

    # --- Der Amboss in Brunos Schmiede ist fest eingebaut ----------------
    # Er sieht aus wie ein Fundort, gehört aber dem Schmied. »grep« darf
    # ihn weder herausziehen noch als Textdatei durchsuchen.
    case "$np" in
        */Schmiede/Amboss)
            play_sound error
            OUT+=("Der Amboss gehört nicht mir, den kann ich nicht mit nehmen")
            return ;;
    esac

    # --- Fundort in Anzeige-Schreibweise: »3x Bits« ----------------------
    # Im Ordnerfenster steht vor jedem Fundort seine Menge (»3x Bits«).
    # Wer genau diese Schreibweise eingibt, soll den Gegenstand ebenfalls
    # herausziehen können. Nur Menge + Name eines echten Fundorts zählen;
    # sonst bleibt die Eingabe eine gewöhnliche grep-Suche.
    local qty item_name item_path
    if [[ "$all" =~ ^([0-9]+)[[:space:]]*[xX][[:space:]]*(.+)$ ]]; then
        qty="${BASH_REMATCH[1]}"
        item_name="${BASH_REMATCH[2]}"
        item_path="$(resolve_path "$item_name" "$CWD")"
        if [ -n "${WORLD_ITEM[$item_path]:-}" ] \
           && [ "${WORLD_N[$item_path]:-1}" = "$qty" ]; then
            district_ensure "$item_path"
            all="$item_name"
            np="$item_path"
        fi
    fi

    # --- Leiche: ziehen oder ablegen -------------------------------------
    # Das muss VOR dem Fundort-Test stehen: Eine Leiche ist kein Item und
    # soll auch nicht als Text durchsucht werden. Das Ziehen/Ablegen selbst
    # steckt in Charakter/NeksLeiche.sh; die doppelten Tokenkosten und EXP
    # berechnet die Eingabe (kern/tokens.sh).
    if declare -F neks_leiche_is_corpse_target >/dev/null 2>&1 \
       && neks_leiche_is_corpse_target "$np"; then
        neks_leiche_grep "$np"
        return
    fi

    # --- Fundort: den Gegenstand herausziehen (ins Inventar) -------------
    # Zuerst die GANZE Eingabe als Pfad prüfen - Fundorte dürfen auch
    # Leerzeichen im Namen tragen.
    if [ -n "${WORLD_ITEM[$np]:-}" ]; then
        local _bn="${np##*/}"
        if [[ "$_bn" == .* ]]; then
            if [ "${SHOW_LS:-0}" != "1" ] || [ "${LS_SHOW_ALL:-0}" != "1" ] || [ "${VIEW_DIR:-}" != "${np%/*}" ]; then
                play_sound error
                OUT+=("grep: ${all}: Datei oder Verzeichnis nicht gefunden")
                return
            fi
        fi
        if [ "${WORLD_MODE[$np]:-grep}" = "use" ]; then
            play_sound error
            OUT+=("grep: ${all}: Das muss ich benutzen – mit »use ${all##*/}«.")
            return
        fi
        play_sound cmd_touch
        world_item_pickup "$np"
        return
    fi

    # --- Sonst: wie das echte grep passende Zeilen zeigen ---------------- #
    # »grep <muster> <datei>« - nur wenn der zweite Teil eine echte Datei ist.
    local pat="$all" e l fp="" head tail
    local -a files=()
    head="${all%% *}"
    [ "$head" = "$all" ] || tail="${all#* }"
    if [ -n "${tail:-}" ]; then
        fp="$(resolve_path "$tail" "$CWD")"
        if [ "${TYPE[$fp]:-}" = "d" ]; then
            play_sound error
            OUT+=("grep: ${tail}: Ist ein Verzeichnis")
            return
        fi
        if [ -n "${TYPE[$fp]:-}" ]; then
            pat="$head"
            files=("$fp")
        fi
    fi
    if [ "${#files[@]}" -eq 0 ]; then
        # Ohne (gültige) Zieldatei: alle Dateien des aktuellen Ordners.
        while IFS= read -r e; do
            [ -n "$e" ] || continue
            [ "${TYPE[$CWD/$e]:-}" = "f" ] && files+=("$CWD/$e")
        done <<< "${CHILDREN[$CWD]}"
    fi

    local hits=0
    for fp in "${files[@]}"; do
        [ -n "${CONTENT[$fp]:-}" ] || continue
        while IFS= read -r l; do
            case "$l" in
                *"$pat"*) OUT+=("${fp##*/}: ${l}"); hits=$((hits + 1)) ;;
            esac
        done <<< "${CONTENT[$fp]}"
    done

    if [ "$hits" -gt 0 ]; then
        play_sound cmd_cat
        OUT+=("── ${hits} Treffer ──")
    else
        play_sound error
        OUT+=("grep: »${pat}«: keine Treffer.")
    fi
}
