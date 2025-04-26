test -f $HOME/.config/fish/conf.d/extra_conf.fish && status filename | grep -q 'vendor_conf.d' && exit 0
## Environment setup
# Apply .profile: use this to put fish compatible .profile stuff in

if test -f $HOME/.fish_profile
  source $HOME/.fish_profile
end

# Replace user home path in history with $HOME variable
sed -i -e "s|'/var/home/$USER\([^']*\)'|\"\$HOME\1\"|g" -e 's|"'"/var/home/$USER"'\([^"]*\)"|"$HOME\1"|g' -e 's|'"/var/home/$USER"'|\$HOME|g' $HOME/.local/share/fish/fish_history >/dev/null 2>&1
sed -i -e "s|'$HOME\([^']*\)'|\"\$HOME\1\"|g" -e 's|"'"$HOME"'\([^"]*\)"|"$HOME\1"|g' -e 's|'"$HOME"'|\$HOME|g' $HOME/.local/share/fish/fish_history >/dev/null 2>&1

if test -f "$HOME/.local/anaconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/.local/anaconda3/etc/fish/conf.d/conda.fish"
    command -vq conda && conda deactivate
end

if test -f "$HOME/.local/miniconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/.local/miniconda3/etc/fish/conf.d/conda.fish"
    command -vq conda && conda deactivate
end
