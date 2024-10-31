// by koeqaife ;)

const battery = await Service.import("battery");

const battery_messages = {
<<<<<<< HEAD
    warnLevels: [15, 5],
    warnTitles: ["Low battery", "Very low battery"],
    warnMessages: ["Plug in the charger", "You there?"],
=======
    warnLevels: [15, 5, 1],
    warnTitles: ["Low battery", "Very low battery", "Critical Battery"],
    warnMessages: ["Plug in the charger", "Please plug in the charger", "Your PC is about to shut down"]
>>>>>>> 206781c0dfe78404143c6395af4cbbc056d101c2
};

let last_warning = 101;

async function notifyUser(index) {
    Utils.execAsync([
        "bash",
        "-c",
        `notify-send "${battery_messages.warnTitles[index]}" "${battery_messages.warnMessages[index]}" -u critical &`
    ]).catch(print);
}

async function battery_notification() {
    const percent = battery.percent;
    const charging = battery.charging;
    if (charging) {
        last_warning = 101;
        return;
    }
<<<<<<< HEAD
    for (let i = battery_messages.warnLevels.length - 1; i >= 0; i--) {
        if (
            percent <= battery_messages.warnLevels[i] && !charging &&
            !battery_warned
        ) {
            battery_warned = true;
            Utils.execAsync([
                "bash",
                "-c",
                `notify-send "${battery_messages.warnTitles[i]}" "${battery_messages.warnMessages[i]}" -u critical &`,
            ]).catch(print);
            break;
        }
=======

    const warningLevel = battery_messages.warnLevels
        .slice()
        .reverse()
        .find((level) => percent <= level && last_warning > level);

    if (warningLevel !== undefined) {
        const index = battery_messages.warnLevels.indexOf(warningLevel);
        last_warning = percent;
        await notifyUser(index);
>>>>>>> 206781c0dfe78404143c6395af4cbbc056d101c2
    }
}

export async function start_battery_warning_service() {
    Utils.timeout(1, () => {
        battery_notification().catch(print);
        battery.connect("changed", () => battery_notification().catch(print));
    });
}
