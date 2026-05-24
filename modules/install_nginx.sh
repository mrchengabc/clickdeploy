#!/bin/bash
# modules/install_nginx.sh

echo "=========================================="
echo "  [1/3] Menginstal Nginx di Debian 12...  "
echo "=========================================="

# Update daftar paket sistem
sudo apt update -y

# 1. ANTISIPASI BENTROK: Periksa & matikan Apache jika terpasang bawaan dari OS template VPS
if systemctl is-active --quiet apache2 || systemctl is-enabled --quiet apache2 2>/dev/null; then
    echo "⚠️ Mendeteksi Apache2 aktif. Menghentikan Apache2 agar port 80 tidak bentrok..."
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    sudo apt purge apache2 -y
fi

# 2. Instalasi Nginx
sudo apt install nginx -y

# 3. PENGAMAN SNIPPET KOSONG
# Membuat folder snippet dan file dummy agar jika ada konfigurasi vhost lama yang merujuk ke sini, Nginx tidak crash.
sudo mkdir -p /etc/nginx/snippets
if [ ! -f /etc/nginx/snippets/security-hardened.conf ]; then
    sudo touch /etc/nginx/snippets/security-hardened.conf
    echo "✔ Membuat file pengaman kosong di /etc/nginx/snippets/security-hardened.conf"
fi

# 4. ANTISIPASI ERROR IPv6: Periksa apakah sistem VPS mendukung IPv6
# Jika tidak mendukung, kita beri komentar (#) pada pengaturan listen IPv6 Nginx agar tidak crash
if [ ! -f /proc/net/if_inet6 ]; then
    echo "⚠️ Sistem Anda tidak mendukung IPv6 (dinonaktifkan). Menyesuaikan konfigurasi default Nginx..."
    if [ -f /etc/nginx/sites-available/default ]; then
        sudo sed -i 's/listen \[::\]:80/#listen \[::\]:80/g' /etc/nginx/sites-available/default
    fi
fi

# 5. OTOMATIS BUKA FIREWALL (UFW) UNTUK PORT WEB (PENTING!)
# Jika UFW terpasang di sistem, script akan otomatis mengizinkan akses ke port 80 dan 443
if command -v ufw >/dev/null 2>&1; then
    echo "Mendeteksi UFW terpasang. Otomatis membuka port 80 (HTTP) & 443 (HTTPS)..."
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw reload
    echo "✔ Port 80 dan 443 berhasil dibuka di firewall UFW."
fi

# 6. Verifikasi konfigurasi sebelum mencoba menjalankan service
echo "Memverifikasi konfigurasi Nginx..."
if sudo nginx -t; then
    echo "✔ Konfigurasi valid. Mengaktifkan service Nginx..."
    sudo systemctl enable nginx
    sudo systemctl restart nginx
else
    echo "❌ Konfigurasi Nginx bermasalah saat divalidasi!"
fi

# 7. Verifikasi Akhir & Debugging Otomatis jika gagal
if systemctl is-active --quiet nginx; then
    echo "=========================================="
    echo "✔ SUKSES: Nginx berhasil berjalan dengan baik!"
    echo "=========================================="
else
    echo "=========================================="
    echo "❌ GAGAL: Nginx tidak dapat dijalankan."
    echo "Menampilkan detail error langsung ke Anda:"
    echo "------------------------------------------"
    sudo nginx -t
    echo "------------------------------------------"
    sudo journalctl -n 15 -u nginx --no-pager
    echo "=========================================="
fi