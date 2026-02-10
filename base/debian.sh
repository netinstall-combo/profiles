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
    debootstrap --variant minbase --include="usrmerge usr-is-merged" $codename /target $repo
    cat /etc/resolv.conf > /target/etc/resolv.conf
    # auto service start disabled
    echo -e "#!/bin/sh\nexit 101" > /target/usr/sbin/policy-rc.d
    chmod +x /target/usr/sbin/policy-rc.d
    dist=stable
    if grep "testing" /netinstall/data/options >/dev/null ; then
        mkdir -p /target/etc/apt/sources.list.d/
        dist="testing"
        echo "deb https://deb.debian.org/debian $dist main contrib non-free non-free-firmware" > /target/etc/apt/sources.list.d/testing.list
    fi
    if grep "no-recommends" /netinstall/data/options >/dev/null ; then
        echo 'APT::Install-Recommends "0";' > /target/etc/apt/apt.conf.d/01norecommend
        echo 'APT::Install-Suggests "0";' >> /target/etc/apt/apt.conf.d/01norecommend
    fi
    if grep "devuan" /netinstall/data/options >/dev/null ; then
        echo "deb http://pkgmaster.devuan.org/merged $dist main contrib non-free non-free-firmware" > /target/etc/apt/sources.list.d/devuan.list
        echo "deb http://pkgmaster.devuan.org/merged $dist-updates main contrib non-free non-free-firmware" >> /target/etc/apt/sources.list.d/devuan.list
        echo "deb http://pkgmaster.devuan.org/merged $dist-security main contrib non-free non-free-firmware" >> /target/etc/apt/sources.list.d/devuan.list
        chroot /target apt update --allow-insecure-repositories
        chroot /target apt install devuan-keyring --allow-unauthenticated -yq
        chroot /target apt update
        chroot /target apt install elogind sysvinit-core openrc systemd- systemd-sysv- -yq --allow-remove-essential
        chroot /target apt-mark hold systemd libsystemd0 libsystemd-shared
        ln -s /bin/true /target/bin/systemctl
        
    fi
    chroot /target apt update
    chroot /target apt full-upgrade -o Dpkg::Options::="--force-confnew" -yq
}

install_package(){
    chroot /target/ apt install -o Dpkg::Options::="--force-confnew" -yq $@
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
    for grp in cdrom floppy sudo audio dip video users plugdev netdev bluetooth lpadmin ; do
        chroot /target usermod -aG "$grp" "$user" || true
    done
}

configure() {
    : dont required
}
