{ config, inputs, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file = {
    ".tmux.conf" = {
      source = link "${dotfiles}/tmux/.tmux.conf";
      force = true;
    };

    ".tmux/plugins/tpm" = {
      source = inputs.tpm;
      force = true;
    };

    ".tmux/plugins/tmux-sensible" = {
      source = "${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible";
      force = true;
    };

    ".tmux/plugins/tmux-yank" = {
      source = "${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank";
      force = true;
    };

    ".tmux/plugins/vim-tmux-navigator" = {
      source = "${pkgs.tmuxPlugins.vim-tmux-navigator}/share/tmux-plugins/vim-tmux-navigator";
      force = true;
    };

    ".tmux/plugins/tmux-sessionx" = {
      source = "${pkgs.tmuxPlugins.tmux-sessionx}/share/tmux-plugins/sessionx";
      force = true;
    };

    ".zshrc" = {
      source = link "${dotfiles}/zsh/.zshrc";
      force = true;
    };

    ".zshenv" = {
      source = link "${dotfiles}/zsh/.zshenv";
      force = true;
    };

    ".zprofile" = {
      source = link "${dotfiles}/zsh/.zprofile";
      force = true;
    };

    ".pi/agent/settings.json" = {
      source = link "${dotfiles}/pi/settings.json";
      force = true;
    };

    ".pi/agent/keybindings.json" = {
      source = link "${dotfiles}/pi/keybindings.json";
      force = true;
    };

    ".pi/agent/extensions" = {
      source = link "${dotfiles}/pi/extensions";
      force = true;
    };

    ".pi/agent/skills" = {
      source = link "${dotfiles}/pi/skills";
      force = true;
    };

    ".pi/agent/prompts" = {
      source = link "${dotfiles}/pi/prompts";
      force = true;
    };

    ".pi/agent/themes" = {
      source = link "${dotfiles}/pi/themes";
      force = true;
    };

    ".agents/.skill-lock.json" = {
      source = link "${dotfiles}/agents/.skill-lock.json";
      force = true;
    };

    ".agents/skills/find-skills" = {
      source = link "${dotfiles}/agents/skills/find-skills";
      force = true;
    };

    ".agents/skills/grill-me" = {
      source = link "${dotfiles}/agents/skills/grill-me";
      force = true;
    };
  };

  xdg.configFile = {
    "nvim" = {
      source = link "${dotfiles}/nvim/nvim";
      force = true;
    };

    "ghostty/config" = {
      source = link "${dotfiles}/ghostty/config";
      force = true;
    };

    "starship.toml" = {
      source = link "${dotfiles}/zsh/starship/starship.toml";
      force = true;
    };
  };
}
