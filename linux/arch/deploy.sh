#!/bin/bash

#######################################################
# Deploy Configurations Script
# Copies all config files to their proper locations
#######################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Create backup
backup_existing() {
    local target=$1
    if [ -e "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$target" "$BACKUP_DIR/"
        log_warn "Backed up existing $target to $BACKUP_DIR"
    fi
}

# Deploy function
deploy_config() {
    local source=$1
    local target=$2
    
    if [ -e "$source" ]; then
        backup_existing "$target"
        mkdir -p "$(dirname "$target")"
        cp -r "$source" "$target"
        log_success "Deployed $target"
    else
        log_warn "Source $source not found, skipping"
    fi
}

echo -e "${BLUE}Deploying configurations...${NC}"
echo ""

# Sway
deploy_config "$SCRIPT_DIR/sway/config" "$HOME/.config/sway/config"

# Waybar
deploy_config "$SCRIPT_DIR/waybar/config" "$HOME/.config/waybar/config"
deploy_config "$SCRIPT_DIR/waybar/style.css" "$HOME/.config/waybar/style.css"

# Wofi
deploy_config "$SCRIPT_DIR/wofi/config" "$HOME/.config/wofi/config"
deploy_config "$SCRIPT_DIR/wofi/style.css" "$HOME/.config/wofi/style.css"

# Mako
deploy_config "$SCRIPT_DIR/mako/config" "$HOME/.config/mako/config"

# Alacritty (from install script or separate file)
if [ -f "$SCRIPT_DIR/alacritty/alacritty.toml" ]; then
    deploy_config "$SCRIPT_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
fi

# Neovim (from main dotfiles)
if [ -d "$SCRIPT_DIR/../../nvim/nvim" ]; then
    deploy_config "$SCRIPT_DIR/../../nvim/nvim" "$HOME/.config/nvim"
fi

# Tmux (from main dotfiles)
if [ -f "$SCRIPT_DIR/../../tmux/tmux_backup/.tmux.conf" ]; then
    deploy_config "$SCRIPT_DIR/../../tmux/tmux_backup/.tmux.conf" "$HOME/.tmux.conf"
fi

echo ""
log_success "All configurations deployed!"

if [ -d "$BACKUP_DIR" ]; then
    log_info "Backups saved to: $BACKUP_DIR"
fi

echo ""
echo "To apply changes:"
echo "  - Sway: Press \$mod+Shift+c to reload"
echo "  - Waybar: killall waybar && waybar &"
echo "  - Mako: makoctl reload"
