status is-interactive || exit 0
_check_local_config

## Useful aliases
alias cd='z'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias c='clear'
alias ip='ip -color=auto'
alias ls='ls --color=auto'
alias tc='tc -color=auto'
alias hw='inxi --expanded -J'
alias fcc='fc-cache -fvr --really-force'
alias dir='dir --color=auto'
alias vim='nvim'
alias vdir='vdir --color=auto'
alias tree='tree -a --dirsfirst'
alias diff='diff --color=auto'
alias wget='curl -LO'
alias jctl="journalctl -xe" # Get the error messages from journalctl
alias grep='grep --color=auto'
alias egrep='grep --color=auto -E'
alias fgrep='grep --color=auto -F'
alias rgrep='grep --color=auto -r'
alias unarcv='unarchive'
alias ramcln="sudo /usr/bin/ramclean"
alias killall='killall -vw'
alias usorted="sort | uniq -c | sort --ignore-leading-blanks --numeric-sort"

# Use some more things with better alternatives
alias l.='eza -A1'
alias la='eza -A  --classify=auto --color=auto --icons=auto --hyperlink --group-directories-first'
alias ll='eza -Al --classify=auto --color=auto --icons=auto --hyperlink --group-directories-first --header --git --octal-permissions --group --smart-group --binary --blocksize --links --time-style="+%a %H:%M:%S %Y.%m.%d"'
alias lt='eza -AT --classify=auto --color=auto --icons=auto --hyperlink --group-directories-first --git'
alias procs="procs --load-config $PROCS_CONFIG_FILE"
alias pscpu='procs --sortd cpu'
alias psmem='procs --sortd rss'
alias proctree='procs --tree'
alias btm="btm --config_location $BOTTOM_CONFIG_FILE"
alias btop='btm'
alias htop='btm --basic'


#function grubup
#  if command -v update-grub
#    sudo update-grub
#  else if command -v zypper
#    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
#  else if command -v dnf || command -v ostree
#    sudo grub2-editenv - unset menu_auto_hide
#    sudo grub2-switch-to-blscfg
#    sudo grub2-mkconfig -o /etc/grub2.cfg
#    sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
#  end
#end

if command -q yazi
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            z -- "$cwd"
        end
        rm -f -- "$tmp"
    end
end

if command -q gedit
    alias gedit="command gedit"
else
    alias gedit="flatpak run --command=gedit --file-forwarding org.gnome.gedit"
end

# distrobox aliases
if command -q distrobox
    alias dbox-hexec="distrobox-host-exec"
    alias dbox-expo-app="distrobox-export -a"

    function dbox-unexpo-app
        distrobox-export -a $argv --delete
    end
    function dbox-expo-bin
        distrobox-export --bin $argv --export-path $HOME/.local/bin
    end
    function dbox-unexpo-bin
        distrobox-export --bin $argv --export-path $HOME/.local/bin --delete
    end
end

# flatpak aliases
if command -q flatpak
    alias flup="flatpak update --assumeyes --noninteractive"
    alias flin="flatpak install"
    alias flre="flatpak install --reinstall"
    alias flrn="flatpak run"
    alias flrm="flatpak uninstall"
    alias flrp="flatpak repair"
    alias flss="flatpak search"
    alias flls="flatpak list --columns=installation,name,size,application,version,runtime"
    alias fldg="echo -e 'Get commits hashes to downgrade to using alias fdgl (flatpak remote-info --log flathub) then put commit hash (without space) and app id right after this alias \nand then mask the app \n \n' && flatpak update --commit="
    alias fldgl="flatpak remote-info --log flathub"
    alias flcln="flatpak uninstall --unused && find $HOME/.var/app -path '*/cache/*' | sed -e '/banners\|coverart\|lutris\s*\$/d' | xargs rm -rvf"
    alias flhst="flatpak history"
    alias flinf="flatpak info"
    alias flmsk="flatpak mask"
    alias flunm="flatpak --remove mask"
end

