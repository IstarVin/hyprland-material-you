// by koeqaife ;)

const hyprland = await Service.import("hyprland");
const battery = await Service.import("battery");
const systemtray = await Service.import("systemtray");
const audio = await Service.import("audio");
const network = await Service.import("network");
const bluetooth = await Service.import("bluetooth");
const mpris = await Service.import("mpris");
const powerProfiles = await Service.import("powerprofiles");
const { GLib, Gio } = imports.gi;
const decoder = new TextDecoder();
import { OpenSettings } from "apps/settings/main.ts";
import { MaterialIcon } from "icons.js";
import config from "services/configuration.ts";
import { FileEnumerator, FileInfo } from "types/@girs/gio-2.0/gio-2.0.cjs";
import { Client } from "types/service/hyprland.js";
import { Variable as VariableType } from "types/variable";
import Button from "types/widgets/button.js";
import Icon from "types/widgets/icon.js";
import { idle_inhibitor } from "../variables.ts";
import { RoundedCorner } from "./misc/cairo_roundedcorner.js";
import { enable_click_through } from "./misc/clickthrough.js";
import { toggleAppsWindow, toggleMediaWindow } from "./sideleft/main.js";

import Gtk from "gi://Gtk?version=3.0";

const keyboard_layout = Variable("none");
hyprland.connect("keyboard-layout", (hyprland, keyboardname, layoutname) => {
    keyboard_layout.setValue(layoutname.trim().toLowerCase().substr(0, 2));
});

const MATERIAL_SYMBOL_SIGNAL_STRENGTH = {
    "network-wireless-signal-excellent-symbolic": "signal_wifi_4_bar",
    "network-wireless-signal-good-symbolic": "network_wifi_3_bar",
    "network-wireless-signal-ok-symbolic": "network_wifi_2_bar",
    "network-wireless-signal-weak-symbolic": "network_wifi_1_bar",
    "network-wireless-signal-none-symbolic": "signal_wifi_0_bar"
};

const time = Variable("");
const date = Variable("");

function getCurrentDateAndTime() {
    // const _date = new Date();

    // const year = _date.getFullYear();
    // const month = String(_date.getMonth() + 1).padStart(2, "0");
    // const day = String(_date.getDate()).padStart(2, "0");

    // const hours = String(_date.getHours()).padStart(2, "0");
    // const minutes = String(_date.getMinutes()).padStart(2, "0");

    const formattedDate = GLib.DateTime.new_now_local().format("%A"); // `${year}-${month}-${day}`;
    const formattedTime = GLib.DateTime.new_now_local().format("%I:%M %p"); // `${hours}:${minutes}`
    // const formattedDate = `${year}-${month}-${day}`;
    // const formattedTime = `${hours}:${minutes}`

    if (time.value != formattedTime) time.setValue(formattedTime!);
    if (date.value != formattedDate) date.setValue(formattedDate!);
}
Utils.interval(1000, getCurrentDateAndTime);

function getIconNameFromClass(windowClass: string) {
    try {
        if (windowClass === 'com.github.th_ch.youtube_music') {
            windowClass = 'youtube-music'
        }
        if (windowClass.includes('deepseek')) {
            return Utils.lookUpIcon('deepseek') ? 'deepseek' : "image-missing";
        } else if (windowClass.includes('chatgpt')) {
            return Utils.lookUpIcon('chatgpt') ? 'chatgpt' : "image-missing";
        }
        
        let formattedClass = windowClass.replace(/\s+/g, "-").toLowerCase();
        let homeDir = GLib.get_home_dir();
        let systemDataDirs = GLib.get_system_data_dirs().map((dir) => dir + "/applications");
        let dataDirs = systemDataDirs.concat([homeDir + "/.local/share/applications"]);
        let icon: string | undefined;

        for (let dir of dataDirs) {
            let applicationsGFile = Gio.File.new_for_path(dir);

            let enumerator: FileEnumerator;
            try {
                enumerator = applicationsGFile.enumerate_children(
                    "standard::name,standard::type",
                    Gio.FileQueryInfoFlags.NONE,
                    null
                );
            } catch (e) {
                continue;
            }

            let fileInfo: FileInfo | null;
            while ((fileInfo = enumerator.next_file(null)) !== null) {
                let desktopFile = fileInfo.get_name();
                if (desktopFile.endsWith(".desktop")) {
                    let fileContents = GLib.file_get_contents(dir + "/" + desktopFile);
                    let matches = /Icon=(\S+)/.exec(decoder.decode(fileContents[1]));
                    if (matches && matches[1]) {
                        if (desktopFile.toLowerCase().includes(formattedClass)) {
                            icon = matches[1];
                            break;
                        }
                    }
                }
            }

            enumerator.close(null);
            if (icon) break;
        }
        return Utils.lookUpIcon(icon) ? icon : "image-missing";
    } catch (e) {
        print("Error getting icon name from class:", e);
        return "image-missing";
    }
}

