# NixOS telepítési útmutató – főgép

Ez az útmutató a különálló `server-nixos` flake telepítésére készült a főgépedre.

## 0. A gép és a céllemezek

A jelenlegi hardvered alapján az alábbiakkal számolunk:

| Eszköz | Feladat | Telepítő érinti? |
|---|---|---|
| 2 TB Kingston KC3000 | Windows 11 | **Nem. Semmiképpen ne válaszd ki Disko céllemezeként.** |
| 1 TB Kingston KC3000 | NixOS | **Igen, ezt fogja újraparticionálni és formázni.** |
| 4 TB WD Gold HDD | Jellyfin médiatár | **Nem. A telepítés nem formázza és nem particionálja.** |
| 240 GB Kingston A400 SATA SSD | Egyelőre nem használjuk | Nem |

> **ADATVESZTÉSI FIGYELMEZTETÉS:** a Disko törli a kiválasztott 1 TB-os SSD teljes partíciós tábláját és tartalmát. A telepítés előtt készíts biztonsági mentést minden fontos adatról. A 2 TB-os Windows SSD-t és a 4 TB-os HDD-t lehetőleg fizikailag is húzd le a telepítés idejére, ha ezt kényelmesen meg tudod tenni. Ha nem húzod le őket, a `/dev/disk/by-id/` azonosítóval akkor is különösen körültekintően ellenőrizd a céllemezt.

## 1. NixOS Live USB

1. Töltsd le a hivatalos NixOS **Graphical ISO**-t.
2. Írd ki USB-re egy USB-író programmal.
3. UEFI módban bootolj róla.
4. Csatlakozz az internethez – lehetőleg Ethernettel.
5. Nyiss terminált, és válts root shellre:

```bash
sudo -i
```

Ellenőrizd a hálózatot:

```bash
ping -c 3 nixos.org
```

## 2. Repository letöltése

A saját Git repository URL-edet használd:

```bash
nix-shell -p git
cd /root
git clone <SERVER_REPOSITORY_URL> server-nixos
cd /root/server-nixos
```

Ha a repository már korábban le lett klónozva, frissítéshez:

```bash
git pull --ff-only
```

A további parancsokat a repository gyökeréből futtasd.

## 3. Az 1 TB-os Kingston KC3000 pontos azonosítása

