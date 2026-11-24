{
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -lah";
      rebuild = "nh os switch";
      update = "nix flake update";
    };
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
