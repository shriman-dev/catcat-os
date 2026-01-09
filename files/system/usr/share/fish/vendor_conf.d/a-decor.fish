status is-interactive || exit 0
_check_local_config

## Run fastfetch to print pretty system info
if test -x /usr/bin/fastfetch
    /usr/bin/fastfetch
else
    command -q fastfetch && fastfetch
end

## Starship prompt
if type -q starship
    if not test -f $HOME/.config/starship.toml
        set -gx STARSHIP_CONFIG '/etc/starship/starship.toml'
    end

    function starship_transient_rprompt_func
        starship module time
    end

#    function starship_transient_prompt_func
#      starship module status
#    end

    source ("starship" init fish --print-full-init | psub) && enable_transience
end

# Catppuccin mocha theme for fzf
set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#47476f,bg:#1E1E2E,spinner:#89b4fa,hl:#fab387 \
--color=fg:#CDD6F4,header:#F38BA8,info:#f2cdcd,pointer:#fab387 \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#f2cdcd,hl+:#fab387 \
--color=selected-bg:#45475A \
--color=border:#47476f,label:#fab387"

## Fish theme
fish_config theme choose "Catppuccin Mocha"

## Zoxide
type -q zoxide && zoxide init fish | source
