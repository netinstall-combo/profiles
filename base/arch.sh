#!/bin/bash

tool_init(){
    apk add zstd
}

install_base_system() {
    cd /target
    wget https://geo.mirror.pkgbuild.com/iso/latest/archlinux-bootstrap-x86_64.tar.zst -O - | zstdcat | \
    tar -xvf -
    ls /target/ | while read line ; do
        rm -rf /target/root.x86_64/$line || true
    done
    mv root.x86_64/* ./
    rm -rf pkglist.x86_64.txt root.x86_64
    cat /etc/resolv.conf > /target/etc/resolv.conf
    sed -i "s|#Server = https://geo.mirror.pkgbuild.com|Server = https://geo.mirror.pkgbuild.com|g" \
        /target/etc/pacman.d/mirrorlist
    sed -i "s/^CheckSpace/#CheckSpace/g" /target/etc/pacman.conf
    sed -i "s/#ParallelDownloads/ParallelDownloads/g" /target/etc/pacman.conf
    for dir in dev sys proc run ; do
        mount --bind /$dir /target/$dir
    done
    chroot /target/ pacman-key --init
    chroot /target/ pacman-key --populate
    chroot /target pacman -Syyu --noconfirm base archlinux-keyring
    for dir in dev sys proc run ; do
        umount -lf /target/$dir
    done
}

install_package(){
    chroot /target pacman -Syy --noconfirm $@
}

remove_package(){
    chroot /target pacman -Rdd --noconfirm $@
}

update_initramfs() {
    for dir in $(ls /target/lib/modules) ; do
        chroot /target mkinitcpio -k $dir -g /boot/initramfs-$dir.img
    done
}

create_user(){
    user="$(cat /netinstall/data/username)"
    pass="$(cat /netinstall/data/password)"
    apk add openssl
    chroot /target useradd -m -s /bin/ash "$user"
    chroot /target usermod -p $(openssl passwd "$pass") "$user"
    chroot /target usermod -p $(openssl passwd "$pass") root
}

configure(){
    case $1 in
      xfce)
        chroot /target systemctl enable lightdm
        ;;
      gnome)
        chroot /target systemctl enable gdm
        ;;
      kde)
        chroot /target systemctl enable sddm
        ;;
    esac
}