#ps aux | grep -iqo fish || clear
## Set values
set -x ANH "/storage/emulated/0"
set -x ni "$HOME/.local/state/nix/profiles/profile/bin"
#set -x NIXPKGS_ALLOW_UNFREE 1
# Hide welcome message
set fish_greeting
set VIRTUAL_ENV_DISABLE_PROMPT "1"
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

# python ta-lib
set -x TA_INCLUDE_PATH "$HOME/.local/state/nix/profiles/profile/include"
set -x TA_LIBRARY_PATH "$HOME/.local/state/nix/profiles/profile/lib"

## Environment setup
# Apply .profile: use this to put fish compatible .profile stuff in

if test -f ~/.fish_profile
  source ~/.fish_profile
end

# Add PATHs
if not contains -- ~/.local/bin ~/.local/podman/bin ~/.local/bin/bim $PATH
  set -p PATH ~/.local/bin ~/.local/podman/bin ~/.local/bin/bim
end
#~/Bkups/Android ~/Bkups/Android/platform-tools ~/Bkups/Android/cmdline-tools ~/Bkups/Android/cmdline-tools/bin

# Replace user home path in history with $HOME variable
sed -i -e "s|'/var/home/$USER\([^']*\)'|\"\$HOME\1\"|g" -e 's|"'"/var/home/$USER"'\([^"]*\)"|"$HOME\1"|g' -e 's|'"/var/home/$USER"'|\$HOME|g' $HOME/.local/share/fish/fish_history
sed -i -e "s|'$HOME\([^']*\)'|\"\$HOME\1\"|g" -e 's|"'"$HOME"'\([^"]*\)"|"$HOME\1"|g' -e 's|'"$HOME"'|\$HOME|g' $HOME/.local/share/fish/fish_history


## Starship prompt
if not test -f ~/.config/starship.toml
    set -x STARSHIP_CONFIG '/etc/starship/starship.toml'
end

if status --is-interactive
   command -vq starship && source ("starship" init fish --print-full-init | psub)
end

## Run fastfetch if session is interactive
if status --is-interactive && type -q fastfetch
     if test -f /usr/bin/fastfetch
        /usr/bin/fastfetch
     else
        fastfetch
     end
end

## Useful aliases
# Common use
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias grep='grep --color=always'
alias dir='dir --color=always'
alias vdir='vdir --color=always'
alias fgrep='fgrep --color=always'
alias egrep='egrep --color=always'
alias ls='ls --color=always'
alias ll='eza -al --color=always --group-directories-first --icons -SH --time-style=relative -o' # preferred listing # Replace ls with eza
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a1"
alias ip="ip -color"
#alias cat='bat --style header --style snip --style changes --style header' # Replace some more things with better alternatives
command -vq thefuck && thefuck --alias | source
alias f="thefuck"
alias ramcln="sudo /bin/ramclean.sh"
alias grubup="$HOME/Honk/Scripts/loonix/grubup.sh"
alias regen-initramfs="command -v akmods && sudo akmods; command -v dracut && sudo dracut --regenerate-all -pf; sync"
alias diskref="$HOME/Honk/Scripts/loonix/disk-man.sh refresh"
alias btr-care="$HOME/Honk/Scripts/loonix/disk-man.sh btr-care"
alias fcc="fc-cache -fvr --really-force "
alias tarnow='tar -acf '
alias untar='tar -xvf '
alias wget='wget -c '
#alias psmem='ps aux | awk '{print $6/1024 " MiB\t\t" $11,$12,$13,$14,$15,$16,$17,$18,$19,$20}' | sort -n ; free -hlm'
alias hw='hwinfo --short'                          # Hardware Info
alias jctl="journalctl -p 3 -xb" # Get the error messages from journalctl
alias netproc="sudo netproc  -B -c -v"
alias gedit="flatpak run --branch=stable --arch=x86_64 --command=gedit --file-forwarding org.gnome.gedit"


# flatpak alias
alias flup="flatpak update"
alias flin="flatpak install"
alias flre="flatpak install --reinstall"
alias flrn="flatpak run"
alias fdgl="flatpak remote-info --log flathub"
alias fldg="echo -e 'put commit hash and app id right after alias \nand then mask the app \n \n' && flatpak update --commit="
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
    mkdir -p $HOME/Bkups/nix-profiles
    set nixpkg $(echo "$argv[2]" | cut -d '.' -f 2-)
    ls -A1 /nix/var/nix/profiles/ | grep -oq $nixpkg || nix-channel --update && nix-env --profile /nix/var/nix/profiles/$nixpkg $argv[1] $argv[2] && ln -sfv /nix/var/nix/profiles/$nixpkg $HOME/Bkups/nix-profiles
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

# arch\garuda alias
alias arup="sudo pacman -Sy && sudo powerpill -Su && paru -Su"
alias arin="sudo pacman -Sy --needed"
alias prin="paru -S"
alias arre="sudo pacman -Sy"
alias ardg="sudo downgrade"
alias arrm="sudo pacman -Rns"
#alias acln="sudo pacman -Scc && sudo pacman -Rns $(pacman -Qqtd)"
alias prss="paru -Ss"
alias arss="pacman -Ss"
alias ahis="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias ainf="pacman -Qi"
alias aist="pacman -Ql"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l' # List amount of -git packages
[ ! -x /usr/bin/yay ] && [ -x /usr/bin/paru ] && alias yay='paru'
# Get fastest mirrors arch\garuda alias
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"


# nix to PATH
#set -x NIX_PATH "nixpkgs=https://github.com/NixOS/nixpkgs/archive/74e2faf5965a12e8fa5cff799b1b19c6cd26b0e3.tar.gz"
#$HOME/.local/state/nix/profiles/profile/etc/profile.d/nix.fish | source

## Export variable need for qt-theme
if type "qtile" >> /dev/null 2>&1
   set -x QT_QPA_PLATFORMTHEME "qt5ct"
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end

# get cool terminal fonts
#source ~/.local/share/icons-in-terminal/icons.fish


## Advanced command-not-found hook
#source /usr/share/doc/find-the-command/ftc.fish


## Functions
# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
	set from (echo $argv[1] | trim-right /)
	set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

if test -f "$HOME/.local/anaconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/.local/anaconda3/etc/fish/conf.d/conda.fish"
    command -vq conda && conda deactivate
end

if test -f "$HOME/.local/miniconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/.local/miniconda3/etc/fish/conf.d/conda.fish"
    command -vq conda && conda deactivate
end


# enable mcfly db to easy access history with ctrl+r
#mcfly init fish | source
#set -gx MCFLY_FUZZY 2
#set -gx MCFLY_RESULTS 40
#set -gx MCFLY_INTERFACE_VIEW BOTTOM
