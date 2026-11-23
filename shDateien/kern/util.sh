# ============================================================
#  TerminalHero - Kleine Helfer
# ============================================================

is_binary_name() {   # 0 = bekannte Binär-Endung
    case "${1,,}" in
        *.tar.gz|*.tgz|*.gz|*.zip|*.jpg|*.jpeg|*.png|*.mp3|*.mp4|*.deb|*.img|*.iso|*.bin|*.pdf) return 0 ;;
        *) return 1 ;;
    esac
}