const dispatch = (ws: string) => hyprland.messageAsync(`dispatch workspace ${ws}`).catch(print);


function Workspaces() {
    let workspace_buttons = new Map<Number, ReturnType<typeof createWorkspaceButton>>();
    const workspace_buttons_array: VariableType<Button<any, any>[] | any> = Variable([]);
    let currentWorkspaceGroup = 0;

    function createWorkspaceButton(id: Number) {
        return Widget.Button({
            on_clicked: () => dispatch(`${id}`),
            child: Widget.Label(`${id}`),
            attribute: { id: id, map: false },
            class_name: "workspace"
        });
    }

    function initializeWorkspaceButtons() {
        const addition = currentWorkspaceGroup * 10
        workspace_buttons.clear()
        for (let i = 1 + addition; i <= 10 + addition; i++) {
            workspace_buttons.set(i, createWorkspaceButton(i));
        }
        workspace_buttons_array.setValue(Array.from(workspace_buttons.values()));
    }

    function update() {
        const asd = Array.from(workspace_buttons.keys()) as number[]
        const previous = Math.floor(asd[0] / 10)
        if (previous !== currentWorkspaceGroup) {
            initializeWorkspaceButtons()
        }
        workspace_buttons.forEach((workspace) => {
            const existingWorkspace = hyprland.workspaces.some((element) => element.id === workspace.attribute.id);
            if (config.config.hide_empty_workspaces) {
                if (!workspace.attribute.map) {
                    let mapSignalId = workspace.connect("map", () => {
                        workspace.set_visible(existingWorkspace);
                        workspace.disconnect(mapSignalId);
                    });
                    workspace.attribute.map = true;
                } else workspace.set_visible(existingWorkspace);
            } else {
                workspace.set_visible(true);
            }
            workspace.toggleClassName("exists", existingWorkspace);
        });
    }

    function activeWorkspace() {
        workspace_buttons.forEach((workspace, key) => {
            workspace.toggleClassName("active", workspace.attribute.id == hyprland.active.workspace.id);
        });
    }

    hyprland.connect("notify::workspaces", () => {
        currentWorkspaceGroup = Math.floor((hyprland.active.workspace.id - 1) / 10);
        activeWorkspace();
        update();
        
    });
    hyprland.connect("notify::active", () => {
        currentWorkspaceGroup = Math.floor((hyprland.active.workspace.id - 1) / 10);
        activeWorkspace();
        update();
    });
    config.connect("notify::config", () => update());

    initializeWorkspaceButtons();
    activeWorkspace();
    update();

    return Widget.EventBox({
        on_scroll_up: () => dispatch("-1"),
        on_scroll_down: () => dispatch("+1"),
        hpack: "center",
        child: Widget.Box({
            children: workspace_buttons_array.bind(),
            class_name: "workspaces"
        })
    });
}

function Clock() {
    return Widget.Button({
        class_name: "clock",
        child: Widget.Box({
            orientation: Gtk.Orientation.VERTICAL,
            children: [
                Widget.Label({
                    class_name: "time",
                    label: time.bind()
                }),
                Widget.Label({
                    class_name: "date",
                    label: date.bind()
                })
            ]
        }),
        on_clicked: (self) => {
            App.toggleWindow("calendar");
        }
    });
}

