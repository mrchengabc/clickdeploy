#!/bin/bash
# modules/rsync_transfer.sh

echo "=========================================="
echo "  [Module] Transfer Data Antar Server (Rsync)..."
echo "=========================================="

# Folder lokal yang ingin dikirim
LOCAL_PATH="/var/backups/clickdeploy/migration"

if [ ! -d "$LOCAL_PATH" ] || [ -z "$(ls -A "$LOCAL_PATH")" ]; then
    echo "❌ Folder migrasi kosong atau tidak ditemukan. Jalankan module migrate terlebih dahulu."
    exit 1
fi

read -p "Masukkan alamat IP VPS Tujuan: " remote_ip
read -p "Masukkan port SSH VPS Tujuan [Default: 22]: " remote_port
remote_port=${remote_port:-22}
read -p "Masukkan user SSH VPS Tujuan [Default: root]: " remote_user
remote_user=${remote_user:-root}
read -p "Masukkan path tujuan di VPS Tujuan [Default: /var/backups/]: " remote_path
remote_path=${remote_path:-"/var/backups/"}

echo "Mulai mentransfer file ke $remote_ip..."
# Perintah rsync: -a (archive), -v (verbose), -z (kompresi saat pengiriman), -P (progress bar)
rsync -avzP -e "ssh -p $remote_port" "$LOCAL_PATH/" "$remote_user@$remote_ip:$remote_path"

if [ $? -eq 0 ]; then
    echo "✔ Sukses! Seluruh file migrasi berhasil dikirim ke server tujuan."
else
    echo "❌ Terjadi kesalahan saat pengiriman menggunakan Rsync."
fi