#!/bin/bash
set -oue pipefail

echo -e "\n$0\n"

mkdir -p /etc/catcat-os/flatpak-list

fileViewers='org.gnome.eog
org.gnome.Papers
org.gnome.FileRoller
com.github.rafostar.Clapper
com.github.neithern.g4music'

graphicsVideoEditors='com.github.PintaProject.Pinta'

docs='org.gnome.gedit'

net='io.gitlab.librewolf-community'

monitoring='net.nokyan.Resources
org.gnome.Logs'

diskBackup='org.gnome.baobab'

sys='org.gnome.PowerStats
org.gnome.ColorViewer
org.gnome.Firmware
app.drey.KeyRack
com.github.tchx84.Flatseal
io.github.giantpinkrobots.flatsweep
io.github.flattool.Warehouse'

vmContainers='io.github.dvlv.boxbuddyrs'

utils='org.gnome.Calculator
org.gnome.clocks
org.gnome.Calendar
org.gnome.Snapshot
org.gnome.Weather
org.gnome.SoundRecorder
com.dec05eba.gpu_screen_recorder'

tweaks='com.mattjakeman.ExtensionManager
org.gnome.Characters'

gaming='com.vysp3r.ProtonPlus'

tools='org.gnome.World.Secrets'

printf "%s\n" $net $fileViewers $graphicsVideoEditors $docs $monitoring $diskBackup $sys $vmContainers $utils $tweaks $gaming $tools > /etc/catcat-os/flatpak-list/install &


# remove
echo 'org.mozilla.firefox
io.github.fastrizwaan.WineZGUI
it.mijorus.gearlever
io.github.nokse22.Exhibit
org.fedoraproject.MediaWriter' > /etc/catcat-os/flatpak-list/remove &


