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


runtimes='org.kde.KStyle.Kvantum//6.6
org.kde.KStyle.Kvantum//6.5
org.kde.KStyle.Kvantum//5.15-23.08
org.kde.KStyle.Kvantum//5.15-22.08
org.kde.KStyle.Kvantum//5.15-21.08
org.kde.KStyle.Kvantum//5.15
org.freedesktop.Platform.VulkanLayer.vkBasalt//24.08
org.freedesktop.Platform.VulkanLayer.vkBasalt//23.08
org.freedesktop.Platform.VulkanLayer.vkBasalt//22.08
org.freedesktop.Platform.VulkanLayer.vkBasalt//21.08
org.freedesktop.Platform.VulkanLayer.gamescope//24.08
org.freedesktop.Platform.VulkanLayer.gamescope//23.08
org.freedesktop.Platform.VulkanLayer.gamescope//22.08
org.freedesktop.Platform.VulkanLayer.MangoHud//24.08
org.freedesktop.Platform.VulkanLayer.MangoHud//23.08
org.freedesktop.Platform.VulkanLayer.MangoHud//22.08
org.freedesktop.Platform.VulkanLayer.MangoHud//21.08
org.freedesktop.Platform.VulkanLayer.OBSVkCapture//24.08
org.freedesktop.Platform.VulkanLayer.OBSVkCapture//23.08
org.freedesktop.Platform.VulkanLayer.OBSVkCapture//22.08
org.freedesktop.Platform.VulkanLayer.OBSVkCapture//21.08'

printf "%s\n" $net $fileViewers $graphicsVideoEditors $docs $monitoring $diskBackup $sys $vmContainers $utils $tweaks $gaming $tools $runtimes > /etc/catcat-os/flatpak-list/install &

# runtimes
#runtimes=(
#'org.kde.KStyle.Kvantum'
#'org.freedesktop.Platform.VulkanLayer.vkBasalt'
#'org.freedesktop.Platform.VulkanLayer.gamescope'
#'org.freedesktop.Platform.VulkanLayer.MangoHud'
#'org.freedesktop.Platform.VulkanLayer.OBSVkCapture'
#)
#for r in "${runtimes[@]}"; do
#   flatpak search --columns=application,branch $r | awk '{print $1 "//" $2}' >> /etc/catcat-os/flatpak-list/install
#done

# remove
echo 'org.mozilla.firefox
io.github.fastrizwaan.WineZGUI
it.mijorus.gearlever
io.github.nokse22.Exhibit
org.fedoraproject.MediaWriter' > /etc/catcat-os/flatpak-list/remove &


