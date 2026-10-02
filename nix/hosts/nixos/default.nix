{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/remote-access.nix
  ];

  networking.hostName = "nixos";

  # Keep this at the version used for the initial NixOS installation.
  system.stateVersion = "26.05";
}