function NetworkMeter() {
    return Widget.Box({
        children: [
            Widget.Box({
                class_name: "",
                visible: true,
                children: [MaterialIcon("download_2", "16px"), Widget.Label({})]
            }),
            Widget.Box({
                class_name: "",
                visible: true,
                children: [MaterialIcon("upload_2", "16px"), Widget.Label({})]
            })
        ]
    });
}

const battery_icons = {
    charging: {
        100: "battery_charging_full",
        90: "battery_charging_90",
        80: "battery_charging_80",
        70: "battery_charging_80",
        60: "battery_charging_60",
        50: "battery_charging_50",
        40: "battery_charging_30",
        30: "battery_charging_30",
        20: "battery_charging_20",
        10: "battery_charging_20",
        0: "battery_charging_20"
    },
    100: "battery_full",
    90: "battery_6_bar",
    80: "battery_5_bar",
    70: "battery_5_bar",
    60: "battery_4_bar",
    50: "battery_3_bar",
    40: "battery_2_bar",
    30: "battery_2_bar",
    20: "battery_1_bar",
    10: "battery_1_bar",
    0: "battery_alert"
};

function getClosestBatteryLevel(level: number, charging: boolean = false) {
    const array = !charging ? battery_icons : battery_icons.charging;
    const levels = Object.keys(array)
        .map(Number)
        .sort((a, b) => b - a);
    for (let i = 0; i < levels.length; i++) {
        if (level >= levels[i]) {
            return array[levels[i]];
        }
    }
    return array[levels[levels.length - 1]];
}

function BatteryLabel() {
    return Widget.Box({
        class_name: "battery",
        visible: false,
        children: [
            MaterialIcon(getClosestBatteryLevel(battery.percent, battery.charging), "16px"),
            Widget.Label({
                label: battery.bind("percent").as((p) => `${p > 0 ? p : 0}%`),
                visible: config.bind("config").as((config) => config.show_battery_percent)
            }),
            Widget.Label({
                label: battery.bind("energy_rate").as((energy_rate) => `  ${energy_rate.toFixed(2)}W`),
                visible: battery.bind("energy_rate").as((energy_rate) => energy_rate != 0)
            })
        ],
        // tooltip_text: battery.bind("percent").as((p) => `Battery: ${p > 0 ? p : 0}%`),
        tooltip_text: battery.bind("time_remaining").as((seconds) => {
            const hours = Math.floor(seconds / 3600); // 1 hour = 3600 seconds
            const minutes = Math.floor((seconds % 3600) / 60); // Remaining minutes
            // const remainingSeconds = seconds % 60; // Remaining seconds (if needed)

            return `${hours} hr ${minutes} min`;
        }),
        setup: (self) => {
            self.hook(battery, () => {
                try {
                    self.children[0].label = getClosestBatteryLevel(battery.percent, battery.charging);
                    self.visible = (battery.percent < 100 && battery.available) || config.config.always_show_battery;
                    self.toggleClassName("critical", battery.percent < 15);
                } catch (e) {
                    print("Error updating battery icon:", e);
                }
            });
            self.hook(config, () => {
                try {
                    if (config.config.always_show_battery) {
                        self.visible = true;
                    } else {
                        self.visible = battery.percent < 100 && battery.available;
                    }
                } catch (e) {
                    print("Error updating battery icon visible:", e);
                }
            });
        }
    });
}

function SysTray() {
    return Widget.Box({
        class_name: "tray",
        spacing: 5,
        setup: (self) => {
            self.hook(systemtray, () => {
                try {
                    if (!systemtray || !systemtray.items) {
                        print("Systemtray or items is undefined");
                        return;
                    }
                    const items = systemtray.items;
                    // @ts-expect-error
                    self.children = items.map((item) => {
                        if (!item.id) return undefined;
                        if (item.id.trim() != "nm-applet" && item.id.trim() != "blueman") {
                            return Widget.Button({
                                child: Widget.Icon({ icon: item.bind("icon"), size: 16 }),
                                on_primary_click_release: (_, event) => item.activate(event),
                                on_secondary_click_release: (_, event) => item.openMenu(event),
                                tooltip_markup: item.bind("tooltip_markup")
                            });
                        } else {
                            return undefined;
                        }
                    });
                    if (self.children.length > 0) self.visible = true;
                    else self.visible = false;
                } catch (e) {
                    print("Could not update system tray:", e);
                    self.visible = false;
                }
            });
        }
    });
}

