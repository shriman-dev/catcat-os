# Show all logs from this boot
[group("logging")]
logs-this-boot:
    sudo journalctl --no-hostname -b 0

# Show all logs from last boot
[group("logging")]
logs-last-boot:
    sudo journalctl --no-hostname -b -1

# Show all the error logs
[group("logging")]
logs-errors:
    #!/usr/bin/bash
    sudo journalctl --no-hostname --merge --priority=3..0

# Show selinux related logs
[group("logging")]
logs-selinux:
    #!/usr/bin/bash
    sudo sestatus
    echo " "
    sudo journalctl --no-hostname -t setroubleshoot

# Show warnings, errors and critical kernel/dmesg logs
[group("logging")]
logs-dmesg:
    #!/usr/bin/bash
    sudo dmesg --color=auto --decode --human --level warn,err,crit,alert,emerg

# SHow all the logs
[group("logging")]
get-logs:
    #!/usr/bin/bash
    sudo journalctl --no-hostname --merge

