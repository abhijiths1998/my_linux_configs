#!/usr/bin/env bash
set -euo pipefail

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃          Hyprland Dotfiles Installer                    ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# ── Colors ───────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Available themes ─────────────────────────
THEMES=(everforest catppuccin gruvbox nord tokyonight dracula rosepine solarized kanagawa onedark)

# ── Component groups ─────────────────────────
CORE_COMPONENTS=(hypr waybar wofi dunst kitty gtk)
ALL_COMPONENTS=(hypr waybar wofi dunst kitty gtk scripts)

# ── Defaults ─────────────────────────────────
SELECTED_THEME="everforest"
SELECTED_COMPONENTS=()
INSTALL_PACKAGES=false
MINIMAL=false
DRY_RUN=false
SKIP_BACKUP=false

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_banner() {
    echo -e "${CYAN}"
    cat << 'BANNER'
    ╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗  ╔╦╗╔═╗╔╦╗╔═╗
    ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║   ║║║ ║ ║ ╚═╗
    ╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝  ═╩╝╚═╝ ╩ ╚═╝
BANNER
    echo -e "${NC}"
}

usage() {
    print_banner
    echo -e "${BOLD}Usage:${NC} ./install.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${GREEN}--theme, -t <name>${NC}       Set theme (default: everforest)"
    echo -e "  ${GREEN}--components, -c <list>${NC}  Comma-separated components to install"
    echo -e "  ${GREEN}--all${NC}                    Install all components"
    echo -e "  ${GREEN}--minimal${NC}                Install only hypr + kitty"
    echo -e "  ${GREEN}--packages, -p${NC}           Also install required packages via pacman/yay"
    echo -e "  ${GREEN}--list-themes${NC}            List available themes"
    echo -e "  ${GREEN}--list-components${NC}        List available components"
    echo -e "  ${GREEN}--dry-run${NC}                Show what would be done without doing it"
    echo -e "  ${GREEN}--no-backup${NC}              Skip backing up existing configs"
    echo -e "  ${GREEN}--help, -h${NC}               Show this help"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ./install.sh --all --theme catppuccin --packages"
    echo -e "  ./install.sh -t gruvbox -c hypr,waybar,kitty"
    echo -e "  ./install.sh --minimal --theme nord"
    echo -e "  ./install.sh --theme everforest --all"
    echo ""
    echo -e "${BOLD}Available themes:${NC} ${THEMES[*]}"
    echo -e "${BOLD}Available components:${NC} ${ALL_COMPONENTS[*]}"
}

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_dry()     { echo -e "${MAGENTA}[DRY-RUN]${NC} $*"; }

validate_theme() {
    local theme="$1"
    for t in "${THEMES[@]}"; do
        [[ "$t" == "$theme" ]] && return 0
    done
    log_error "Unknown theme: $theme"
    echo -e "Available themes: ${THEMES[*]}"
    exit 1
}

validate_component() {
    local comp="$1"
    for c in "${ALL_COMPONENTS[@]}"; do
        [[ "$c" == "$comp" ]] && return 0
    done
    log_error "Unknown component: $comp"
    echo -e "Available components: ${ALL_COMPONENTS[*]}"
    exit 1
}

backup_config() {
    local target="$1"
    if [[ -e "$target" && "$SKIP_BACKUP" == false ]]; then
        mkdir -p "$BACKUP_DIR"
        local relative="${target#$HOME/}"
        local backup_path="$BACKUP_DIR/$relative"
        mkdir -p "$(dirname "$backup_path")"
        if [[ "$DRY_RUN" == true ]]; then
            log_dry "Would backup: $target -> $backup_path"
        else
            cp -r "$target" "$backup_path" 2>/dev/null || true
            log_info "Backed up: $relative"
        fi
    fi
}

link_or_copy() {
    local src="$1"
    local dest="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would link: $src -> $dest"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    backup_config "$dest"
    rm -rf "$dest"
    ln -sf "$src" "$dest"
    log_success "Linked: $(basename "$src") -> $dest"
}

copy_file() {
    local src="$1"
    local dest="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would copy: $src -> $dest"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    backup_config "$dest"
    cp -f "$src" "$dest"
    log_success "Copied: $(basename "$src")"
}

