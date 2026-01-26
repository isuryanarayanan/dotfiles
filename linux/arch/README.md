# Arch Linux Setup Guide

This guide documents the setup process for my Arch Linux installation with Sway window manager.

## Quick Start

```bash
# SSH into the machine
ssh supers@192.168.1.9

# Clone dotfiles
git clone https://github.com/isuryanarayanan/dotfiles.git ~/dotfiles

# Run the install script
cd ~/dotfiles/linux/arch
chmod +x install.sh
./install.sh
```

## Post-Installation Checklist

After running the base Arch installation, here's what needs to be configured:

### 1. System Basics

- [ ] Enable multilib repository (for 32-bit packages)
- [ ] Configure pacman parallel downloads
- [ ] Install an AUR helper (yay/paru)

### 2. Display & Window Manager (Sway)

- [ ] Install Sway and dependencies
- [ ] Configure Waybar (status bar)
- [ ] Set up Wofi/Rofi (application launcher)
- [ ] Configure screen locking (swaylock)
- [ ] Set up notifications (mako/dunst)

### 3. Development Environment

- [ ] Neovim with plugins
- [ ] Tmux with TPM
- [ ] Git configuration
- [ ] Programming languages (Python, Node.js, etc.)

### 4. Terminal & Shell

- [ ] Install preferred terminal (Alacritty/Kitty/foot)
- [ ] Configure Zsh/Fish with plugins
- [ ] Set up Starship prompt (optional)

### 5. Utilities

- [ ] File manager (Thunar/ranger)
- [ ] Screenshot tools (grim + slurp)
- [ ] Clipboard manager (wl-clipboard)
- [ ] Audio (PipeWire/PulseAudio)
- [ ] Bluetooth

---

## Detailed Configuration

### Sway Basics

Sway is a tiling Wayland compositor, a drop-in replacement for i3 on Wayland.

**Key concepts:**

- `$mod` key (usually Super/Windows key)
- Workspaces (virtual desktops)
- Containers and tiling layouts
- Scratchpad (hidden workspace)

**Essential keybindings (default):**
| Key | Action |
|-----|--------|
| `$mod+Enter` | Open terminal |
| `$mod+d` | Open app launcher |
| `$mod+Shift+q` | Kill focused window |
| `$mod+1-9` | Switch to workspace |
| `$mod+Shift+1-9` | Move window to workspace |
| `$mod+h/j/k/l` | Focus left/down/up/right |
| `$mod+Shift+h/j/k/l` | Move window |
| `$mod+v` | Split vertically |
| `$mod+b` | Split horizontally |
| `$mod+f` | Toggle fullscreen |
| `$mod+Shift+space` | Toggle floating |
| `$mod+Shift+e` | Exit Sway |

### File Locations

| Config    | Path                                 |
| --------- | ------------------------------------ |
| Sway      | `~/.config/sway/config`              |
| Waybar    | `~/.config/waybar/`                  |
| Alacritty | `~/.config/alacritty/alacritty.toml` |
| Neovim    | `~/.config/nvim/`                    |
| Tmux      | `~/.tmux.conf`                       |
| Wofi      | `~/.config/wofi/`                    |

---

## Troubleshooting

### Common Issues

1. **Sway won't start**: Check if you're in the `seat` group: `groups $USER`
2. **No audio**: Ensure PipeWire is running: `systemctl --user status pipewire`
3. **Screen sharing broken**: Install `xdg-desktop-portal-wlr`
4. **Fonts look weird**: Install `noto-fonts`, `ttf-dejavu`, `ttf-liberation`