function AppLauncher() {
    const button = Widget.Button({
        class_name: "filled_tonal_button",
        on_clicked: () => {
            toggleAppsWindow();
        },
        child: MaterialIcon("search"),
        setup: (self) => {
            self.hook(config, () => {
                try {
                    if (config.config.hide_applauncher_button != !self.is_visible())
                        self.set_visible(!config.config.hide_applauncher_button);
                } catch (e) {
                    print("Error updating app launcher button visibility:", e);
                }
            });
        }
    });

    return button;
}

function OpenSideLeft() {
    const button = Widget.Button({
        class_name: "filled_tonal_button",
        visible: false,
        on_clicked: () => {
            App.toggleWindow("sideleft");
        },
        child: MaterialIcon("dock_to_right")
    });

    return button;
}

function Network() {
    return Widget.Button({
        class_name: "bar_wifi",
        on_primary_click_release: () => {
            OpenSettings("network");
        },
        on_secondary_click_release: (_, event) => {
            const nm_applet = systemtray.items.find((item) => item.id == "nm-applet");
            if (nm_applet) {
                nm_applet.openMenu(event);
            } else {
                Utils.execAsync("nm-connection-editor").catch(print);
            }
        },
        child: MaterialIcon("signal_wifi_off", "16px"),
        tooltip_text: "Disabled"
    }).hook(network, (self) => {
        try {
            if (network.wired.internet === "connected") {
            self.tooltip_text = "Wired Connection";
            self.child.label = "settings_ethernet";
        } else if (network.wifi.enabled) {
                self.tooltip_text = network.wifi.ssid || "Unknown";
                self.child.label = MATERIAL_SYMBOL_SIGNAL_STRENGTH[network.wifi.icon_name] || "signal_wifi_off";
            } else {
                self.tooltip_text = "Disabled";
                self.child.label = "signal_wifi_off";
            }
        } catch (e) {
            print("Error updating wifi icon:", e);
        }
    });
}

function Bluetooth() {
    return Widget.Button({
        class_name: "bar_bluetooth",
        on_primary_click_release: () => {
            OpenSettings("bluetooth");
        },
        on_secondary_click_release: (_, event) => {
            const blueman = systemtray.items.find((item) => item.id == "blueman");
            if (blueman) {
                blueman.openMenu(event);
            } else {
                Utils.execAsync("blueman-manager").catch(print);
            }
        },
        child: MaterialIcon("bluetooth_disabled", "16px")
    }).hook(bluetooth, (self) => {
        try {
            if (bluetooth.connected_devices.length > 0) {
                self.child.label = "bluetooth_connected";
            } else if (bluetooth.enabled) {
                self.child.label = "bluetooth";
            } else {
                self.child.label = "bluetooth_disabled";
            }
        } catch (e) {
            print("Error updating bluetooth icon:", e);
        }
    });
}

function MediaPlayer() {
    let metadata = mpris.players[0]?.metadata;
    const button = Widget.Button({
        class_name: "filled_tonal_button",
        on_primary_click_release: () => {
            toggleMediaWindow();
        },
        on_middle_click_release: () => {
            Utils.execAsync(["playerctl", "play-pause"]).catch(print);
        },
        on_secondary_click_release: () => {
            Utils.execAsync(["hyprctl", "dispatch", "togglespecialworkspace", "music"]);
        },
        child: MaterialIcon("play_circle"),
        visible: false,
        tooltip_text: "Unknown"
    })
        .hook(mpris, (self) => {
            try {
                if (mpris.players.length > 0) {
                    self.visible = !config.config.hide_media_button && true;
                    metadata = mpris.players[0]?.metadata;
                    if (metadata) self.tooltip_text = `${metadata["xesam:artist"]} - ${metadata["xesam:title"]}`;
                } else {
                    self.visible = false;
                    self.tooltip_text = "Unknown";
                }
            } catch (e) {
                print("Error updating media player icon:", e);
            }
        })
        .hook(config, (self) => {
            try {
                if (mpris.players.length > 0) {
                    if (config.config.hide_media_button != !self.is_visible())
                        self.set_visible(!config.config.hide_media_button);
                }
            } catch (e) {
                print("Error updating media player button visibility:", e);
            }
        });

    return button;
}

