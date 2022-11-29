#!/bin/bash

declare -A device_list

XML_TEMPLATE="<hostdev mode='subsystem' type='pci' managed='no'>\n"
XML_TEMPLATE+="<driver name='vfio'/>\n<source>\n"
XML_TEMPLATE+="%s\n</source>\n</hostdev>"

vm_exists() {
    local vmname="$1"

    [[ "x$vmname" == "x" ]] && false

    if [[ $(virsh list --all | grep $vmname > /dev/null 2>&1; echo $?) == 0 ]]
    then
        echo 1
    else
        echo 0
    fi
}

pci_virt_to_dev() {
    local virt="$1"

    dev=$(echo $virt | sed "s@^pci_\([0-9]\{4\}\)_\([0-9]\{2\}\)_\([0-9]\{2\}\)_\([0-9]\).*@\1:\2:\3.\4@")
    echo "$dev"
}

get_pci_desc() {
    local pci="$1"

    desc=$(lspci -s $pci | cut -d ' ' -f 4-)
    echo "$desc"
}

list_nvidia_devices() {
    local i=0;
    local devices=$(lspci | grep -i nvidia | cut -d ' ' -f 1)

    for dev in $devices
    do
        local description=$(get_pci_desc $dev)
        device_list[$i]="$dev"

        echo "$i) $dev -> $description"
        ((i++))
    done

    if [[ ${#device_list[@]} -eq 0 ]]
    then
        echo "No device found"
        exit 1
    fi
}

list_attached_devices() {
    local i=0;
    local vmname="$1"

    if [[ ! -d "$HOME/.devices/$vmname" ]]
    then
        echo "No device attached (by this program)"
        exit 1
    fi

    pushd "$HOME/.devices/$vmname" > /dev/null

    for dev in *
    do
        [[ -d "$dev" ]] || continue

        device_list[$i]="$dev"

        echo "$i) $(pci_virt_to_dev $dev)"

        pushd "$dev" > /dev/null
        for grp in *
        do
            local pci=$(pci_virt_to_dev pci_$grp)
            echo "   \`-> $pci: $(get_pci_desc $pci)"
        done
        popd > /dev/null
        ((i++))
    done

    if [[ ${#device_list[@]} -eq 0 ]]
    then
        echo "No device attached (by this program)"
        exit 1
    fi

    popd > /dev/null
}

attach_devices() {
    local vmname="$1"
    local option=""

    # print the list of devices and ask for user input
    list_nvidia_devices

    echo -n "Choose the devices [crtl-c to quit]: "
    read option
    echo ""

    # place to store the attached devices
    mkdir -p "$HOME/.devices/$vmname"
    pushd "$HOME/.devices/$vmname" > /dev/null

    # user can enter more than one option, attach each of them
    for id in $option
    do
        # make sure the input is sane
        case $id in
            [0-9]*)
                if [[ "$id" -ge ${#device_list[@]} ]]
                then
                    echo "Invalid option $id"
                    popd > /dev/null
                    exit 1
                fi
                ;;

            *)
                echo "Invalid option $id"
                popd > /dev/null
                exit 1;
                ;;
        esac

        local virsh_dev=$(echo ${device_list[$id]} | sed "s@\([0-9]\{4\}\):\([0-9]\{2\}\):\([0-9]\{2\}\).\([0-9]\)@pci_\1_\2_\3_\4@")

        # create a place to store the XML for the chosen device
        mkdir -p $virsh_dev
        pushd $virsh_dev > /dev/null

        # attach all devices under the same IOMMU group
        while read -r line
        do
            filename=$(echo "$line" | awk 'match($0, /.*0x([0-9]+).*0x([0-9]+).*0x([0-9]+).*0x([0-9]+)/, arr) { name=arr[1]"_"arr[2]"_"arr[3]"_"arr[4]".xml"; print name }')
            printf "Creating %s\n" "$filename"
            printf "$XML_TEMPLATE" "$line" > "$filename"
            printf "Attaching %s\n" "$filename"
            virsh attach-device "$vmname" "$filename" --config
        done < <(virsh nodedev-dumpxml $virsh_dev | grep address)

        popd > /dev/null
    done

    popd > /dev/null
}

detach_devices() {
    local vmname="$1"
    local option=""

    list_attached_devices "$vmname"
    echo -n "Choose the devices [crtl-c to quit]: "
    read option
    echo ""

    pushd "$HOME/.devices/$vmname" > /dev/null

    # user can enter more than one option, attach each of them
    for id in $option
    do
        # make sure the input is sane
        case $id in
            [0-9]*)
                if [[ "$id" -ge ${#device_list[@]} ]]
                then
                    echo "Invalid option $id"
                    popd > /dev/null
                    exit 1
                fi
                ;;

            *)
                echo "Invalid option $id"
                popd > /dev/null
                exit 1;
                ;;
        esac

        pushd "${device_list[$id]}" > /dev/null
        for xml in *
        do
            echo "Detaching ${device_list[$id]}"
            virsh detach-device "$vmname" "$xml" --config
        done
        popd > /dev/null

        rm -fr "${device_list[$id]}"
    done
}

main() {
    local vmname="$1"
    local action="$2"

    if [[ $(vm_exists "$vmname") == 0 ]]
    then
        echo "Invalid VM $vmname"
        exit 1
    fi

    case "$action" in
        -a)
            attach_devices "$vmname"
            ;;

        -d)
            detach_devices "$vmname"
            ;;

        *)
            echo "Invalid action: $action"
            exit 1
            ;;
    esac
}

vmname=${1:-<null>}
action=${2:--a}
main "$vmname" "$action"
