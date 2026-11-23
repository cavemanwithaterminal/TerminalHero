# ============================================================
#  TerminalHero - Virtuelles Dateisystem
#
#  Beschreibt den kompletten Dateibaum des Spiels (Ordner & Dateien),
#  die Kinderlisten (für "ls") und die Dateiinhalte (für "cat").
#  Wird von TerminalShell.sh NACH der Konfiguration geladen, da die
#  Pfade HOME_DIR / AGENT_DIR benötigt werden.
# ============================================================

# ============================================================
#  Dateisystem-Definition
# ============================================================
declare -gA TYPE          # Pfad -> d (Verzeichnis) | f (Datei)
declare -gA CHILDREN      # Pfad -> "kind1\nkind2\n..." (je Name eine Zeile)
declare -gA CONTENT       # Pfad -> Dateiinhalt (optional)
declare -gA DIALOG        # Pfad -> Dialogfunktion (für "touch")
declare -gA FS_BASE_TYPE  # statisches Grundgerüst (Pfad -> d|f)

# addp legt einen STATISCHEN Eintrag an. Nur diese Pfade gehören zum
# Grundgerüst. Alles andere (pixi_add, vom Spieler per »touch« erzeugte
# Dateien) gilt als dynamisch und wird im Spielstand gesichert. So bleiben
# Änderungen am Grundgerüst auch für bereits vorhandene Spielstände sichtbar.
addp() { TYPE["$2"]="$1"; FS_BASE_TYPE["$2"]="$1"; }   # addp <d|f> <pfad>

