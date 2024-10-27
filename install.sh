#!/bin/bash

if ! grep -q "arch" /etc/os-release; then
    echo ":: This script is designed to run on Arch Linux."
    exit 1
fi

if [ ! -d "$HOME/dotfiles" ]; then
    echo ":: The directory $HOME/dotfiles does not exist."
    exit 1
fi

execute_command() {
    while true; do
        "$@"
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            break
        else
            echo "Command failed with exit code $exit_code."
            choice=$(gum choose "Continue the script" "Retry the command" "Exit the script")
            case $choice in
            "Continue the script") break ;;
            "Retry the command") continue ;;
            "Exit the script") exit 1 ;;
            esac
        fi
    done
}

proceed() {
    local message=$1
    local exit_on_no=${2:-true}
    echo "$message"
    # if gum confirm "$message"; then
    # 	return 0
    # else
    # 	echo ":: Skipping $message."
    # 	if $exit_on_no; then
    # 		echo ":: Exiting script."
    # 		exit 0
    # 	else
    # 		return 1
    # 	fi
    # fi
}

preference_select() {
    local type=$1
    shift
    local app_type=$1
    shift
    local CHOICE=$1
    # local options=("$@")

    # gum style \
    # 	--foreground 212 --border-foreground 212 --border normal \
    # 	--align center --width 50 --margin "0 2" --padding "1 2" \
    # 	"Select a(n) $type to install"

    # CHOICE=$(gum choose "${options[@]}" "NONE")

    if [[ $CHOICE != "NONE" ]]; then
        execute_command yay -Sy
        execute_command yay -S --needed --noconfirm $CHOICE
        python -O "$HOME"/dotfiles/ags/scripts/apps.py --"$app_type" $CHOICE
    else
        echo "Not installing a(n) $type..."
        sleep .4
    fi
}

install_yay() {
    echo ":: Installing yay..."
    execute_command sudo pacman -Sy
    execute_command sudo pacman -S --needed --noconfirm base-devel git
    execute_command git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    execute_command makepkg -si --noconfirm --needed
}

install_microtex() {
    cd ~/dotfiles/setup/MicroTex/
    execute_command makepkg -si
}

install_packages() {
    echo ":: Installing packages"
    sleep 1
    yay -Sy
    execute_command yay -S --noconfirm --needed \
        hyprland hyprshot hyprcursor hypridle hyprlang hyprpaper hyprpicker hyprlock \
        hyprutils hyprwayland-scanner xdg-dbus-proxy xdg-desktop-portal \
        xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs \
        xdg-utils libxdg-basedir python-pyxdg aylurs-gtk-shell swww gtk3 gtk4 \
        adw-gtk-theme libdbusmenu-gtk3 python-pip python-pillow sddm \
        sddm-theme-corners-git nm-connection-editor network-manager-applet \
        networkmanager gnome-bluetooth-3.0 wl-gammarelay-rs bluez bluez-libs bluez-utils \
        cliphist wl-clipboard libadwaita swappy nwg-look \
        pavucontrol polkit-gnome brightnessctl man-pages gvfs xarchiver zip imagemagick \
        blueman fastfetch bibata-cursor-theme gum python-pywayland dbus \
        libdrm mesa fwupd bun-bin pipewire wireplumber udiskie \
        lm_sensors gnome-system-monitor playerctl ttf-meslo-nerd ttf-google-sans \
        ttf-font-awesome ttf-opensans ttf-roboto lshw ttf-material-symbols-variable-git \
        fontconfig dart-sass ttf-meslo-nerd-font-powerlevel10k cpio meson cmake \
        python-materialyoucolor-git gtksourceview3 gtksourceviewmm cairomm \
        gtkmm3 tinyxml2 python-requests python-numpy lsd fzf zoxide zsh bat less \
        yazi p7zip fd ffmpegthumbnailer chafa poppler \
        unzip tmux go bluetooth-autoconnect btop powertop \
        neovim ntfs-3g nautilus-code nautilus-open-any-terminal mpv tailscale \
        gnome-system-monitor gnome-text-editor ufw encfs seahorse gvfs-smb amdvlk reflector \
        python-setproctitle

}

setup_yay() {
    if command -v yay &>/dev/null; then
        echo ":: Yay is installed"
        sleep 1
    else
        echo ":: Yay is not installed!"
        sleep 1
        install_yay
    fi
}

setup_sensors() {
    execute_command sudo sensors-detect --auto >/dev/null
}

check_config_folders() {
    local CHECK_CONFIG_FOLDERS="ags alacritty hypr swappy"
    local DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
    local EXISTING="NO"

    mkdir -p "$HOME/.backup/$DATETIME/"

    for dir in $CHECK_CONFIG_FOLDERS; do
        if [ -d "$HOME/.config/$dir" ]; then
            echo ":: Attention: directory $dir already exists in .config"
            mv $HOME/.config/$dir "$HOME/.backup/$DATETIME/"
            EXISTING="YES"
        fi
    done

    if [[ $EXISTING == "YES" ]]; then
        echo ":: Old config folder(s) backed up at ~/.backup folder"
    fi
}

