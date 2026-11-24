# Storage layout and media HDD

## 1 TB Kingston KC3000 (NixOS system disk)

Disko creates a GPT layout with:

- 1 GiB EFI System Partition mounted at `/boot`
- Remaining space in a LUKS2 container
- Btrfs subvolumes mounted at `/`, `/home`, `/nix`, `/var/log`, `/var/lib/ollama`, `/var/lib/open-webui`, and `/var/lib/jellyfin`
- zstd compression and `noatime`

The model files, Open WebUI database/configuration and Jellyfin metadata therefore live in persistent subvolumes on the system SSD. A normal `nixos-rebuild switch` does not format or reset these paths.

The configuration uses zram and does not create a disk swap partition/file. With 32 GB RAM this is a reasonable initial setup; adjust later if your workloads show a need for disk-backed swap.

## 4 TB WD Gold HDD (media only)

The HDD is intentionally not part of the Disko layout. Do not run Disko against it. First identify it after installation:

```bash
lsblk -o NAME,SIZE,MODEL,FSTYPE,LABEL,UUID,MOUNTPOINTS
sudo blkid
```

If it already contains media, preserve its existing filesystem and use its UUID. If it is blank, decide on a filesystem and format it manually only after verifying the device model and capacity. Formatting erases the selected disk.

After obtaining the filesystem UUID, add a mount declaration to a new file such as `hosts/server/media-storage.nix`:

```nix
{
  fileSystems."/srv/media" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_WD_GOLD_FILESYSTEM_UUID";
    fsType = "ext4"; # Replace with the actual filesystem type.
    options = [ "nofail" "noatime" ];
  };
}
```

Then import `./media-storage.nix` in `hosts/server/configuration.nix` and rebuild. Do not guess the UUID or filesystem type. For NTFS, exFAT, or another filesystem, use its correct `fsType` and required package/support instead of `ext4`.

Create media folders and give Jellyfin read access, for example:

```bash
sudo mkdir -p /srv/media/{movies,series,music}
sudo chown -R jellyfin:jellyfin /srv/media
```

If you prefer to manage files as your normal user, use a shared group/ACL rather than making the whole media tree owned exclusively by Jellyfin.
