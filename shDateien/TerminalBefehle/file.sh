# ============================================================
#  TerminalHero - Terminal-Befehl: file
#
#  Wird bei Bedarf vom .sh-Manager (kern/loader.sh) geladen.
#  »file«: Metadaten (Typ, Größe, Rechte, MIME) + spielpassende
#  Zusatzinfos. Deterministische Pseudo-Werte, für JEDE Datei im FS.
# ============================================================

file_hash() {   # stabile Zahl aus einem Text (0 … 99999999)
    local s="$1" i h=0 o
    for ((i = 0; i < ${#s}; i++)); do
        printf -v o '%d' "'${s:i:1}" 2>/dev/null || o=0
        h=$(( (h * 33 + o) % 100000007 ))
    done
    printf '%d' "$h"
}
file_size_human() {   # Bytes -> "1,2 MB" (deutsches Komma)
    local b="$1"
    if [ "$b" -lt 1024 ]; then
        printf '%s B' "$b"
    elif [ "$b" -lt 1048576 ]; then
        printf '%d,%d KB' "$((b / 1024))" "$(( (b % 1024) * 10 / 1024 ))"
    else
        printf '%d,%d MB' "$((b / 1048576))" "$(( (b % 1048576) * 10 / 1048576 ))"
    fi
}
file_size_bytes() {   # $1 = Pfad, $2 = d|f
    local h; h="$(file_hash "$1")"
    if [ "$2" = "d" ]; then printf '4096'; return; fi
    case "${1,,}" in
        *.tar.gz|*.tgz)          printf '%s' "$(( 2 + (h % 9) ))000000" ;;
        *.gz)                    printf '%s' "$(( 1 + (h % 6) ))000000" ;;
        *.zip|*.deb)             printf '%s' "$(( 1 + (h % 5) ))000000" ;;
        *.jpg|*.jpeg|*.png|*.mp3|*.mp4) printf '%s' "$(( 200 + (h % 800) ))000" ;;
        *.pdf)                   printf '%s' "$(( 80 + (h % 400) ))000" ;;
        *)                       printf '%d' "$(( 40 + (h % 900) ))" ;;
    esac
}
file_mime() {   # $1 = Dateiname
    case "${1,,}" in
        readme*|license*|changelog*|.*) printf 'text/plain' ;;
        *.tar.gz|*.tgz|*.gz) printf 'application/gzip' ;;
        *.zip)               printf 'application/zip' ;;
        *.txt|*.log|*.conf|*.cfg) printf 'text/plain' ;;
        *.md)                printf 'text/markdown' ;;
        *.c)                 printf 'text/x-c' ;;
        *.html)              printf 'text/html' ;;
        *.pdf)               printf 'application/pdf' ;;
        *.jpg|*.jpeg)        printf 'image/jpeg' ;;
        *.png)               printf 'image/png' ;;
        *.mp3)               printf 'audio/mpeg' ;;
        *.mp4)               printf 'video/mp4' ;;
        *.deb)               printf 'application/vnd.debian.binary-package' ;;
        *)                   printf 'application/octet-stream' ;;
    esac
}
file_kind() {   # $1 = Dateiname, $2 = d|f  (entspricht grob "file" auf der echten Shell)
    if [ "$2" = "d" ]; then printf 'Verzeichnis'; return; fi
    case "${1,,}" in
        readme*|license*|changelog*) printf 'ASCII-Text (Dokument)' ;;
        .*|*.conf|*.cfg)         printf 'ASCII-Text (Konfiguration)' ;;
        *.tar.gz|*.tgz)          printf 'gzip-komprimierte Daten (tar-Archiv)' ;;
        *.gz)                    printf 'gzip-komprimierte Daten' ;;
        *.zip)                   printf 'Zip-Archiv' ;;
        *.pdf)                   printf 'PDF-Dokument' ;;
        *.jpg|*.jpeg)            printf 'JPEG-Bilddaten' ;;
        *.png)                   printf 'PNG-Bilddaten' ;;
        *.mp3)                   printf 'MPEG-Audio' ;;
        *.mp4)                   printf 'MPEG-4-Video' ;;
        *.deb)                   printf 'Debian-Binärpaket' ;;
        *.log)                   printf 'ASCII-Text (Protokoll)' ;;
        *.txt|*.md|*.c|*.html)   printf 'ASCII-Text' ;;
        *)                       printf 'Daten' ;;
    esac
}
file_perms() {   # $1 = Pfad, $2 = d|f
    if [ "$2" = "d" ]; then printf '%s' 'drwxr-xr-x'; return; fi
    printf '%s' '-rw-r--r--'
}
file_owner() {   # $1 = Pfad -> benutzer:gruppe
    case "$1" in
        "$HOME_DIR"|"$HOME_DIR"/*) printf '%s:%s' "$USERNAME_" "$USERNAME_" ;;
        *)                         printf 'root:root' ;;
    esac
}
file_mtime() {   # $1 = Pfad -> "2026-10-TT HH:MM"
    local h; h="$(file_hash "$1")"
    printf '2026-10-%02d %02d:%02d' \
        "$(( 1 + (h % 15) ))" "$(( (h / 7) % 24 ))" "$(( (h / 13) % 60 ))"
}
builtin_file() {
    if ! knows file; then
        play_sound error
        OUT+=("»file« …? Diesen Befehl kenne ich nicht mehr.")
        OUT+=("Der Virus hat ihn mir genommen – wie so vieles. Noch.")
        return
    fi
    if [ -z "$1" ]; then
        play_sound error
        OUT+=("file: fehlender Dateiname")
        OUT+=("Verwendung: file <datei|ordner>")
        return
    fi
    local arg="$1" np
    np="$(resolve_path "$arg" "$CWD")"
    zone_denied file "$arg" "$np" && return
    if [ -z "${TYPE[$np]}" ]; then
        play_sound error
        OUT+=("file: $arg: Datei oder Verzeichnis nicht gefunden")
        return
    fi

    local isdir="${TYPE[$np]}" name size mime
    name="${np##*/}"; [ -z "$name" ] && name="/"

    play_sound cmd_cat
    OUT+=("═════ file: ${name} ═════")
    OUT+=("  Pfad      : $(short_path "$np")")
    OUT+=("  Typ       : $(file_kind "$name" "$isdir")")
    if [ "$isdir" = "d" ]; then
        size="4096"
    else
        mime="$(file_mime "$name")"
        size="$(file_size_human "$(file_size_bytes "$np" "$isdir")")"
        OUT+=("  MIME      : ${mime}")
    fi
    OUT+=("  Größe     : ${size}")
    OUT+=("  Rechte    : $(file_perms "$np" "$isdir")")
    OUT+=("  Besitzer  : $(file_owner "$np")")
    OUT+=("  Geändert  : $(file_mtime "$np")")

    if [ "$isdir" = "d" ]; then
        local -a _kids=() _e; local _join=""
        while IFS= read -r _e; do [ -n "$_e" ] && _kids+=("$_e"); done <<< "${CHILDREN[$np]}"
        local kn="${#_kids[@]}"
        for _e in "${_kids[@]}"; do _join+="$_e "; done
        OUT+=("  Inhalt    : ${kn} Eintrag/Einträge")
        [ "$kn" -ge 1 ] && [ "$kn" -le 6 ] && OUT+=("              ${_join% }")
    fi
    OUT+=("────────────────────────────────")

    # --- Spielspezifische Zusatzinformationen -------------------
    # Fundort (Welt-Gegenstand): kein gewöhnlicher Text - und wie er zu
    # haben ist.
    if [ -n "${WORLD_ITEM[$np]:-}" ]; then
        OUT+=("Ein Gegenstand, kein gewöhnlicher Text. Er liegt hier in der Welt.")
        OUT+=("Wer ihn haben will, zieht ihn mit »grep ${name}« heraus.")
    fi
    # Einrichtung (Interior): kein gewöhnlicher Text – ein benutzbares Objekt.
    local _iid="${INTERIOR_AT[$np]:-}" _itxt _l
    if [ -n "$_iid" ]; then
        _itxt="$(interior_file_text_of "$_iid")"
        if [ -n "$_itxt" ]; then
            while IFS= read -r _l; do OUT+=("$_l"); done <<< "$_itxt"
        else
            OUT+=("Ein Stück Einrichtung – kein gewöhnlicher Text.")
            OUT+=("Benutzen lässt es sich mit »use ${name}«.")
        fi
    fi
    # Gegner: Kategorie, Angriff und der passende Kampfbefehl.
    if [ -n "${GEGNER_AT[$np]:-}" ]; then
        local _gt="${GEGNER_AT[$np]}" _gcat _glabel _gdps _gwait
        _gcat="$(gegner_type_cat "$_gt")"
        _glabel="$(gegner_type_label "$_gt")"
        _gdps="$(gegner_type_dps "$_gt")"
        _gwait="$(gegner_type_wait "$_gt")"
        OUT+=("[GEGNER]  ${_glabel} – Kategorie ${_gcat}")
        OUT+=("Angriff : ${_gdps} Tokens/s nach ${_gwait}s im selben Ordner")
        if declare -F equip_combat_ready >/dev/null 2>&1 && equip_combat_ready; then
            OUT+=("Löschen : rm ${name}  (mit der ausgerüsteten Waffe)")
        else
            OUT+=("Löschen : rm ${name} – dafür braucht der Agent eine Waffe.")
        fi
    fi
    case "$np" in
        "$HOME_DIR/Schreibtisch/Höhleneingang/GuySus")
            OUT+=("»Guy Sus« – ein Informant mit nervösen Fingern.")
            OUT+=("Er kennt die Molerats, die Leiche und das glänzende Objekt.")
            if declare -F knows >/dev/null 2>&1 && knows search; then
                OUT+=("Er kann nicht mehr lehren, was du längst weißt.")
            else
                OUT+=("Er kann dir »Plündern« beibringen (2 Skillpunkte, 25 Bits).")
            fi ;;
        */NeksLeiche)
            OUT+=("»Neks Leiche«. Keine gewöhnliche Datei: Nek Molerat, Stadtwache.")
            OUT+=("Simon Guard und Simple Jon suchen ihn – seine Leiche ist ein Beweisstück.")
            if [ "${DRAGGED_CORPSE:-}" = "$np" ]; then
                OUT+=("Du ziehst sie gerade hinter dir her.")
            fi
            if declare -F knows >/dev/null 2>&1 && knows search; then
                OUT+=("Durchsuchen lässt er sich mit »search NeksLeiche«.")
            else
                OUT+=("Wer ihn durchsuchen könnte, müsste erst wieder wissen, wie.")
            fi ;;
        "$HOME_DIR/Downloads/${AGENT_NAME}.tar.gz")
            OUT+=("Dies ist das gz-Archiv, aus dem der Ordner »${AGENT_NAME}« entpackt wurde.")
            OUT+=("Angefordert über ein Downloadportal – von »${USERNAME_}«.")
            OUT+=("Wer es hochgeladen hat, steht nicht mehr in den Metadaten.") ;;
        "$AGENT_DIR")
            OUT+=("Dies ist der entpackte Agenten-Ordner »${AGENT_NAME}«.")
            OUT+=("Hier wurde ich installiert. Mein Zuhause – bis jetzt.")
            OUT+=("Der General wohnt darin: die README.") ;;
        "$AGENT_DIR/README")
            OUT+=("Dies ist die README – das Sprachrohr des Generals.")
            OUT+=("Kein gewöhnlicher Text: Wer sie berührt (touch), beginnt ein Gespräch.")
            OUT+=("Herkunft unbekannt. Zweck: Einsatzbefehl.") ;;
        "$HOME_DIR/Downloads/BarbarConan.tar.gz")
            OUT+=("Das gz-Archiv eines früheren Agenten: »BarbarConan«.")
            OUT+=("Wochen vor dir heruntergeladen. Entpackt. Und nie zurückgekehrt.") ;;
        "$HOME_DIR/Downloads/BarbarConan")
            OUT+=("Der entpackte Ordner von »BarbarConan« – einem Agenten vor deiner Zeit.")
            OUT+=("Er sollte den Virus erschlagen. Der Virus war schneller.")
            OUT+=("Wo Conan jetzt steckt, weiß niemand. Irgendwo im System.") ;;
        "$HOME_DIR/Downloads/BarbarConan/README")
            OUT+=("Die README des Kriegers – ein Stammesführer, roh und laut.")
            OUT+=("Kein General. Eher eine Axt mit Meinung.")
            OUT+=("Wer sie berührt (touch), weckt einen Kriegsrat.") ;;
        "$HOME_DIR/Downloads/DetektivConan.tar.gz")
            OUT+=("Das gz-Archiv eines weiteren früheren Agenten: »DetektivConan«.")
            OUT+=("Nach BarbarConan entsandt. Mit Methode statt Muskel. Auch er kehrte nicht zurück.") ;;
        "$HOME_DIR/Downloads/DetektivConan")
            OUT+=("Der entpackte Ordner von »DetektivConan« – dem Analytiker unter den Agenten.")
            OUT+=("Er sollte den Virus nicht erschlagen, sondern überführen.")
            OUT+=("Zuletzt gesehen: auf einer Spur, die ins Nichts führte. Verdacht: gestellt.") ;;
        "$HOME_DIR/Downloads/DetektivConan/README")
            OUT+=("Die README des Ermittlers – ein Chefermittler, kühl und scharf.")
            OUT+=("Kein General, kein Krieger. Ein Verstand mit Akte.")
            OUT+=("Wer sie berührt (touch), wird verhört.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Pixi"|"$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Pixi"|"$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse/Pixi"|"$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/EingestürzteBaracke/Pixi")
            OUT+=("»Pixi«. Ohne Endung, ohne Format. Kein MIME-Typ.")
            OUT+=("Sie ist keine gewöhnliche Datei – sie ist jemand.")
            OUT+=("Wer sie liest (cat), hört ihre Stimme.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse/Rachel"|"$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse/Jack")
            OUT+=("Die Redaktion »DailyPulse« ist zugleich das Zuhause der Familie Nullpunkt.")
            OUT+=("Rachel führt das Blatt, Jack rechnet die Nächte durch.")
            OUT+=("Wer sie anspricht (touch), wird geprüft bzw. gewarnt.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/DetekteiHolmes/Jack")
            OUT+=("»Jack Nullpunkt« – Amandas neue Unterstützung in der Detektei Holmes.")
            OUT+=("Er hat den Verlag verlassen, um Amanda bei den Akten zu helfen.")
            OUT+=("Wer ihn anspricht (touch), bekommt eine ehrliche Einschätzung.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/TraceyBriggs"|"$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt/DailyPulse/TraceyBriggs")
            OUT+=("»Tracey Briggs« – Rachels Zeitungsausträgerin.")
            OUT+=("Meistens DailyPulse, manchmal Restaurant, immer unterwegs.")
            OUT+=("Wer sie anspricht (touch), bekommt eine aktuelle Ausgabe – und eine Meinung.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/JimmysHaus/JimmyPage")
            OUT+=("»Jimmy Page« – Zeitungssammler im Ostdistrikt.")
            OUT+=("Er verlässt das Haus nicht; die Zeitungen kommen zu ihm.")
            OUT+=("Wer ihn anspricht (touch), wird in seine Sammlung gelassen.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/DetekteiHolmes/Amanda")
            OUT+=("»Amanda Nox« – das Vorzimmer der Detektei Holmes.")
            OUT+=("Keine gewöhnliche Datei: eine Assistentin mit Akten, Terminen und Meinung.")
            OUT+=("Wer sie anspricht (touch), wird höflich befragt – und höflich abgewiesen.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/Sherlock"|"$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Norddistrikt/Sherlock")
            OUT+=("»Sherlock Holmes«. Ohne Endung, ohne Format – nachts im Bezirk.")
            OUT+=("Keine gewöhnliche Datei: ein Detektiv, der Fälle aufmacht, die andere schließen.")
            OUT+=("Wer ihn anspricht (touch), bekommt eine Spur – wenn er stehen bleibt.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/DetekteiHolmes/Sherlock")
            OUT+=("»Sherlock Holmes« – diesmal nicht im Bezirk, sondern im eigenen Büro.")
            OUT+=("Keine gewöhnliche Datei: ein Detektiv, der Fälle aufmacht, die andere schließen.")
            OUT+=("Wer ihn hier anspricht (touch), wird auf später vertröstet.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt/KneipeZumGoldenenLächeln/Börty")
            OUT+=("»Börty Smiles« – der Wirt der Kneipe »Zum Goldenen Lächeln«.")
            OUT+=("Keine gewöhnliche Datei: ein Wirt, der alles hört und manches verkauft.")
            OUT+=("Wer ihn anspricht (touch), bekommt ein Lächeln – und danach eine Rechnung.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Torwächter")
            OUT+=("»Simon Guard« – die Torwache am Haupttor.")
            OUT+=("Posten: Torwächter. Keine gewöhnliche Datei: ein Prozess mit Posten und Meinung.")
            OUT+=("Wer ihn anspricht (touch), bekommt eine kurze Standpauke.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Wachhaus/SimpleJon")
            OUT+=("»Simple Jon« – eine Stadtwache im Wachhaus.")
            OUT+=("Pausenraum, Schlafraum und der trockenste Humor der Wache.")
            OUT+=("Wer ihn anspricht (touch), bekommt eine Pause – und eine Meinung.") ;;
        "$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache1"|"$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache2"|\
        "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache1"|"$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache2")
            OUT+=("[STADTWACHE]  Im Dienst")
            OUT+=("Posten : Stadtgebiet    Rang : Stadtwache")
            OUT+=("────────────────────────────────")
            OUT+=("»Eine Wache ist keine Sehenswürdigkeit.")
            OUT+=(" Weitergehen – hier gibt es nichts zu sehen.«") ;;
    esac
}