# ── Package Installation ─────────────────────
install_packages() {
    log_info "Installing required packages..."

    local PACMAN_PKGS=(
        hyprland
        waybar
        wofi
        dunst
        kitty
        swww
        grim
        slurp
        grimblast-git
        wl-clipboard
        cliphist
        polkit-gnome
        thunar
        pavucontrol
        blueman
        network-manager-applet
        brightnessctl
        playerctl
        python3
        hypridle
        hyprlock
        wlogout
        xdg-desktop-portal-hyprland
        qt5-wayland
        qt6-wayland
        adw-gtk3
        papirus-icon-theme
    )

    local AUR_PKGS=(
        bibata-cursor-theme
        ttf-jetbrains-mono-nerd
        swww
        grimblast-git
        wlogout
    )

    # Detect package manager
    if command -v yay &>/dev/null; then
        PKG_MGR="yay"
    elif command -v paru &>/dev/null; then
        PKG_MGR="paru"
    else
        PKG_MGR="pacman"
        log_warn "No AUR helper found. AUR packages will be skipped."
        log_warn "Install yay or paru for full setup."
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would install with $PKG_MGR: ${PACMAN_PKGS[*]}"
        if [[ "$PKG_MGR" != "pacman" ]]; then
            log_dry "Would install AUR packages: ${AUR_PKGS[*]}"
        fi
        return
    fi

    log_info "Using $PKG_MGR to install packages..."

    if [[ "$PKG_MGR" == "pacman" ]]; then
        sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" 2>/dev/null || true
    else
        "$PKG_MGR" -S --needed --noconfirm "${PACMAN_PKGS[@]}" "${AUR_PKGS[@]}" 2>/dev/null || true
    fi

    log_success "Packages installed"
}

# ── Component Installers ─────────────────────
install_hypr() {
    log_info "Installing Hyprland config..."
    local hypr_dir="$HOME/.config/hypr"
    mkdir -p "$hypr_dir"

    link_or_copy "$DOTFILES/config/hypr/hyprland.conf" "$hypr_dir/hyprland.conf"
    link_or_copy "$DOTFILES/config/hypr/keybinds.conf" "$hypr_dir/keybinds.conf"
    link_or_copy "$DOTFILES/config/hypr/rules.conf"    "$hypr_dir/rules.conf"
    link_or_copy "$DOTFILES/config/hypr/autostart.conf" "$hypr_dir/autostart.conf"
}

install_waybar() {
    log_info "Installing Waybar config..."
    local waybar_dir="$HOME/.config/waybar"
    mkdir -p "$waybar_dir"

    link_or_copy "$DOTFILES/config/waybar/config.jsonc" "$waybar_dir/config.jsonc"
    link_or_copy "$DOTFILES/config/waybar/style.css"    "$waybar_dir/style.css"
}

install_wofi() {
    log_info "Installing Wofi config..."
    local wofi_dir="$HOME/.config/wofi"
    mkdir -p "$wofi_dir"

    link_or_copy "$DOTFILES/config/wofi/config"    "$wofi_dir/config"
    link_or_copy "$DOTFILES/config/wofi/style.css"  "$wofi_dir/style.css"
}

install_dunst() {
    log_info "Installing Dunst config..."
    local dunst_dir="$HOME/.config/dunst"
    mkdir -p "$dunst_dir"

    copy_file "$DOTFILES/config/dunst/dunstrc" "$dunst_dir/dunstrc"
}

install_kitty() {
    log_info "Installing Kitty config..."
    local kitty_dir="$HOME/.config/kitty"
    mkdir -p "$kitty_dir"

    link_or_copy "$DOTFILES/config/kitty/kitty.conf" "$kitty_dir/kitty.conf"
}

install_gtk() {
    log_info "Installing GTK config..."
    local gtk_dir="$HOME/.config/gtk-3.0"
    mkdir -p "$gtk_dir"

    copy_file "$DOTFILES/config/gtk-3.0/settings.ini" "$gtk_dir/settings.ini"
}

install_scripts() {
    log_info "Installing scripts..."
    chmod +x "$DOTFILES/scripts/"*.sh
    log_success "Scripts ready in $DOTFILES/scripts/"
}

