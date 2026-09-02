# MicDefault — compilar en CachyOS (Arch) e instalar en el iPhone 6s por SSH

No lo he podido compilar yo: necesita el SDK de iOS (frameworks Foundation/AVFoundation),
que es propiedad de Apple. Tampoco tengo forma de conectarme a tu iPhone ni a tu equipo.
Esto deja todo listo para que en CachyOS solo sea `make package` y un `scp`.

## 1. Dependencias en CachyOS
Theos en Linux usa su propio toolchain (clang con soporte de targets Darwin/arm64
más el SDK de iOS embebido que trae el propio instalador, no necesitas Xcode).
Con `pacman` cubres casi todo; `ldid` (firmador de binarios que Theos necesita en
Linux) solo está en AUR, así que va con `paru`, como ya lo tienes configurado:

```bash
sudo pacman -Syu --needed curl git perl base-devel coreutils xz clang lld
paru -S --needed ldid-git
```

## 2. Instalar Theos en tu equipo
```bash
export THEOS=~/theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
echo 'export THEOS=$HOME/theos' >> ~/.bashrc
echo 'export THEOS_PACKAGE_SCHEME=rootless' >> ~/.bashrc
source ~/.bashrc
```
Esto descarga también `theos-sdk` (headers + stubs de las frameworks de iOS necesarios
para linkar, sin necesitar Xcode real) y `ldid` para firmar los binarios en Linux.

## 3. Compilar el proyecto
```bash
# descomprime MicDefault.zip donde quieras, por ejemplo ~/MicDefault
cd ~/MicDefault
make clean
make package FINALPACKAGE=1
```
El `.deb` resultante queda en `~/MicDefault/packages/`.

## 4. Habilitar SSH en el iPhone (si no lo tienes ya)
Desde Sileo en el propio 6s: instala `openssh` (repo Procursus/BigBoss). Arranca con
`sudo dpkg-reconfigure openssh-server` si hace falta, y anota la IP del iPhone (Ajustes >
Wi-Fi > icono (i) de la red conectada).

## 5. Copiar e instalar desde CachyOS
```bash
scp packages/*.deb mobile@<IP_DEL_IPHONE>:/tmp/
ssh mobile@<IP_DEL_IPHONE> "sudo dpkg -i /tmp/$(basename packages/*.deb)"
```
Si CachyOS te bloquea el `scp` por firewall, revisa `sudo ufw status` o el equivalente
con `firewalld`/`nftables` que tengas activo por defecto en esa instalación.

(usuario/contraseña por defecto en jailbreaks palera1n suele ser `mobile`/`alpine` y
`root`/`alpine` — cámbialas si no lo has hecho ya, es lo primero que se prueba en
cualquier escaneo de red).

## 6. Uso, ya en el iPhone (por SSH o NewTerm2)
```bash
/var/jb/usr/bin/micdefault list
/var/jb/usr/bin/micdefault set front
/var/jb/usr/bin/micdefault get
```

Tras `set`, relanza la app en cuestión (no hace falta respring; el hook lee el plist
en cada `setActive:` de AVAudioSession).

## Limitación conocida
Esto controla el mic por defecto solo en apps de terceros que enlazan UIKit y usan
`AVAudioSession` en su propio proceso (WhatsApp, Cámara, grabadoras...). No cubre
Siri ni el daemon de llamadas, que gestionan audio directamente vía `mediaserverd`,
fuera del alcance de este hook.
