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

## Zoxide
type -q zoxide && zoxide init fish | source

# Fzf colors
set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS\
--color=bg+:bright-black,gutter:-1,spinner:bright-magenta,hl:bright-blue \
--color=fg:bright-white,header:bright-red,info:bright-yellow,pointer:blue \
--color=marker:bright-blue,fg+:bright-white:bold,prompt:bright-yellow,hl+:bright-blue \
--color=selected-bg:bright-black \
--color=border:bright-black,label:bright-magenta"

# Fish syntex highlightings
set -U fish_color_autosuggestion 'brblack'
set -U fish_color_cancel 'red'
set -U fish_color_command 'cyan' '--bold'
set -U fish_color_comment 'brblack'
set -U fish_color_cwd 'brcyan'
set -U fish_color_cwd_root 'brcyan'
set -U fish_color_end 'cyan' '--bold'
set -U fish_color_error 'red'
set -U fish_color_escape 'brpurple'
set -U fish_color_history_current '--bold'
set -U fish_color_host 'brred'
set -U fish_color_host_remote 'red'
set -U fish_color_keyword 'brcyan' '--bold'
set -U fish_color_normal 'normal'
set -U fish_color_operator 'brred' '--bold'
set -U fish_color_option 'brblue'
set -U fish_color_param 'brcyan'
set -U fish_color_quote 'brgreen'
set -U fish_color_redirection 'brblue' '--bold'
set -U fish_color_search_match '--bold' '--background=brblack'
set -U fish_color_selection '--bold' '--background=brblack'
set -U fish_color_status 'red'  '--bold'
set -U fish_color_user 'bryellow'
set -U fish_color_valid_path '--underline'
set -U fish_pager_color_completion 'normal'
set -U fish_pager_color_description 'bryellow'
set -U fish_pager_color_prefix 'brcyan' '--bold'
set -U fish_pager_color_progress 'bryellow' '--bold' '--background=black'
set -U fish_pager_color_background
set -U fish_pager_color_secondary_background
set -U fish_pager_color_secondary_completion
set -U fish_pager_color_secondary_description
set -U fish_pager_color_secondary_prefix
set -U fish_pager_color_selected_background
set -U fish_pager_color_selected_completion
set -U fish_pager_color_selected_description
set -U fish_pager_color_selected_prefix
