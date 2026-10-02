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
    ripgrep
    starship
    tlrc
    tmux
    tree-sitter
    unzip
    wl-clipboard
    xclip
    zoxide
  ];
}
