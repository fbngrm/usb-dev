#!/usr/bin/env bash

set -o errexit

LSBLK_COLS="NAME,RM,TYPE,MOUNTPOINT,LABEL"
UNMOUNTED_COLOR=$(xrdb -query | grep "*color9" | cut -f 2)
MOUNTED_COLOR=$(xrdb -query | grep "*color10" | cut -f 2)

# Define your preferred terminal and file explorer applications
TERMINAL="kitty --directory"
FILE_EXPLORER="thunar"

# Create the JQ filter with no extra whitespaces or spaces between `%{A}` blocks
JQ_SCR='.blockdevices[] |
    select(.rm != false and .type == "part") |
        if .mountpoint != null then
            "%{F'$MOUNTED_COLOR'}"
            + "%{A1:'$TERMINAL' " + .mountpoint + ":}"
            + "%{A2:'$FILE_EXPLORER' " + .mountpoint + ":}"
            + "%{A3:udisksctl unmount --no-user-interaction -b " + .name + ":}"
        else
            "%{F'$UNMOUNTED_COLOR'}"
            + "%{A1:udisksctl mount --no-user-interaction -b " + .name + ":}"
            + "%{A3:udisksctl power-off --no-user-interaction -b " + .name + ":}"
        end
        + " " + (.label // (.name | sub("/dev/" ; ""))) + "%{A}%{A}%{A}  "'

# Execute lsblk and jq, and strip any excess newlines/spaces using tr and sed
lsblk -pJlo $LSBLK_COLS |
jq -r "$JQ_SCR" |
tr '\n' ' ' |
sed 's/[[:space:]]\{2,\}/ /g' | # Replace multiple spaces with a single space
sed 's/[[:space:]]*$//' # Remove trailing spaces
