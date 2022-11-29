#!/bin/bash

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

run_perf() {
    local vmname="$1"
    local pid=0

    while [[ $(ps -C qemu-system-ppc64 -o pid=,args= | grep $vmname | sed "s/^\s\+//" | cut -d ' ' -f 1) == "" ]]
    do
        sleep 0.1
    done

    pid=$(ps -C qemu-system-ppc64 -o pid=,args= | grep $vmname | sed "s/^\s\+//" | cut -d ' ' -f 1)
    sudo perf record -e syscalls:sys_enter_mmap -e page-faults -e context-switches -g -p "$pid" -o "$vmname".data
}

run_vm() {
    local vmname="$1"

    virsh start "$vmname" --console
}

main() {
    local vmname="$1"

    if [[ $(vm_exists "$vmname") == 1 ]]
    then
        run_perf "$vmname" &
        run_vm "$vmname"
        exit 0
    else
        echo "vm \"$vmname\" doesn't exist"
        exit 1
    fi
}

main "$1"
