#!/bin/bash
# modules/backup_healthcheck.sh

BACKUP_DIR="/var/backups/clickdeploy"
DATE=$(date +%F)

echo "=========================================="
echo "  [Module] Backup & Healthcheck System... "
echo "=========================================="

echo "1) Jalankan Monitor Kesehatan Server (Healthcheck)"
echo "2) Jalankan Backup Manual dengan Rotasi (7 hari)"
read -p "Pilih [1-2]: " hc_opt

if [ "$hc_opt" == "1" ]; then
    echo "--- HEALTHCHECK REPORT ---"
    echo "Disk Usage:"
    df -h | grep '^/dev/'
    echo "--------------------------"
    echo "Memory Usage:"
    free -h
    echo "--------------------------"
    echo "Active Services:"
    for service in nginx mariadb php8.2-fpm redis-server; do
        systemctl is-active --quiet $service && echo "✔ $service: RUNNING" || echo "❌ $service: STOPPED"
    done
elif [ "$hc_opt" == "2" ]; then
    read -p "Masukkan nama folder domain yang ingin dibackup (di /var/www/): " domain_name
    TARGET_DIR="/var/www/$domain_name"
    
    if [ -d "$TARGET_DIR" ]; then
        sudo mkdir -p "$BACKUP_DIR"
        echo "Mencadangkan file..."
        sudo tar -czf "$BACKUP_DIR/${domain_name}_files_$DATE.tar.gz" -C "$TARGET_DIR" .
        
        # Coba backup database jika ada MariaDB
        if command -v mariadb >/dev/null 2>&1; then
            echo "Mencari database..."
            # Asumsi nama database sama dengan nama domain (tanpa titik)
            DB_NAME=$(echo "$domain_name" | sed 's/\./_/g')
            if mariadb -e "USE $DB_NAME" 2>/dev/null; then
                sudo mysqldump --single-transaction --quick "$DB_NAME" | gzip > "$BACKUP_DIR/${domain_name}_db_$DATE.sql.gz"
                echo "✔ Database $DB_NAME berhasil dibackup."
            fi
        fi
        
        echo "✔ Backup selesai disimpan di: $BACKUP_DIR"
        
        # Rotasi Otomatis: Hapus file backup yang berumur lebih dari 7 hari
        sudo find "$BACKUP_DIR" -type f -mtime +7 -name "${domain_name}*" -delete
        echo "✔ Pembersihan otomatis file backup berusia >7 hari selesai."
    else
        echo "❌ Folder domain $TARGET_DIR tidak ditemukan."
    fi
fi