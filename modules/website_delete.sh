#!/bin/bash
# modules/website_delete.sh

echo "=========================================="
echo "  [Module] Hapus Domain (Delete Domain)"
echo "=========================================="

read -p "Masukkan Nama Domain yang ingin dihapus: " domain
if [ -z "$domain" ]; then
    echo "❌ Domain tidak boleh kosong!"
    exit 1
fi

# Tanyakan Otorisasi Konfirmasi
echo "⚠️  PERINGATAN! Anda akan menghapus file website dan database untuk $domain!"
read -p "Apakah Anda benar-benar yakin ingin menghapus? (ya/tidak): " konfirmasi

if [ "$konfirmasi" != "ya" ]; then
    echo "❌ Penghapusan dibatalkan."
    exit 0
fi

# 1. Hapus Nginx Virtual Host
sudo rm -f "/etc/nginx/sites-enabled/$domain"
sudo rm -f "/etc/nginx/sites-available/$domain"
sudo systemctl reload nginx
echo "✔ Konfigurasi Nginx dihapus."

# 2. Hapus Database dan User Database
DB_NAME=$(echo "$domain" | sed 's/\./_/g')
DB_USER="usr_${DB_NAME:0:10}"

if command -v mariadb >/dev/null 2>&1; then
    sudo mariadb -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"
    sudo mariadb -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
    sudo mariadb -e "FLUSH PRIVILEGES;"
    echo "✔ Database dan User Database berhasil dibersihkan."
fi

# 3. Hapus File Website
WEB_PATH="/var/www/$domain"
if [ -d "$WEB_PATH" ]; then
    sudo rm -rf "$WEB_PATH"
    echo "✔ Seluruh file di $WEB_PATH berhasil dihapus."
fi

echo "✔ Sukses! Domain $domain telah sepenuhnya dihapus."