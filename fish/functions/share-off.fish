function share-off
    sudo systemctl stop smb nmb
    if test $status -eq 0
        notify-send 'Samba Server' 'Sharing Berhenti' -i network-offline
        echo "Samba stopped successfully."
    end
end
