#!/usr/bin/fish

# 1. Pindah direktori
cd ~/Documents/windows11/

# 2. Jalankan container
echo "Memulai podman-compose..."
podman-compose up -d

# 3. Pantau log di background
echo "Menunggu Windows siap..."

# Gunakan file sementara untuk menampung log agar bisa dibaca real-time
set log_file (mktemp)

# Jalankan logs di background dan simpan PID-nya
podman-compose logs -f > $log_file &
set log_pid $last_pid

# Loop pengecekan teks
while true
    if grep -q "Windows started successfully" $log_file
        echo "Sistem terdeteksi siap!"
        # Matikan proses logs agar tidak 'stuck'
        kill $log_pid
        break
    end
    sleep 2 # Beri jeda agar tidak membebani CPU
end

# Hapus file sementara
rm $log_file

# 4. Jalankan RDP
echo "Membuka RDP..."
sdl-freerdp3 /v:127.0.0.1 /u:aris /p:aris123 /cert:ignore /f /network:lan /gfx:avc444 /rfx /compression /video /drive:shared,/shared /scale:140