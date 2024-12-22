set -e
set -o pipefail
source /netinstall/utils/iniparser.sh
tool_init(){
    apk add debootstrap
}
install_base_system() {
    codename="$(ini_parse distro codename < /netinstall/data/profile)"
    repo="$(ini_parse distro repository < /netinstall/data/profile)"
    ln -s sid /usr/share/debootstrap/scripts/$codename || true
    debootstrap $codename /target $repo
    cat /etc/resolv.conf > /target/etc/resolv.conf
}

install_package(){
    chroot /target/ apt install -yq $@
}

remove_package() {
    chroot /target/ apt purge -yq $@
}

update_initramfs() {
    : dont required
}

create_user(){
    user="$(cat /netinstall/data/username)"
    pass="$(cat /netinstall/data/password)"
    chroot /target useradd -m -s /bin/ash "$user"
    chroot /target usermod -p $(openssl passwd "$pass") "$user"
    chroot /target usermod -p $(openssl passwd "$pass") root
}

configure() {
    case $1 in
      testing)
        echo "deb https://deb.debian.org/debian testing main contrib non-free non-free-firmware" > /target/etc/apt/sources.list
        chroot /target apt update
        chroot /target apt full-upgrade -yq
        ;;
    esac
}