function KeyboardLayout() {
    const widget = Widget.Label({
        class_name: "keyboard",
        visible: keyboard_layout.bind().as((c) => c != "none"),
        // visible: false,
        label: keyboard_layout.bind()
    });
    return widget;
}

function OpenSideBar() {
    const button = Widget.Button({
        class_name: "filled_tonal_button",
        visible: false,
        on_primary_click_release: () => {
            App.toggleWindow("sidebar");
        },
        on_secondary_click_release: () => {
            OpenSettings();
        },
        child: MaterialIcon("dock_to_left")
    });

    return button;
}

const focus = ({ address }) => Utils.execAsync(`hyprctl dispatch focuswindow address:${address}`).catch(print);

function TaskBar() {
    if (!config.config.show_taskbar) {
        return undefined;
    }
    let globalWidgets: Button<Icon<any>, any>[] = [];

    function Clients(clients: Client[]) {
        const currentClientIds = clients.map((client) => client.address);
        globalWidgets = globalWidgets.filter((widget) => currentClientIds.includes(widget.attribute.client.address));

        globalWidgets.sort((a, b) => {
            if (a.attribute.pid == b.attribute.pid) {
                return a.attribute.workspace - b.attribute.workspace;
            }
            return a.attribute.pid - b.attribute.pid;
        });

        clients.forEach((client) => {
            if (client.class === "Alacritty" || client.class === 'kitty') return;

            let widget = globalWidgets.find((w) => w.attribute.client.address === client.address);

            if (widget) {
                widget.tooltip_markup = client.title;
            } else {
                let icon: string | undefined;
                if (client.class === "com.github.Aylur.ags") {
                    icon =
                        client.initialTitle === "Settings"
                            ? "emblem-system-symbolic"
                            : client.initialTitle === "Emoji Picker"
                            ? "face-smile-symbolic"
                            : undefined;
                } else {
                    icon = getIconNameFromClass(client.class);
                }

                widget = Widget.Button({
                    attribute: {
                        client: client,
                        workspace: client.workspace,
                        pid: client.pid
                    },
                    child: Widget.Icon({ icon, size: 16 }),
                    tooltip_markup: client.title,
                    on_clicked: () => focus(client)
                });
                globalWidgets.push(widget);
            }
        });
        return globalWidgets;
    }

    return Widget.Box({
        class_name: "tray",
        spacing: 5,
        setup: (self) => {
            self.hook(hyprland, () => {
                try {
                    self.children = Clients(hyprland.clients);
                    self.visible = self.children.length > 0;
                } catch (e) {
                    print("Could not update taskbar:", e);
                    self.visible = false;
                }
            });
        }
    });
}

function VolumeIndicator() {
    return Widget.EventBox({
        on_scroll_up: () => (audio.speaker.volume += 0.01),
        on_scroll_down: () => (audio.speaker.volume -= 0.01),
        class_name: "volume_box",
        child: Widget.Button({
            on_primary_click_release: () => App.toggleWindow("audio"),
            // on_middle_click_release: () => (audio.speaker.is_muted = !audio.speaker.is_muted),
            on_middle_click_release: () => Utils.execAsync(`${App.configDir}/scripts/toggle-audio-out`),
            on_secondary_click_release: () => Utils.execAsync("pavucontrol -t 3").catch(print),
            child: MaterialIcon("volume_off", "16px").hook(audio.speaker, (self) => {
                try {
                    const vol = audio.speaker.volume * 100;
                    const icon = [
                        [101, "sound_detection_loud_sound"],
                        [67, "volume_up"],
                        [34, "volume_down"],
                        [1, "volume_mute"],
                        [0, "volume_off"]
                    ].find(([threshold]) => Number(threshold) <= vol)?.[1];
                    if (audio.speaker.is_muted) self.label = "volume_off";
                    else self.label = String(icon!);
                    self.tooltip_text = `Volume ${Math.floor(vol)}%`;
                } catch (e) {
                    print("Error updating volume icon:", e);
                }
            })
        })
    });
}

