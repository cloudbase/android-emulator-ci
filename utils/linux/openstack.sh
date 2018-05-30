function boot_vm() {
    VMID=$(nova boot $@ --poll | grep " id " | cut -d "|" -f 3)
    NOVABOOT_EXIT=$?

    if [ $NOVABOOT_EXIT -ne 0 ]; then
        nova show "$VMID"
        nova delete $VMID
        log_summary "Failed to create devstack VM: $VMID"
        return 1
    fi
    echo $VMID
}

function get_vm_ip() {
    local vmName=$1
    local vms=`nova list | grep $vmName`
    local vmCount=`echo $vms | wc -l`

    if [[ -z $vms ]]; then
        log_summary "Could not find vm $vmName."
        return 1
    fi

    if [[ $vmCount -gt 1 ]]; then
        log_summary "Found multiple vms."
        return 1
    fi

    ip=`echo $vms | cut -d '|' -f 7 | sed -r 's/.*=//'`
    echo $ip
}
