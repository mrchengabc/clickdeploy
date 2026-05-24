#!/bin/bash
# modules/website_restore.sh

echo "=========================================="
echo "  [Module] Restore Domain dari Backup...  "
echo "=========================================="

read -p "Masukkan Nama Domain yang ingin di-restore: " domain
read -p "Path Absolut File Backup (.tar.gz): " file_backup
read -p "Path Absolut Database Backup (.sql.gz) [Opsional]: " db_backup

# Buat folder root domain jika belum ada
WEB_ROOT="/var/www/$domain/public"
sudo mkdir -p "$WEB_ROOT"

# 1. Ekstrak File Web
if [ -f "$file_backup" ]; then
    echo "Mengekstrak file web..."
    sudo tar -xzf "$file_backup" -C "/var/www/$domain"
    sudo chown -R www-data:www-data "/var/www/$domain"
    echo "✔ File berhasil diekstrak."
else
    echo "❌ File backup web tidak ditemukan!"
    exit 1
fi

# 2. Restore Database
if [ -f "$db_backup" ]; then
    DB_NAME=$(echo "$domain" | sed 's/\./_/g')
    DB_USER="usr_${DB_NAME:0:10}"
    DB_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    
    echo "Menyiapkan database baru $DB_NAME..."
    sudo mariadb -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
    sudo mariadb -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    sudo mariadb -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
    sudo mariadb -e "FLUSH PRIVILEGES;"
    
    echo "Mengimpor database..."
    zcat "$db_backup" | sudo mariadb "$DB_NAME"
    echo "✔ Database berhasil di-restore."
    echo "⚠️  PENTING: Jangan lupa sesuaikan informasi database baru di wp-config.php atau file config aplikasi Anda:"
    echo "   Database Name: $DB_NAME"
    echo "   Database User: $DB_USER"
    echo "   Database Pass: $DB_PASS"
fi