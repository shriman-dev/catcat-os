#!/bin/bash
set -oue pipefail
pwd

pkgs(){
#btdu
curl -Lo /usr/bin/btdu https://github.com/CyberShadow/btdu/releases/latest/download/btdu-static-x86_64
chmod +x /usr/bin/btdu

# yazi
curl -Lo /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
curl -Lo /usr/share/applications/yazi.desktop https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main/assets/yazi.desktop
curl -Lo /usr/share/icons/yazi.png https://raw.githubusercontent.com/sxyazi/yazi/refs/heads/main/assets/logo.png

unzip /tmp/yazi.zip
cp -dvf yazi-x86_64-unknown-linux-gnu/yazi /usr/bin/
chmod +x /usr/bin/yazi

# ascii-image-converter
curl -Lo /tmp/ascii-image-converter.tar.gz https://github.com/TheZoraiz/ascii-image-converter/releases/latest/download/ascii-image-converter_Linux_amd64_64bit.tar.gz

mkdir -p /tmp/ascii-image-converter
tar -xf /tmp/ascii-image-converter.tar.gz -C /tmp/ascii-image-converter --strip-components=1

cp -dvf /tmp/ascii-image-converter/ascii-image-converter /usr/bin/
chmod +x /usr/bin/ascii-image-converter

# pipes.sh
git clone https://github.com/pipeseroni/pipes.sh.git /tmp/pipes.sh
cp -dvf /tmp/pipes.sh/pipes.sh /usr/bin/

# pokemonsay-newgenerations
git clone https://github.com/HRKings/pokemonsay-newgenerations.git /tmp/pokemonsay-newgenerations

cp -drf /tmp/pokemonsay-newgenerations/pokemons /usr/bin/
cp -dvf /tmp/pokemonsay-newgenerations/pokemonsay.sh /usr/bin/
cp -dvf /tmp/pokemonsay-newgenerations/pokemonthink.sh /usr/bin/


# dualsensectl
########


# extra
curl -Lo /usr/share/applications/micro.desktop https://raw.githubusercontent.com/zyedidia/micro/refs/heads/master/assets/packaging/micro.desktop



cd /tmp/files/scripts
}
pkgs
