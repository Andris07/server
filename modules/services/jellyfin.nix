{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # The HDD is intentionally NOT partitioned or formatted by this repository.
  # Mount it at /srv/media after identifying its filesystem UUID; see docs/storage.md.
  systemd.tmpfiles.rules = [ "d /srv/media 0755 jellyfin jellyfin - -" ];
}
