test -f $HOME/.config/fish/conf.d/01_decor.fish && status filename | grep -q 'vendor_conf.d' && exit 0

## Run fastfetch if session is interactive
if status --is-interactive && type -q fastfetch
  test -f /usr/bin/fastfetch && /usr/bin/fastfetch || fastfetch
end

## Starship prompt
if not test -f $HOME/.config/starship.toml
  set -x STARSHIP_CONFIG '/etc/starship/starship.toml'
end

function starship_transient_rprompt_func
  starship module time
end
#function starship_transient_prompt_func
#  starship module status
#end

if status --is-interactive
  command -vq starship && source ("starship" init fish --print-full-init | psub) && enable_transience
end
