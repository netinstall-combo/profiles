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
    # auto service start disabled
    echo -e "#!/bin/sh\nexit 101" > /target/usr/sbin/policy-rc.d
    chmod +x /target/usr/sbin/policy-rc.d
    if grep "testing" /netinstall/data/options >/dev/null ; then
        mkdir -p /target/etc/apt/sources.list.d/
        echo "deb https://deb.debian.org/debian testing main contrib non-free non-free-firmware" > /target/etc/apt/sources.list.d/testing.list
        chroot /target apt update
        chroot /target apt full-upgrade -yq
    fi
    if ! grep "recommends" /netinstall/data/options >/dev/null ; then
        echo 'APT::Install-Recommends "0";' > /target/etc/apt/apt.conf.d/01norecommend
        echo 'APT::Install-Suggests "0";' >> /target/etc/apt/apt.conf.d/01norecommend
    fi
    if ! grep "systemd" /netinstall/data/options >/dev/null ; then
        # remove systemd
        rm -f /target/var/lib/dpkg/info/systemd.p* || true
        chroot /target apt install orphan-sysvinit-scripts sysvinit-core sysv-rc libpam-elogind -yq
        chroot /target apt-mark hold systemd
        ln -s true /target/bin/systemctl
    fi
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
}

configure() {
    : dont required
}