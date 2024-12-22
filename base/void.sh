set -e
set -o pipefail

tool_init(){
    : dont required
}
install_base_system() {
    cd /target
    fname=$(wget -O - https://repo-default.voidlinux.org/live/current/ \
        | grep x86_64 | grep ROOTFS | grep musl | head -n 1 | cut -f2 -d "\"")
    wget https://repo-default.voidlinux.org/live/current/$fname -O - | xzcat | \
    tar -xvf -
    cat /etc/resolv.conf > /target/etc/resolv.conf
    chroot /target xbps-pkgdb -ua
    chroot /target/ xbps-install -Syu
}

install_package(){
    chroot /target/ xbps-install -Sy $@
}

remove_package() {
    chroot /target/ xbps-remove -Ry $@
}

create_user(){
    user="$(cat /netinstall/data/username)"
    pass="$(cat /netinstall/data/password)"
    apk add openssl
    chroot /target useradd -m -s /bin/ash "$user"
    chroot /target usermod -p $(openssl passwd "$pass") "$user"
    chroot /target usermod -p $(openssl passwd "$pass") root
}

update_initramfs() {
    : dont required
}

configure() {
    : fixme
}