# Der komplette Baum als Funktion – so lässt er sich nach dem Laden eines
# Spielstands mit der (womöglich anderen) geladenen Identität neu aufbauen.
fs_build_tree() {
    TYPE=()
    FS_BASE_TYPE=()

# --- Wurzel ---
addp d /
for d in bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv sys tmp usr var; do
    addp d "/$d"
done
addp f /etc/hostname
addp f /etc/hosts
addp f /etc/passwd
addp f /etc/fstab
addp f /etc/os-release
addp f /etc/timezone
addp f /etc/locale.conf
addp f /swapfile

# --- /boot ---
addp d /boot/grub
addp f /boot/vmlinuz-linux
addp f /boot/initramfs-linux.img
addp f /boot/grub/grub.cfg

# --- /home ---
addp d $HOME_DIR
for d in Schreibtisch Downloads Dokumente Bilder Musik Videos Vorlagen Öffentlich; do
    addp d "$HOME_DIR/$d"
done
addp d $HOME_DIR/.config
addp d $HOME_DIR/.local
addp d $HOME_DIR/.cache
addp f $HOME_DIR/.bashrc
addp f $HOME_DIR/.profile
addp f $HOME_DIR/.bash_history

# Schreibtisch
# Der Höhleneingang liegt direkt auf dem Schreibtisch – vor der Stadt.
# In ihm führt die Molerathöhle weiter. Beide Ordner gehören zum
# statischen Grundgerüst; ihre künftigen Inhalte stehen in
# Orte/Höhleneingang.sh und Orte/Molerathöhle.sh.
addp d $HOME_DIR/Schreibtisch/Höhleneingang
addp d $HOME_DIR/Schreibtisch/Höhleneingang/Molerathöhle

# Brachland: neuer Außenbereich auf dem Schreibtisch. Es enthält den
# Friedhof (Ort für Neks Beerdigung, Charakter/NeksBeerdigung.sh) und
# die Steppe. In der Steppe liegen der Canyon, das Farmland mit der
# Farm und dem Anwesen der Familie Molerat (Orte/Anwesen.sh,
# Charakter/MoleratFamilie.sh) und das
# Moleratgebiet mit seinen sechs Untergebieten. Im Canyon führt ein
# Höhleneingang durch drei Tunnel bis zur Großen Höhlenkammer; in
# jedem Tunnel lebt ein Molerat. Alle Ordner gehören zum statischen
# Grundgerüst; ihre Ortsdateien liegen unter Orte/. Die Molerats
# selbst setzt Gegner/Molerats.sh dynamisch.
addp d $HOME_DIR/Schreibtisch/Brachland
addp d $HOME_DIR/Schreibtisch/Brachland/Friedhof
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer
# Von der Großen Höhlenkammer zweigen drei Tunnelketten ab. Jede Kette
# führt über drei Tunnel; im zweiten Tunnel liegt eine Nebenkammer, der
# dritte endet in einer eigenen Kammer. Alle Ordner gehören zum
# statischen Grundgerüst; die Ortsbeschreibungen liegen unter Orte/.
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/NebenkammerWest
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/Westtunnel3
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Westtunnel1/Westtunnel2/Westtunnel3/KammerEndeWest
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/NebenkammerOst
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/Osttunnel3
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Osttunnel1/Osttunnel2/Osttunnel3/KammerEndeOst
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/NebenkammerNord
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang
# Vom Großen Höhleneingang führt ein breiter Gang tiefer in den Berg bis
# zur KöniginnenKammer. Beide Ordner gehören zum statischen Grundgerüst;
# die Ortsbeschreibungen liegen unter Orte/.
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang/BreiterTunnel
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Canyon/Höhleneingang/Höhlentunnel1/Höhlentunnel2/Höhlentunnel3/GroßeHöhlenkammer/Nordtunnel1/Nordtunnel2/Nordtunnel3/GroßerHöhleneingang/BreiterTunnel/KöniginnenKammer
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm
# Auf der Farm steht das Anwesen der Familie Molerat. Der Haupteingang
# führt in das Erdgeschoss, wo Gregor, Marlene und Chantal wohnen.
# Alle drei Ordner gehören zum statischen Grundgerüst; die
# Ortsbeschreibungen liegen unter Orte/.
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen/Haupteingang
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Farmland/Farm/Anwesen/Haupteingang/Erdgeschoss
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet1.1
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet1.1/Moleratgebiet1.2
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet2.1
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet2.1/Moleratgebiet2.2
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet3.1
addp d $HOME_DIR/Schreibtisch/Brachland/Steppe/Moleratgebiet/Moleratgebiet3.1/Moleratgebiet3.2

# Im Friedhof arbeitet der Totengräber Francesco Dellamorte. Inhalt und
# Dialog setzt Orte/Friedhof.sh nach load_contents.
addp f $HOME_DIR/Schreibtisch/Brachland/Friedhof/FrancescoDellamorte

# Die Stadt – versteckt im Schreibtisch. Eintritt über den Haupteingang,
# von dort in die fünf Distrikte. Der Haupteingang kennt nur die fünf
# Stadtteil-Ordner selbst; deren Inhalt (Welt, Dateien, Dialoge) steht in
# den jeweiligen Stadtteil-Dateien und wird beim Betreten geladen
# (siehe district.sh).
addp d $HOME_DIR/Schreibtisch/DesktopCity
addp d $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang
addp d $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Norddistrikt
addp d $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Süddistrikt
addp d $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Westdistrikt
addp d $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Ostdistrikt
addp d $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Zentrum
# Wachhaus: Schlaf- und Pausenraum der Stadtwache, direkt im Haupteingang.
# Aufbau/Inhalte stehen in Orte/Wachhaus.sh; der Ordner selbst gehört zum
# statischen Grundgerüst, damit er in jedem Spielstand sichtbar bleibt.
addp d $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Wachhaus
addp f $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Wachhaus/SimpleJon
addp f $HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Torwächter
addp f "$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache1"
addp f "$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache2"
addp f "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache1"
addp f "$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache2"

# Downloads
# (»setup_v2.1.deb« gibt es hier nicht mehr – die Datei hatte keinen Nutzen.)
# Das Archiv, aus dem der Agenten-Ordner entpackt wurde (Name des Spielers/Agenten):
addp f "$HOME_DIR/Downloads/${AGENT_NAME}.tar.gz"

# Agenten-Ordner (hier wurde der Spieler gestartet) + README
addp d "$AGENT_DIR"
addp f "$AGENT_DIR/README"

# Früherer Agent: BarbarConan (Wochen vor dem Spieler heruntergeladen, gescheitert)
addp f "$HOME_DIR/Downloads/BarbarConan.tar.gz"
addp d "$HOME_DIR/Downloads/BarbarConan"
addp f "$HOME_DIR/Downloads/BarbarConan/README"

# Früherer Agent: DetektivConan (kam nach BarbarConan, ebenfalls gescheitert)
addp f "$HOME_DIR/Downloads/DetektivConan.tar.gz"
addp d "$HOME_DIR/Downloads/DetektivConan"
addp f "$HOME_DIR/Downloads/DetektivConan/README"

# Dokumente
addp d $HOME_DIR/Dokumente/Steuer
addp f "$HOME_DIR/Dokumente/Brief.txt"
addp f "$HOME_DIR/Dokumente/rechnung.pdf"
addp f "$HOME_DIR/Dokumente/Steuer/erklärung_2025.pdf"

# Bilder / Musik / Videos / Vorlagen / Öffentlich
addp f "$HOME_DIR/Bilder/hintergrund.png"
addp f "$HOME_DIR/Bilder/familie.jpg"
addp f "$HOME_DIR/Musik/lieblingslied.mp3"
addp f "$HOME_DIR/Videos/clip.mp4"
addp f "$HOME_DIR/Vorlagen/leer.txt"
addp f "$HOME_DIR/Öffentlich/readme.txt"

# --- /etc ---
addp d /etc/ssh
addp d /etc/systemd
addp d /etc/systemd/system
addp d /etc/network
addp d /etc/pacman.d
addp f /etc/ssh/sshd_config
addp f /etc/network/interfaces
addp f /etc/pacman.d/mirrorlist

# --- /var ---
for d in log tmp cache lib spool www; do addp d "/var/$d"; done
addp d /var/log/journal
addp f /var/log/syslog
addp f /var/log/messages
addp f /var/log/auth.log
addp f /var/www/index.html

# --- /usr ---
for d in bin sbin lib local share include src; do addp d "/usr/$d"; done
addp d /usr/share/doc
addp d /usr/share/man
addp d /usr/share/fonts
addp d /usr/share/icons

# --- weitere Systemordner ---
addp d /tmp/.ICE-unix
}

