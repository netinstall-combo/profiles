set -e
set -o pipefail
source /netinstall/utils/iniparser.sh
tool_init(){
    apk add debootstrap
}
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

install_base_system() {
    codename="$(ini_parse distro codename < /netinstall/data/profile)"
    repo="$(ini_parse distro repository < /netinstall/data/profile)"
    ln -s sid /usr/share/debootstrap/scripts/$codename || true
    debootstrap --variant minbase $codename /target $repo
    cat /etc/resolv.conf > /target/etc/resolv.conf
    cat> /target/etc/apt/apt.conf.d/01norecommend << EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF
    # remove systemd
    rm -f /target/var/lib/dpkg/info/systemd.p* || true
    chroot /target apt install orphan-sysvinit-scripts sysvinit-core sysv-rc libpam-elogind -yq
    chroot /target apt-mark hold systemd
    ln -s true /target/bin/systemctl
    # auto service start disabled
    echo -e "#!/bin/sh\nexit 101" > /target/usr/sbin/policy-rc.d
    chmod +x /target/usr/sbin/policy-rc.d
}

install_package(){
    chroot /target/ apt install --no-install-recommends -o Dpkg::Options::="--force-confnew" -yq $@
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
    apk add openssl
    chroot /target useradd -m -s /bin/bash "$user"
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