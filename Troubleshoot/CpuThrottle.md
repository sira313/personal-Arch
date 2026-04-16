## 🛠️ Ringkasan Diagnosis & Perbaikan: ThinkPad T495s (AMD Ryzen)

### 1. Gejala (Symptoms)
* **CPU Lock:** Prosesor tiba-tiba terkunci di frekuensi **480MHz - 500MHz** (harusnya bisa 2000MHz+).
* **High Load:** Google Chrome atau proses sistem memakan 100% CPU, namun sistem terasa sangat lambat (*lagging*).
* **Input Lag:** Muncul pesan error di journal: `libinput error: event processing lagging behind`.
* **Throttling:** Terjadi meski suhu tidak terlalu panas (sering dipicu perpindahan mode power atau pembersihan snapshot).

### 2. Diagnosis Akar Masalah
Ada tiga penyebab utama yang saling bertumpuk:
1.  **Bug STAPM (AMD Firmware):** Fitur *Skin Temperature Aware Power Management* pada ThinkPad seri ini sering salah membaca ambang batas suhu casing dan memaksa CPU ke status daya terendah.
2.  **Btrfs Quota (qgroup):** Fitur quota pada Btrfs sangat berat. Saat Snapper menghapus snapshot, kernel akan memakan resource CPU secara masif untuk menghitung ulang ukuran data, yang memicu *thermal throttle*.
3.  **Inkompatibilitas Tool:** Tool populer seperti `throttled` hanya untuk Intel, sehingga tidak bekerja pada Ryzen kamu.

---

### 3. Langkah Perbaikan yang Dilakukan

#### **Langkah A: Mematikan Btrfs Quota**
Ini adalah langkah wajib bagi pengguna Arch + Btrfs + Snapper agar sistem tidak *freeze* saat *background maintenance*.
```fish
sudo btrfs quota disable /
```

#### **Langkah B: Melepas Limitasi Daya (Bypass Throttling)**
Menggunakan `ryzenadj` untuk menulis ulang batas daya (*power limits*) langsung ke register hardware, memaksa CPU keluar dari jebakan 500MHz.
* **Install:** `paru -S ryzenadj-git`
* **Command:** `sudo ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=25000`

---

### 4. Solusi Permanen & Alur Kerja
Kamu telah membuat fungsi otomatis di Fish Shell untuk menangani jika masalah ini muncul kembali (misalnya setelah ganti mode ke *Power Saver* atau bangun dari *Sleep*).

**Lokasi Fungsi:** `~/.config/fish/functions/fixcpu.fish`
```
function fixcpu --description 'Fix AMD Ryzen throttling by overriding power limits'
    echo "Mencoba melepaskan limitasi daya CPU..."
    
    # Menjalankan ryzenadj dengan parameter yang sudah kita uji
    sudo ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=25000
    
    if test $status -eq 0
        echo "Berhasil! Memeriksa frekuensi CPU saat ini..."
        # Menampilkan frekuensi CPU saat ini sekilas
        grep "cpu MHz" /proc/cpuinfo | head -n 4
    else
        echo "Gagal menjalankan ryzenadj. Pastikan password sudo benar."
    end
end
```

**Cara Pakai:**
Tinggal ketik `fixcpu` di terminal Kitty.

| Kondisi | Tindakan |
| :--- | :--- |
| **Normal / Colok Charger** | Gunakan mode **Balanced**. |
| **Baterai / Power Saver** | Jika mulai lag, jalankan perintah `fixcpu`. |
| **Setelah Update Kernel** | Pastikan `ryzenadj-git` tetap terinstall. |

---

### 5. Hasil Akhir
Sistem sekarang berjalan di mode **Balanced** dengan CPU load rendah (~7%), memori stabil, dan frekuensi prosesor dinamis (bisa naik di atas 1000MHz sesuai kebutuhan), tanpa gangguan dari pembersihan snapshot Snapper.
