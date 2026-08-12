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
    set pawship_conf "$HOME/.config/pawship.toml"
    set starship_conf "$HOME/.config/starship.toml"

    if not test -f "$starship_conf"
        set starship_conf "/etc/starship/starship.toml"
    end

    if test -d "/usr/share/catcat-os"
        if not diff -q "$starship_conf" "$pawship_conf" >/dev/null 2>&1
            install -D -m 0644 "$starship_conf" "$pawship_conf"
            sed -i 's|^Fedora =.*|Fedora = ""|' "$pawship_conf"
        end
        set -gx STARSHIP_CONFIG "$pawship_conf"
    else
        set -gx STARSHIP_CONFIG "$starship_conf"
    end

#    function starship_transient_prompt_func
#        starship module cmd_duration
#    end

#    function starship_transient_rprompt_func
#      starship module status
#    end

    source (starship init fish --print-full-init | psub) && enable_transience
end

## Zoxide
if type -q zoxide
    zoxide init fish | source
    alias cd='z'
end

# Fzf colors
set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS\
--color=bg+:bright-black,gutter:-1,spinner:bright-magenta,hl:bright-blue \
--color=fg:bright-white,header:bright-red,info:bright-yellow,pointer:blue \
--color=marker:bright-blue,fg+:bright-white:bold,prompt:bright-yellow,hl+:bright-blue \
--color=selected-bg:bright-black \
--color=border:bright-black,label:bright-magenta"

# Fish syntex highlightings
set -g fish_color_autosuggestion 'brblack'
set -g fish_color_cancel 'red'
set -g fish_color_command 'cyan' '--bold'
set -g fish_color_comment 'brblack'
set -g fish_color_cwd 'brcyan'
set -g fish_color_cwd_root 'brcyan'
set -g fish_color_end 'cyan' '--bold'
set -g fish_color_error 'red'
set -g fish_color_escape 'brpurple'
set -g fish_color_history_current '--bold'
set -g fish_color_host 'brred'
set -g fish_color_host_remote 'red'
set -g fish_color_keyword 'brcyan' '--bold'
set -g fish_color_normal 'normal'
set -g fish_color_operator 'brred' '--bold'
set -g fish_color_option 'brblue'
set -g fish_color_param 'brcyan'
set -g fish_color_quote 'brgreen'
set -g fish_color_redirection 'brblue' '--bold'
set -g fish_color_search_match '--bold' '--background=brblack'
set -g fish_color_selection '--bold' '--background=brblack'
set -g fish_color_status 'red'  '--bold'
set -g fish_color_user 'bryellow'
set -g fish_color_valid_path '--underline'
set -g fish_pager_color_completion 'normal'
set -g fish_pager_color_description 'bryellow'
set -g fish_pager_color_prefix 'brcyan' '--bold'
set -g fish_pager_color_progress 'bryellow' '--bold' '--background=black'
set -g fish_pager_color_background
set -g fish_pager_color_secondary_background
set -g fish_pager_color_secondary_completion
set -g fish_pager_color_secondary_description
set -g fish_pager_color_secondary_prefix
set -g fish_pager_color_selected_background
set -g fish_pager_color_selected_completion
set -g fish_pager_color_selected_description
set -g fish_pager_color_selected_prefix
