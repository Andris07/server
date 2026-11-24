{
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = false;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };
}
