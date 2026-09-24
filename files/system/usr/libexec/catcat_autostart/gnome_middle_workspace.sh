#!/usr/bin/bash
attempt=0
max_attempts=8
# Run only if dynamic-workspaces is not set
if [[ "$(dconf read /org/gnome/mutter/dynamic-workspaces)" == "false" ]]; then
    workspace_count=$(dconf read /org/gnome/desktop/wm/preferences/num-workspaces)
    # If workspace_count is even number, make it odd so switching to middle workspace looks nicer
    if (((workspace_count % 2) == 0)); then
        workspace_count=$((workspace_count + 1))
        dconf write /org/gnome/desktop/wm/preferences/num-workspaces "${workspace_count}"
    fi

    middle_workspace=$((workspace_count / 2))
    # Attempt to switch to the middle workspace
    while [[ ${attempt} -lt ${max_attempts} ]]; do
        /usr/bin/wmctrl -s "${middle_workspace}"
        # Exit if it is already middle workspace
        /usr/bin/wmctrl -d | grep -w "${middle_workspace}  \*" && exit 0
        # Decrease speed of attempt after 4th attempts
        { [[ ${attempt} -lt 4 ]] && sleep 0.2; } || sleep 1
        attempt=$(( attempt + 1 ))
    done
fi
