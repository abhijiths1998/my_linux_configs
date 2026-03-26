# My Linux Configs

Arch Linux + Hyprland rice with 10 themes, a one-command installer, and a Nobara-parity gaming setup script for NVIDIA.

## Quick Start

```bash
git clone https://github.com/abhijiths1998/my_linux_configs.git ~/.dotfiles
cd ~/.dotfiles

# Hyprland desktop setup
./install.sh --all --theme everforest --packages

# Gaming setup (Nobara parity, NVIDIA optimized)
./gaming-setup.sh
```

## Themes

| Theme | Description |
|-------|-------------|
| `everforest` | Soft green dark mode (default) |
| `catppuccin` | Catppuccin Mocha - pastel dark |
| `gruvbox` | Retro warm dark |
| `nord` | Arctic cool blues |
| `tokyonight` | Neon-inspired dark |
| `dracula` | Purple-accented dark |
| `rosepine` | Muted rose tones |
| `solarized` | Ethan Schoonover's dark variant |
| `kanagawa` | Wave-inspired Japanese palette |
| `onedark` | Atom One Dark |

## Usage

```bash
# Full install with packages
./install.sh --all --theme catppuccin --packages

# Specific components only
./install.sh --theme gruvbox --components hypr,waybar,kitty

# Minimal (just hyprland + kitty)
./install.sh --minimal --theme nord

# Preview without changes
./install.sh --all --theme dracula --dry-run

# List themes
./install.sh --list-themes

# Switch theme at runtime
~/.dotfiles/scripts/theme-switch.sh tokyonight
# Or press Super+Shift+T for interactive picker
```

## Components

- **hypr** - Hyprland window manager config
- **waybar** - Status bar
- **wofi** - Application launcher
- **dunst** - Notification daemon
- **kitty** - Terminal emulator
- **gtk** - GTK3 theming
- **scripts** - Wallpaper & theme switching

## Keybindings

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (kitty) |
| `Super + D` | App launcher (wofi) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move to workspace |
| `Super + Shift + T` | Theme picker |
| `Super + Shift + X` | Lock screen |
| `Print` | Screenshot (area) |

## Structure

```
~/.dotfiles/
├── install.sh              # Main installer
├── config/
│   ├── hypr/               # Hyprland configs
│   ├── waybar/             # Bar config + base styles
│   ├── wofi/               # Launcher config + styles
│   ├── dunst/              # Notification config
│   ├── kitty/              # Terminal config
│   └── gtk-3.0/            # GTK settings
├── themes/
│   └── <theme>/            # Per-theme color files
├── scripts/
│   ├── wallpaper.sh        # Wallpaper setter (swww)
│   └── theme-switch.sh     # Runtime theme switcher
└── wallpapers/             # Place wallpapers here
```

## Dependencies

Installed automatically with `--packages` flag. Requires an AUR helper (yay/paru) for some packages.

Core: `hyprland waybar wofi dunst kitty swww`
Extras: `grim slurp grimblast wl-clipboard cliphist thunar pavucontrol hypridle hyprlock wlogout`
Fonts: `ttf-jetbrains-mono-nerd`
Themes: `adw-gtk3 papirus-icon-theme bibata-cursor-theme`

---

## Gaming Setup (Nobara Parity)

`gaming-setup.sh` turns a vanilla Arch install into a gaming-ready system matching what Nobara provides out of the box.

```bash
# Full gaming setup
./gaming-setup.sh

# Skip specific components
./gaming-setup.sh --skip-nvidia       # No NVIDIA drivers
./gaming-setup.sh --skip-kernel       # Keep current kernel
./gaming-setup.sh --skip-controllers  # No controller drivers

# Preview what would happen
./gaming-setup.sh --dry-run
```

### What it installs

| Category | Packages |
|----------|----------|
| **NVIDIA** | `nvidia-dkms`, `nvidia-utils`, `lib32-nvidia-utils`, Wayland env vars, DKMS rebuild hook |
| **Kernel** | `linux-zen` (fsync, futex2, better scheduling) |
| **Steam** | Steam, Proton-GE, Lutris, Heroic, Bottles, Wine-staging |
| **Tools** | GameMode, MangoHud, GameScope, DXVK, VKD3D |
| **Controllers** | xpadneo (Xbox), dualsensectl (PS5), hid-nintendo (Switch) |
| **Multimedia** | OBS Studio, Discord, full GStreamer/FFmpeg codecs |
| **Tweaks** | `vm.max_map_count`, I/O schedulers, ananicy-cpp, SSD TRIM, optional mitigations=off |

### Steam Launch Options

```
gamemoderun %command%                  # CPU governor optimization
mangohud %command%                     # FPS/stats overlay
gamescope -f -- %command%              # SteamOS-style compositing
gamemoderun mangohud %command%         # Both together
```

---

## Desktop Essentials

`essentials-setup.sh` installs everything you need for daily use on a fresh Arch install.

```bash
# Install everything
./essentials-setup.sh

# Skip specific categories
./essentials-setup.sh --skip-office --skip-dev

# Preview
./essentials-setup.sh --dry-run
```

### What it installs

| Category | Packages |
|----------|----------|
| **Browser** | Zen Browser (preferred) > Brave > Firefox fallback |
| **Communication** | Discord, Telegram, Signal, Thunderbird |
| **Web Apps** | webapp-manager / Tangram (Flatpak fallback) |
| **Keyring** | gnome-keyring, Seahorse, PAM auto-unlock |
| **GUI Store** | Pamac (AUR + Flatpak support) / bauh fallback |
| **Torrent** | qBittorrent |
| **Media** | MPV, Spotify, Zathura (PDF), Loupe (images), Kooha (recorder) |
| **Office** | LibreOffice Fresh + spell check |
| **Utilities** | Thunar, btop, KeePassXC, Bluetooth, file-roller, gnome-disk-utility, Ventoy, nwg-look, fastfetch |
| **Fonts** | JetBrains Mono NF, Fira Code NF, Cascadia Code NF, Noto (CJK + emoji), Font Awesome |
| **Flatpak** | Flatpak + Flathub remote |
| **Backup** | Timeshift + cronie for scheduled snapshots |
| **Dev Tools** | Neovim, lazygit, Docker, VS Code, Python, Node.js, build essentials |
