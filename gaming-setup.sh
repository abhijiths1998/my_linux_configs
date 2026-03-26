#!/usr/bin/env bash
set -euo pipefail

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃   Arch Linux Gaming Setup — Nobara Parity                       ┃
# ┃   Especially optimized for NVIDIA GPUs                          ┃
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
SKIP_NVIDIA=false
SKIP_KERNEL=false
SKIP_STEAM=false
SKIP_TWEAKS=false
SKIP_CONTROLLERS=false
AUR_HELPER=""

print_banner() {
    echo -e "${GREEN}"
    cat << 'BANNER'
     ╔═╗╦═╗╔═╗╦ ╦  ╔═╗╔═╗╔╦╗╦╔╗╔╔═╗
     ╠═╣╠╦╝║  ╠═╣  ║ ╦╠═╣║║║║║║║║ ╦
     ╩ ╩╩╚═╚═╝╩ ╩  ╚═╝╩ ╩╩ ╩╩╝╚╝╚═╝
      Nobara-parity gaming for Arch
BANNER
    echo -e "${NC}"
}

usage() {
    print_banner
    echo -e "${BOLD}Usage:${NC} ./gaming-setup.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${GREEN}--all${NC}                Install everything (default)"
    echo -e "  ${GREEN}--skip-nvidia${NC}        Skip NVIDIA driver installation"
    echo -e "  ${GREEN}--skip-kernel${NC}        Skip gaming kernel (linux-zen)"
    echo -e "  ${GREEN}--skip-steam${NC}         Skip Steam/Lutris/launchers"
    echo -e "  ${GREEN}--skip-tweaks${NC}        Skip kernel/system performance tweaks"
    echo -e "  ${GREEN}--skip-controllers${NC}   Skip controller driver setup"
    echo -e "  ${GREEN}--dry-run${NC}            Show what would be done"
    echo -e "  ${GREEN}--help, -h${NC}           Show this help"
    echo ""
    echo -e "${BOLD}What this does (Nobara parity):${NC}"
    echo -e "  1. NVIDIA proprietary drivers + DKMS + Wayland patches"
    echo -e "  2. linux-zen kernel (better scheduling, fsync, futex2)"
    echo -e "  3. Steam, Proton-GE, Lutris, Wine, Heroic, Bottles"
    echo -e "  4. Vulkan + lib32 + DXVK/VKD3D"
    echo -e "  5. GameMode, MangoHud, GameScope"
    echo -e "  6. Performance tweaks (vm.max_map_count, split lock, etc.)"
    echo -e "  7. Xbox/PS/Switch controller support"
    echo -e "  8. OBS Studio, Discord, multimedia codecs"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Preflight Checks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root. The script uses sudo where needed."
        exit 1
    fi
}

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "This script is for Arch Linux (or Arch-based distros) only."
        exit 1
    fi
    log_success "Arch Linux detected"
}

detect_gpu() {
    if lspci | grep -qi "nvidia"; then
        NVIDIA_GPU=true
        local gpu_name
        gpu_name=$(lspci | grep -i "vga\|3d" | grep -i nvidia | head -1 | sed 's/.*: //')
        log_success "NVIDIA GPU detected: $gpu_name"
    else
        NVIDIA_GPU=false
        log_warn "No NVIDIA GPU detected"
        if [[ "$SKIP_NVIDIA" == false ]]; then
            log_warn "Skipping NVIDIA setup automatically"
            SKIP_NVIDIA=true
        fi
    fi
}

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
        return
    fi

    log_info "Installing: $desc"
    $AUR_HELPER -S --needed --noconfirm "${pkgs[@]}" 2>&1 | tail -3 || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Component Installers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enable_multilib() {
    log_section "Enabling multilib repository"

    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        log_success "multilib already enabled"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would enable multilib in /etc/pacman.conf"
        return
    fi

    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    log_success "multilib enabled"
}