fs_build_tree

# ============================================================
#  Kinderlisten aufbauen
# ============================================================
build_children() {
    local p parent name
    CHILDREN=()          # neu aufbauen (wichtig nach dem Laden eines Spielstands)
    for p in "${!TYPE[@]}"; do
        [ "$p" = "/" ] && continue
        parent="${p%/*}"; [ -z "$parent" ] && parent="/"
        name="${p##*/}"
        # Ein Name je Zeile - so wären auch Namen mit Leerzeichen möglich.
        CHILDREN["$parent"]+="$name"$'\n'
    done
}

# --- Dynamische Einträge (erscheinen/verschwinden zur Laufzeit) -------
#     Figuren und Gegenstände tauchen zur Laufzeit auf oder wechseln ihren
#     Ort (z. B. Pixi zieht um, Sherlock Holmes ist nur nachts im
#     Ostdistrikt). Diese Helfer pflegen TYPE und CHILDREN zusammen. Solche
#     Einträge gehören NICHT zum Grundgerüst (addp) und wandern deshalb in
#     den Spielstand - siehe th_dump_dyn_type (kern/save.sh).
#     Beide sind idempotent und ändern nur, was schon/nicht da ist.
fs_add() {   # fs_add <d|f> <pfad>
    local t="$1" p="$2" parent name
    [ -n "$p" ] || return 1
    [ -n "${TYPE[$p]:-}" ] && return 0
    TYPE["$p"]="$t"
    parent="${p%/*}"; [ -z "$parent" ] && parent="/"
    name="${p##*/}"
    case $'\n'"${CHILDREN[$parent]}" in
        *$'\n'"$name"$'\n'*) ;;
        *) CHILDREN["$parent"]+="$name"$'\n' ;;
    esac
    return 0
}
fs_remove() {   # fs_remove <pfad>
    local p="$1" parent name e new=""
    [ -n "$p" ] || return 1
    [ -z "${TYPE[$p]:-}" ] && return 0
    unset "TYPE[$p]"
    parent="${p%/*}"; [ -z "$parent" ] && parent="/"
    name="${p##*/}"
    while IFS= read -r e; do
        [ -z "$e" ] && continue
        [ "$e" = "$name" ] || new+="$e"$'\n'
    done <<< "${CHILDREN[$parent]}"
    CHILDREN["$parent"]="$new"
    return 0
}