# ── Theme Application ────────────────────────
apply_theme() {
    local theme="$1"
    local theme_dir="$DOTFILES/themes/$theme"

    log_info "Applying theme: ${BOLD}$theme${NC}"

    if [[ ! -d "$theme_dir" ]]; then
        log_error "Theme directory not found: $theme_dir"
        exit 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_dry "Would apply theme '$theme' to all installed components"
        return
    fi

    # Hyprland theme
    if [[ -f "$theme_dir/hypr-theme.conf" ]]; then
        cp "$theme_dir/hypr-theme.conf" "$HOME/.config/hypr/theme.conf"
        log_success "Hyprland theme applied"
    fi

    # Waybar colors
    if [[ -f "$theme_dir/waybar-colors.css" ]]; then
        cp "$theme_dir/waybar-colors.css" "$HOME/.config/waybar/colors.css"
        log_success "Waybar colors applied"
    fi

    # Wofi colors
    if [[ -f "$theme_dir/wofi-colors.css" ]]; then
        cp "$theme_dir/wofi-colors.css" "$HOME/.config/wofi/colors.css"
        log_success "Wofi colors applied"
    fi

    # Kitty theme
    if [[ -f "$theme_dir/kitty-theme.conf" ]]; then
        cp "$theme_dir/kitty-theme.conf" "$HOME/.config/kitty/theme.conf"
        log_success "Kitty theme applied"
    fi

    # Dunst theme
    if [[ -f "$theme_dir/dunst-theme" ]]; then
        local dunstrc="$HOME/.config/dunst/dunstrc"
        if [[ -f "$dunstrc" ]]; then
            # Merge theme into dunstrc
            python3 << PYEOF
import configparser
base = configparser.ConfigParser()
base.read("$dunstrc")
theme = configparser.ConfigParser()
theme.read("$theme_dir/dunst-theme")
for section in theme.sections():
    if not base.has_section(section):
        base.add_section(section)
    for key, value in theme.items(section):
        base.set(section, key, value)
with open("$dunstrc", "w") as f:
    base.write(f)
PYEOF
            log_success "Dunst theme applied"
        fi
    fi

    # Save current theme
    echo "$theme" > "$DOTFILES/.current-theme"
    log_success "Theme set to: $theme"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Parse Arguments
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

while [[ $# -gt 0 ]]; do
    case "$1" in
        --theme|-t)
            SELECTED_THEME="$2"
            validate_theme "$SELECTED_THEME"
            shift 2
            ;;
        --components|-c)
            IFS=',' read -ra SELECTED_COMPONENTS <<< "$2"
            for comp in "${SELECTED_COMPONENTS[@]}"; do
                validate_component "$comp"
            done
            shift 2
            ;;
        --all)
            SELECTED_COMPONENTS=("${ALL_COMPONENTS[@]}")
            shift
            ;;
        --minimal)
            MINIMAL=true
            SELECTED_COMPONENTS=(hypr kitty)
            shift
            ;;
        --packages|-p)
            INSTALL_PACKAGES=true
            shift
            ;;
        --list-themes)
            echo -e "${BOLD}Available themes:${NC}"
            for t in "${THEMES[@]}"; do
                if [[ -d "$DOTFILES/themes/$t" ]]; then
                    echo -e "  ${GREEN}$t${NC}"
                else
                    echo -e "  ${RED}$t${NC} (missing)"
                fi
            done
            exit 0
            ;;
        --list-components)
            echo -e "${BOLD}Available components:${NC}"
            for c in "${ALL_COMPONENTS[@]}"; do
                echo -e "  ${GREEN}$c${NC}"
            done
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Default to all components if none specified
if [[ ${#SELECTED_COMPONENTS[@]} -eq 0 ]]; then
    SELECTED_COMPONENTS=("${ALL_COMPONENTS[@]}")
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_banner

echo -e "${BOLD}Configuration:${NC}"
echo -e "  Theme:      ${CYAN}$SELECTED_THEME${NC}"
echo -e "  Components: ${CYAN}${SELECTED_COMPONENTS[*]}${NC}"
echo -e "  Packages:   ${CYAN}$INSTALL_PACKAGES${NC}"
echo -e "  Dry run:    ${CYAN}$DRY_RUN${NC}"
echo ""

if [[ "$DRY_RUN" == false ]]; then
    read -rp "Proceed with installation? [Y/n] " confirm
    if [[ "${confirm,,}" == "n" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""

# Install packages if requested
if [[ "$INSTALL_PACKAGES" == true ]]; then
    install_packages
    echo ""
fi

# Install selected components
for comp in "${SELECTED_COMPONENTS[@]}"; do
    case "$comp" in
        hypr)    install_hypr ;;
        waybar)  install_waybar ;;
        wofi)    install_wofi ;;
        dunst)   install_dunst ;;
        kitty)   install_kitty ;;
        gtk)     install_gtk ;;
        scripts) install_scripts ;;
    esac
done

echo ""

# Apply theme
apply_theme "$SELECTED_THEME"

echo ""

if [[ "$DRY_RUN" == true ]]; then
    log_dry "Dry run complete. No changes were made."
else
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Backups saved to: $BACKUP_DIR"
    fi
    echo ""
    echo -e "${GREEN}${BOLD}Installation complete!${NC}"
    echo -e "Theme: ${CYAN}$SELECTED_THEME${NC}"
    echo ""
    echo -e "${BOLD}Quick commands:${NC}"
    echo -e "  Switch theme:  ${CYAN}~/.dotfiles/scripts/theme-switch.sh <theme>${NC}"
    echo -e "  Or press:      ${CYAN}Super+Shift+T${NC} for interactive picker"
    echo ""
    echo -e "You may need to ${YELLOW}log out and back in${NC} for all changes to take effect."
fi
