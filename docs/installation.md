# NixOS server installation (Live USB)

This guide installs the standalone `server` configuration onto the **1 TB Kingston KC3000 only**. It leaves the 2 TB Windows 11 SSD and 4 TB WD Gold HDD alone.

> **Destructive operation:** Disko will partition and format the device specified in `hosts/server/disko.nix`. Do not continue until that path is confirmed to be the 1 TB KC3000. A wrong device path can erase Windows or media data.

## 1. Boot the NixOS installer

1. Create and boot a NixOS minimal or graphical Live USB in UEFI mode.
2. Connect to the network.
3. Open a terminal and become root:

```bash
sudo -i
```

## 2. Identify the 1 TB KC3000

Do not assume it is `/dev/nvme0n1`. List disks and their model/serial identifiers:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/ | grep -i nvme
```

Find the Kingston KC3000 with approximately 1 TB capacity. Copy its stable `/dev/disk/by-id/...` path (prefer the whole-drive identifier, not a `-part1` entry).

Double-check that the 2 TB Windows SSD and the 4 TB WD Gold are different devices. If uncertain, stop and verify before proceeding.

## 3. Get the repository

If this repository is already published to your Git hosting service:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  run nixpkgs#git -- clone YOUR_REPOSITORY_URL /root/server-nixos
cd /root/server-nixos
```

Alternatively, copy the repository onto the Live USB environment at `/root/server-nixos` and `cd` into its root. Replace `YOUR_REPOSITORY_URL` with the actual clone URL; it is intentionally not guessed here.

## 4. Set the Disko target

Edit the Disko file:

```bash
vim hosts/server/disko.nix
```

Replace:

```nix
device = "/dev/disk/by-id/REPLACE_WITH_1TB_KINGSTON_KC3000_ID";
```

with the exact stable whole-disk ID you identified in step 2.

Read the file again and verify that this is the 1 TB KC3000. The 2 TB Windows drive and 4 TB WD Gold must not appear as Disko targets.

## 5. Partition, encrypt, and mount

This command destroys the target disk, creates the EFI partition, creates the LUKS2 container and Btrfs subvolumes, and mounts them under `/mnt`:

```bash
nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#server
```

Set a strong LUKS passphrase when prompted. You will need it on every boot. Do not lose it.

Verify the resulting layout:

```bash
lsblk -f
findmnt -R /mnt
```

Check carefully that only the intended 1 TB KC3000 has been partitioned. The Windows SSD and WD Gold must remain unchanged.

## 6. Put the repository on the installed system and generate hardware configuration

After Disko has mounted the target filesystems, copy the repository from the Live environment into the persistent home subvolume. The configured `nh` command expects this exact location:

```bash
mkdir -p /mnt/home/andris
cp -a /root/server-nixos /mnt/home/andris/server-nixos
chown -R 1000:100 /mnt/home/andris/server-nixos
cd /mnt/home/andris/server-nixos
nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix`. Copy it into the repository host directory:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/server/hardware-configuration.nix
```

Open the generated file and inspect it. Replace the repository's generic `hosts/server/hardware-configuration.nix` with the generated file. Because Disko already defines the filesystems, remove any duplicate `fileSystems` and `swapDevices` declarations from the generated file, but retain hardware-specific kernel modules/initrd settings. Do not leave stale UUIDs from another installation.

## 7. Install

The first evaluation creates `flake.lock`; keep it in the repository and commit it after installation:

```bash
nix flake lock
nixos-install --root /mnt --flake /mnt/home/andris/server-nixos#server
```

Set the root password when asked. When installation completes, reboot and remove the Live USB:

```bash
reboot
```

Unlock the encrypted system volume with the LUKS passphrase. Log in as `root` and set the normal user's password:

```bash
passwd andris
```

Then log in as `andris`. The account is in `wheel` and `networkmanager`; the first login starts Home Manager activation. If Ly does not appear, switch to a TTY and inspect the boot/service logs.

## 8. First update and service checks

From the installed system:

```bash
cd /home/andris/server-nixos
sudo nixos-rebuild switch --flake .#server
systemctl status sshd
systemctl status ollama
systemctl status open-webui
systemctl status jellyfin
```

Useful local endpoints:

- Open WebUI: `http://localhost:8080`
- Jellyfin: `http://localhost:8096`
- Ollama API (local only): `http://127.0.0.1:11434`

From another device on the same LAN, use the server's LAN IP for WebUI and Jellyfin. Do not expose these services directly to the public internet without a deliberate reverse-proxy, authentication, TLS, and firewall plan.

## 9. Add the media HDD

Follow `docs/storage.md`. The WD Gold is not auto-formatted and is not mounted until its actual filesystem UUID and type are known.

## 10. Check AMD GPU acceleration

The RX 9070 is listed as supported by current ROCm documentation and current Ollama GPU documentation. The NixOS configuration selects `pkgs.ollama-rocm`, but actual acceleration must be verified on the installed kernel/ROCm package combination:

```bash
nix shell nixpkgs#rocmPackages.rocminfo -c rocminfo | grep -E 'Name:|gfx'
journalctl -u ollama -b --no-pager | tail -n 100
ollama run llama3.2:3b
```

While a model is running, check `btop`/GPU monitoring and Ollama logs to ensure it is not silently falling back to CPU. Do not set `rocmOverrideGfx` preemptively; only investigate it if ROCm fails to identify the card.

## Important note about the graphical session

Hyprland + Caelestia is included as the local console desktop. The machine remains configured as a server: SSH and the background services run independently of whether the graphical session is logged in.
