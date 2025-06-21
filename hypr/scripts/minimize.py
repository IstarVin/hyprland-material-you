#!/usr/bin/python3

import os
import subprocess
import json
import argparse
import time

parser = argparse.ArgumentParser()
parser.add_argument("window", type=str)
parser.add_argument("exec", type=str)
args = parser.parse_args()

clients_json = subprocess.run(
    ["hyprctl", "-j", "clients"], capture_output=True, text=True
).stdout
clients = json.loads(clients_json)

win_attr, win_data = args.window.split(":")

exists = False
window = None

for i in clients:
    if i[win_attr] == win_data:
        window = i
        exists = True
        break

if not exists:
    subprocess.run(['hyprctl', 'dispatch', 'exec', '[float]', args.exec])
    subprocess.run(['hyprctl', 'dispatch', 'focuswindow', args.window])
    print("started")
    exit()

current_window_json = subprocess.run(
    ["hyprctl", "-j", "activewindow"], capture_output=True, text=True
).stdout
current_window = json.loads(current_window_json)

if current_window != {}:
    current_workspace = current_window["workspace"]["id"]
    ws = current_window["workspace"]["name"]
else:
    current_wokrspace_json = subprocess.run(
        ["hyprctl", "-j", "activeworkspace"], capture_output=True, text=True
    ).stdout
    current_workspace = json.loads(current_wokrspace_json)["id"]
    ws = current_workspace

# time.sleep(2)

if window["workspace"]["id"] != current_workspace:
    print(ws, args.window)
    subprocess.run(['hyprctl', 'dispatch', 'movetoworkspacesilent', f'{ws},{args.window}'])
    subprocess.run(['hyprctl', 'dispatch', 'focuswindow', args.window])

else:
    if window["focusHistoryID"] == 0:
        subprocess.run(['hyprctl', 'dispatch', 'movetoworkspacesilent', f'99,{args.window}'])
    else:
        subprocess.run(['hyprctl', 'dispatch', 'focuswindow', args.window])
