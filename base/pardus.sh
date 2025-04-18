set -e
set -o pipefail
source /netinstall/utils/iniparser.sh
source /netinstall/profiles/base/debian.sh

install_base_system() {
    codename="$(ini_parse distro codename < /netinstall/data/profile)"
    ln -s sid /usr/share/debootstrap/scripts/$codename-deb || true
    debootstrap --no-check-gpg --variant minbase --arch=amd64 --exclude=usr-is-merged ${codename}-deb \
        /target "https://depo.pardus.org.tr/pardus"
   cat > /target/etc/apt/sources.list <<EOF
deb https://deb.debian.org/debian stable main contrib non-free non-free-firmware
deb http://depo.pardus.org.tr/pardus $codename-deb main contrib non-free non-free-firmware
deb http://depo.pardus.org.tr/pardus $codename main contrib non-free non-free-firmware
deb http://depo.pardus.org.tr/guvenlik $codename-deb main contrib non-free non-free-firmware
EOF
    cat /etc/resolv.conf > /target/etc/resolv.conf
    chroot /target apt-get update --allow-insecure-repositories
    chroot /target apt-get install pardus-archive-keyring \
        --allow-unauthenticated -yq -o Dpkg::Options::="--force-confnew"
    # auto service start disabled
    echo -e "#!/bin/sh\nexit 101" > /target/usr/sbin/policy-rc.d
    chmod +x /target/usr/sbin/policy-rc.d
    if grep "backports" /netinstall/data/options >/dev/null ; then
        cat > /target/etc/apt/sources.list.d/$codename-backports.list <<EOF
deb http://depo.pardus.org.tr/backports $codename-backports main contrib non-free
EOF
        cat > /target/etc/apt/preferences.d/backports <<EOF
Package: *
Pin: release a=$codename-backports
Pin-Priority: 900
EOF
    fi
    if grep "testing" /netinstall/data/options >/dev/null ; then
        mkdir -p /target/etc/apt/sources.list.d/
        echo "deb https://deb.debian.org/debian testing main contrib non-free non-free-firmware" > /target/etc/apt/sources.list.d/testing.list
    fi
    if grep "no-recommends" /netinstall/data/options >/dev/null ; then
        echo 'APT::Install-Recommends "0";' > /target/etc/apt/apt.conf.d/01norecommend
        echo 'APT::Install-Suggests "0";' >> /target/etc/apt/apt.conf.d/01norecommend
    fi
    chroot /target apt update
    chroot /target apt full-upgrade -o Dpkg::Options::="--force-confnew" -yq
    install_package sysv-rc sysvinit-utils sysvinit-core -yq
}

