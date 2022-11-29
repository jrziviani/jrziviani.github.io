#!/bin/bash

modprobe vfio-pci

for device in $@;
do
    cd /sys/bus/pci/devices/${device}/iommu_group/devices/
    for dev in *;
    do
        echo "Detaching $dev..."
        echo 'vfio-pci' > /sys/bus/pci/devices/${dev}/driver_override
        echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
        echo '' > /sys/bus/pci/devices/${dev}/driver_override
        sleep 1
        echo "done"
    done
done
