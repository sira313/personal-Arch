### Arch Linux Boot Time Optimization Summary

Tujuan: Mengurangi durasi *boot time* pada sistem Arch Linux dengan Btrfs, UKI, dan systemd-boot.

#### 1. Diagnosa Awal
* Mengidentifikasi durasi *boot* menggunakan:
    ```bash
    systemd-analyze blame
    systemd-analyze critical-chain
    ```
* Ditemukan jeda pada fase *udev trigger* dan inisialisasi perangkat.

#### 2. Eksperimen Optimasi Initramfs
* **Percobaan:** Beralih dari `udev` hook tradisional ke `systemd` hook di `/etc/mkinitcpio.conf`.
* **Konfigurasi:**
    ```bash
    # HOOKS diubah menjadi:
    HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)
    ```
* **Hasil:** Perubahan berhasil, namun terjadi peningkatan durasi *booting* secara statistik karena *coldplugging* perangkat yang lebih agresif. Keputusan diambil untuk kembali ke `udev` hook demi stabilitas dan kecepatan optimal.

#### 3. Optimasi User-Space (NetworkManager)
* **Strategi:** Memindahkan beban *startup* NetworkManager agar tidak menghambat *booting* utama dengan menambahkan jeda (delay) *pre-start*.
* **Langkah:**
    1. Jalankan perintah: `sudo systemctl edit NetworkManager.service`
    2. Tambahkan baris berikut di editor:
    ```ini
    [Service]
    ExecStartPre=/usr/bin/sleep 2
    ```
* **Hasil:** Proses jaringan tetap berjalan lancar, namun tidak menjadi *bottleneck* saat sistem pertama kali masuk ke *desktop*.

#### 4. Reversi & Pembersihan
* **Reversi:** Mengembalikan `HOOKS` ke konfigurasi standar (`udev` hook) dan menjalankan `sudo mkinitcpio -P` untuk memperbarui UKI.
* **Pembersihan:** Memastikan tidak ada *service* atau *udev rules* pihak ketiga yang tidak perlu (seperti `fwupd`) di sistem.

#### 5. Hasil Akhir
* **Boot Time:** 14 detik (sejak dari `systemd-boot`).
* **Status:** Sistem berjalan optimal, bersih dari *bloatware*, dan memiliki konfigurasi *initramfs* yang stabil.
