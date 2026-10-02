# Setup - NixOS

NixOS uses the repository flake and Home Manager rather than the imperative `setup.sh` flow used on macOS and conventional Linux distributions.

## Design

- NixOS modules manage the host, services, login shell, and system behavior.
- Home Manager installs user-facing CLI packages.
- Home Manager creates out-of-store symlinks to `~/dotfiles`, keeping managed configuration writable and Git-visible.
- The flake tracks `nixos-unstable` for a simple, current package set; `system.stateVersion` remains at the original installation value.
- Credentials, sessions, caches, and other machine state remain outside the repository.

## Initial installation

Clone the repository using HTTPS because a fresh host may not have SSH keys yet:

```bash
git clone https://github.com/isuryanarayanan/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Enable flakes for the initial commands without changing the existing system configuration:

```bash
nix flake lock --extra-experimental-features "nix-command flakes"
nix flake check --extra-experimental-features "nix-command flakes"
```

Build the NixOS configuration without activating it:

```bash
sudo nixos-rebuild build \
  --flake ~/dotfiles#nixos \
  --extra-experimental-features "nix-command flakes"
```

Review the build, then test it for the current boot only:

```bash
sudo nixos-rebuild test \
  --flake ~/dotfiles#nixos \
  --extra-experimental-features "nix-command flakes"
```

When the test is healthy, make it the active boot configuration:

```bash
sudo nixos-rebuild switch \
  --flake ~/dotfiles#nixos \
  --extra-experimental-features "nix-command flakes"
```

The resulting system enables `nix-command` and `flakes`, so later rebuilds only need:

```bash
sudo nixos-rebuild switch --flake ~/dotfiles#nixos
```

## Managed host

The `nixos` host currently describes:

- x86_64 Linux with systemd-boot and EFI
- KDE Plasma 6 with SDDM
- NetworkManager, Tailscale, and OpenSSH
- PipeWire audio and printing
- user `suryan` with Zsh
- Home Manager packages and writable links to this repository

Hardware-specific filesystem UUIDs and kernel configuration live in:

```text
nix/hosts/nixos/hardware-configuration.nix
```

Do not reuse that file for another machine. Add another directory under `nix/hosts/` instead.

## Updating

Update pinned flake inputs:

```bash
cd ~/dotfiles
nix flake update
sudo nixos-rebuild switch --flake ~/dotfiles#nixos
```

Review and commit `flake.lock` after a successful update.

## Rollback

Reboot and select an older generation from the systemd-boot menu, or roll back immediately:

```bash
sudo nixos-rebuild switch --rollback
```

## Secrets and local state

Do not commit:

- SSH private keys
- Pi authentication, sessions, trust state, or caches
- Tailscale state
- service-account credentials
- host secrets or plaintext API keys

Password-based SSH remains enabled until key-based or Tailscale SSH access has been configured and tested.
