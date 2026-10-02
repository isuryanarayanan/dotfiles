{ ... }:

{
  imports = [
    ../modules/home
  ];

  home.username = "suryan";
  home.homeDirectory = "/home/suryan";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
