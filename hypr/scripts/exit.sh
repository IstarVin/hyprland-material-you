#!/bin/bash
killall -9 Hyprland
loginctl terminate-user $USER
sleep 2
