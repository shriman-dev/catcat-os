#!/bin/bash

[[ -f /tmp/papirus-folders.sh ]] || curl -Lo /tmp/papirus-folders.sh https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/refs/heads/master/papirus-folders
chmod -v +x /tmp/papirus-folders.sh

sed -i -e 's|config_dir=.*|config_dir="/tmp/$PROGNAME"|' /tmp/papirus-folders.sh
sed -i -e 's|PROGNAME=.*|PROGNAME="papirusfolders"|' /tmp/papirus-folders.sh

[[ -d /tmp/papirus-catcat ]] || git clone https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git /tmp/papirus-catcat


sed -i 's|\[orange\]=.*|\[orange\]="    #404059 #fab387 #fab387 #cdd6f4"|' /tmp/papirus-catcat/tools/build_color_folders.sh

#/tmp/papirus-catcat/tools/build_color_folders.sh

/tmp/papirus-folders.sh --theme /tmp/papirus-catcat/Papirus --color orange

rm -rf /tmp/Catppuccin-Papirus-Orange
cp -drf /tmp/papirus-catcat/Papirus /tmp/Catppuccin-Papirus-Orange

find /tmp/Catppuccin-Papirus-Orange -mindepth 2 -type d -not -wholename  '*/symbolic*' -not -wholename '*/places*' -not -wholename '*/16x16/actions*' -not -wholename '*/16x16/devices*' -not -wholename '*/18x18*' -not -wholename '*24x24/actions*' -not -wholename '*22x22/actions*'  -exec rm -rf {} +

find /tmp/Catppuccin-Papirus-Orange -type f -wholename '*/places*' -not -wholename '*16x16/*' -not -wholename '*18x18/*' -not -wholename '*/symbolic*'  -not -wholename '*orange*' -exec rm {} +
find /tmp/Catppuccin-Papirus-Orange -type f -wholename '*deeporange*' -exec rm {} +
find /tmp/Catppuccin-Papirus-Orange -type f -wholename '*paleorange*' -exec rm {} +


find /tmp/Catppuccin-Papirus-Orange -empty -type d -exec rm -rf {} +

rm /tmp/Catppuccin-Papirus-Orange/icon-theme.cache
rm -rf /tmp/Catppuccin-Papirus-Orange/symbolic/mimetypes
rm -rf /tmp/Catppuccin-Papirus-Orange/symbolic/apps
rm -rf /tmp/Catppuccin-Papirus-Orange/symbolic/devices
rm -rf /tmp/Catppuccin-Papirus-Orange/16x16/devices

find /tmp/Catppuccin-Papirus-Orange  -xtype l -exec rm {} +

for i in $( grep -rl '#444444' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed -i -e 's|#444444|#cdd6f4|' $i
done


# go-previous.svg
for i in $( grep -rl 'M 14,7 H 6 L 9.5,3.5 8,2 2,8 8,14 9.5,12.5 6,9 H 14 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed  -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done

#go-first.svg
for i in $( grep -rl 'M 16,7 H 9 L 12.5,3.5 11,2 5,8 11,14 12.5,12.5 9,9 H 16 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed  -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-first-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done

#go-next.svg
for i in $( grep -rl 'M 2,9 H 10 L 6.5,12.5 8,14 14,8 8,2 6.5,3.5 10,7 H 2 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed  -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done

#go-last.svg
for i in $( grep -rl 'M 0,9 H 7 L 3.5,12.5 5,14 11,8 5,2 3.5,3.5 7,7 H 0 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed  -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-last-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done

#go-up.svg
for i in $( grep -rl 'M 7,14 V 6 L 3.5,9.5 2,8 8,2 14,8 12.5,9.5 9,6 V 14 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed  -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-up-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done

#go-top-symbolic.svg
for i in $( grep -rl 'M 7,16 V 9 L 3.5,12.5 2,11 8,5 14,11 12.5,12.5 9,9 V 16 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed  -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-top-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done

#go-down.svg
for i in $( grep -rl 'M 7,2 V 10 L 3.5,6.5 2,8 8,14 14,8 12.5,6.5 9,10 V 2 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed  -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-down-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done

#go-bottom.svg
for i in $( grep -rl 'M 7,0 V 7 L 3.5,3.5 2,5 8,11 14,5 12.5,3.5 9,7 V 0 Z' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed -i -e "s|<path.*|$(grep '<path' /usr/share/icons/Adwaita/symbolic/actions/go-bottom-symbolic.svg)|;s|<path|<path style=\"fill:currentColor\" class=\"ColorScheme-Text\"|;/circle/d" $i
done


for i in $( grep -rl '#2e3436' /tmp/Catppuccin-Papirus-Orange/ ); do
    sed -i -e 's|#2e3436|#cdd6f4|' $i
done