install_nvidia() {
    log_section "NVIDIA Drivers (Proprietary + DKMS)"

    if [[ "$SKIP_NVIDIA" == true ]]; then
        log_warn "Skipping NVIDIA setup"
        return
    fi

    # Core NVIDIA packages
    pkg_install "NVIDIA proprietary drivers" \
        nvidia-dkms \
        nvidia-utils \
        lib32-nvidia-utils \
        nvidia-settings \
        opencl-nvidia \
        lib32-opencl-nvidia

    # Vulkan + DXVK support
    pkg_install "NVIDIA Vulkan/DXVK" \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader \
        vulkan-tools

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would configure NVIDIA kernel modules and Wayland support"
        return
    fi

    # ── mkinitcpio: add nvidia modules ───────
    local mkinit="/etc/mkinitcpio.conf"
    if ! grep -q "nvidia nvidia_modeset nvidia_uvm nvidia_drm" "$mkinit" 2>/dev/null; then
        log_info "Adding NVIDIA modules to mkinitcpio..."
        sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkinit"
        # Clean up double spaces
        sudo sed -i 's/MODULES=( /MODULES=(/' "$mkinit"
    fi

    # ── Kernel parameter: nvidia_drm.modeset=1 ──
    # For systemd-boot
    if [[ -d /boot/loader/entries ]]; then
        log_info "Configuring nvidia_drm.modeset=1 for systemd-boot..."
        for entry in /boot/loader/entries/*.conf; do
            if ! grep -q "nvidia_drm.modeset=1" "$entry" 2>/dev/null; then
                sudo sed -i '/^options/ s/$/ nvidia_drm.modeset=1 nvidia_drm.fbdev=1/' "$entry"
            fi
        done
    fi

    # For GRUB
    if [[ -f /etc/default/grub ]]; then
        if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
            log_info "Configuring nvidia_drm.modeset=1 for GRUB..."
            sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1 nvidia_drm.fbdev=1"/' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
    fi

    # ── NVIDIA pacman hook (rebuild on kernel update) ──
    sudo mkdir -p /etc/pacman.d/hooks
    sudo tee /etc/pacman.d/hooks/nvidia.hook > /dev/null << 'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = nvidia-dkms
Target = linux
Target = linux-zen
Target = linux-lts

[Action]
Description = Rebuilding NVIDIA DKMS module and updating initramfs...
Depends = mkinitcpio
When = PostTransaction
NeedsTargets
Exec = /bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
HOOK
    log_success "NVIDIA pacman hook installed"

    # ── Wayland environment variables ────────
    local nvidia_env="/etc/profile.d/nvidia-wayland.sh"
    sudo tee "$nvidia_env" > /dev/null << 'ENV'
# NVIDIA Wayland compatibility
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBVA_DRIVER_NAME=nvidia
export __GL_GSYNC_ALLOWED=1
export __GL_VRR_ALLOWED=1
export WLR_NO_HARDWARE_CURSORS=1
export NVD_BACKEND=direct
ENV
    log_success "NVIDIA Wayland environment configured"

    # ── Enable nvidia services ───────────────
    sudo systemctl enable nvidia-suspend.service 2>/dev/null || true
    sudo systemctl enable nvidia-resume.service 2>/dev/null || true
    sudo systemctl enable nvidia-hibernate.service 2>/dev/null || true

    # Rebuild initramfs
    log_info "Rebuilding initramfs..."
    sudo mkinitcpio -P
    log_success "NVIDIA drivers fully configured"
}

install_gaming_kernel() {
    log_section "Gaming Kernel (linux-zen)"

    if [[ "$SKIP_KERNEL" == true ]]; then
        log_warn "Skipping gaming kernel"
        return
    fi

    pkg_install "linux-zen kernel" \
        linux-zen \
        linux-zen-headers

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would set linux-zen as default boot kernel"
        return
    fi

    # Update bootloader to use zen kernel
    if [[ -d /boot/loader ]]; then
        log_info "Updating systemd-boot default to linux-zen..."
        # Create zen entry if not exists
        local zen_entry="/boot/loader/entries/arch-zen.conf"
        if [[ ! -f "$zen_entry" ]]; then
            local existing_entry
            existing_entry=$(find /boot/loader/entries/ -name "*.conf" | head -1)
            if [[ -n "$existing_entry" ]]; then
                sudo cp "$existing_entry" "$zen_entry"
                sudo sed -i 's/vmlinuz-linux\b/vmlinuz-linux-zen/g' "$zen_entry"
                sudo sed -i 's/initramfs-linux\b/initramfs-linux-zen/g' "$zen_entry"
                sudo sed -i 's/title .*/title Arch Linux (zen)/' "$zen_entry"
            fi
        fi
        sudo sed -i 's/^default .*/default arch-zen.conf/' /boot/loader/loader.conf 2>/dev/null || true
    fi

    if [[ -f /etc/default/grub ]]; then
        log_info "Regenerating GRUB config for zen kernel..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    log_success "linux-zen installed (better fsync, futex2, scheduler)"
}

