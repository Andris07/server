# Configuration map

This repository is independent from the laptop/desktop configuration repository. It has one flake output: `nixosConfigurations.server`.

```text
flake.nix
hosts/server/
  configuration.nix
  disko.nix
modules/
  boot/       GRUB EFI
  desktop/    Ly, PipeWire, Hyprland
  hardware/   AMD graphics and CPU
  services/   Ollama, Open WebUI, Jellyfin, SSH
  system/     packages, Home Manager, locale, network, Nix, user, zram
home/andris/  Home Manager user configuration
 docs/        installation and storage guides
```

The original repository's useful conventions are retained: modular NixOS modules, Home Manager for `andris`, Hungarian locale/keyboard, Flakes, Hyprland Lua configuration, Alacritty, Fuzzel, and the `rebuild` alias. Laptop/desktop host switching and unrelated Niri configuration are intentionally excluded.
