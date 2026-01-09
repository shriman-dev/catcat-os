function _check_local_config
    # Check if conf file with same name exists in local fish directory then exit
    set -l curr_conf (basename (status filename))
    test -f "$__fish_config_dir/conf.d/$curr_conf" &&
    string match -qr "vendor_conf.d" (status filename) && exit 0
end

