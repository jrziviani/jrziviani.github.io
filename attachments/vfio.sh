#!/bin/bash

helpme() {
    echo "Usage: ./$0 <device1> [<device2> <device3>]"
    exit 1
}

detach() {
    device="$1"
    group=$(readlink /sys/bus/pci/devices/${device}/iommu_group)
    group=${group##*/}

    echo "IOMMU group: $group"

    pushd /sys/bus/pci/devices/${device}/iommu_group/devices/
    for dev in *;
    do
        echo "Detaching $(lspci -s $dev)..."
        echo 'vfio-pci' > /sys/bus/pci/devices/${dev}/driver_override
        echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
        echo '' > /sys/bus/pci/devices/${dev}/driver_override
        echo "done"
    done
    popd
}

main() {
    devices=$@
    [[ -z "$1" ]] && helpme

    modprobe vfio-pci

    for device in $devices;
    do
        [[ -d "/sys/bus/pci/devices/${device}" ]] || helpme
        detach "$device"
        echo "----------------------------"
    done
}

main $@