Listázd a lemezeket:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS
```

Listázd az NVMe azonosítókat:

```bash
ls -l /dev/disk/by-id/ | grep -i nvme
```

Keresd meg az **1 TB-os Kingston KC3000** teljes lemezazonosítóját. A lemezazonosító nem végződhet `-part1`, `-part2` stb. szöveggel.

A kiválasztott azonosítót ellenőrizd vissza:

```bash
readlink -f /dev/disk/by-id/IDE_MASOLD_BE_AZ_AZONOSITOT
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS "$(readlink -f /dev/disk/by-id/IDE_MASOLD_BE_AZ_AZONOSITOT)"
```

**Ne folytasd**, amíg a modell és a kapacitás alapján nem bizonyos, hogy a kiválasztott eszköz az 1 TB-os KC3000. Ne használj találomra `/dev/nvme0n1` vagy `/dev/nvme1n1` útvonalat.

## 4. Disko céllemez beállítása

Nyisd meg:

```bash
nano hosts/server/disko.nix
```

A fájl elején ezt a sort:

```nix
device = "/dev/disk/by-id/REPLACE_WITH_1TB_KC3000_ID";
```

cseréld le a 3. lépésben ellenőrzött, teljes 1 TB-os KC3000 azonosítóra. Példa formátum (ne másold be szó szerint):

```nix
device = "/dev/disk/by-id/nvme-KINGSTON_SKC3000...";
```

Mentsd el a fájlt, majd olvasd vissza, és ellenőrizd még egyszer:

```bash
grep 'device =' hosts/server/disko.nix
```

## 5. Tervezett partíció- és Btrfs-elrendezés

A Disko a következő struktúrát hozza létre **kizárólag az 1 TB-os SSD-n**:

| Elem | Csatolási pont / cél | Titkosítás |
|---|---|---|
| 1 GiB EFI System Partition | `/boot` | Nem |
| A fennmaradó terület LUKS2 konténerként | Btrfs fájlrendszert tartalmaz | Igen |
| Btrfs `@root` subvolume | `/` | Igen |
| Btrfs `@home` subvolume | `/home` | Igen |
| Btrfs `@nix` subvolume | `/nix` | Igen |
| Btrfs `@var-log` subvolume | `/var/log` | Igen |
| Btrfs `@ollama` subvolume | `/var/lib/ollama` | Igen |
| Btrfs `@jellyfin` subvolume | `/var/lib/jellyfin` | Igen |
| Btrfs `@swap` subvolume + 16 GiB swapfile | `/.swapvol` | Igen |

A subvolume-ok **nem külön partíciók és nem foglalnak le előre rögzített méretet**: ugyanazon Btrfs fájlrendszer szabad helyén osztoznak. A zram swap is engedélyezett. A hibernálás nincs beállítva.

Az EFI partíció titkosítatlan, hogy az UEFI el tudja olvasni a bootfájlokat. A többi SSD-terület LUKS2-vel titkosított. A konfiguráció nem engedélyezi az `allowDiscards` opciót.

## 6. LUKS jelszó és partícionálás

Hozz létre egy ideiglenes kulcsfájlt a Live USB munkamenetében:

```bash
umask 077
read -rsp "LUKS jelszó: " LUKS_PASSWORD
echo
printf '%s' "$LUKS_PASSWORD" > /tmp/server-luks.key
unset LUKS_PASSWORD
chmod 600 /tmp/server-luks.key
```

A jelszót biztonságosan tárold el. Ha elveszíted a jelszót és nincs más használható helyreállítási kulcsod, a titkosított adatok nem lesznek visszaállíthatók. A korai boot jelszókérésnél a billentyűzetkiosztás eltérhet, ezért olyan jelszót válassz, amelyet az initramfs kiosztásával is biztosan be tudsz írni.

**Utolsó ellenőrzés a formázás előtt:**

```bash
cat hosts/server/disko.nix | grep 'device ='
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
```

Csak akkor indítsd el a Diskót, ha a konfigurációban szereplő eszköz biztosan az 1 TB-os KC3000.

```bash
nix run github:nix-community/disko/latest -- --mode destroy,format,mount ./hosts/server/disko.nix
```

Ez a parancs törli és újraparticionálja a megadott lemezt. Ne futtasd újra csak azért, mert egy későbbi telepítési lépés hibát jelez.

Ellenőrizd a létrejött csatolásokat:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
findmnt -R /mnt
swapon --show
```

Akkor folytasd, ha a `/mnt`, `/mnt/boot`, `/mnt/home`, `/mnt/nix`, `/mnt/var/log`, `/mnt/var/lib/ollama` és `/mnt/var/lib/jellyfin` csatolások rendben vannak, és a swapfile is létrejött.

## 7. Hardverkonfiguráció generálása

A Disko már létrehozta és `/mnt` alá csatolta a célrendszer fájlrendszereit. Generáld le a gép hardverkonfigurációját a fájlrendszer-definíciók nélkül:

```bash
nixos-generate-config --root /mnt --no-filesystems
```

Másold át a hardverkonfigurációt a repositoryba:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/server/hardware-configuration.nix
```

Ellenőrizd, hogy a fájlban ne legyenek Disko által már kezelt `fileSystems` vagy `swapDevices` bejegyzések. A `--no-filesystems` opció miatt ezeknek nem kell szerepelniük.

## 8. Felhasználói jelszó hash létrehozása

A konfiguráció az `andris` felhasználó jelszóhashét innen olvassa:

`/var/lib/secrets/andris-password`

Hozd létre a célrendszeren:

```bash
mkdir -p /mnt/var/lib/secrets
nix shell nixpkgs#whois -c mkpasswd -m sha-512 | tee /mnt/var/lib/secrets/andris-password >/dev/null
chmod 600 /mnt/var/lib/secrets/andris-password
```

A `mkpasswd` bekéri a jelszót. A hash ne kerüljön be a Git repositoryba.

## 9. Flake lock, ellenőrzés és build

A repository első használatakor generáld le a lockfile-t:

```bash
nix flake lock
```

Ellenőrizd a flake kiértékelését:

```bash
nix flake check --no-build
```

Ez kiértékelési ellenőrzés, nem teljes buildteszt. Ezután buildeld le a célrendszert:

```bash
nix build .#nixosConfigurations.server.config.system.build.toplevel --no-link --show-trace
```

Ha bármelyik parancs hibával leáll, **ne telepíts tovább**: először a hiba okát kell megoldani.

## 10. NixOS telepítése

Ha a Disko csatolásai, a hardverkonfiguráció, a jelszóhash és a build is rendben van:

```bash
nixos-install --flake .#server
```

Sikeres telepítés után:

```bash
sync
reboot
```

Távolítsd el az USB-t, majd bootolj az 1 TB-os SSD-ről. A rendszer indulásakor add meg a LUKS jelszót, majd jelentkezz be `andris` felhasználóként.

## 11. Első indítás utáni ellenőrzés

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
findmnt / /home /nix /var/log /var/lib/ollama /var/lib/jellyfin
swapon --show
systemctl --failed
```