function idleInhibitor() {
    return Widget.Button({
        child: MaterialIcon("coffee", "16px"),
        on_clicked: toggleIdleInhibitor
    }).hook(idle_inhibitor, (self) => {
        self.visible = idle_inhibitor.value;
    });
}

function powerProfile() {
    return Widget.Button({
        on_clicked: () => {
            if (powerProfiles.active_profile === "performance") {
                powerProfiles.active_profile = "power-saver";
            } else {
                powerProfiles.active_profile = "performance";
            }
        },
        on_secondary_click_release: () => {
            powerProfiles.active_profile = "balanced";
        },
        child: MaterialIcon("data_saver_on", "16px").hook(powerProfiles, (self) => {
            switch (powerProfiles.active_profile) {
                case "performance":
                    self.label = "speed";
                    self.tooltip_text = "Performance";
                    break;
                case "balanced":
                    self.label = "token";
                    self.tooltip_text = "Balanced";
                    break;
                case "power-saver":
                    self.label = "data_saver_on";
                    self.tooltip_text = "Power Saver";
                    break;
                default:
            }
        })
    });
}

const OpenClipHist = () =>
    Widget.Button({
        class_name: "bar_cliphist",
        on_clicked: (self) => App.toggleWindow("cliphist"),
        child: MaterialIcon("content_paste", "16px"),
        visible: !config.config.hide_cliphist_button,
        setup: (self) => {
            self.hook(config, () => {
                try {
                    self.set_visible(!config.config.hide_cliphist_button);
                } catch (e) {
                    print("Error updating cliphist button visibility:", e);
                }
            });
        }
    });

const Applets = () =>
    Widget.Box({
        class_name: "bar_applets",
        spacing: 5,
        children: [idleInhibitor(), powerProfile(), VolumeIndicator(), Bluetooth(), Network(), OpenClipHist()]
    });

const Dot = () =>
    Widget.Label({
        class_name: "dot",
        use_markup: true,
        label: "·",
        css: "font-weight: 900;"
    });

function Left() {
    const workspaces = config.config.workspaces_to_the_left ? Workspaces() : undefined;

    // @ts-expect-error
    return Widget.Box({
        // margin_left: 15,
        class_name: "modules_left",
        hpack: "start",
        spacing: 8,
        children: [AppLauncher(), MediaPlayer(), workspaces, TaskBar()] //, OpenSideLeft()
    });
}

function Center() {
    const workspaces = !config.config.workspaces_to_the_left ? Workspaces() : undefined;

    // @ts-expect-error
    return Widget.Box({
        class_name: "modules_center",
        hpack: "center",
        spacing: 8,
        children: [workspaces]
    });
}

function Right() {
    return Widget.Box({
        // margin_right: 15,
        class_name: "modules_right",
        hpack: "end",
        spacing: 8,
        children: [BatteryLabel(), SysTray(), Applets(), Clock(), OpenSideBar()]
        // KeyboardLayout(),
    });
}

export const Bar = async (monitor = 0) => {
    return Widget.Window({
        name: `bar-${monitor}`,
        class_name: "bar",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        child: Widget.CenterBox({
            start_widget: Left(),
            center_widget: Center(),
            end_widget: Right()
        })
    });
};

export const BarCornerTopLeft = (monitor = 0) =>
    Widget.Window({
        monitor,
        name: `bar_corner_tl${monitor}`,
        class_name: "transparent",
        layer: "top",
        anchor: ["top", "left"],
        exclusivity: "normal",
        visible: true,
        child: RoundedCorner("top_left", { className: "corner" }),
        setup: enable_click_through
    });

export const BarCornerTopRight = (monitor = 0) =>
    Widget.Window({
        monitor,
        name: `bar_corner_tr${monitor}`,
        class_name: "transparent",
        layer: "top",
        anchor: ["top", "right"],
        exclusivity: "normal",
        visible: true,
        child: RoundedCorner("top_right", { className: "corner" }),
        setup: enable_click_through
    });
