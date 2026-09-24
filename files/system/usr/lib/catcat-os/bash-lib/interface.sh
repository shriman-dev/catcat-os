#!/usr/bin/env bash
## Function to generate a choice selection and return the selected choice
# CHOICE=$(Choice option1 option2 "option 3")
# *user selects "option 3"*
# echo "$CHOICE" will return "option 3"
Choose() {
    local CHOICE
    CHOICE=$(ugum choose "$@")
    echo "${CHOICE}"
}

## Function to generate a confirm dialog and return the selected choice
# CHOICE=$(Confirm "Are you sure you want to do this?")
# *user selects "No"*
# echo "$CHOICE" will return "1"
# 0 = Yes
# 1 = No
Confirm() {
    ugum confirm "$@"
    echo $?
}

# Function to generate background color from foreground color
# option 38 (foreground) which can be flipped to 48 (background)
# NOTE: doublequote the color or future calls to bg will error out!
# option 38 (foreground) which can be flipped to 48 (background)
# bgblue=$(Bg "$blue")
# echo "${bgblue}text now has blue background${normal} this text has no background color"
Bg() {
    local COLOR="${1}"
    echo "${COLOR}" | sed -E 's/\[3([0-8]{1,1})/\[4\1/'
}

# Function to generate a clickable link, you can call this using
Urllink() {
    local URL="${1}" TEXT="${2}"
    # Generate a clickable hyperlink
    printf "\033]8;;%s\033\\%s\033]8;;\033\\\n" "${URL}" "${TEXT}${noc}"
}

# Function to generates a centered text header
# With customizable padding character, width, and symmetrical padding
symmetric_heading() {
    local text="$1" padding_char="${2:-#}" output_width=${3:-75} color_var="${4:-noc}"
    local -n color="${color_var}"
    local total=$(( output_width - ${#text} - 2 ))

    if (( total < 0 )); then
        err "Text too long for width ${output_width}"
        return 1
    fi

    # Calculate padding: left gets half, right gets the remainder (handles odd numbers)
    local left right left_pad right_pad
    left=$(( total / 2 ))
    right=$(( total - left ))
    printf -v left_pad "%${left}s"; left_pad=${left_pad// /"${padding_char}"}
    printf -v right_pad "%${right}s"; right_pad=${right_pad// /"${padding_char}"}

    printf "%s %s %s\n" "${color}${left_pad}" "${text}" "${right_pad}${noc}"
}

# Same as above but with upper and lower borders using given character
enclosed_heading() {
    local text="${1}" padding_char="${2:-#}" output_width=${3:-75} border
    local -n color_ref="${4:-noc}"
    printf -v border "%${output_width}s"; border=${border// /"${padding_char}"}

    printf "\n%s\n" "${color_ref}${border}${noc}"
    symmetric_heading "${text}" "${padding_char}" "${output_width}" "${4:-noc}"
    printf "%s\n\n" "${color_ref}${border}${noc}"
}
