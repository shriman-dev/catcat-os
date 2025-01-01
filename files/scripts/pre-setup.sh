#!/bin/bash
set -oue pipefail

echo -e "\n$0\n"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


pkgs(){
# buttersnap
curl -Lo /usr/bin/buttersnap.sh https://raw.githubusercontent.com/shriman-dev/buttersnap.sh/refs/heads/main/buttersnap.sh
chmod +x /usr/bin/buttersnap.sh

# gocryptfs
curl -Lo /tmp/gocryptfs.tar.gz $(curl -s -X GET https://api.github.com/repos/rfjakob/gocryptfs/releases/latest | grep -i '"browser_download_url": "[^"]*amd64.tar.gz"' | cut -d '"' -f4)
mkdir -p /tmp/gocryptfsTarExtract
tar -xf /tmp/gocryptfs.tar.gz -C /tmp/gocryptfsTarExtract
cp -dvf /tmp/gocryptfsTarExtract/gocryptfs /usr/bin/
chmod +x /usr/bin/gocryptfs

# btdu
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
