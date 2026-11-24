{ pkgs, inputs, ... }:
{
  programs.firefox.enable = true;
  home.packages = with pkgs; [
    vscode
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
  ];
}
