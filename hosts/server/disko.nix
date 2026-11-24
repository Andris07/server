# IMPORTANT: Replace the device path with the stable by-id path of the 1 TB KC3000.
# This is the ONLY disk this Disko layout is allowed to partition or format.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/REPLACE_WITH_1TB_KINGSTON_KC3000_ID";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/ollama" = {
                    mountpoint = "/var/lib/ollama";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/open-webui" = {
                    mountpoint = "/var/lib/open-webui";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/jellyfin" = {
                    mountpoint = "/var/lib/jellyfin";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
