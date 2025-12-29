#
# ~/.bashrc
#
# User specific aliases and functions
if [[ -d ~/.shell.d ]]; then
	for rc in ~/.shell.d/*; do
		if [[ -f "${rc}" ]]; then
			. "${rc}"
		fi
	done
fi

unset rc
