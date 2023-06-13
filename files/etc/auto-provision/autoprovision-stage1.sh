#!/bin/sh

# autoprovision stage 1: this script will be executed upon boot without a valid extroot (i.e. when rc.local is found and run from the internal overlay)

. /etc/auto-provision/autoprovision-functions.sh

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
}

checkValidPendrive()
{
    local DEVICE="/dev/sda" # The drive we check
    local RESULT="false" # The default result until proven otherwise

    # Check if the device exists
    if [ -b "$DEVICE" ]; then
        # Get the number of partitions
        local PARTITIONS=$(fdisk -l "$DEVICE" | grep "$DEVICE" | wc -l)

        if [ "$PARTITIONS" -eq 1 ]; then
            log "Device $DEVICE is uninitialized (no partitions) so we will erase and partition it."
            RESULT="true"
        elif [ "$PARTITIONS" -eq 2 ]; then
            # Get the label of the single partition
            PARTITION_LABEL=$(blkid -s LABEL -o value "$DEVICE"1)

            if [ "$PARTITION_LABEL" = "SETUP" ]; then
                log "The single partition on $DEVICE has the label 'SETUP' so we will erase and partition it."
                RESULT="true"
                # This is a success
            else
                log "The single partition on $DEVICE does not have the label 'SETUP' so we will not erase it."
                # This is a failure
            fi
        else
            log "Device $DEVICE has $PARTITIONS partitions so we will not erase it."
            # This is a failure
        fi
    else
        log "Device $DEVICE does not exist."
        # This is a failure
    fi

    echo "$RESULT"
}

getPendriveSize()
{
    # this is needed for the mmc card in some (all?) Huawei 3G dongle.
    # details: https://dev.openwrt.org/ticket/10716#comment:4
    if [ -e /dev/sda ]; then
        # force re-read of the partition table
        head -c 1024 /dev/sda >/dev/null
    fi

    if (grep -q sda /proc/partitions) then
        cat /sys/block/sda/size
    else
        echo 0
    fi
}

hasBigEnoughPendrive()
{
    local size=$(getPendriveSize)
    if [ $size -ge 600000 ]; then
        log_say "Found a pendrive of size: $(($size / 2 / 1024)) MB"
        return 0
    else
        return 1
    fi
}

setupPendrivePartitions()
{
    # erase partition table
    dd if=/dev/zero of=/dev/sda bs=1M count=1

    # sda1 is 'swap'
    # sda2 is 'root'
    # sda3 is 'data'
    fdisk /dev/sda <<EOF
o
n
p
1

+64M
n
p
2

+512M
n
p
3


t
1
82
w
q
EOF
    log_say "Finished partitioning /dev/sda using fdisk"

    sleep 2

    until [ -e /dev/sda1 ]
    do
        echo "Waiting for partitions to show up in /dev"
        sleep 1
    done

    mkswap -L swap -U $swapUUID /dev/sda1
    mkfs.ext4 -F -L root -U $rootUUID /dev/sda2
    mkfs.ext4 -F -L data -U $dataUUID /dev/sda3

    log_say "Finished setting up filesystems"
}

setupExtroot()
{
    mkdir -p /mnt/extroot/
    mount -U $rootUUID /mnt/extroot

    overlay_root=/mnt/extroot/upper

    # at this point we could copy the entire root (a previous version of this script did that), or just the overlay from the flash,
    # but it seems to work fine if we just create an empty overlay that is only replacing the rc.local from the firmware.

    # let's write a new rc.local on the extroot that will shadow the one which is in the rom (to run stage2 instead of stage1)
    mkdir -p ${overlay_root}/etc/
    cat >${overlay_root}/etc/rc.local <<EOF
/etc/auto-provision/autoprovision-stage2.sh
exit 0
EOF

    # TODO FIXME when this below is enabled then Chaos Calmer doesn't turn on the network and the device remains unreachable

    # make sure that we shadow the /var -> /tmp symlink in the new extroot, so that /var becomes persistent across reboots.
#    mkdir -p ${overlay_root}/var
    # KLUDGE: /var/state is assumed to be transient, so link it to tmp, see https://dev.openwrt.org/ticket/12228
#    cd ${overlay_root}/var
#    ln -s /tmp state
#    cd -

    log_say "Finished setting up extroot"
}

autoprovisionStage1()
{
    log_say "Checking if this is a valid pendrive"
    if [ "$(checkValidPendrive)" = "true" ]; then
        log_say "This is a valid pendrive"

        signalAutoprovisionWorking

        signalAutoprovisionWaitingForUser
        signalWaitingForPendrive

        until hasBigEnoughPendrive
        do
            log_say "Waiting for a pendrive to be inserted"
            sleep 3
        done

        signalAutoprovisionWorking # to make it flash in sync with the USB led
        signalFormatting

        sleep 1

        setupPendrivePartitions
        sleep 1
        setupExtroot

        sync
        stopSignallingAnything
        reboot
    else # if pendrive invalid, wait 30s then reboot
        log_say "This is not a valid pendrive"
        log_say "Please insert a USB drive with a single partition with the label 'SETUP' or no partitions at all (uninitialized)."
        log_say "Sleeping for 30s and then rebooting."
        # pull our variable in from .profile
        . /root/.profile
        # Check if $REPO = main, if so reboot
        if [ "$REPO" = "main" ]; then
            sleep 30
            log_say "REPO is set to main, rebooting"
            reboot
        else
            log_say "REPO is set to ${REPO}, not rebooting"
        fi
    fi # end valid pendrive check
}

autoprovisionStage1
