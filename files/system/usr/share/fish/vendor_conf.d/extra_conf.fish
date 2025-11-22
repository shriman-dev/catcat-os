test -f $HOME/.config/fish/conf.d/extra_conf.fish && status filename | grep -q 'vendor_conf.d' && exit 0
## Environment setup
# Fish command history
function history
  builtin history --show-time='%F %T '
end

# Apply .profile: use this to put fish compatible .profile stuff in
if test -f $HOME/.fish_profile
  source $HOME/.fish_profile
end

# Replace user home path in history with $HOME variable
sed -i -e "s|'/var/home/$USER\([^']*\)'|\"\$HOME\1\"|g" \
       -e 's|"'"/var/home/$USER"'\([^"]*\)"|"$HOME\1"|g' \
       -e 's|'"/var/home/$USER"'|\$HOME|g' $HOME/.local/share/fish/fish_history >/dev/null 2>&1

sed -i -e "s|'$HOME\([^']*\)'|\"\$HOME\1\"|g" -e 's|"'"$HOME"'\([^"]*\)"|"$HOME\1"|g' \
       -e 's|'"$HOME"'|\$HOME|g' $HOME/.local/share/fish/fish_history >/dev/null 2>&1


# Source and deactivate conda by default
if test -f "$HOME/.local/anaconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/.local/anaconda3/etc/fish/conf.d/conda.fish"
    if command -v conda >/dev/null 2>&1; conda deactivate; end
end

if test -f "$HOME/.local/miniconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/.local/miniconda3/etc/fish/conf.d/conda.fish"
    if command -v conda >/dev/null 2>&1; conda deactivate; end
end
