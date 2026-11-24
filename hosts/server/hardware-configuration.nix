# Generated during installation with:
# nixos-generate-config --root /mnt --no-filesystems
# Replace this file with the generated hardware-configuration.nix.
{ ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
}
