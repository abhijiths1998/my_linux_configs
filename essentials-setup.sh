#!/usr/bin/env bash
set -euo pipefail

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃   Arch Linux Desktop Essentials                                 ┃
# ┃   Everything you need after a fresh install                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# ── Colors ───────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*"; }
log_section() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}\n"; }

# ── Globals ──────────────────────────────────
DRY_RUN=false
AUR_HELPER=""
INSTALLED_BROWSER=""

# ── Category skip flags ──────────────────────
SKIP_BROWSER=false
SKIP_COMMUNICATION=false
SKIP_WEBAPPS=false
SKIP_KEYRING=false
SKIP_STORE=false
SKIP_TORRENT=false
SKIP_MEDIA=false
SKIP_OFFICE=false
SKIP_UTILITIES=false
SKIP_FONTS=false
SKIP_FLATPAK=false
SKIP_BACKUP=false
SKIP_DEV=false

print_banner() {
    echo -e "${CYAN}"
    cat << 'BANNER'
    ╔═╗╔═╗╔═╗╔═╗╔╗╔╔╦╗╦╔═╗╦  ╔═╗
    ║╣ ╚═╗╚═╗║╣ ║║║ ║ ║╠═╣║  ╚═╗
    ╚═╝╚═╝╚═╝╚═╝╝╚╝ ╩ ╩╩ ╩╩═╝╚═╝
     Desktop essentials for Arch
BANNER
    echo -e "${NC}"
}

