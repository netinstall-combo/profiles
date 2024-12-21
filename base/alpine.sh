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
}

install_package(){
     chroot /target apk add $@
}

update_initramfs() {
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet rootfstype=ext4 modules=sd-mod,usb-storage,ext4"' > /target/etc/default/grub
    for dir in $(ls /target/lib/modules) ; do
        chroot /target mkinitfs $dir
    done
}
