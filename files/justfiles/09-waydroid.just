# vim: set ft=make :

alias setup-waydroid := configure-waydroid

# Launch Waydroid configuration helper. Options: init | configure | gpu | integration | reset | helper
[group("apps")]
configure-waydroid ACTION="":
    #!/usr/bin/bash
    source /usr/lib/catcat-os/bash-lib.sh
    OPTION="{{ ACTION }}"
    VARIANT_IMAGE="$(grep 'VARIANT_ID' /usr/lib/os-release)"
    # Get current Waydroid status
    WAYDROID_STATUS_RUNNING="$(systemctl is-active waydroid-container || echo "unknown")"
    WAYDROID_STATUS="${yellow}Disabled And ${WAYDROID_STATUS_RUNNING^}${normal}"
    if systemctl is-enabled --quiet waydroid-container; then
        WAYDROID_STATUS="${green}Enabled And ${WAYDROID_STATUS_RUNNING^}${normal}"
    fi
    if [ "${OPTION}" == "help" ]; then
      echo "Usage: ujust configure-waydroid <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'init' to select Initialize Waydroid"
      echo "  Use 'config' to select Configure Waydroid"
      echo "  Use 'gpu' to choose Select GPU for Waydroid"
      echo "  Use 'integrate' to enable desktop window integration for Waydroid"
      echo "  Use 'reset' to reset Waydroid (also removes waydroid-related files from user home)"
      echo "  Use 'helper' to install waydroid-helper app (https://github.com/waydroid-helper/waydroid-helper)"
      exit 0
    elif [ "${OPTION}" == "" ]; then
      echo -e "${bold}Waydroid Setup${normal}"
      echo -e "${bold}Waydroid Status:${normal} ${WAYDROID_STATUS}"
        OPTION=$(ugum choose "Initialize Waydroid" \
                             "Configure Waydroid" \
                             "Select GPU for Waydroid" \
                             "Enable Desktop Window Integration" \
                             "Reset Waydroid (also removes waydroid-related files from user home)" \
                             "Install waydroid-helper app")
    fi

    case "${OPTION}" in
        "Initialize Waydroid"|init|initialize)
            log "INFO" "Initializing Waydroid..."
            if [[ ! "${VARIANT_IMAGE}" =~ "catcat-os-hh" ]]; then
                sudo systemctl enable --now waydroid-container
            fi
            log "INFO" "This might take a bit, please be patient"
            sudo waydroid init -c 'https://ota.waydro.id/system' -v 'https://ota.waydro.id/vendor'
            sudo restorecon -R /var/lib/waydroid
            log "INFO" "Waydroid has been initialized, please run waydroid once before you Configure Waydroid"
            echo ""
            ;;
        "Configure Waydroid"|config|configure)
            log "INFO" "Running Waydroid configuration helper..."
            git clone https://github.com/ublue-os/waydroid_script.git --depth 1 /tmp/waydroid_script
            python -m venv /tmp/waydroid_script/venv
            source /tmp/waydroid_script/venv/bin/activate
            sudo pip install -r /tmp/waydroid_script/requirements.txt
            sudo /tmp/waydroid_script/main.py
            deactivate
            sudo rm -rf /tmp/waydroid_script
            echo ""
            ;;
        "Select GPU for Waydroid"|gpu|graphics-card)
            log "INFO" "Selecting GPU for Waydroid..."
            sudo /usr/bin/waydroid-choose-gpu
            echo ""
            ;;
        "Enable Desktop Window Integration"|integrate|integration)
            log "INFO" "Enabling desktop window integration for Waydroid..."
            waydroid prop set persist.waydroid.multi_windows true
            echo ""
            ;;
        "Reset Waydroid (also removes waydroid-related files from user home)"|reset)
            log "INFO" "Resetting Waydroid..."
            sudo rm -rf /var/lib/waydroid \
                        /home/.waydroid \
                        "${HOME}/waydroid" \
                        "${HOME}/.share/waydroid" \
                        "${HOME}/.local/share/waydroid" \
                        "${HOME}/.local/share/applications"/*aydroid*
            log "INFO" "Waydroid has been ${green}reset${normal}."
            echo ""
            ;;
        "Install waydroid-helper app"|helper)
            log "INFO" "Installing waydroid-helper..."
            DIRECT_GHPKG=1
            TMP_DIR="/tmp/extra_pkgs"
            BIN_DIR="${HOME}/.local/bin"
            get_ghpkg --name "waydroid-helper.AppImage" \
                      --repo "waydroid-helper/waydroid-helper" \
                      --regx 'x86_64\.AppImage$' \
                      --force
            ln -sf "${HOME}/.local/bin/waydroid-helper.AppImage" "${HOME}/Me/Desktop"
            rm -rf "${TMP_DIR}"
            log "INFO" "Install complete, waydroid-helper has been added to apps grid/menu"
            echo ""
            ;;
        *)
            log "INFO" "No changes made."
            echo ""
            ;;
    esac
