#!/bin/bash

#######################################################
# Arch Linux Setup Script
# Author: Surya Narayanan
# Description: Automated setup for Arch with Sway WM
#######################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please don't run this script as root. It will ask for sudo when needed."
    exit 1
fi

# Dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#######################################################
# CONFIGURATION - Edit these to customize
#######################################################

# AUR Helper: yay or paru
AUR_HELPER="yay"

# Terminal emulator: alacritty, kitty, or foot
TERMINAL="alacritty"

# Shell: zsh or fish
SHELL_CHOICE="zsh"

# Install development tools
INSTALL_DEV_TOOLS=true

# Install gaming tools (Steam, etc.)
INSTALL_GAMING=false

# Programming languages to install
INSTALL_PYTHON=true
INSTALL_NODEJS=true
INSTALL_RUST=false
INSTALL_GO=false

#######################################################
# PACKAGE LISTS
#######################################################

# Base system packages
BASE_PACKAGES=(
    base-devel
    git
    wget
    curl
    unzip
    zip
    htop
    btop
    neofetch
    man-db
    man-pages
)

# Sway and Wayland packages
SWAY_PACKAGES=(
    sway
    swaylock
    swayidle
    swaybg
    waybar
    wofi
    mako
    grim
    slurp
    wl-clipboard
    xdg-desktop-portal-wlr
    xorg-xwayland
)

# Audio packages (PipeWire)
AUDIO_PACKAGES=(
    pipewire
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    wireplumber
    pavucontrol
)

# Bluetooth packages
BLUETOOTH_PACKAGES=(
    bluez
    bluez-utils
    blueman
)

# Font packages
FONT_PACKAGES=(
    ttf-dejavu
    ttf-liberation
    noto-fonts
    noto-fonts-emoji
    ttf-font-awesome
    ttf-jetbrains-mono-nerd
)

# Terminal and shell packages
TERMINAL_PACKAGES=(
    $TERMINAL
    tmux
    fzf
    ripgrep
    fd
    bat
    exa
    zoxide
    starship
)

# Development packages
DEV_PACKAGES=(
    neovim
    git
    lazygit
    github-cli
    docker
    docker-compose
)

# Utility packages
UTILITY_PACKAGES=(
    thunar
    gvfs
    file-roller
    imv
    mpv
    firefox
    networkmanager
    network-manager-applet
)

# AUR packages (installed via yay/paru)
AUR_PACKAGES=(
    visual-studio-code-bin
    google-chrome
    spotify
)

#######################################################
# FUNCTIONS
#######################################################

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║         Arch Linux Setup Script                    ║"
    echo "║         Sway + Neovim + Tmux                       ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

