status is-interactive || exit 0
_check_local_config

# Fish command history
function _hist
    # Merge history merge from other fish sessions execpt private mode
    if test -z "$fish_private_mode"
        builtin history merge
    end
    # Extract the raw command from history entries by removing everything up to the timestamp
    # Using a non-greedy regex "?" to avoid matching commands containing the character.
    set -f time_regex '^.*? │ '
    # Use a null character instead of newline to separate commands in a pipeline
    # Since commands can span multiple lines and newlines would break them
    set -f commands_selected (
        builtin history --null --show-time="%F %T │ " |
            _fzf_wrapper --read0 --print0 --multi --scheme=history \
                --prompt="History > " --query=(commandline) --preview-window="bottom:4:wrap" \
                --preview="string replace --regex '$time_regex' '' -- {} | fish_indent --ansi" |
            string split0 |
            # remove timestamps from commands selected
            string replace --regex $time_regex ''
    )

    if test $status -eq 0
        commandline --replace -- $commands_selected
    end

    commandline --function repaint
end

# Fish history sync
function _hisync
    builtin history save
    builtin history merge
end

# Use hist and hisync (history sync) without saving itself into history
abbr -a hist --position command ' _hist'
abbr -a hisync --position command ' _hisync'

# Run fish functions and aliases with sudo
function sudo --wraps sudo
    set sudo_args
    set sudo_args_with_value (
            LANG=C command sudo --help | string match -gr '^\s*(-\w),\s*(--\w[\w-]*)=')

    while set -q argv[1]
        switch "$argv[1]"
            case '--'
                set -a sudo_args $argv[1]
                set -e argv[1]
                break
            case $sudo_args_with_value
                set -a sudo_args $argv[1]
                set -e argv[1]
            case '-*'
            case '*'
                break
        end
        set -a sudo_args $argv[1]
        set -e argv[1]
    end

    if functions -q -- $argv[1]
        set -- argv fish -C "$(functions --no-details -- $argv[1])" -c '$argv' -- $argv
    end

    command sudo $sudo_args $argv
end

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