usage() {
    print_banner
    echo -e "${BOLD}Usage:${NC} ./essentials-setup.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${GREEN}--all${NC}                  Install everything (default)"
    echo -e "  ${GREEN}--skip-browser${NC}         Skip browser (Zen/Brave)"
    echo -e "  ${GREEN}--skip-communication${NC}   Skip Discord/Telegram/Signal"
    echo -e "  ${GREEN}--skip-webapps${NC}         Skip web app manager"
    echo -e "  ${GREEN}--skip-keyring${NC}         Skip keyring/secrets setup"
    echo -e "  ${GREEN}--skip-store${NC}           Skip GUI package manager"
    echo -e "  ${GREEN}--skip-torrent${NC}         Skip torrent client"
    echo -e "  ${GREEN}--skip-media${NC}           Skip media players/viewers"
    echo -e "  ${GREEN}--skip-office${NC}          Skip LibreOffice"
    echo -e "  ${GREEN}--skip-utilities${NC}       Skip system utilities"
    echo -e "  ${GREEN}--skip-fonts${NC}           Skip font installation"
    echo -e "  ${GREEN}--skip-flatpak${NC}         Skip Flatpak setup"
    echo -e "  ${GREEN}--skip-backup${NC}          Skip Timeshift/snapshot tools"
    echo -e "  ${GREEN}--skip-dev${NC}             Skip dev tools (neovim, git, etc.)"
    echo -e "  ${GREEN}--dry-run${NC}              Show what would be installed"
    echo -e "  ${GREEN}--help, -h${NC}             Show this help"
    echo ""
    echo -e "${BOLD}Categories:${NC}"
    echo -e "  Browser, Communication, Web Apps, Keyring, GUI Store,"
    echo -e "  Torrent, Media, Office, Utilities, Fonts, Flatpak,"
    echo -e "  Backup/Snapshots, Dev Tools"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

detect_aur_helper() {
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        log_warn "No AUR helper found. Installing yay..."
        install_yay
    fi
    log_success "AUR helper: $AUR_HELPER"
}

install_yay() {
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install yay"
        AUR_HELPER="yay"
        return
    fi
    sudo pacman -S --needed --noconfirm git base-devel
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    cd "$tmpdir/yay-bin"
    makepkg -si --noconfirm
    cd - >/dev/null
    rm -rf "$tmpdir"
    AUR_HELPER="yay"
    log_success "yay installed"
}

pkg_install() {
    local desc="$1"
    shift
    local pkgs=("$@")

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would install ($desc): ${pkgs[*]}"
        return 0
    fi

    log_info "Installing: $desc"
    $AUR_HELPER -S --needed --noconfirm "${pkgs[@]}" 2>&1 | tail -3 || true
}

# Check if a package is available in repos/AUR
pkg_available() {
    $AUR_HELPER -Si "$1" &>/dev/null 2>&1
}

# Check if a package is already installed
pkg_installed() {
    pacman -Qi "$1" &>/dev/null 2>&1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Component Installers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_browser() {
    log_section "Browser"

    if [[ "$SKIP_BROWSER" == true ]]; then
        log_warn "Skipping browser"
        return
    fi

    # Priority: Zen Browser > Brave > Firefox (fallback)
    if pkg_installed zen-browser-bin 2>/dev/null || pkg_installed zen-browser 2>/dev/null; then
        log_success "Zen Browser already installed"
        INSTALLED_BROWSER="zen"
    elif pkg_available zen-browser-bin 2>/dev/null; then
        pkg_install "Zen Browser" zen-browser-bin
        INSTALLED_BROWSER="zen"
    elif pkg_available zen-browser 2>/dev/null; then
        pkg_install "Zen Browser" zen-browser
        INSTALLED_BROWSER="zen"
    else
        log_warn "Zen Browser not available, falling back to Brave"
        if pkg_available brave-bin 2>/dev/null; then
            pkg_install "Brave Browser" brave-bin
            INSTALLED_BROWSER="brave"
        else
            log_warn "Brave not available either, installing Firefox"
            pkg_install "Firefox" firefox
            INSTALLED_BROWSER="firefox"
        fi
    fi

    log_success "Browser: $INSTALLED_BROWSER"
}

install_communication() {
    log_section "Communication"

    if [[ "$SKIP_COMMUNICATION" == true ]]; then
        log_warn "Skipping communication apps"
        return
    fi

    # Discord
    pkg_install "Discord" discord

    # Telegram
    pkg_install "Telegram" telegram-desktop

    # Signal (privacy-focused messaging)
    pkg_install "Signal" signal-desktop

    # Thunderbird (email)
    pkg_install "Thunderbird (email)" thunderbird

    log_success "Communication apps installed"
}

install_webapps() {
    log_section "Web App Manager"

    if [[ "$SKIP_WEBAPPS" == true ]]; then
        log_warn "Skipping web app manager"
        return
    fi

    # linux-webapp-manager — fork of Mint's webapp-manager, works on Arch
    # Creates .desktop entries for web apps that run in their own browser window
    if pkg_available webapp-manager 2>/dev/null; then
        pkg_install "Web App Manager (Mint fork)" webapp-manager
        log_success "webapp-manager installed"
    elif pkg_available linux-webapp-manager 2>/dev/null; then
        pkg_install "Linux Web App Manager" linux-webapp-manager
        log_success "linux-webapp-manager installed"
    else
        log_warn "webapp-manager not found in repos, trying Flatpak later..."
        # Will be installed as Flatpak if flatpak is enabled
        if [[ "$SKIP_FLATPAK" == false ]]; then
            WEBAPP_FLATPAK_FALLBACK=true
        else
            log_warn "No web app manager available — install manually from AUR"
        fi
    fi
}

install_keyring() {
    log_section "Keyring & Secrets Management"

    if [[ "$SKIP_KEYRING" == true ]]; then
        log_warn "Skipping keyring setup"
        return
    fi

    pkg_install "GNOME Keyring + Seahorse" \
        gnome-keyring \
        seahorse \
        libsecret \
        libgnome-keyring

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would configure PAM for gnome-keyring auto-unlock"
        return
    fi

    # ── PAM auto-unlock on login ─────────────
    local pam_login="/etc/pam.d/login"
    if ! grep -q "pam_gnome_keyring" "$pam_login" 2>/dev/null; then
        log_info "Configuring PAM for keyring auto-unlock..."
        # Add after auth
        if ! grep -q "pam_gnome_keyring.so" "$pam_login"; then
            echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a "$pam_login" >/dev/null
            echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a "$pam_login" >/dev/null
        fi
    fi

    # For GDM/SDDM/greetd
    for greeter_pam in /etc/pam.d/greetd /etc/pam.d/sddm /etc/pam.d/gdm-password; do
        if [[ -f "$greeter_pam" ]]; then
            if ! grep -q "pam_gnome_keyring.so" "$greeter_pam" 2>/dev/null; then
                echo "auth       optional     pam_gnome_keyring.so" | sudo tee -a "$greeter_pam" >/dev/null
                echo "session    optional     pam_gnome_keyring.so auto_start" | sudo tee -a "$greeter_pam" >/dev/null
                log_success "Keyring PAM configured for $(basename "$greeter_pam")"
            fi
        fi
    done

    # ── Environment variable for keyring daemon ──
    local keyring_env="$HOME/.config/environment.d/keyring.conf"
    mkdir -p "$(dirname "$keyring_env")"
    if [[ ! -f "$keyring_env" ]]; then
        cat > "$keyring_env" << 'EOF'
SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh
EOF
        log_success "Keyring SSH agent env configured"
    fi

    log_success "Keyring and secrets management configured"
}

install_store() {
    log_section "GUI Package Manager"

    if [[ "$SKIP_STORE" == true ]]; then
        log_warn "Skipping GUI store"
        return
    fi

    # pamac — Manjaro's GUI store, works great on Arch, supports AUR + Flatpak
    if pkg_available pamac-aur 2>/dev/null; then
        pkg_install "Pamac (GUI package manager)" pamac-aur
    elif pkg_available pamac-all 2>/dev/null; then
        pkg_install "Pamac (GUI package manager)" pamac-all
    else
        # Fallback to bauh — supports pacman, AUR, Flatpak, Snap, AppImage
        log_warn "pamac not available, trying bauh..."
        if pkg_available bauh 2>/dev/null; then
            pkg_install "bauh (universal GUI store)" bauh
        else
            log_warn "No GUI store available in current repos"
            log_warn "You may need to add chaotic-aur for pamac"
        fi
    fi

    if [[ "$DRY_RUN" == false ]]; then
        # Enable pamac AUR support if installed
        local pamac_conf="/etc/pamac.conf"
        if [[ -f "$pamac_conf" ]]; then
            if grep -q "^#EnableAUR" "$pamac_conf"; then
                sudo sed -i 's/^#EnableAUR/EnableAUR/' "$pamac_conf"
                log_success "Pamac AUR support enabled"
            fi
            if grep -q "^#CheckAURUpdates" "$pamac_conf"; then
                sudo sed -i 's/^#CheckAURUpdates/CheckAURUpdates/' "$pamac_conf"
                log_success "Pamac AUR update checks enabled"
            fi
        fi
    fi

    log_success "GUI package manager installed"
}

install_torrent() {
    log_section "Torrent Client"

    if [[ "$SKIP_TORRENT" == true ]]; then
        log_warn "Skipping torrent client"
        return
    fi

    pkg_install "qBittorrent" qbittorrent

    log_success "qBittorrent installed"
}

install_media() {
    log_section "Media Players & Viewers"

    if [[ "$SKIP_MEDIA" == true ]]; then
        log_warn "Skipping media apps"
        return
    fi

    # Video player
    pkg_install "MPV (video player)" mpv

    # Music player
    pkg_install "Spotify" spotify-launcher

    # Image viewer
    pkg_install "Loupe (image viewer)" loupe

    # PDF viewer
    pkg_install "Zathura (PDF viewer)" \
        zathura \
        zathura-pdf-mupdf

    # Screen recorder (complements OBS for quick clips)
    if pkg_available kooha 2>/dev/null; then
        pkg_install "Kooha (screen recorder)" kooha
    fi

    # Media info / metadata
    pkg_install "MediaInfo" mediainfo

    # ── Screenshot tools ─────────────────────
    pkg_install "Screenshot tools" \
        grim \
        slurp \
        swappy

    # grimblast (grim wrapper with better UX)
    if pkg_available grimblast-git 2>/dev/null; then
        pkg_install "Grimblast" grimblast-git
    fi

    # Flameshot (full GUI screenshot editor, Wayland support)
    pkg_install "Flameshot (screenshot editor)" flameshot

    log_success "Media apps installed"
}

install_office() {
    log_section "Office Suite"

    if [[ "$SKIP_OFFICE" == true ]]; then
        log_warn "Skipping office suite"
        return
    fi

    pkg_install "LibreOffice (fresh)" libreoffice-fresh

    # Spelling
    pkg_install "Spell check (English)" hunspell-en_us

    log_success "LibreOffice installed"
}

install_utilities() {
    log_section "System Utilities"

    if [[ "$SKIP_UTILITIES" == true ]]; then
        log_warn "Skipping utilities"
        return
    fi

    # ── File management ──────────────────────
    pkg_install "File management" \
        thunar \
        thunar-volman \
        thunar-archive-plugin \
        tumbler \
        gvfs \
        gvfs-mtp \
        gvfs-gphoto2

    # Archive manager
    pkg_install "Archive tools" \
        file-roller \
        p7zip \
        unrar \
        unzip \
        zip

    # ── Disk & USB ───────────────────────────
    pkg_install "Disk utility" gnome-disk-utility

    # Ventoy for bootable USBs
    if pkg_available ventoy-bin 2>/dev/null; then
        pkg_install "Ventoy (bootable USB)" ventoy-bin
    fi

    # ── System monitoring ────────────────────
    pkg_install "System monitor" \
        btop \
        fastfetch

    # ── Calculator ───────────────────────────
    pkg_install "Calculator" gnome-calculator

    # ── Clipboard manager (if not via cliphist already) ──
    # cliphist is already in hyprland setup, skip if present
    if ! pkg_installed cliphist 2>/dev/null; then
        pkg_install "Clipboard history" cliphist
    fi

    # ── Password manager ─────────────────────
    pkg_install "KeePassXC (password manager)" keepassxc

    # ── Bluetooth ────────────────────────────
    pkg_install "Bluetooth" \
        bluez \
        bluez-utils \
        blueman

    if [[ "$DRY_RUN" == false ]]; then
        sudo systemctl enable --now bluetooth.service 2>/dev/null || true
        log_success "Bluetooth service enabled"
    fi

    # ── Network ──────────────────────────────
    pkg_install "Network tools" \
        networkmanager \
        network-manager-applet \
        nm-connection-editor

    if [[ "$DRY_RUN" == false ]]; then
        sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
    fi

    # ── Power management ─────────────────────
    pkg_install "Power management" \
        power-profiles-daemon

    if [[ "$DRY_RUN" == false ]]; then
        sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
    fi

    # ── Appearance ───────────────────────────
    pkg_install "Appearance tools" \
        nwg-look \
        qt5ct \
        qt6ct

    # ── XDG / MIME ───────────────────────────
    pkg_install "XDG utilities" \
        xdg-utils \
        xdg-user-dirs

    if [[ "$DRY_RUN" == false ]]; then
        xdg-user-dirs-update 2>/dev/null || true
    fi

    log_success "System utilities installed"
}

install_fonts() {
    log_section "Fonts"

    if [[ "$SKIP_FONTS" == true ]]; then
        log_warn "Skipping fonts"
        return
    fi

    pkg_install "Nerd Fonts & system fonts" \
        ttf-jetbrains-mono-nerd \
        ttf-firacode-nerd \
        noto-fonts \
        noto-fonts-cjk \
        noto-fonts-emoji \
        ttf-liberation \
        ttf-dejavu \
        ttf-roboto \
        ttf-cascadia-code-nerd \
        otf-font-awesome

    if [[ "$DRY_RUN" == false ]]; then
        fc-cache -fv >/dev/null 2>&1
        log_success "Font cache updated"
    fi

    log_success "Fonts installed"
}

install_flatpak() {
    log_section "Flatpak"

    if [[ "$SKIP_FLATPAK" == true ]]; then
        log_warn "Skipping Flatpak"
        return
    fi

    pkg_install "Flatpak" flatpak

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would add Flathub remote"
        return
    fi

    # Add Flathub
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    log_success "Flathub repository added"

    # Web app manager fallback via Flatpak
    if [[ "${WEBAPP_FLATPAK_FALLBACK:-false}" == true ]]; then
        log_info "Installing Tangram (web app manager) via Flatpak..."
        flatpak install -y flathub re.sonny.Tangram 2>/dev/null || true
        log_success "Tangram web app manager installed via Flatpak"
    fi

    log_success "Flatpak configured"
}

install_backup() {
    log_section "Backup & Snapshots"

    if [[ "$SKIP_BACKUP" == true ]]; then
        log_warn "Skipping backup tools"
        return
    fi

    # Timeshift for system snapshots
    if pkg_available timeshift 2>/dev/null; then
        pkg_install "Timeshift (system snapshots)" timeshift
    fi

    # Also install rsync for Timeshift rsync mode
    pkg_install "rsync" rsync

    if [[ "$DRY_RUN" == false ]]; then
        # Enable cronie for scheduled snapshots
        if pkg_installed cronie 2>/dev/null || true; then
            pkg_install "cronie (cron daemon)" cronie
            sudo systemctl enable --now cronie.service 2>/dev/null || true
        fi
    fi

    log_success "Backup tools installed"
    log_info "Open Timeshift to configure automatic snapshots"
}

install_dev_tools() {
    log_section "Developer Tools"

    if [[ "$SKIP_DEV" == true ]]; then
        log_warn "Skipping dev tools"
        return
    fi

    # Neovim
    pkg_install "Neovim" neovim

    # Git (usually present, but ensure extras)
    pkg_install "Git tools" \
        git \
        git-lfs \
        lazygit

    # Build essentials
    pkg_install "Build tools" \
        base-devel \
        cmake \
        ninja \
        gcc

    # Python
    pkg_install "Python" \
        python \
        python-pip \
        python-virtualenv

    # Node.js (via nvm is better, but system package as baseline)
    pkg_install "Node.js" nodejs npm

    # Docker
    pkg_install "Docker" docker docker-compose

    if [[ "$DRY_RUN" == false ]]; then
        sudo systemctl enable docker.service 2>/dev/null || true
        sudo usermod -aG docker "$USER" 2>/dev/null || true
        log_success "Docker enabled (re-login for group change)"
    fi

    # VS Code
    if pkg_available visual-studio-code-bin 2>/dev/null; then
        pkg_install "VS Code" visual-studio-code-bin
    elif pkg_available code 2>/dev/null; then
        pkg_install "Code OSS" code
    fi

    log_success "Dev tools installed"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Parse Arguments
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WEBAPP_FLATPAK_FALLBACK=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-browser)       SKIP_BROWSER=true; shift ;;
        --skip-communication) SKIP_COMMUNICATION=true; shift ;;
        --skip-webapps)       SKIP_WEBAPPS=true; shift ;;
        --skip-keyring)       SKIP_KEYRING=true; shift ;;
        --skip-store)         SKIP_STORE=true; shift ;;
        --skip-torrent)       SKIP_TORRENT=true; shift ;;
        --skip-media)         SKIP_MEDIA=true; shift ;;
        --skip-office)        SKIP_OFFICE=true; shift ;;
        --skip-utilities)     SKIP_UTILITIES=true; shift ;;
        --skip-fonts)         SKIP_FONTS=true; shift ;;
        --skip-flatpak)       SKIP_FLATPAK=true; shift ;;
        --skip-backup)        SKIP_BACKUP=true; shift ;;
        --skip-dev)           SKIP_DEV=true; shift ;;
        --dry-run)            DRY_RUN=true; shift ;;
        --all)                shift ;;
        --help|-h)            usage; exit 0 ;;
        *)                    log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_banner

