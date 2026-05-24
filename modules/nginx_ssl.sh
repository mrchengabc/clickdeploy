#!/bin/bash
# modules/nginx_ssl.sh

echo "=========================================="
echo "  [Module] Instalasi & Konfigurasi SSL... "
echo "=========================================="

# 1. Install Certbot jika belum ada di sistem
if ! command -v certbot >/dev/null 2>&1; then
    echo "Certbot belum terpasang. Menginstal Certbot dan modul Nginx..."
    sudo apt update -y
    sudo apt install certbot python3-certbot-nginx -y
fi

# 2. Deteksi dan tampilkan daftar domain yang aktif di Nginx
echo "Daftar domain yang aktif di VPS saat ini:"
echo "------------------------------------------"

# Mengambil daftar file dari folder sites-enabled, lalu mengabaikan konfigurasi 'default' bawaan Nginx
LIST_DOMAINS=$(ls -1 /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "^default$")

if [ -z "$LIST_DOMAINS" ]; then
    echo " (Tidak ada domain aktif yang ditemukan) "
    echo "------------------------------------------"
    echo "❌ Silakan tambahkan domain terlebih dahulu melalui menu website sebelum memasang SSL."
    exit 1
else
    # Menampilkan daftar domain dengan rapi
    echo "$LIST_DOMAINS"
    echo "------------------------------------------"
fi

# 3. Input nama domain
read -p "Ketik nama domain dari daftar di atas: " domain

if [ -z "$domain" ]; then
    echo "❌ Nama domain tidak boleh kosong!"
    exit 1
fi

# 4. Validasi: Pastikan domain yang diketik ada dalam daftar sistem
if ! echo "$LIST_DOMAINS" | grep -Fq "$domain"; then
    echo "❌ Error: Domain '$domain' tidak terdaftar atau tidak aktif di VPS Anda!"
    exit 1
fi

# 5. Opsi Tambahan: Pasang SSL untuk versi WWW sekaligus
read -p "Apakah Anda juga ingin memasang SSL untuk www.$domain? (ya/tidak): " include_www

# 6. Meminta email untuk notifikasi Let's Encrypt
read -p "Masukkan email Anda (untuk notifikasi kedaluwarsa SSL): " email
if [ -z "$email" ]; then
    echo "❌ Email tidak boleh kosong."
    exit 1
fi

echo "Memulai proses instalasi SSL untuk $domain..."

# 7. Eksekusi Certbot dengan opsi kondisional
if [ "$include_www" == "ya" ]; then
    echo "Memasang SSL untuk $domain dan www.$domain..."
    sudo certbot --nginx -d "$domain" -d "www.$domain" --non-interactive --agree-tos --email "$email" --redirect
else
    echo "Memasang SSL hanya untuk $domain..."
    sudo certbot --nginx -d "$domain" --non-interactive --agree-tos --email "$email" --redirect
fi

# 8. Verifikasi keberhasilan dan Memastikan auto-renew berjalan
if [ $? -eq 0 ]; then
    echo "=========================================="
    echo "✔ SUKSES: SSL Let's Encrypt berhasil dipasang!"
    echo "=========================================="
    
    # Cek apakah systemd timer untuk auto-renew berjalan
    if systemctl is-active --quiet certbot.timer; then
        echo "✔ Auto-renew otomatis aktif via systemd-timer."
    else
        # Tambahkan fallback cron job jika systemd timer tidak aktif
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        echo "✔ Auto-renew cadangan ditambahkan ke Crontab harian."
    fi
else
    echo "=========================================="
    echo "❌ GAGAL: Terjadi kendala saat pemasangan SSL."
    echo "Pastikan IP domain Anda sudah benar-benar terarah ke VPS ini."
    echo "=========================================="
fi