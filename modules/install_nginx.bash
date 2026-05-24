#!/bin/bash
# modules/install_nginx.sh

echo "=========================================="
echo "  [1/3] Menginstal Nginx di Debian 12...  "
echo "=========================================="

# Update package list
sudo apt update -y

# Install Nginx
sudo apt install nginx -y

# Aktifkan dan jalankan Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Menampilkan status Nginx secara singkat
if systemctl is-active --quiet nginx; then
    echo "✔ Nginx berhasil diinstal dan berjalan dengan baik."
else
    echo "❌ Terjadi masalah, Nginx gagal dijalankan."
fi