install_icon_theme() {
    gum style \
        --foreground 212 --border-foreground 212 --border normal \
        --align center --width 50 --margin "0 2" --padding "1 2" \
        "Select an icon theme to install"

    CHOICE=$(gum choose "Tela Icon Theme" "Papirus Icon Theme" "Adwaita Icon Theme")

    if [[ $CHOICE == "Tela Icon Theme" ]]; then
        echo ":: Installing Tela icons..."
        mkdir -p /tmp/install
        cd /tmp/install
        git clone https://github.com/vinceliuice/Tela-icon-theme
        cd Tela-icon-theme

        gum style \
            --foreground 212 --border-foreground 212 --border normal \
            --align center --width 50 --margin "0 2" --padding "1 2" \
            "Select a color theme"

        COLOR_CHOICE=$(gum choose --height=20 "nord" "black" "blue" "green" "grey" "orange" \
            "pink" "purple" "red" "yellow" "brown")

        ./install.sh $COLOR_CHOICE
        echo -e "Tela-$COLOR_CHOICE-dark\nTela-$COLOR_CHOICE-light" >$HOME/dotfiles/.settings/icon-theme
        cd $HOME/dotfiles

    elif [[ $CHOICE == "Papirus Icon Theme" ]]; then
        yay -S --noconfirm --needed papirus-icon-theme papirus-folders

        echo -e "Papirus-Dark\nPapirus-Light" >$HOME/dotfiles/.settings/icon-theme

        gum style \
            --foreground 212 --border-foreground 212 --border normal \
            --align center --width 50 --margin "0 2" --padding "1 2" \
            "Select a color theme"

        COLOR_CHOICE=$(gum choose --height=20 "black" "blue" "cyan" "green" "grey" "indigo" \
            "brown" "purple" "nordic" "pink" "red" "deeporange" "white" "yellow")

        papirus-folders -C $COLOR_CHOICE

    else
        yay -S --noconfirm --needed adwaita-icon-theme
        echo -e "Adwaita\nAdwaita" >$HOME/dotfiles/.settings/icon-theme
    fi
}

setup_colors() {
    echo ":: Setting colors"
    execute_command python -O $HOME/dotfiles/material-colors/generate.py --color "#0000FF"
}

setup_sddm() {
    echo ":: Setting SDDM"
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp $HOME/dotfiles/sddm/sddm.conf /etc/sddm.conf.d/
    sudo cp $HOME/dotfiles/sddm/sddm.conf /etc/
    sudo chmod 777 /etc/sddm.conf.d/sddm.conf
    sudo chmod 777 /etc/sddm.conf
    sudo chmod -R 777 /usr/share/sddm/themes/corners/
    "$HOME"/dotfiles/sddm/scripts/wallpaper.sh
}

copy_files() {
    echo ":: Copying files"
    mkdir -p $HOME/.config
    "$HOME"/dotfiles/setup/copy.sh
    if [ -d "$HOME/wallpaper" ]; then
        echo ":: Error: directory wallpaper already exists in home"
    else
        cp -r $HOME/dotfiles/wallpapers $HOME/wallpaper
    fi
}

create_links() {
    echo ":: Creating links"
    ln -f $HOME/dotfiles/electron-flags.conf $HOME/.config/electron-flags.conf
    ln -s $HOME/dotfiles/ags $HOME/.config/ags
    ln -s $HOME/dotfiles/alacritty $HOME/.config/alacritty
    ln -s $HOME/dotfiles/hypr $HOME/.config/hypr
    ln -s $HOME/dotfiles/swappy $HOME/.config/swappy

    cd $main_cwd

    find .dots -maxdepth 1 -mindepth 1 |
        while read i; do
            rm -rf "${HOME:-/home/$USER}/$(basename "$i")"
            ln -sf "$(pwd)/$i" "${HOME:-/home/$USER}/$(basename "$i")"
        done

    find .config -maxdepth 1 -mindepth 1 |
        while read i; do
            rm -rf "$HOME/$i"
            ln -sf "$(pwd)/$i" "$HOME/$i"
        done
}

install_vencord() {
    echo ":: Vencord"
    sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"
    mkdir -p $HOME/.config/Vencord/settings/
    ln -f $HOME/.cache/material/material-discord.css $HOME/.config/Vencord/settings/quickCss.css
}

remove_gtk_buttons() {
    echo ":: Remove window close and minimize buttons in GTK"
    gsettings set org.gnome.desktop.wm.preferences button-layout ':'
}