confirm() {
    read -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

update_system() {
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm
    log_success "System updated"
}

configure_pacman() {
    log_info "Configuring pacman..."
    
    # Enable parallel downloads and colors
    sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    sudo sed -i 's/#Color/Color/' /etc/pacman.conf
    
    # Enable multilib (for 32-bit packages)
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy
    fi
    
    log_success "Pacman configured"
}

install_aur_helper() {
    if command -v $AUR_HELPER &> /dev/null; then
        log_info "$AUR_HELPER is already installed"
        return
    fi
    
    log_info "Installing $AUR_HELPER..."
    
    cd /tmp
    git clone "https://aur.archlinux.org/$AUR_HELPER.git"
    cd $AUR_HELPER
    makepkg -si --noconfirm
    cd ~
    
    log_success "$AUR_HELPER installed"
}

install_packages() {
    local packages=("$@")
    log_info "Installing packages: ${packages[*]}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

install_aur_packages() {
    local packages=("$@")
    log_info "Installing AUR packages: ${packages[*]}"
    $AUR_HELPER -S --needed --noconfirm "${packages[@]}"
}

setup_shell() {
    log_info "Setting up $SHELL_CHOICE..."
    
    if [ "$SHELL_CHOICE" = "zsh" ]; then
        sudo pacman -S --needed --noconfirm zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions
        
        # Install Oh My Zsh
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
        
        # Change default shell
        chsh -s $(which zsh)
        
    elif [ "$SHELL_CHOICE" = "fish" ]; then
        sudo pacman -S --needed --noconfirm fish
        chsh -s $(which fish)
    fi
    
    log_success "Shell configured"
}

setup_neovim() {
    log_info "Setting up Neovim..."
    
    # Create config directory
    mkdir -p ~/.config/nvim
    
    # Copy nvim config from dotfiles
    if [ -d "$DOTFILES_DIR/nvim/nvim" ]; then
        cp -r "$DOTFILES_DIR/nvim/nvim/"* ~/.config/nvim/
        log_success "Neovim config copied from dotfiles"
    else
        log_warn "Neovim dotfiles not found, using defaults"
    fi
    
    # Install vim-plug
    if [ ! -f ~/.config/nvim/autoload/plug.vim ]; then
        curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    log_success "Neovim setup complete"
}

setup_tmux() {
    log_info "Setting up Tmux..."
    
    # Copy tmux config
    if [ -f "$DOTFILES_DIR/tmux/tmux_backup/.tmux.conf" ]; then
        cp "$DOTFILES_DIR/tmux/tmux_backup/.tmux.conf" ~/.tmux.conf
        log_success "Tmux config copied from dotfiles"
    fi
    
    # Install TPM (Tmux Plugin Manager)
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        log_success "TPM installed"
    fi
    
    log_success "Tmux setup complete"
}

setup_sway() {
    log_info "Setting up Sway..."
    
    mkdir -p ~/.config/sway
    mkdir -p ~/.config/waybar
    mkdir -p ~/.config/wofi
    mkdir -p ~/.config/mako
    
    # Create Sway config if it doesn't exist
    if [ ! -f ~/.config/sway/config ]; then
        cp /etc/sway/config ~/.config/sway/config
        
        # Add some customizations
        cat >> ~/.config/sway/config << 'EOF'

# Custom Configurations
# =====================

# Set terminal
set $term alacritty

# Set app launcher
set $menu wofi --show drun

# Gaps
gaps inner 5
gaps outer 5

# Borders
default_border pixel 2
default_floating_border pixel 2

# Focus follows mouse
focus_follows_mouse yes

# Start Waybar
bar {
    swaybar_command waybar
}

# Autostart
exec_always --no-startup-id mako

# Screenshot bindings
bindsym Print exec grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Print exec grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Volume controls (if using PipeWire)
bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Brightness controls
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
EOF
        log_success "Sway config created"
    fi
    
    log_success "Sway setup complete"
}

setup_waybar() {
    log_info "Setting up Waybar..."
    
    mkdir -p ~/.config/waybar
    
    # Create Waybar config
    cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    
    "modules-left": ["sway/workspaces", "sway/mode", "sway/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],
    
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true
    },
    
    "clock": {
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format": "{:%a %d %b  %H:%M}"
    },
    
    "cpu": {
        "format": " {usage}%",
        "tooltip": false
    },
    
    "memory": {
        "format": " {}%"
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": " {signalStrength}%",
        "format-ethernet": " {ipaddr}",
        "format-disconnected": "⚠ Disconnected",
        "tooltip-format": "{ifname}: {ipaddr}"
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " muted",
        "format-icons": {
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    },
    
    "tray": {
        "spacing": 10
    }
}
EOF

    # Create Waybar style
    cat > ~/.config/waybar/style.css << 'EOF'
* {
    font-family: "JetBrains Mono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
}

window#waybar {
    background-color: rgba(30, 30, 46, 0.9);
    color: #cdd6f4;
    border-bottom: 2px solid #45475a;
}

#workspaces button {
    padding: 0 10px;
    color: #6c7086;
    background-color: transparent;
    border-radius: 0;
}

#workspaces button:hover {
    background: rgba(69, 71, 90, 0.4);
}

#workspaces button.focused {
    color: #a6e3a1;
    border-bottom: 2px solid #a6e3a1;
}

#clock,
#battery,
#cpu,
#memory,
#network,
#pulseaudio,
#tray {
    padding: 0 10px;
}

#battery.charging, #battery.plugged {
    color: #a6e3a1;
}

#battery.critical:not(.charging) {
    color: #f38ba8;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

@keyframes blink {
    to {
        color: #1e1e2e;
        background-color: #f38ba8;
    }
}
EOF

    log_success "Waybar setup complete"
}

setup_alacritty() {
    log_info "Setting up Alacritty..."
    
    mkdir -p ~/.config/alacritty
    
    cat > ~/.config/alacritty/alacritty.toml << 'EOF'
# Alacritty Configuration

[window]
padding = { x = 10, y = 10 }
decorations = "full"
opacity = 0.95
dynamic_title = true

[scrolling]
history = 10000
multiplier = 3

[font]
normal = { family = "JetBrains Mono Nerd Font", style = "Regular" }
bold = { family = "JetBrains Mono Nerd Font", style = "Bold" }
italic = { family = "JetBrains Mono Nerd Font", style = "Italic" }
size = 11.0

[cursor]
style = { shape = "Block", blinking = "On" }
blink_interval = 750

[keyboard]
bindings = [
    { key = "V", mods = "Control|Shift", action = "Paste" },
    { key = "C", mods = "Control|Shift", action = "Copy" },
]

# Catppuccin Mocha theme
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.cursor]
text = "#1e1e2e"
cursor = "#f5e0dc"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#bac2de"

