test -f $HOME/.config/fish/conf.d/aliases.fish && status filename | grep -q 'vendor_conf.d' && exit 0
## Useful aliases
# Fish command history
function history
  builtin history --show-time='%F %T '
end

# Common use
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

function y
  set tmp (mktemp -t "yazi-cwd.XXXXXX")
  yazi $argv --cwd-file="$tmp"
  if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    builtin cd -- "$cwd"
  end
  rm -f -- "$tmp"
end

abbr -a --position anywhere -- --help '--help | bat -pplhelp'
abbr -a --position anywhere -- --help-all '--help-all | bat -pplhelp'
alias bathelp 'bat --plain --language=help'
function help
  $argv --help 2>&1 | bathelp
end

if command -v gedit
  alias gedit="command gedit"
else
  alias gedit="flatpak run --branch=stable --arch=x86_64 --command=gedit --file-forwarding org.gnome.gedit"
end

command -vq thefuck && thefuck --alias | source
alias f='thefuck'

alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias fcc='fc-cache -fvr --really-force'
alias hw='hwinfo --short'
alias jctl="journalctl -p 3 -xb" # Get the error messages from journalctl
alias killall='killall -vw'
alias ramcln="sudo /usr/bin/ramclean"
alias tarnow='tar -acf '
alias untar='tar -xvf '
alias wget='wget -c '
alias tree 'tree -a'
alias diff='diff --color=auto'
alias dir='dir --color=always'
alias egrep='egrep --color=always'
alias fgrep='fgrep --color=always'
alias grep='grep --color=always'
alias ip='ip -color=auto'
alias ls='ls --color=always'
alias tc='tc -color=auto'
alias vdir='vdir --color=always'
# Use some more things with better alternatives
alias bat='bat --style="header,snip,changes" --paging=never'
alias l.='eza -a1'
alias la='eza -a --color=always --hyperlink --group-directories-first --icons=always'
alias ll='eza -alob -SH --git --color=always --hyperlink --group-directories-first --icons=always --time-style="+%a %b %d %H:%M:%S %Y"'
alias lt='eza -aT --git --color=always --hyperlink --group-directories-first --icons=always'
alias procs="procs --load-config $PROCS_CONFIG_FILE"
alias pscpu='procs --sortd cpu'
alias psmem='procs --sortd rss'
alias ps-tree='procs --tree'

# flatpak alias
alias flup="flatpak update"
alias flin="flatpak install"
alias flre="flatpak install --reinstall"
alias flrn="flatpak run"
alias fdgl="flatpak remote-info --log flathub"
alias fldg="echo -e 'Get commits hashes to downgrade to using alias fdgl (flatpak remote-info --log flathub) then put commit hash (without space) and app id right after this alias \nand then mask the app \n \n' && flatpak update --commit="
alias flrm="flatpak uninstall"
alias fcln="flatpak uninstall --unused && find $HOME/.var/app -path '*/cache/*' | sed -e '/banners\|coverart\|lutris\s*\$/d' | xargs rm -rvf"
alias flss="flatpak search"
alias fhis="flatpak history"
alias finf="flatpak info"
alias fist="flatpak list --columns=installation,name,size,application,version,runtime"
alias fmsk="flatpak mask"
alias funm="flatpak --remove mask"
alias flrp="flatpak repair"

# distrobox alias
alias arch-btw="distrobox enter arch-btw -- fish"
alias gaming-box="distrobox enter fedora-box-gaming -- fish"
alias uwubun="distrobox enter uwubuntu -- fish"

alias boxhoex="distrobox-host-exec"
alias boxexpoa="distrobox-export -a"

function boxunexpoa
  distrobox-export -a $argv --delete
end
function boxexpob
  distrobox-export --bin $argv --export-path $HOME/.local/bin/bim
end
function boxunexpob
  distrobox-export --bin $argv --export-path $HOME/.local/bin/bim --delete
end

# nix alias
alias niup="nix-channel --update && nix-env -b --upgrade"
alias niin="nix-channel --update && nix-env -ib"
alias nire="nix-collect-garbage && nix-channel --update && nix-env -ib"
alias ndgl="nix-env -qaP"
alias nidg="nix-env -u --always"
alias nirm="nix-env --uninstall"
alias ncln="nix-store --optimise && nix-collect-garbage"
alias niss="nix-channel --update && nix-env -qas" # use '' to search
alias ninf="nix-channel --update && nix-env -qas --description"
alias nist="nix-channel --update && nix-env -q"
alias nigl="nix-env --list-generations"
alias nigs="nix-env -G"
alias nigd="nix-env --delete-generations"
alias nirb="nix-env --rollback"
alias nirp="nix-store --verify --check-contents --repair"
function nix-profiled
    mkdir -p $HOME/.local/state/nix/custom-profiles
    set nixpkg $(echo "$argv[2]" | cut -d '.' -f 2-)
    ls -A1 /nix/var/nix/profiles/ | grep -oq $nixpkg || nix-channel --update && nix-env --profile /nix/var/nix/profiles/$nixpkg $argv[1] $argv[2] && ln -sfv /nix/var/nix/profiles/$nixpkg $HOME/.local/state/nix/custom-profiles
end

# apt alias
alias apup="sudo apt update && sudo apt upgrade"
alias apin="sudo apt install"
alias apre="sudo apt install --reinstall "
# use version num for downgrade
alias aprm="sudo apt autoremove"
alias apcln="sudo apt autoremove && sudo apt autoclean"
alias apss="apt search"
alias aphis="cat /var/log/apt/history.log"
alias apinf="apt info"
alias apist="apt list --installed"

# dnf alias
alias dnup="dnf repolist | grep -ioq 'nobara' && sudo dnf update nobara-repos  --refresh ; sudo dnf distro-sync --refresh && sudo dnf upgrade && sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg"
alias dnin="sudo dnf install"
alias dnre="sudo dnf reinstall"
alias dndg="sudo dnf downgrade"
alias dnrm="sudo dnf autoremove"
alias dcln="sudo dnf autoremove && sudo dnf clean all"
alias dnss="dnf search"
alias dhis="dnf history"
alias dinf="dnf info"
alias dist="dnf list"

# arch alias
alias arup="sudo pacman -Sy && sudo powerpill -Su && paru -Su"
alias arin="sudo pacman -Sy --needed"
alias prin="paru -S"
alias arre="sudo pacman -Sy"
alias ardg="sudo downgrade"
alias arrm="sudo pacman -Rns"
alias acln="sudo pacman -Scc && sudo pacman -Rns (pacman -Qqtd)"
alias prss="paru -Ss"
alias arss="pacman -Ss"
alias ahis="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias ainf="pacman -Qi"
alias aist="pacman -Ql"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
[ ! -x /usr/bin/yay ] && [ -x /usr/bin/paru ] && alias yay='paru'
# Get fastest mirrors arch alias
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"
