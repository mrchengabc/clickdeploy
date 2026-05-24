#!/bin/bash
# modules/website_migrate.sh

MIGRATE_DIR="/var/backups/clickdeploy/migration"
DATE=$(date +%s)

echo "=========================================="
echo "  [Module] Migrasi & Ekspor Domain...     "
echo "=========================================="

# 1. Deteksi dan tampilkan daftar domain yang aktif di Nginx
echo "Daftar domain yang aktif di VPS saat ini:"
echo "------------------------------------------"

# Mengambil daftar file dari folder sites-enabled, lalu mengabaikan konfigurasi 'default' bawaan Nginx
LIST_DOMAINS=$(ls -1 /etc/nginx/sites-enabled/ 2>/dev/null | grep -v "^default$")

if [ -z "$LIST_DOMAINS" ]; then
    echo " (Tidak ada domain aktif yang ditemukan) "
    echo "------------------------------------------"
    echo "❌ Tidak ada website yang dapat dimigrasikan."
    exit 0
else
    # Menampilkan daftar domain dengan rapi
    echo "$LIST_DOMAINS"
    echo "------------------------------------------"
fi

# 2. Input nama domain dari pengguna
read -p "Ketik nama domain yang ingin dimigrasikan: " domain

if [ -z "$domain" ]; then
    echo "❌ Nama domain tidak boleh kosong!"
    exit 1
fi

# 3. Validasi: Pastikan domain yang diketik ada di dalam daftar sistem
if ! echo "$LIST_DOMAINS" | grep -Fq "$domain"; then
    echo "❌ Error: Domain '$domain' tidak terdaftar atau tidak aktif di VPS Anda!"
    exit 1
fi

WEB_ROOT="/var/www/$domain"
if [ ! -d "$WEB_ROOT" ]; then
    echo "❌ Folder website $WEB_ROOT tidak ditemukan!"
    exit 1
fi

sudo mkdir -p "$MIGRATE_DIR"

# 4. Kompres File Web
echo ""
echo "Mengompres seluruh file website untuk $domain..."
sudo tar -czf "$MIGRATE_DIR/${domain}_files_$DATE.tar.gz" -C "$WEB_ROOT" .
echo "✔ File web berhasil dikompres."

# 5. Ekspor Database (Dioptimalkan untuk DB berukuran besar)
DB_NAME=$(echo "$domain" | sed 's/\./_/g')
if command -v mariadb >/dev/null 2>&1; then
    echo "Mengekspor database $DB_NAME (menggunakan optimasi dump)..."
    
    # Cek apakah database benar-benar ada di MariaDB
    if mariadb -e "USE \`$DB_NAME\`" 2>/dev/null; then
        # --single-transaction mencegah tabel terkunci, --quick menghemat memori server
        sudo mysqldump --single-transaction --quick --lock-tables=false "$DB_NAME" | gzip > "$MIGRATE_DIR/${domain}_db_$DATE.sql.gz"
        echo "✔ Database berhasil diekspor."
    else
        echo "⚠️  Database '$DB_NAME' tidak ditemukan. Hanya mencadangkan file website."
    fi
else
    echo "⚠️  Database tidak terdeteksi atau MariaDB tidak terinstal di VPS ini."
fi

echo "=========================================="
echo "✔ Selesai! Hasil migrasi tersimpan di:"
echo "   File: $MIGRATE_DIR/${domain}_files_$DATE.tar.gz"
if [ -f "$MIGRATE_DIR/${domain}_db_$DATE.sql.gz" ]; then
    echo "   Database: $MIGRATE_DIR/${domain}_db_$DATE.sql.gz"
fi
echo "=========================================="