setup_services() {
    echo ":: Services"

    if systemctl is-active --quiet bluetooth.service; then
        echo ":: bluetooth.service already running."
    else
        sudo systemctl enable bluetooth.service
        sudo systemctl start bluetooth.service
        echo ":: bluetooth.service activated successfully."
    fi

    if systemctl is-active --quiet NetworkManager.service; then
        echo ":: NetworkManager.service already running."
    else
        sudo systemctl enable NetworkManager.service
        sudo systemctl start NetworkManager.service
        echo ":: NetworkManager.service activated successfully."
    fi

    sudo systemctl enable sddm
}

update_user_dirs() {
    echo ":: User dirs"
    xdg-user-dirs-update
}

misc_tasks() {
    echo ":: Misc"
    hyprctl reload
    ags --init
    execute_command python $HOME/dotfiles/hypr/scripts/wallpaper.py -R
    use_zsh

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

use_zsh() {
    sudo chsh -s zsh aj
}

aj_disk() {
    uuid="a670b2de-99ca-43e3-8c34-3fc50150c12e"
    if sudo blkid | grep $uuid >/dev/null 2>&1; then
        sudo mkdir /mnt/AJ/
        user=$(whoami)
        sudo chown $user:$user /mnt/AJ/
        echo -ne "
# AJ
UUID=$uuid /mnt/AJ btrfs defaults 0 2
" | sudo tee -a /etc/fstab

        sudo mount -a
        sudo systemctl daemon-reload

        ln -sf /mnt/AJ $HOME/AJ
        ln -sf /mnt/AJ/{Documents,Downloads,Pictures,Projects,Videos} $HOME

        cp -r /mnt/AJ/.ssh/ $HOME
        # cwd=$(pwd)
        # cd $main_cwd
        # bash link_configs.sh
        # cd $cwd

        mkdir ~/.hehe
    fi
}

plymouth_install() {
    yay -S --noconfirm plymouth plymouth-theme-archlinux
    if pacman -Q grub >/dev/null 2>&1; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash/' /etc/default/grub
        sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub

        sudo sed -i '/echo "\$message"/d' /etc/grub.d/10_linux

        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    sudo sed -i '/^HOOKS/s/udev/& plymouth/' /etc/mkinitcpio.conf

    sudo plymouth-set-default-theme -R archlinux
}

evremap_install() {
    cd $main_cwd

    yay -S --noconfirm evremap
    sudo cp -f evremap/evremap.toml /etc
    sudo cp -f evremap/evremap.service /etc/systemd/user
    sudo systemctl enable --now evremap
}

rog_install() {
    if ! pacman -Q cachyos-mirrorlist >/dev/null 2>&1; then
        sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
        sudo pacman-key --finger 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
        sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
        sudo pacman-key --finger 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35

        wget "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x8b15a6b0e9a3fa35" -O /tmp/g14.sec
        sudo pacman-key -a /tmp/g14.sec
        rm /tmp/g14.sec

        echo -ne "
 [g14]
 Server = https://arch.asus-linux.org
 " | sudo tee -a /etc/pacman.conf
    fi

    sudo pacman -Suy --noconfirm asusctl power-profiles-daemon supergfxctl switcheroo-control
    sudo systemctl enable --now power-profiles-daemon supergfxd switcheroo-control

    asusctl -c 60
    asusctl led-mode static -c 614F9A
    echo "Skip if fail"
}

rog_setup() {
    if hostnamectl status | grep ROG >/dev/null 2>&1; then
        rog_install
        evremap_install
    fi
}

main() {
    main_cwd=$(pwd)

    if [[ $1 == "packages" ]]; then
        setup_yay
        install_packages
        exit 0
    fi

    setup_yay
    if ! command -v gum &>/dev/null; then
        echo ":: gum not installed"
        execute_command sudo pacman -S gum
    fi

    proceed "Proceed with installing packages?" false && install_packages
    preference_select "file manager" "filemanager" "nautilus"
    preference_select "internet browser" "browser" "brave"
    preference_select "terminal emulator" "terminal" "alacritty"
    proceed "Proceed with installing MicroTex?" false && install_microtex
    proceed "Proceed with setting up sensors?" false && setup_sensors
    proceed "Proceed with checking config folders?*" && check_config_folders
    proceed "Proceed with installing icon themes?" false && install_icon_theme
    proceed "Proceed with setting up SDDM?" false && setup_sddm
    proceed "Proceed with copying files?*" && copy_files
    proceed "Proceed with creating links?*" && create_links
    proceed "Proceed with setting up colors?*" && setup_colors
    # ask_continue "Proceed with installing Vencord?" false && install_vencord
    proceed "Proceed with removing GTK buttons?" false && remove_gtk_buttons
    proceed "Proceed with setting up services?*" && setup_services
    # proceed "Proceed with updating user directories?*" && update_user_dirs
    proceed "Proceed with miscellaneous tasks?*" && misc_tasks
    proceed "Plymouth Install" && plymouth_install
    proceed "Setup ROG" && rog_setup
    proceed "Setup AJ Disk" && aj_disk

    echo "Please restart your PC"
}

main "$@"