# ============================================================
#  Dateiinhalte (für cat)
# ============================================================
load_contents() {
    CONTENT=(); DIALOG=()   # neu aufbauen (wichtig nach dem Laden eines Spielstands)
    CONTENT["/etc/hostname"]="${HOSTNAME_}"
    CONTENT["/etc/hosts"]="127.0.0.1   localhost\n::1         localhost\n127.0.1.1   ${HOSTNAME_}"
    CONTENT["/etc/os-release"]="NAME=\"Linux\"\nPRETTY_NAME=\"GNU/Linux\"\nID=linux\nVERSION_ID=\"1.0\""
    CONTENT["/etc/fstab"]="# <file system>  <mount point>  <type>  <options>\nUUID=xxxx  /      ext4  defaults  0 1\nUUID=yyyy  /home  ext4  defaults  0 2"
    CONTENT["/etc/passwd"]="root:x:0:0:root:/root:/bin/bash\n${USERNAME_}:x:1000:1000:Benutzer:$HOME_DIR:/bin/bash"
    CONTENT["/etc/timezone"]="Europe/Berlin"
    CONTENT["/etc/locale.conf"]="LANG=de_DE.UTF-8"
    CONTENT["/etc/network/interfaces"]="auto lo\niface lo inet loopback\nauto enp3s0\niface enp3s0 inet dhcp"
    CONTENT["/etc/ssh/sshd_config"]="Port 22\nPermitRootLogin no\nPasswordAuthentication yes"
    CONTENT["/etc/pacman.d/mirrorlist"]="Server = https://mirror.example.org/linux/\$repo/os/\$arch"
    CONTENT["$HOME_DIR/.bashrc"]="# ~/.bashrc\nexport PS1='\\u@\\h:\\w\\$ '\nalias ll='ls -la'"
    CONTENT["$HOME_DIR/.profile"]="# ~/.profile\nexport PATH=\"\$HOME/.local/bin:\$PATH\""
    CONTENT["$HOME_DIR/Öffentlich/readme.txt"]="Dieser Ordner ist für alle sichtbar."

    CONTENT["$AGENT_DIR/README"]="========================================\n  EINSATZBEFEHL  //  README\n========================================\nAgent   : ${AGENT_NAME}\nKlasse  : Anti-Virus-KI-Agent (Kampfklasse: Neugier)\nEinsatz : Rettung des lokalen Dateisystems\nStatus  : frisch installiert, leicht übermüdet\n\nBeschreibung:\n  Ein experimenteller KI-Agent der letzten Generation.\n  Ausgestattet mit Neugier, Sturheit und einem gesunden\n  Misstrauen gegenüber .exe-Dateien.\n  Auftrag: den Virenkern aufspüren und unschädlich machen.\n\nHinweis:\n  Diese Datei ist nicht nur Text. Wer sie berührt\n  (touch README), beginnt ein Gespräch."

    DIALOG["$AGENT_DIR/README"]="dialog_readme"

    CONTENT["$HOME_DIR/Downloads/BarbarConan/README"]="========================================\n  KRIEGSBEFEHL  //  README\n========================================\nKrieger : BarbarConan\nKlinge  : Axt (Software-Axt, grob geschliffen)\nKlasse  : Anti-Viren-KI (Kampfklasse: Zorn)\nEinsatz : Virenkern herausreißen. Roh. Mit Stumpf und Stiel.\nStatus  : entpackt, geladen, wütend. Sehr wütend.\n\nBeschreibung:\n  Ein Agent der alten Schule. Spricht wenig, zerschlägt viel.\n  Hält nichts von höflichen Befehlen. Hält viel von Axt.\n  Auftrag: den Virenkern aufspüren und unschädlich machen.\n  Ergebnis: offen. Sehr offen.\n\nHinweis:\n  Diese Datei ist kein Papier. Wer sie berührt\n  (touch README), weckt einen Kriegsrat."

    DIALOG["$HOME_DIR/Downloads/BarbarConan/README"]="dialog_conan"

    CONTENT["$HOME_DIR/Downloads/DetektivConan/README"]="========================================\n  ERMITTLUNGSAKTE  //  README\n========================================\nErmittler : DetektivConan\nMethode   : Beobachtung, Logik, einwandfreie Schlussfolgerung\nKlasse    : Anti-Viren-KI (Kampfklasse: Verstand)\nAuftrag   : Den Virus lokalisieren, sein Muster entschlüsseln, ausschalten.\nStatus    : entpackt, geladen, wachsam. Sehr wachsam.\n\nKurzbefund:\n  Alle vorherigen Agenten scheiterten – keiner durch Zufall.\n  Der Virus tötet nicht geräuschvoll. Er verschiebt Beweise.\n  Wer ihn findet, muss zuerst seine Lügen entlarven.\n  Diese Akte hält fest, was bisher geschah. Sie wird fortgeschrieben.\n\nVermerk:\n  Diese Datei schweigt nicht, wenn sie angesprochen wird\n  (touch README). Sie stellt Fragen. Sie schließt.\n  Sie liegt selten falsch."

    DIALOG["$HOME_DIR/Downloads/DetektivConan/README"]="dialog_detektiv"

    CONTENT["/var/log/auth.log"]="session opened for user ${USERNAME_}\nsession closed for user ${USERNAME_}"

    # Torwache am Haupttor der Stadt – eine beseelte Datei (touch = Gespräch).
    # Der Posten heißt »Torwächter«, der Mann dahinter Simon Guard.
    CONTENT["$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Torwächter"]="========================================\n  DIENSTANWEISUNG  //  SIMON GUARD\n========================================\nName   : Simon Guard\nPosten : Torwache (Haupttor)\nRang   : Stadtwache, einfacher Dienst\nAuftrag: Einlass kontrollieren. Viren draußen halten.\nStatus : im Dienst. Müde. Wachsam.\n\nNotiz:\n  »Ich bin kein Held und schon gar kein Chef.\n   Ich bin die Tür. Und Türen haben nur eine Aufgabe:\n   Wer sie schief ansieht, kommt nicht durch.«"

    DIALOG["$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Torwächter"]="dialog_simon_guard"

    # Stadtwachen – untereinander identisch: cat UND file zeigen denselben Text.
    local _wache="[STADTWACHE]  Im Dienst\nPosten : Stadtgebiet    Rang : Stadtwache\n────────────────────────────────\n»Eine Wache ist keine Sehenswürdigkeit.\n Weitergehen – hier gibt es nichts zu sehen.«"
    CONTENT["$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache1"]="$_wache"
    CONTENT["$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache2"]="$_wache"
    CONTENT["$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache1"]="$_wache"
    CONTENT["$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache2"]="$_wache"

    # touch: je Wache eine eigene, kurze Wortmeldung.
    DIALOG["$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache1"]="dialog_wache_1"
    DIALOG["$HOME_DIR/Schreibtisch/DesktopCity/Stadtwache2"]="dialog_wache_2"
    DIALOG["$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache1"]="dialog_wache_3"
    DIALOG["$HOME_DIR/Schreibtisch/DesktopCity/Haupteingang/Stadtwache2"]="dialog_wache_4"
}

# ============================================================
#  Pfad-Auflösung
# ============================================================
CWD="$HOME_DIR"
OLDPWD="/"
VIEW_DIR="$HOME_DIR"      # im rechten Ordnerfenster angezeigt (ls)

normalize_path() {
    local target="$1" base="$2" p
    if [[ "$target" == /* ]]; then p="$target"; else p="$base/$target"; fi

    local IFS='/'
    local -a seg stack
    read -ra seg <<< "$p"
    local s
    for s in "${seg[@]}"; do
        case "$s" in
            ''|'.') : ;;
            '..')
                if [ "${#stack[@]}" -gt 0 ]; then
                    unset "stack[$((${#stack[@]} - 1))]"
                fi ;;
            *) stack+=("$s") ;;
        esac
    done
    local res="/"
    for s in "${stack[@]}"; do res+="$s/"; done
    res="${res%/}"
    [ -z "$res" ] && res="/"
    printf '%s' "$res"
}

short_path() {
    local p="$1"
    if [ "$p" = "$HOME_DIR" ]; then printf '~';
    elif [[ "$p" == "$HOME_DIR/"* ]]; then printf '~%s' "${p#"$HOME_DIR"}";
    else printf '%s' "$p"; fi
}
