#!/bin/bash
# modules/nginx_ssl.sh

echo "=========================================="
echo "  [Module] Instalasi & Konfigurasi SSL... "
echo "=========================================="

# 1. Install Certbot jika belum ada
if ! command -v certbot >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install certbot python3-certbot-nginx -y
fi

read -p "Masukkan domain yang ingin dipasang SSL (misal: domain.com atau www.domain.com): " domain
read -p "Masukkan email Anda (untuk notifikasi kedaluwarsa SSL): " email

if [ -z "$domain" ] || [ -z "$email" ]; then
    echo "❌ Domain dan Email tidak boleh kosong."
    exit 1
fi

# Buat sertifikat menggunakan plugin Nginx milik certbot
sudo certbot --nginx -d "$domain" --non-interactive --agree-tos --email "$email" --redirect

# Memastikan cron job atau systemd timer untuk auto-renew berjalan
if systemctl is-active --quiet certbot.timer; then
    echo "✔ Auto-renew otomatis aktif via systemd-timer."
else
    # Tambahkan fallback cron job jika systemd timer tidak ada
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    echo "✔ Auto-renew ditambahkan ke Crontab harian."
fi