echo -e "${BOLD}Desktop Essentials Installer${NC}"
echo ""
echo -e "  Browser:         ${CYAN}$([ "$SKIP_BROWSER" == true ] && echo "skip" || echo "Zen > Brave > Firefox")${NC}"
echo -e "  Communication:   ${CYAN}$([ "$SKIP_COMMUNICATION" == true ] && echo "skip" || echo "Discord, Telegram, Signal, Thunderbird")${NC}"
echo -e "  Web Apps:        ${CYAN}$([ "$SKIP_WEBAPPS" == true ] && echo "skip" || echo "webapp-manager / Tangram")${NC}"
echo -e "  Keyring:         ${CYAN}$([ "$SKIP_KEYRING" == true ] && echo "skip" || echo "gnome-keyring + PAM auto-unlock")${NC}"
echo -e "  GUI Store:       ${CYAN}$([ "$SKIP_STORE" == true ] && echo "skip" || echo "Pamac / bauh")${NC}"
echo -e "  Torrent:         ${CYAN}$([ "$SKIP_TORRENT" == true ] && echo "skip" || echo "qBittorrent")${NC}"
echo -e "  Media:           ${CYAN}$([ "$SKIP_MEDIA" == true ] && echo "skip" || echo "MPV, Spotify, Zathura, Loupe")${NC}"
echo -e "  Office:          ${CYAN}$([ "$SKIP_OFFICE" == true ] && echo "skip" || echo "LibreOffice")${NC}"
echo -e "  Utilities:       ${CYAN}$([ "$SKIP_UTILITIES" == true ] && echo "skip" || echo "Thunar, btop, KeePassXC, Bluetooth, ...")${NC}"
echo -e "  Fonts:           ${CYAN}$([ "$SKIP_FONTS" == true ] && echo "skip" || echo "Nerd Fonts, Noto, system fonts")${NC}"
echo -e "  Flatpak:         ${CYAN}$([ "$SKIP_FLATPAK" == true ] && echo "skip" || echo "Flatpak + Flathub")${NC}"
echo -e "  Backup:          ${CYAN}$([ "$SKIP_BACKUP" == true ] && echo "skip" || echo "Timeshift")${NC}"
echo -e "  Dev Tools:       ${CYAN}$([ "$SKIP_DEV" == true ] && echo "skip" || echo "Neovim, Docker, VS Code, Python, Node")${NC}"
echo -e "  Dry run:         ${CYAN}$DRY_RUN${NC}"
echo ""