install_steam_and_launchers() {
    log_section "Steam, Launchers & Wine"

    if [[ "$SKIP_STEAM" == true ]]; then
        log_warn "Skipping Steam/launchers"
        return
    fi

    # Steam + Proton dependencies
    pkg_install "Steam" \
        steam

    # Wine and dependencies (what Nobara ships)
    pkg_install "Wine staging + dependencies" \
        wine-staging \
        wine-mono \
        wine-gecko \
        winetricks \
        lib32-giflib \
        lib32-gnutls \
        lib32-libxcomposite \
        lib32-libxinerama \
        lib32-libxslt \
        lib32-mpg123 \
        lib32-v4l-utils \
        lib32-alsa-lib \
        lib32-alsa-plugins \
        lib32-libpulse \
        lib32-openal \
        lib32-libgpg-error \
        lib32-sqlite \
        lib32-libldap

    # Lutris
    pkg_install "Lutris" \
        lutris

    # Proton-GE (custom Proton with extra patches)
    pkg_install "Proton-GE custom" \
        proton-ge-custom-bin

    # Heroic Games Launcher (Epic/GOG)
    pkg_install "Heroic launcher" \
        heroic-games-launcher-bin

    # Bottles (Wine prefix manager)
    pkg_install "Bottles" \
        bottles

    log_success "All game launchers installed"
}

install_gaming_tools() {
    log_section "Gaming Tools (GameMode, MangoHud, GameScope)"

    # GameMode — dynamic CPU governor optimization
    pkg_install "GameMode" \
        gamemode \
        lib32-gamemode

    # MangoHud — Vulkan/OpenGL overlay (FPS, temps, etc.)
    pkg_install "MangoHud" \
        mangohud \
        lib32-mangohud

    # GameScope — SteamOS session compositing
    pkg_install "GameScope" \
        gamescope

    # DXVK/VKD3D — DirectX to Vulkan translation
    pkg_install "DXVK + VKD3D" \
        vkd3d \
        lib32-vkd3d

    # Vulkan tools
    pkg_install "Vulkan tools" \
        vulkan-tools \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader

    log_success "Gaming tools installed"
}

install_controller_support() {
    log_section "Controller Support (Xbox, PS, Switch)"

    if [[ "$SKIP_CONTROLLERS" == true ]]; then
        log_warn "Skipping controller setup"
        return
    fi

    # Steam handles most controllers, but for non-Steam:
    pkg_install "Controller drivers" \
        game-devices-udev

    # Xbox wireless (xpadneo) + wired (xone)
    pkg_install "Xbox controller support" \
        xpadneo-dkms

    # PS4/PS5 DualSense support
    pkg_install "DualSense support" \
        dualsensectl

    # General HID support
    pkg_install "HID support" \
        hid-nintendo-dkms

    if [[ "$DRY_RUN" == false ]]; then
        # Ensure controllers get proper permissions
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger 2>/dev/null || true
    fi

    log_success "Controller support configured"
}