# nix aliases
if command -q nix-env
    alias niup="nix-channel --update && nix-env -b --upgrade"
    alias niin="nix-channel --update && nix-env -ib"
    alias nire="nix-collect-garbage && nix-channel --update && nix-env -ib"
    alias nirm="nix-env --uninstall"
    alias nirb="nix-env --rollback"
    alias nirp="nix-store --verify --check-contents --repair"
    alias niss="nix-channel --update && nix-env -qas" # use '' to search
    alias nils="nix-channel --update && nix-env -q"
    alias nidg="nix-env -u --always"
    alias nicln="nix-store --optimise && nix-collect-garbage"
    alias niinf="nix-channel --update && nix-env -qas --description"
    alias nilsg="nix-env --list-generations"
    alias niswg="nix-env --switch-generation"
    alias nirmg="nix-env --delete-generations"

    function nix-profiled
        set custom_profiles_dir "$HOME/.local/state/nix/custom-profiles"
        set nixpkg $(echo "$argv[2]" | cut -d '.' -f 2-)
        mkdir -p $custom_profiles_dir
        if not ls -A1 $custom_profiles_dir | grep -oq $nixpkg
            nix-channel --update && nix-env --profile $custom_profiles_dir/$nixpkg $argv[1] $argv[2]
        end
    end
end

# dnf aliases
if command -q dnf
    alias dnfup="sudo dnf distro-sync --refresh && sudo dnf upgrade && sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg"
    alias dnfin="sudo dnf install"
    alias dnfre="sudo dnf reinstall"
    alias dnfrm="sudo dnf autoremove"
    alias dnfss="dnf search"
    alias dnfls="dnf list"
    alias dnfdg="sudo dnf downgrade"
    alias dnfcln="sudo dnf autoremove && sudo dnf clean all"
    alias dnfhst="dnf history"
    alias dnfinf="dnf info"
end

# apt aliases
if command -q apt
    alias aptup="sudo apt update && sudo apt upgrade"
    alias aptin="sudo apt install" # use version num for downgrade
    alias aptre="sudo apt install --reinstall"
    alias aptrm="sudo apt autoremove"
    alias aptss="apt search"
    alias aptls="apt list --installed"
    alias aptcln="sudo apt autoremove && sudo apt autoclean"
    alias apthst="sudo cat /var/log/apt/history.log"
    alias aptinf="apt info"
end

# arch aliases
if command -q pacman
    alias pacup="sudo pacman -Sy && sudo powerpill -Su && paru -Su"
    alias pacin="sudo pacman -Sy --needed"
    alias yayin="paru -S"
    alias pacre="sudo pacman -Sy"
    alias pacrm="sudo pacman -Rns"
    alias pacss="pacman -Ss"
    alias yayss="paru -Ss"
    alias pacls="pacman -Ql"
    alias pacdg="sudo downgrade"
    alias paccln="sudo pacman -Scc && sudo pacman -Rns (pacman -Qqtd)"
    alias pachst="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
    alias pacinf="pacman -Qi"

    alias fixpac="sudo rm /var/lib/pacman/db.lck"
    alias gitpac='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
    alias yay='paru'

    # Get fastest mirrors arch alias
    alias mirrorr="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
    alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
    alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
    alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"
end

## Useful abbreviations
abbr -- - 'z -'
abbr cp 'cp -v'
abbr ln 'ln -v'
abbr mv 'mv -v'
abbr rm 'rm -v'
abbr df 'df -h'
abbr du 'du -h'
abbr free  'free -hm'
abbr chmod 'chmod -v'
abbr chown 'chown -v'
abbr rmdir 'rmdir -v'
abbr mkdir 'mkdir -vp'

abbr -c sudo cp 'cp -v'
abbr -c sudo ln 'ln -v'
abbr -c sudo mv 'mv -v'
abbr -c sudo df 'df -h'
abbr -c sudo du 'du -h'
abbr -c sudo free  'free -hm'
abbr -c sudo chmod 'chmod -v'
abbr -c sudo chown 'chown -v'
abbr -c sudo mkdir 'mkdir -vp'
abbr -c sudo mount 'mount -vm'

abbr sysd 'sudo systemctl'
abbr sysdu 'systemctl --user'
abbr mount 'sudo mount -vm'
abbr sysctl 'sudo sysctl'
abbr nethogs 'sudo nethogs -a -C -b -v 4'
abbr bandwhich 'sudo bandwhich --processes --connections'
abbr localdnsctl 'sudo localdnsctl -v'

# Help wrapper with bat
abbr -a --position anywhere -- --help '--help | bat -fpplhelp'
abbr -a --position anywhere -- --help-all '--help-all | bat -fpplhelp'