if [[ "$DRY_RUN" == false ]]; then
    read -rp "Proceed with installation? [Y/n] " confirm
    if [[ "${confirm,,}" == "n" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""

# Preflight
if [[ $EUID -eq 0 ]]; then
    log_error "Do not run as root. The script uses sudo where needed."
    exit 1
fi

detect_aur_helper

# Run all installers
install_browser
install_communication
install_webapps
install_keyring
install_store
install_torrent
install_media
install_office
install_utilities
install_fonts
install_flatpak
install_backup
install_dev_tools

# ── Summary ──────────────────────────────────
log_section "Setup Complete"

echo -e "${GREEN}${BOLD}Desktop essentials installed!${NC}"
echo ""
echo -e "${BOLD}What's ready:${NC}"
[[ "$SKIP_BROWSER" == false ]] && \
    echo -e "  ${GREEN}*${NC} Browser: $INSTALLED_BROWSER"
[[ "$SKIP_COMMUNICATION" == false ]] && \
    echo -e "  ${GREEN}*${NC} Discord, Telegram, Signal, Thunderbird"
[[ "$SKIP_WEBAPPS" == false ]] && \
    echo -e "  ${GREEN}*${NC} Web app manager"
[[ "$SKIP_KEYRING" == false ]] && \
    echo -e "  ${GREEN}*${NC} GNOME Keyring with auto-unlock"
[[ "$SKIP_STORE" == false ]] && \
    echo -e "  ${GREEN}*${NC} GUI package manager"
[[ "$SKIP_TORRENT" == false ]] && \
    echo -e "  ${GREEN}*${NC} qBittorrent"
[[ "$SKIP_MEDIA" == false ]] && \
    echo -e "  ${GREEN}*${NC} MPV, Spotify, Zathura, Loupe"
[[ "$SKIP_OFFICE" == false ]] && \
    echo -e "  ${GREEN}*${NC} LibreOffice"
[[ "$SKIP_UTILITIES" == false ]] && \
    echo -e "  ${GREEN}*${NC} Thunar, btop, KeePassXC, Bluetooth, nwg-look, ..."
[[ "$SKIP_FONTS" == false ]] && \
    echo -e "  ${GREEN}*${NC} Nerd Fonts, Noto (CJK + emoji), system fonts"
[[ "$SKIP_FLATPAK" == false ]] && \
    echo -e "  ${GREEN}*${NC} Flatpak + Flathub"
[[ "$SKIP_BACKUP" == false ]] && \
    echo -e "  ${GREEN}*${NC} Timeshift (configure snapshots in GUI)"
[[ "$SKIP_DEV" == false ]] && \
    echo -e "  ${GREEN}*${NC} Neovim, Git, Docker, VS Code, Python, Node.js"
echo ""
echo -e "${BOLD}Recommended next steps:${NC}"
echo -e "  ${CYAN}1.${NC} Open Timeshift and set up automatic snapshots"
echo -e "  ${CYAN}2.${NC} Open Pamac and enable AUR/Flatpak if not auto-configured"
echo -e "  ${CYAN}3.${NC} Run ${CYAN}nwg-look${NC} to configure GTK appearance"
echo -e "  ${CYAN}4.${NC} Run ${CYAN}qt5ct${NC} / ${CYAN}qt6ct${NC} to configure Qt appearance"
echo -e "  ${CYAN}5.${NC} Log out and back in for keyring + Docker group changes"
