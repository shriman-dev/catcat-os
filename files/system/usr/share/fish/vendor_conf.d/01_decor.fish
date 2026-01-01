status is-interactive || exit 0
_check_local_config

## Run fastfetch to print pretty system info
test -f /usr/bin/fastfetch && /usr/bin/fastfetch || fastfetch

## Starship prompt
if not test -f $HOME/.config/starship.toml
  set -gx STARSHIP_CONFIG '/etc/starship/starship.toml'
end

function starship_transient_rprompt_func
  starship module time
end

#function starship_transient_prompt_func
#  starship module status
#end

type -q starship && source ("starship" init fish --print-full-init | psub) && enable_transience
