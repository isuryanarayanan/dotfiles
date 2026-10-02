{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    gcc
    ghostty
    gnumake
    kdePackages.kate
    lazygit
    neovim
    nodejs_22
    pi-coding-agent
    python311
    ripgrep
    starship
    tlrc
    tmux
    tmux-sessionizer
    tree-sitter
    unzip
    uv
    wl-clipboard
    xclip
    zoxide
  ];
}
