function share-on
    sudo systemctl start smb nmb
    if test $status -eq 0
        notify-send 'Samba Server' 'Folder Public Aktif' -i network-server
        echo "Samba started successfully."
    end
end
