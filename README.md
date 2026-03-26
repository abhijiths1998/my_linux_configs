# Hyprland Dotfiles

Arch Linux + Hyprland rice with 10 themes and a one-command installer.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/hyprland-dots.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --all --theme everforest --packages
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