Grafikus felület:

- A Ly bejelentkezőkezelőnek el kell indulnia.
- Válaszd a Hyprlandet.
- A Caelestia shell automatikusan elindul.
- `Super + Enter`: Alacritty.
- `Super + D`: Fuzzel.
- `Super + Shift + E`: Hyprland kilépés.

Szolgáltatások:

```bash
systemctl status ollama
systemctl status open-webui
systemctl status jellyfin
systemctl status sshd
```

Az Ollama RX 9070 gyorsítását külön is ellenőrizd. Az RX 9070 támogatott GPU-ként szerepel az Ollama aktuális ROCm dokumentációjában, de a NixOS-csomag és a ROCm runtime tényleges együttműködését a telepített verziókkal kell validálni. Ha a GPU nem jelenik meg, először a szolgáltatás naplóit vizsgáld:

```bash
journalctl -u ollama -b --no-pager
```

## 12. A 4 TB-os WD Gold médiatár beállítása

A 4 TB-os HDD-t a telepítési Disko-konfiguráció **nem formázza és nem particionálja**. Ez szándékos: a HDD tartalmát külön kell ellenőrizni, és csak akkor szabad formázni, ha biztosan nincs rajta megtartandó adat.

Azonosítsd a lemezt:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,UUID,MOUNTPOINTS
```

Ha már van rajta megtartandó fájlrendszer és adat, ne formázd. A későbbi beállításhoz a tényleges UUID-t és fájlrendszert használd. Ha üres, és kifejezetten médiatárolónak készíted elő, választhatsz ext4 fájlrendszert és `MEDIA` címkét – ez a művelet minden meglévő adatot törölne a HDD-ről.

A kívánt csatolási pont:

```text
/srv/media
```

A Jellyfin médiakönyvtárait majd ezen belül hozd létre (például `/srv/media/Movies` és `/srv/media/TV`). A HDD formázása és automatikus csatolása külön, ellenőrzött lépés legyen; a jelenlegi flake szándékosan nem találgatja a HDD UUID-jét.

## 13. Frissítés és későbbi build

A repository frissítése:

```bash
cd /root/server-nixos
git pull --ff-only
nix flake lock
```

Build a futó rendszer módosítása nélkül:

```bash
nix build .#nixosConfigurations.server.config.system.build.toplevel --no-link
```

A konfiguráció aktiválása:

```bash
sudo nixos-rebuild switch --flake .#server
```

**Ne futtasd a Disko formázó parancsát normál frissítéskor vagy `switch` előtt.** A Disko konfiguráció csak a telepítési lemezelrendezést írja le; a `nixos-rebuild switch` nem particionálja újra az SSD-t.

---

## Fontos architekturális megjegyzés

Ez a repository önálló NixOS-konfiguráció. A meglévő `nixos_flake_config` repositoryt nem módosítja, és később egy külön szervergépre is önmagában klónozható.

Mivel a meglévő repository `hosts/desktop/filesystems.nix` fájlja jelenleg konkrét, korábbi UUID-ket használ, **ne válts át automatikusan annak `desktop` targetjére ezen az új telepítésen**. Ahhoz előbb a két konfiguráció közös lemez- és mountstratégiáját kell összehangolni. A jelenlegi telepítési útmutató a `server` flake önálló telepítését végzi el; nem állítja, hogy a változatlan régi desktop target már kompatibilis az újonnan particionált 1 TB-os SSD-vel.
