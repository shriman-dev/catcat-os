status is-interactive || exit 0
_check_local_config

# Fish command history
function _hist
    builtin history --reverse --show-time='%F %T '
end

# Fish history sync
function _hisync
    builtin history save
    builtin history merge
end

# Use hist and hisync (history sync) without saving itself into history
abbr -a hist --position command ' _hist'
abbr -a hisync --position command ' _hisync'

# Apply .profile: use this to put fish compatible .profile stuff in
if test -f $HOME/.fish_profile
    source $HOME/.fish_profile
end

# Replace user home path in history with $HOME variable
begin
    sed -i -e "s|'/var/home/$USER\([^']*\)'|\"\$HOME\1\"|g" \
        -e 's|"'"/var/home/$USER"'\([^"]*\)"|"$HOME\1"|g' \
        -e 's|'"/var/home/$USER"'|\$HOME|g' $HOME/.local/share/fish/fish_history >/dev/null 2>&1 &

    sed -i -e "s|'$HOME\([^']*\)'|\"\$HOME\1\"|g" -e 's|"'"$HOME"'\([^"]*\)"|"$HOME\1"|g' \
        -e 's|'"$HOME"'|\$HOME|g' $HOME/.local/share/fish/fish_history >/dev/null 2>&1 &
end
