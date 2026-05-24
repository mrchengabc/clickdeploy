#!/bin/bash
# modules/create_swap.sh

echo "=========================================="
echo "      [Module] Tambah & Atur Swap File     "
echo "=========================================="

# 1. Periksa apakah swap sudah ada
CURRENT_SWAP=$(swapon --show --noheadings)
if [ ! -z "$CURRENT_SWAP" ]; then
    echo "⚠️ Sistem Anda sudah mendeteksi adanya SWAP aktif:"
    swapon --show
    echo "------------------------------------------"
    read -p "Apakah Anda ingin tetap membuat file swap baru? (ya/tidak): " confirm_swap
    if [ "$confirm_swap" != "ya" ]; then
        echo "Proses pembuatan swap dibatalkan."
        exit 0
    fi
fi

# 2. Tanyakan ukuran Swap yang diinginkan
echo "Pilih ukuran Swap yang ingin dibuat:"
echo "1) 1 GB (Disarankan untuk RAM 1GB-2GB)"
echo "2) 2 GB (Disarankan untuk RAM 2GB-4GB)"
echo "3) 4 GB"
echo "4) Tentukan ukuran sendiri (Custom)"
read -p "Pilihan [1-4]: " swap_opt

case $swap_opt in
    1) SWAP_SIZE_GB=1 ;;
    2) SWAP_SIZE_GB=2 ;;
    3) SWAP_SIZE_GB=4 ;;
    4) 
        read -p "Masukkan ukuran Swap dalam GB (misal: 3): " custom_size
        if ! [[ "$custom_size" =~ ^[0-9]+$ ]]; then
            echo "❌ Input harus berupa angka!"
            exit 1
        fi
        SWAP_SIZE_GB=$custom_size
        ;;
    *)
        echo "❌ Pilihan tidak valid."
        exit 1
        ;;
esac

SWAP_PATH="/swapfile"

# 3. Periksa sisa ruang hardisk VPS
FREE_DISK_KB=$(df --output=avail / | tail -n 1)
REQUIRED_DISK_KB=$((SWAP_SIZE_GB * 1024 * 1024))

if [ "$FREE_DISK_KB" -lt "$REQUIRED_DISK_KB" ]; then
    echo "❌ Gagal: Ruang disk tidak mencukupi untuk membuat swap sebesar ${SWAP_SIZE_GB}GB."
    exit 1
fi

echo "Membuat file swap sebesar ${SWAP_SIZE_GB}GB di $SWAP_PATH..."

# 4. Alokasikan file swap (menggunakan fallocate, jika gagal otomatis ganti dengan metode dd)
if ! sudo fallocate -l "${SWAP_SIZE_GB}G" "$SWAP_PATH" 2>/dev/null; then
    echo "fallocate gagal, beralih ke metode 'dd' (mohon tunggu beberapa saat)..."
    sudo dd if=/dev/zero of="$SWAP_PATH" bs=1M count=$((SWAP_SIZE_GB * 1024)) status=progress
fi

# 5. Atur hak akses agar hanya root yang bisa membaca file swap (keamanan)
sudo chmod 600 "$SWAP_PATH"

# 6. Format file menjadi swap area
sudo mkswap "$SWAP_PATH"

# 7. Aktifkan swap secara instan
sudo swapon "$SWAP_PATH"

# 8. Tambahkan ke fstab agar swap otomatis aktif kembali jika VPS direboot
if ! grep -q "$SWAP_PATH" /etc/fstab; then
    echo "$SWAP_PATH none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null
    echo "✔ Konfigurasi swap ditambahkan ke /etc/fstab."
fi

# 9. Optimasi Swappiness ke angka 10 (mencegah VPS SSD menulis swap terlalu agresif)
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null
else
    sudo sed -i 's/^vm.swappiness=.*/vm.swappiness=10/g' /etc/sysctl.conf
fi
sudo sysctl -p > /dev/null

echo "=========================================="
echo "✔ Sukses: Swap sebesar ${SWAP_SIZE_GB}GB berhasil aktif!"
echo "Menampilkan status memori saat ini:"
echo "------------------------------------------"
free -h
echo "=========================================="