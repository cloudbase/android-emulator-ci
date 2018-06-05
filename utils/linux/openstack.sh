function boot_vm() {
    local VMID=$(nova boot $@ --poll | grep " id " | cut -d "|" -f 3)
    local NOVABOOT_EXIT=$?

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

    local ip=`echo $vms | cut -d '|' -f 7 | sed -r 's/.*=//'`
    if [[ -z $ip ]]; then
        log_summary "Failed to retrieve vm \"$vmName\" ip."
        return 1;
    fi

    echo $ip
}

function delete_vm_if_exists() {
    local VM_ID=$1

    if [[ -z $VM_ID ]]; then
        log_summary "No vm id specified. Skipping delete."
    fi

    if [[ $(nova list | grep $VM_ID) ]]; then
        log_summary "Deleting vm $VM_ID"
        nova delete $VM_ID
    else
        log_summary "VM $VM_ID does not exist. Skipping delete."
    fi
}
