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

unzip /tmp/yazi.zip
cp -vf yazi-x86_64-unknown-linux-gnu/yazi /usr/bin/
chmod +x /usr/bin/yazi

# ascii-image-converter
curl -Lo /tmp/ascii-image-converter.tar.gz https://github.com/TheZoraiz/ascii-image-converter/releases/latest/download/ascii-image-converter_Linux_amd64_64bit.tar.gz

mkdir -p /tmp/ascii-image-converter
tar -xf /tmp/ascii-image-converter.tar.gz -C /tmp/ascii-image-converter --strip-components=1

cp -vf /tmp/ascii-image-converter/ascii-image-converter /usr/bin/
chmod +x /usr/bin/ascii-image-converter

# pipes.sh
git clone https://github.com/pipeseroni/pipes.sh.git /tmp/pipes.sh
cp -vf /tmp/pipes.sh/pipes.sh /usr/bin/

# pokemonsay-newgenerations
git clone https://github.com/HRKings/pokemonsay-newgenerations.git /tmp/pokemonsay-newgenerations

cp -rf /tmp/pokemonsay-newgenerations/pokemons /usr/bin/
cp -vf /tmp/pokemonsay-newgenerations/pokemonsay.sh /usr/bin/
cp -vf /tmp/pokemonsay-newgenerations/pokemonthink.sh /usr/bin/


# dualsensectl
########

cd /tmp/files/scripts
}
pkgs
