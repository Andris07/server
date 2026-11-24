{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/boot/grub.nix
    ../../modules/desktop/base.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/hardware/amd.nix
    ../../modules/services/jellyfin.nix
    ../../modules/services/ollama.nix
    ../../modules/services/open-webui.nix
    ../../modules/services/openssh.nix
    ../../modules/system/core.nix
    ../../modules/system/home-manager.nix
    ../../modules/system/locale.nix
    ../../modules/system/networking.nix
    ../../modules/system/nix.nix
    ../../modules/system/users.nix
    ../../modules/system/zram.nix
  ];

  networking.hostName = "server";
  system.stateVersion = "26.05";
}
