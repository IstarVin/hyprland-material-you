#!/bin/bash
if ! virsh -c qemu:///system list --all | grep $1 >/dev/null 2>&1; then
    exit 1
fi
if ! virsh -c qemu:///system list | grep $1 | grep running >/dev/null 2>&1; then
    notify-send "Starting $1 VM"
    virsh --connect=qemu:///system start $1
    sleep 13
fi

hyprctl dispatch togglespecialworkspace $1
