status is-interactive || exit 0
_check_local_config


# Puffer fish # https://github.com/nickeb96/puffer-fish
#######################################################

function _puffer_fish_expand_bang
    if commandline --search-field >/dev/null
        commandline --search-field --insert '!'
    else if string match --quiet -- '!' "$(commandline --current-token)"
        commandline --current-token $history[1]
    else
        commandline --insert '!'
    end
end

function _puffer_fish_expand_buck
    if commandline --search-field >/dev/null
        commandline --search-field --insert '$'
    else if string match --quiet '!' -- "$(commandline --current-token)"
        commandline --current-token ''
        commandline -f history-token-search-backward
    else
        commandline --insert '$'
    end
end

function _puffer_fish_expand_dot
    if commandline --search-field >/dev/null
        commandline --search-field --insert '.'
    else if string match --quiet --regex -- '^(\.\./)*\.\.$' "$(commandline --current-token)"
        commandline --insert '/..'
    else
        commandline --insert '.'
    end
end

function _puffer_fish_expand_star
    if commandline --search-field >/dev/null
        commandline --search-field --insert '*'
    else if string match --quiet -- '!' "$(commandline --current-token)"
        set -l prev_cmd $history[1]
        set -l prev_args (string split ' ' $prev_cmd)
        set -e prev_args[1]  # remove command name
        set -l arg_str (string join ' ' $prev_args)
        # replace !* with all arguments
        commandline --current-token ''
        commandline --insert $arg_str
    else
        commandline --insert '*'
    end
end

function _puffer_fish_key_bindings --on-variable fish_key_bindings
    set -l modes
    if test "$fish_key_bindings" = fish_default_key_bindings
        set modes default insert
    else
        set modes insert default
    end

    bind --mode $modes[1] '.' _puffer_fish_expand_dot
    bind --mode $modes[1] '!' _puffer_fish_expand_bang
    bind --mode $modes[1] '$' _puffer_fish_expand_buck
    bind --mode $modes[1] '*' _puffer_fish_expand_star
    bind --mode $modes[2] --erase '.' '!' '$' '*'
end

_puffer_fish_key_bindings

set -l uninstall_event puffer_fish_key_bindings_uninstall

function _$uninstall_event --on-event $uninstall_event
    bind -e '.'
    bind -e '!'
    bind -e '$'
    bind -e '*'
end

#######################################################


