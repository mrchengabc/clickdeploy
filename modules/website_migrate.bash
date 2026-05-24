#!/bin/bash
# modules/website_migrate.sh

MIGRATE_DIR="/var/backups/clickdeploy/migration"
DATE=$(date +%s)

echo "=========================================="
echo "  [Module] Migrasi & Ekspor Domain...     "
echo "=========================================="

read -p "Masukkan Nama Domain yang ingin dimigrasikan: " domain
WEB_ROOT="/var/www/$domain"

if [ ! -d "$WEB_ROOT" ]; then
    echo "❌ Folder website $WEB_ROOT tidak ditemukan!"
    exit 1
fi

sudo mkdir -p "$MIGRATE_DIR"

# 1. Kompres File Web
echo "Mengompres file website..."
sudo tar -czf "$MIGRATE_DIR/${domain}_files_$DATE.tar.gz" -C "$WEB_ROOT" .
echo "✔ File web berhasil dikompres."

# 2. Ekspor Database (Dioptimalkan untuk DB berukuran besar)
DB_NAME=$(echo "$domain" | sed 's/\./_/g')
if command -v mariadb >/dev/null 2>&1; then
    echo "Mengekspor database $DB_NAME (menggunakan optimasi dump)..."
    # --single-transaction mencegah tabel terkunci, --quick menghemat memori server
    sudo mysqldump --single-transaction --quick --lock-tables=false "$DB_NAME" | gzip > "$MIGRATE_DIR/${domain}_db_$DATE.sql.gz"
    echo "✔ Database berhasil diekspor."
else
    echo "⚠️  Database tidak terdeteksi atau MariaDB tidak terinstal."
fi

echo "✔ Selesai! Hasil migrasi tersimpan di:"
echo "   File: $MIGRATE_DIR/${domain}_files_$DATE.tar.gz"
echo "   Database: $MIGRATE_DIR/${domain}_db_$DATE.sql.gz"