[colors.bright]
black = "#585b70"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#a6adc8"
EOF

    log_success "Alacritty setup complete"
}

setup_programming_languages() {
    if [ "$INSTALL_PYTHON" = true ]; then
        log_info "Installing Python..."
        sudo pacman -S --needed --noconfirm python python-pip python-pipx
    fi
    
    if [ "$INSTALL_NODEJS" = true ]; then
        log_info "Installing Node.js..."
        sudo pacman -S --needed --noconfirm nodejs npm
        
        # Install nvm for version management
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    
    if [ "$INSTALL_RUST" = true ]; then
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    
    if [ "$INSTALL_GO" = true ]; then
        log_info "Installing Go..."
        sudo pacman -S --needed --noconfirm go
    fi
    
    log_success "Programming languages installed"
}

enable_services() {
    log_info "Enabling system services..."
    
    # NetworkManager
    sudo systemctl enable --now NetworkManager
    
    # Bluetooth
    sudo systemctl enable --now bluetooth
    
    # Docker
    if command -v docker &> /dev/null; then
        sudo systemctl enable --now docker
        sudo usermod -aG docker $USER
        log_info "Added user to docker group (re-login required)"
    fi
    
    # PipeWire user services
    systemctl --user enable --now pipewire
    systemctl --user enable --now pipewire-pulse
    systemctl --user enable --now wireplumber
    
    log_success "Services enabled"
}

create_directories() {
    log_info "Creating user directories..."
    
    mkdir -p ~/Pictures/screenshots
    mkdir -p ~/Documents
    mkdir -p ~/Downloads
    mkdir -p ~/Projects
    mkdir -p ~/dev
    mkdir -p ~/.local/bin
    
    log_success "Directories created"
}

print_post_install() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Installation Complete!                     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Post-installation steps:${NC}"
    echo ""
    echo "1. Reboot your system:"
    echo "   sudo reboot"
    echo ""
    echo "2. Start Sway from TTY:"
    echo "   sway"
    echo ""
    echo "3. Install Neovim plugins:"
    echo "   nvim +PlugInstall +qall"
    echo ""
    echo "4. Install Tmux plugins:"
    echo "   Press prefix + I (Ctrl+b then Shift+I) in tmux"
    echo ""
    echo "5. Configure Git:"
    echo "   git config --global user.name \"Your Name\""
    echo "   git config --global user.email \"your@email.com\""
    echo ""
    echo -e "${BLUE}Sway Keybindings:${NC}"
    echo "   Super+Enter     - Open terminal"
    echo "   Super+d         - Open app launcher"
    echo "   Super+Shift+q   - Close window"
    echo "   Super+Shift+e   - Exit Sway"
    echo ""
}

#######################################################
# MAIN SCRIPT
#######################################################

main() {
    print_banner
    
    log_info "Starting Arch Linux setup..."
    log_info "This script will install and configure your system"
    echo ""
    
    if ! confirm "Do you want to continue?"; then
        log_warn "Setup cancelled"
        exit 0
    fi
    
    echo ""
    
    # Run setup steps
    update_system
    configure_pacman
    install_aur_helper
    
    log_info "Installing base packages..."
    install_packages "${BASE_PACKAGES[@]}"
    
    log_info "Installing Sway and Wayland packages..."
    install_packages "${SWAY_PACKAGES[@]}"
    
    log_info "Installing audio packages..."
    install_packages "${AUDIO_PACKAGES[@]}"
    
    log_info "Installing Bluetooth packages..."
    install_packages "${BLUETOOTH_PACKAGES[@]}"
    
    log_info "Installing fonts..."
    install_packages "${FONT_PACKAGES[@]}"
    
    log_info "Installing terminal packages..."
    install_packages "${TERMINAL_PACKAGES[@]}"
    
    if [ "$INSTALL_DEV_TOOLS" = true ]; then
        log_info "Installing development packages..."
        install_packages "${DEV_PACKAGES[@]}"
    fi
    
    log_info "Installing utility packages..."
    install_packages "${UTILITY_PACKAGES[@]}"
    
    # AUR packages
    if confirm "Install AUR packages (VS Code, Chrome, Spotify)?"; then
        install_aur_packages "${AUR_PACKAGES[@]}"
    fi
    
    # Setup configurations
    setup_shell
    setup_neovim
    setup_tmux
    setup_sway
    setup_waybar
    setup_alacritty
    setup_programming_languages
    
    # Create directories
    create_directories
    
    # Enable services
    enable_services
    
    # Print post-install instructions
    print_post_install
}

# Run main function
main "$@"
