#!/usr/bin/bash

DESKTOP_EXTRAS=(
    # # File Viewers
    "app/org.videolan.VLC/x86_64/stable"
    "app/app.drey.EarTag/x86_64/stable"
    "app/de.leopoldluley.Clapgrep/x86_64/stable"

    # Graphics and Video Editors
    "app/org.upscayl.Upscayl/x86_64/stable"
    "app/org.gnome.gitlab.YaLTeR.Identity/x86_64/stable"

    # Document Viewers and Editors
    "app/org.onlyoffice.desktopeditors/x86_64/stable"

    # Disk Analyze, Backup and Encryption
    "app/io.github.mpobaschnig.Vaults/x86_64/stable"

    # System Apps
#    "app/org.gnome.ColorViewer/x86_64/stable"

    # Productivity and Development
    "app/dev.zed.Zed/x86_64/stable"
    "app/com.logseq.Logseq/x86_64/stable"

    # Gaming Apps
    "app/com.usebottles.bottles/x86_64/stable"
    "app/com.vysp3r.ProtonPlus/x86_64/stable"
    "app/page.kramo.Cartridges/x86_64/stable"
    "app/io.github.radiolamp.mangojuice/x86_64/stable"
    "app/io.github.benjamimgois.goverlay/x86_64/stable"
    "app/io.github.ilya_zlobintsev.LACT/x86_64/stable"

    # Cleanups and Optimize
    "app/com.github.qarmin.czkawka/x86_64/stable"

    # Runtimes
    "runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt/x86_64/25.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt/x86_64/24.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt/x86_64/23.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt/x86_64/22.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/25.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/22.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/25.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/22.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/25.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/23.08"
    "runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/22.08"

)

DESKTOP_COMMON=(
    # # File Viewers
    #"app/org.gnome.eog/x86_64/stable"
    "app/org.gnome.Loupe/x86_64/stable"
    "app/app.fotema.Fotema/x86_64/stable"
    "app/org.gnome.Papers/x86_64/stable"
    "app/org.gnome.FileRoller/x86_64/stable"
    "app/org.gnome.Showtime/x86_64/stable"
    "app/io.github.celluloid_player.Celluloid/x86_64/stable"
    "app/org.gnome.Decibels/x86_64/stable"
    "app/com.github.neithern.g4music/x86_64/stable"
    "app/dev.geopjr.Collision/x86_64/stable"
    "app/org.gnome.meld/x86_64/stable"
    "app/io.github.tobagin.scramble/x86_64/stable"

    # Graphics and Video Editors
    "app/com.github.PintaProject.Pinta/x86_64/stable"
    "app/org.inkscape.Inkscape/x86_64/stable"
    "app/be.alexandervanhee.gradia/x86_64/stable"
    "app/org.pitivi.Pitivi/x86_64/stable"

    # Document Viewers and Editors
    "app/org.gnome.gedit/x86_64/stable"
    "app/io.github.mrvladus.List/x86_64/stable"
    "app/com.github.johnfactotum.Foliate/x86_64/stable"
    "app/garden.jamie.Morphosis/x86_64/stable"
    "app/com.github.flxzt.rnote/x86_64/stable"
    "app/org.libreoffice.LibreOffice/x86_64/stable"

    # Net and Browser
    "app/io.gitlab.librewolf-community/x86_64/stable"
    "app/io.freetubeapp.FreeTube/x86_64/stable"
    "app/io.github.giantpinkrobots.varia/x86_64/stable"

    # Monitoring Apps
    "app/net.nokyan.Resources/x86_64/stable"
    "app/org.gnome.Logs/x86_64/stable"

    # Disk Analyze, Backup and Encryption
    "app/org.gnome.baobab/x86_64/stable"
    "app/org.gnome.World.PikaBackup/x86_64/stable"

    # Software Stores
    "app/io.github.flattool.Warehouse/x86_64/stable"

    # System Apps
    "app/org.gnome.PowerStats/x86_64/stable"
    "app/org.gnome.Firmware/x86_64/stable"
    "app/com.github.tchx84.Flatseal/x86_64/stable"
    "app/app.drey.KeyRack/x86_64/stable"

    # Utilities
    "app/org.gnome.Calculator/x86_64/stable"
    "app/org.gnome.clocks/x86_64/stable"
    "app/org.gnome.Calendar/x86_64/stable"
    "app/org.gnome.Snapshot/x86_64/stable"
    "app/org.gnome.Weather/x86_64/stable"
    "app/org.gnome.SoundRecorder/x86_64/stable"
    "app/com.github.wwmm.easyeffects/x86_64/stable"
    "app/io.github.TheWisker.Cavasik/x86_64/stable"
    "app/com.dec05eba.gpu_screen_recorder/x86_64/stable"
    "app/org.gnome.Characters/x86_64/stable"
    "app/com.belmoussaoui.Decoder/x86_64/stable"
    "app/re.sonny.Junction/x86_64/stable"
    "app/net.codelogistics.clicker/x86_64/stable"

    # Tweak Desktop Environment
    "app/com.mattjakeman.ExtensionManager/x86_64/stable"

    # Productivity and Development
    "app/io.github.efogdev.mpris-timer/x86_64/stable"
    "app/com.toolstack.Folio/x86_64/stable"
    "app/se.sjoerd.Graphs/x86_64/stable"
    "app/re.sonny.Eloquent/x86_64/stable"
    "app/dev.bragefuglseth.Keypunch/x86_64/stable"
    "app/me.iepure.devtoolbox/x86_64/stable"

    # Gaming Apps
    "app/org.gnome.Chess/x86_64/stable"

    # Useful Tools
    "app/org.gnome.World.Secrets/x86_64/stable"
    "app/org.localsend.localsend_app/x86_64/stable"
    "app/com.github.tenderowl.frog/x86_64/stable"

    # Cleanups and Optimize
    "app/io.github.giantpinkrobots.flatsweep/x86_64/stable"

    # Runtimes
    "runtime/org.kde.KStyle.Kvantum/x86_64/6.9"
    "runtime/org.kde.KStyle.Kvantum/x86_64/6.6"
    "runtime/org.kde.KStyle.Kvantum/x86_64/6.5"
    "runtime/org.kde.KStyle.Kvantum/x86_64/6.10"
    "runtime/org.kde.KStyle.Kvantum/x86_64/5.15-24.08"
    "runtime/org.kde.KStyle.Kvantum/x86_64/5.15-23.08"
    "runtime/org.kde.KStyle.Kvantum/x86_64/5.15-22.08"
    "runtime/org.kde.KStyle.Kvantum/x86_64/5.15"
)
