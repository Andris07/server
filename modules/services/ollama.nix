{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    host = "127.0.0.1";
    port = 11434;
    # RX 9070 is gfx1201; RX 9070 XT is gfx1201 too.
    # Leave rocmOverrideGfx unset unless ROCm fails to identify the card.
  };
}
