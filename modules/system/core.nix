{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim wget curl git gh tree unzip zip ripgrep fd jq btop file
    pciutils usbutils lm_sensors smartmontools nvme-cli
    fastfetch nil nixfmt
  ];

  programs.nh = {
    enable = true;
    flake = "/home/andris/server-nixos";
  };
}