install_multimedia() {
    log_section "Multimedia & Social"

    # Codecs (what Nobara ships out of the box)
    pkg_install "Multimedia codecs" \
        ffmpeg \
        gstreamer \
        gst-plugins-base \
        gst-plugins-good \
        gst-plugins-bad \
        gst-plugins-ugly \
        gst-libav \
        lib32-gst-plugins-base

    # OBS Studio
    pkg_install "OBS Studio" \
        obs-studio

    # Discord
    pkg_install "Discord" \
        discord

    # Hardware video acceleration
    if [[ "$NVIDIA_GPU" == true ]]; then
        pkg_install "NVIDIA VA-API" \
            libva-nvidia-driver
    fi

    log_success "Multimedia stack installed"
}

apply_performance_tweaks() {
    log_section "Performance Tweaks (Nobara-style)"

    if [[ "$SKIP_TWEAKS" == true ]]; then
        log_warn "Skipping performance tweaks"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would apply sysctl gaming tweaks and I/O scheduler config"
        return
    fi

    # ── sysctl tweaks (what Nobara sets) ─────
    local sysctl_conf="/etc/sysctl.d/99-gaming.conf"
    sudo tee "$sysctl_conf" > /dev/null << 'SYSCTL'
# ── Gaming Performance Tweaks ────────────────
# Match Nobara's out-of-box tuning

# Increase max memory map areas (required by many games/Wine)
vm.max_map_count = 2147483642

# Disable split lock detection (performance penalty in some games)
kernel.split_lock_mitigate = 0

# Network tweaks for online gaming
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1

# Reduce swap usage (keep games in RAM)
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Larger receive buffer for network games
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Disable watchdog (saves a tiny bit of CPU)
kernel.nmi_watchdog = 0
SYSCTL
    sudo sysctl --system >/dev/null 2>&1
    log_success "sysctl gaming tweaks applied"

    # ── I/O scheduler for NVMe/SSD ──────────
    local udev_io="/etc/udev/rules.d/60-ioschedulers.rules"
    sudo tee "$udev_io" > /dev/null << 'UDEV'
# NVMe: none (already fast, no scheduler overhead)
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# SSD: mq-deadline
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# HDD: bfq
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
UDEV
    log_success "I/O schedulers configured (NVMe: none, SSD: mq-deadline, HDD: bfq)"

    # ── Disable mitigations (optional, big perf gain) ──
    # This is what Nobara does — trades security mitigations for performance
    # Only for dedicated gaming machines
    echo ""
    echo -e "${YELLOW}${BOLD}Optional:${NC} Disable CPU security mitigations for ~5-15% perf gain?"
    echo -e "  This is what Nobara does on gaming installs."
    echo -e "  Only recommended for dedicated gaming machines, NOT for servers."
    read -rp "  Disable mitigations? [y/N] " mitigate_choice
    if [[ "${mitigate_choice,,}" == "y" ]]; then
        if [[ -d /boot/loader/entries ]]; then
            for entry in /boot/loader/entries/*.conf; do
                if ! grep -q "mitigations=off" "$entry" 2>/dev/null; then
                    sudo sed -i '/^options/ s/$/ mitigations=off/' "$entry"
                fi
            done
        fi
        if [[ -f /etc/default/grub ]]; then
            if ! grep -q "mitigations=off" /etc/default/grub; then
                sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 mitigations=off"/' /etc/default/grub
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            fi
        fi
        log_success "CPU mitigations disabled (reboot required)"
    else
        log_info "Keeping CPU mitigations enabled"
    fi

    # ── Enable fstrim for SSDs ───────────────
    sudo systemctl enable --now fstrim.timer 2>/dev/null || true
    log_success "Weekly SSD TRIM enabled"

    # ── Ananicy-cpp (auto nice daemon) ───────
    pkg_install "Ananicy-cpp (process priority daemon)" \
        ananicy-cpp \
        cachyos-ananicy-rules-git

    if [[ "$DRY_RUN" == false ]]; then
        sudo systemctl enable --now ananicy-cpp.service 2>/dev/null || true
        log_success "ananicy-cpp enabled (auto-prioritizes games)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Parse Arguments
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-nvidia)      SKIP_NVIDIA=true; shift ;;
        --skip-kernel)      SKIP_KERNEL=true; shift ;;
        --skip-steam)       SKIP_STEAM=true; shift ;;
        --skip-tweaks)      SKIP_TWEAKS=true; shift ;;
        --skip-controllers) SKIP_CONTROLLERS=true; shift ;;
        --dry-run)          DRY_RUN=true; shift ;;
        --all)              shift ;;
        --help|-h)          usage; exit 0 ;;
        *)                  log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_banner

echo -e "${BOLD}This script will configure your Arch install for gaming parity with Nobara.${NC}"
echo ""
echo -e "  NVIDIA drivers:  ${CYAN}$([ "$SKIP_NVIDIA" == true ] && echo "skip" || echo "install")${NC}"
echo -e "  Gaming kernel:   ${CYAN}$([ "$SKIP_KERNEL" == true ] && echo "skip" || echo "linux-zen")${NC}"
echo -e "  Steam/launchers: ${CYAN}$([ "$SKIP_STEAM" == true ] && echo "skip" || echo "install")${NC}"
echo -e "  Perf tweaks:     ${CYAN}$([ "$SKIP_TWEAKS" == true ] && echo "skip" || echo "apply")${NC}"
echo -e "  Controllers:     ${CYAN}$([ "$SKIP_CONTROLLERS" == true ] && echo "skip" || echo "install")${NC}"
echo -e "  Dry run:         ${CYAN}$DRY_RUN${NC}"
echo ""

if [[ "$DRY_RUN" == false ]]; then
    echo -e "${YELLOW}${BOLD}WARNING:${NC} This will modify system packages, kernel params, and boot config."
    read -rp "Continue? [y/N] " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""

# Preflight
check_root
check_arch
detect_gpu
detect_aur_helper

# Enable multilib (required for 32-bit gaming libs)
enable_multilib

# Install everything
install_nvidia
install_gaming_kernel
install_steam_and_launchers
install_gaming_tools
install_controller_support
install_multimedia
apply_performance_tweaks

# ── Summary ──────────────────────────────────
log_section "Setup Complete"

echo -e "${GREEN}${BOLD}Your Arch install is now gaming-ready!${NC}"
echo ""
echo -e "${BOLD}What was configured:${NC}"
[[ "$SKIP_NVIDIA" == false && "$NVIDIA_GPU" == true ]] && \
    echo -e "  ${GREEN}*${NC} NVIDIA proprietary drivers + DKMS + Wayland env"
[[ "$SKIP_KERNEL" == false ]] && \
    echo -e "  ${GREEN}*${NC} linux-zen kernel (fsync, futex2, better scheduling)"
[[ "$SKIP_STEAM" == false ]] && \
    echo -e "  ${GREEN}*${NC} Steam, Proton-GE, Lutris, Heroic, Bottles, Wine-staging"
echo -e "  ${GREEN}*${NC} GameMode, MangoHud, GameScope"
echo -e "  ${GREEN}*${NC} Vulkan + DXVK + VKD3D + lib32 stack"
[[ "$SKIP_CONTROLLERS" == false ]] && \
    echo -e "  ${GREEN}*${NC} Xbox/PS/Switch controller support"
echo -e "  ${GREEN}*${NC} OBS Studio, Discord, multimedia codecs"
[[ "$SKIP_TWEAKS" == false ]] && \
    echo -e "  ${GREEN}*${NC} vm.max_map_count, I/O schedulers, ananicy-cpp"
echo ""
echo -e "${BOLD}Quick tips:${NC}"
echo -e "  ${CYAN}gamemoderun %command%${NC}      — Add to Steam launch options"
echo -e "  ${CYAN}mangohud %command%${NC}          — FPS overlay in Steam launch options"
echo -e "  ${CYAN}gamescope -f -- %command%${NC}   — Fullscreen compositing"
echo -e "  ${CYAN}protonup${NC}                    — Update Proton-GE versions"
echo ""
echo -e "${YELLOW}${BOLD}A reboot is required${NC} for kernel/driver changes to take effect."
echo -e "Run: ${CYAN}sudo reboot${NC}"
