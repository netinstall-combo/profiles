#!/bin/sh
set -e
set -o pipefail

tool_init(){
    : dont required
}

install_base_system() {
    cd /target
    uri="https://dl-cdn.alpinelinux.org/alpine/edge/releases/$(uname -m)/"
    tarball=$(wget -O - "$uri" |grep "alpine-minirootfs" | grep "tar.gz<" | \
        sort -V | tail -n 1 | cut -f2 -d"\"")
    wget -O "$tarball" "$uri/$tarball"
    tar -xvf "$tarball"
    rm -f "$tarball"
    cat > /target/etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF
    cat /etc/resolv.conf > /target/etc/resolv.conf
    chroot /target apk add eudev ca-certificates elogind dbus fuse
    chroot /target rc-update add dbus
    chroot /target rc-update add udev sysinit
    chroot /target rc-update add udev-trigger sysinit
    chroot /target rc-update add udev-settle sysinit
    chroot /target rc-update add udev-postmount default
    chroot /target rc-update add elogind
    chroot /target rc-update add fuse
}

install_package(){
     chroot /target apk add $@
}

remove_package(){
    chroot /target apk del $@
}
update_initramfs() {
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet rootfstype=ext4 modules=sd-mod,usb-storage,ext4"' > /target/etc/default/grub
    for dir in $(ls /target/lib/modules) ; do
        chroot /target mkinitfs $dir
    done
}

create_user(){
    user="$(cat /netinstall/data/username)"
    pass="$(cat /netinstall/data/password)"
    apk add openssl
    chroot /target apk add shadow
    chroot /target useradd -m -s /bin/ash "$user"
    chroot /target usermod -p $(openssl passwd "$pass") "$user"
    chroot /target usermod -p $(openssl passwd "$pass") root
 
}

configure(){
    : fixme
}