# Standalone NixOS server

A self-contained NixOS Flakes configuration based on the original `nixos_flake_config` repository. This repository targets the main PC as a **server with a local Hyprland + Caelestia desktop session**.

## Included

- NixOS Unstable + Flakes + Home Manager + Disko
- LUKS2-encrypted Btrfs on the dedicated 1 TB Kingston KC3000
- Hyprland, Ly, Alacritty, Fuzzel and Caelestia Shell
- AMD graphics and ROCm-enabled Ollama package for the RX 9070
- Open WebUI, Jellyfin, OpenSSH
- NetworkManager, zram, btop, SMART/NVMe and system tools

## Important storage boundary

The Disko layout in `hosts/server/disko.nix` must point **only** to the 1 TB KC3000. It must never point to the 2 TB Windows SSD or the 4 TB WD Gold media HDD. The Disko operation is destructive. The media HDD is deliberately not formatted or partitioned by this repository.

Read `docs/installation.md` before installing and `docs/storage.md` before mounting the media HDD.

## Build / switch after installation

```bash
cd /home/andris/server-nixos
sudo nixos-rebuild switch --flake .#server
```

Update inputs deliberately, then rebuild:

```bash
nix flake update
sudo nixos-rebuild switch --flake .#server
```

The initial `flake.lock` is generated on the first evaluation. Commit it to Git so future installs use the same dependency revisions.
