#!/bin/bash
mkdir -p /etc/catcat-os/flatpak-list

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo --system
flatpak remote-modify --system --prio=9 flathub

#- org.gnome.Loupe
fileViewers='org.gnome.eog
org.gnome.Shotwell
com.github.rafostar.Clapper
org.videolan.VLC
org.gnome.Music
app.drey.EarTag
org.gnome.Papers
org.gnome.meld
dev.geopjr.Collision
org.gnome.FileRoller
com.github.qarmin.czkawka
fr.romainvigier.MetadataCleaner'

#- org.kde.krita
#- org.inkscape.Inkscape
#- org.shotcut.Shotcut
graphicsVideoEditors='com.github.PintaProject.Pinta
org.gimp.GIMP
com.rawtherapee.RawTherapee
org.upscayl.Upscayl
org.pitivi.Pitivi'

#- org.gnome.TextEditor
#- com.calibre_ebook.calibre
docs='org.gnome.gedit
org.libreoffice.LibreOffice
org.onlyoffice.desktopeditors
com.toolstack.Folio
com.github.flxzt.rnote
garden.jamie.Morphosis'

net='io.gitlab.librewolf-community
org.gnome.Epiphany
io.freetubeapp.FreeTube
io.github.giantpinkrobots.varia'

monitoring='net.nokyan.Resources
org.gnome.Logs'

diskBackup='org.gnome.baobab
io.github.mpobaschnig.Vaults
org.gnome.World.PikaBackup'

sys='org.gnome.PowerStats
org.gnome.ColorViewer
org.gnome.Firmware
com.github.tchx84.Flatseal
io.github.giantpinkrobots.flatsweep
io.github.flattool.Warehouse'

vmContainers='org.gnome.Boxes
io.github.dvlv.boxbuddyrs'

#- io.github.seadve.Kooha
#- net.sapples.LiveCaptions
utils='org.gnome.Calculator
org.gnome.clocks
org.gnome.Calendar
org.gnome.Snapshot
org.gnome.Weather
org.gnome.SoundRecorder
org.nickvision.cavalier
com.dec05eba.gpu_screen_recorder
com.belmoussaoui.Decoder
net.codelogistics.clicker
re.sonny.Junction'

# tweaks
tweaks='com.mattjakeman.ExtensionManager
org.gnome.Characters'

# gaming
#- com.valvesoftware.Steam
#- net.lutris.Lutris
#com.heroicgameslauncher.hgl
#org.ryujinx.Ryujinx
gaming='com.usebottles.bottles
com.vysp3r.ProtonPlus
com.github.Matoking.protontricks'

# tools
tools='org.gnome.World.Secrets
org.localsend.localsend_app
com.github.tenderowl.frog'

printf "%s\n" $fileViewers $graphicsVideoEditors $docs $net $monitoring $diskBackup $sys $vmContainers $utils $tweaks $gaming $tools > /etc/catcat-os/flatpak-list/install

# runtimes
runtimes=(
'org.kde.KStyle.Kvantum'
'org.freedesktop.Platform.VulkanLayer.vkBasalt'
'org.freedesktop.Platform.VulkanLayer.gamescope'
'org.freedesktop.Platform.VulkanLayer.MangoHud'
'org.freedesktop.Platform.VulkanLayer.OBSVkCapture'
)
for r in "${runtimes[@]}"; do
   flatpak search --columns=application,branch $r | awk '{print $1 "//" $2}' >> /etc/catcat-os/flatpak-list/install
done

# remove
echo 'org.mozilla.firefox
io.github.fastrizwaan.WineZGUI
it.mijorus.gearlever
io.github.nokse22.Exhibit
org.fedoraproject.MediaWriter' > /etc/catcat-os/flatpak-list/remove


