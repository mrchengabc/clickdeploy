#!/bin/bash
# modules/website_delete.sh

echo "=========================================="
echo "  [Module] Hapus Domain (Delete Domain)"
echo "=========================================="

# 1. Deteksi dan tampilkan daftar domain yang aktif di Nginx
echo "Daftar domain yang terinstal di VPS saat ini:"
echo "------------------------------------------"

# Mengambil daftar file dari folder sites-enabled, lalu mengabaikan konfigurasi 'default' bawaan Nginx
LIST_DOMAINS=$(ls -1 /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "^default$")

if [ -z "$LIST_DOMAINS" ]; then
    echo " (Tidak ada domain aktif yang ditemukan) "
    echo "------------------------------------------"
    echo "❌ Tidak ada website yang dapat dihapus."
    exit 0
else
    # Menampilkan daftar domain dengan rapi
    echo "$LIST_DOMAINS"
    echo "------------------------------------------"
fi

# 2. Menerima input domain dari pengguna
read -p "Ketik nama domain yang ingin dihapus: " domain

if [ -z "$domain" ]; then
    echo "❌ Nama domain tidak boleh kosong!"
    exit 1
fi

# 3. Validasi: Pastikan domain yang diketik memang ada di dalam daftar sistem
if ! echo "$LIST_DOMAINS" | grep -Fq "$domain"; then
    echo "❌ Error: Domain '$domain' tidak terdaftar di sistem VPS Anda!"
    exit 1
fi

# 4. Tanyakan Otorisasi Konfirmasi
echo ""
echo "⚠️  PERINGATAN KERAS! Anda akan menghapus secara permanen:"
echo "   - File website di /var/www/$domain"
echo "   - Konfigurasi Nginx untuk $domain"
echo "   - Database & User Database untuk $domain"
echo ""
read -p "Apakah Anda benar-benar yakin ingin menghapus? (ya/tidak): " konfirmasi

if [ "$konfirmasi" != "ya" ]; then
    echo "❌ Proses penghapusan dibatalkan."
    exit 0
fi

echo "Memulai proses penghapusan untuk $domain..."

# 5. Hapus Nginx Virtual Host (Konfigurasi website)
sudo rm -f "/etc/nginx/sites-enabled/$domain"
sudo rm -f "/etc/nginx/sites-available/$domain"
sudo systemctl reload nginx
echo "✔ Konfigurasi Nginx untuk $domain berhasil dihapus."

# 6. Hapus Database dan User Database terkait
# (Konvensi penamaan mengikuti standar pembuatan di website_add.sh)
DB_NAME=$(echo "$domain" | sed 's/\./_/g')
DB_USER="usr_${DB_NAME:0:10}"

if command -v mariadb >/dev/null 2>&1; then
    # Menghapus database dan user di MariaDB secara senyap
    sudo mariadb -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"
    sudo mariadb -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
    sudo mariadb -e "FLUSH PRIVILEGES;"
    echo "✔ Database '$DB_NAME' dan User '$DB_USER' berhasil dihapus."
fi

# 7. Hapus Folder File Website
WEB_PATH="/var/www/$domain"
if [ -d "$WEB_PATH" ]; then
    sudo rm -rf "$WEB_PATH"
    echo "✔ Folder file di $WEB_PATH berhasil dihapus."
fi

echo "=========================================="
echo "✔ Sukses! Domain $domain telah sepenuhnya dibersihkan dari server."
echo "=========================================="