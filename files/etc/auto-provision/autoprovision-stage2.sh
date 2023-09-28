#!/bin/bash

# autoprovision stage 2: this script will be executed upon boot if the extroot was successfully mounted (i.e. rc.local is run from the extroot overlay)

. /etc/auto-provision/autoprovision-functions.sh

# Command to check if a command ran successfully
check_run() {
    if eval "$@"; then
        return 0  # Command ran successfully, return true
    else
        return 1  # Command failed to run, return false
    fi
}

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
}

# Command to wait for Internet connection
wait_for_internet() {
    while ! ping -q -c3 1.1.1.1 >/dev/null 2>&1; do
        log_say "Waiting for Internet connection..."
        sleep 1
    done
    log_say "Internet connection established"
}

# Command to wait for opkg to finish
wait_for_opkg() {
  while pgrep -x opkg >/dev/null; do
    log_say "Waiting for opkg to finish..."
    sleep 1
  done
  log_say "opkg is released, our turn!"
}

installPackages()
{
    signalAutoprovisionWaitingForUser

    until (opkg update)
    do
        log_say "opkg update failed. No internet connection? Retrying in 15 seconds..."
        sleep 15
    done

    signalAutoprovisionWorking

    log_say "Autoprovisioning stage2 is about to install packages"

    # CUSTOMIZE
    # install some more packages that don't need any extra steps
    log_say "updating all packages!"

    log_say "                                                                      "
    log_say " ███████████             ███                         █████            "
    log_say "░░███░░░░░███           ░░░                         ░░███             "
    log_say " ░███    ░███ ████████  ████  █████ █████  ██████   ███████    ██████ "
    log_say " ░██████████ ░░███░░███░░███ ░░███ ░░███  ░░░░░███ ░░░███░    ███░░███"
    log_say " ░███░░░░░░   ░███ ░░░  ░███  ░███  ░███   ███████   ░███    ░███████ "
    log_say " ░███         ░███      ░███  ░░███ ███   ███░░███   ░███ ███░███░░░  "
    log_say " █████        █████     █████  ░░█████   ░░████████  ░░█████ ░░██████ "
    log_say "░░░░░        ░░░░░     ░░░░░    ░░░░░     ░░░░░░░░    ░░░░░   ░░░░░░  "
    log_say "                                                                      "
    log_say "                                                                      "
    log_say " ███████████                        █████                             "
    log_say "░░███░░░░░███                      ░░███                              "
    log_say " ░███    ░███   ██████  █████ ████ ███████    ██████  ████████        "
    log_say " ░██████████   ███░░███░░███ ░███ ░░░███░    ███░░███░░███░░███       "
    log_say " ░███░░░░░███ ░███ ░███ ░███ ░███   ░███    ░███████  ░███ ░░░        "
    log_say " ░███    ░███ ░███ ░███ ░███ ░███   ░███ ███░███░░░   ░███            "
    log_say " █████   █████░░██████  ░░████████  ░░█████ ░░██████  █████           "
    log_say "░░░░░   ░░░░░  ░░░░░░    ░░░░░░░░    ░░░░░   ░░░░░░  ░░░░░            "

    # Keep trying to run opkg update until it succeeds
    while ! check_run "opkg update"; do
        log_say "\"opkg update\" failed. Retrying in 15 seconds..."
        sleep 15
    done

    ## INSTALL MESH  ##
    log_say "Installing Mesh Packages..."
    opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard
    opkg remove wpad wpad-basic wpad-basic-openssl wpad-basic-wolfssl wpad-wolfssl
    opkg install wpad-mesh-openssl kmod-batman-adv batctl avahi-autoipd batctl-full luci-app-dawn
    opkg install /etc/luci-app-easymesh_2.2_all.ipk
    opkg install /etc/luci-proto-batman-adv_git-22.104.47289-0a762fd_all.ipk
    
    # List of our packages to install
    local PACKAGE_LIST="acme attr avahi-dbus-daemon base-files busybox ca-bundle certtool cgi-io curl davfs2 dbus ddns-scripts-services dnsmasq dropbear firewall fstools fuse3-utils fwtool getrandom git git-http jq bash glib2 gnupg hostapd-common ip-full ip6tables ipset iptables iptables-mod-ipopt iw iwinfo jshn jsonfilter kernel kmod-bluetooth kmod-btmrvl kmod-cfg80211 kmod-crypto-aead kmod-crypto-ccm kmod-crypto-cmac kmod-crypto-ctr kmod-crypto-ecb kmod-crypto-ecdh kmod-crypto-gcm kmod-crypto-gf128 kmod-crypto-ghash kmod-crypto-hash kmod-crypto-hmac kmod-crypto-kpp kmod-crypto-lib-blake2s kmod-crypto-lib-chacha20 kmod-crypto-lib-chacha20poly1305 kmod-crypto-lib-curve25519 kmod-crypto-lib-poly1305 kmod-crypto-manager kmod-crypto-null kmod-crypto-rng kmod-crypto-seqiv kmod-crypto-sha256 kmod-fuse kmod-gpio-button-hotplug kmod-hid kmod-input-core kmod-input-evdev kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-ipopt kmod-ipt-ipset kmod-ipt-nat kmod-ipt-offload kmod-lib-crc-ccitt kmod-lib-crc16 kmod-mac80211 kmod-mmc kmod-mwifiex-sdio luci-compat luci-lib-ipkg kmod-mwlwifi kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nfnetlink kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-regmap-core kmod-slhc kmod-tun kmod-udptunnel4 kmod-udptunnel6 kmod-usb-core kmod-wireguard libatomic1 libattr libavahi-client libavahi-dbus-support libblkid1 libbpf0 libbz2-1.0 libc libcap libcurl4 libdaemon libdbus libelf1 libev libevdev libevent2-7 libexif libexpat libffi libffmpeg-mini libflac libfuse1 libfuse3-3 libgcc1 libgmp10 libgnutls libhttp-parser libid3tag libip4tc2 libip6tc2 libipset13 libiwinfo-data libiwinfo-lua libiwinfo20210430 libjpeg-turbo libjson-c5 liblua5.1.5 liblucihttp-lua liblucihttp0 liblzo2 libmbedtls12 libmnl0 libmount1 libncurses6 libneon libnettle8 libnftnl11 libnghttp2-14 libnl-tiny1 libogg0 libopenssl-conf libopenssl1.1 libowipcalc libpam libpcre libpopt0 libprotobuf-c libpthread libreadline8 librt libsmartcols1 libsodium libsqlite3-0 libtasn1 libtirpc libubus-lua libuci-lua libuci20130104 libuclient20201210 libudev-zero liburing libusb-1.0-0 libustream-wolfssl20201210 libuuid1 libvorbis libxml2 libxtables12 logd lua luci luci-app-ddns luci-app-firewall luci-app-minidlna luci-app-openvpn luci-app-opkg luci-app-samba4 luci-app-statistics luci-mod-dashboard luci-app-vnstat luci-app-shadowsocks-libev luci-app-smartdns luci-app-vpn-policy-routing luci-app-vpnbypass luci-app-watchcat luci-app-wireguard luci-base luci-i18n-firewall-en luci-i18n-wireguard-en luci-lib-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-proto-wireguard luci-theme-bootstrap luci-theme-material luci-theme-openwrt-2020 minidlna mount-utils mtd mwifiex-sdio-firmware mwlwifi-firmware-88w8964 netifd ocserv odhcp6c odhcpd-ipv6only openssh-sftp-client openssh-sftp-server openssl-util openvpn-openssl openwrt-keyring opkg owipcalc ppp ppp-mod-pppoe procd procd-seccomp procd-ujail python3-base python3-email python3-light python3-logging python3-openssl python3-pysocks python3-urllib resolveip rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rpcsys rpcd-mod-rrdns rsync samba4-libs samba4-server shadowsocks-libev-config shadowsocks-libev-ss-tunnel smartdns socat socksify sshfs terminfo tor ubi-utils uboot-envtools ubox ubus ubusd uci uclient-fetch uhttpd uhttpd-mod-ubus urandom-seed urngd usbutils usign vpn-policy-routing vpnbypass vpnc-scripts watchcat wg-installer-client wget-ssl wireguard-tools wireless-regdb wpad-basic-wolfssl zlib kmod-usb-storage block-mount kmod-fs-ext4 kmod-fs-exfat e2fsprogs fdisk"

    count=$(echo "$PACKAGE_LIST" | wc -w)
    log_say "Packages to install: ${count}"

    # Convert the object list to an array
    IFS=' ' read -r -a objects <<< "$PACKAGE_LIST"

    # Loop until the object_list array is empty
    while [[ ${#objects[@]} -gt 0 ]]; do
        # Get a slice of 10 objects or the remaining objects if less than 10
        slice=("${objects[@]:0:10}")

        # Remove the echoed objects from the list
        objects=("${objects[@]:10}")

        # Join the slice into a single line with spaces
        line=$(printf "%s " "${slice[@]}")

        # Remove leading/trailing whitespaces
        line=$(echo "$line" | xargs)

        # opkg install the 10 packages
        eval "opkg install $line"
    done

   ## We have to remove dnsmasq (which is required to be installed on build) and install dnsmasq-full
   opkg remove dnsmasq
   # Get rid of the old dhcp config
   [ -f /etc/config/dhcp ] && rm /etc/config/dhcp
   # Install the dnsmasq-full package since we want that
   opkg install dnsmasq-full
   # Move the default dhcp config to the right place
   [ -f /etc/config/dhcp ] && mv /etc/config/dhcp /etc/config/dhcp.orig
   # Put our pre-configured config in its place
   [[ -f /etc/config/dhcp.pr && ! -f /etc/config/dhcp ]] && cp /etc/config/dhcp.pr /etc/config/dhcp

}

autoprovisionStage2()
{
    log_say "Autoprovisioning stage2 speaking"

    signalAutoprovisionWorking

    # CUSTOMIZE: with an empty argument it will set a random password and only ssh key based login will work.
    # please note that stage2 requires internet connection to install packages and you most probably want to log_say in
    # on the GUI to set up a WAN connection. but on the other hand you don't want to end up using a publically
    # available default password anywhere, therefore the random here...
    setRootPassword "torguard"

    installPackages

    chmod +x ${overlay_root}/etc/rc.local
    cat >${overlay_root}/etc/rc.local <<EOF
chmod a+x /etc/stage3.sh
{ bash /etc/stage3.sh; } && exit 0 || { log "** PRIVATEROUTER ERROR **: stage3.sh failed - rebooting in 30 seconds"; sleep 30; reboot; }
EOF

}

# Fix our DNS and update packages and do not check https certs
fixPackagesDNS()
{
    log_say "Fixing DNS (if needed) and installing required packages for opkg"

    # Domain to check
    domain="privaterouter.com"

    # DNS server to set if domain resolution fails
    dns_server="1.1.1.1"

    # Perform the DNS resolution check
    if ! nslookup "$domain" >/dev/null 2>&1; then
        log_say "Domain resolution failed. Setting DNS server to $dns_server."

        # Update resolv.conf with the new DNS server
        echo "nameserver $dns_server" > /etc/resolv.conf
    else
        log_say "Domain resolution successful."
    fi

    log_say "Installing opkg packages"
    opkg update --no-check-certificate
    opkg install --no-check-certificate wget-ssl unzip ca-bundle ca-certificates git git-http jq curl bash nano ntpdate

    # Set the time to fix ssl cert issues
    ntpdate -q 0.openwrt.pool.ntp.org
}

# Wait for Internet connection
wait_for_internet

# Wait for opkg to finish
wait_for_opkg

# Fix our DNS Server and install some required packages
fixPackagesDNS

autoprovisionStage2

reboot
