#!/bin/python3


import json
import os
import subprocess

clients_json = subprocess.run(
    ["hyprctl", "-j", "clients"], capture_output=True, text=True
).stdout
clients = json.loads(clients_json)

music_is_open = False


for i in clients:
    print(i.get("title"))
    if "YouTube Music" in i.get("title"):
        music_is_open = True


if not music_is_open:
    os.system("youtube-music")

os.system("playerctl play-pause")
