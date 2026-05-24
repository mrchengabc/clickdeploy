#!/bin/bash
# modules/wordpress_utils.sh

echo "=========================================="
echo "  [Module] WP-CLI & WordPress Utilities... "
echo "=========================================="

# 1. Install WP-CLI secara global jika belum ada
if ! command -v wp >/dev/null 2>&1; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    echo "✔ WP-CLI berhasil diinstal secara global."
fi

# Fungsi utilitas
echo "Pilih opsi utilitas:"
echo "1) Perbaiki Permissions WordPress (Chmod/Chown)"
echo "2) Aktifkan Maintenance Mode"
echo "3) Matikan Maintenance Mode"
read -p "Opsi [1-3]: " wp_opt

case $wp_opt in
    1)
        read -p "Masukkan path absolut folder WordPress (misal: /var/www/domain.com/public): " wp_path
        if [ -d "$wp_path" ]; then
            sudo chown -R www-data:www-data "$wp_path"
            find "$wp_path" -type d -exec chmod 755 {} \;
            find "$wp_path" -type f -exec chmod 644 {} \;
            echo "✔ Permissions diperbaiki (Direktori: 755, File: 644, Owner: www-data)"
        else
            echo "❌ Folder tidak ditemukan!"
        fi
        ;;
    2)
        read -p "Masukkan path absolut folder WordPress: " wp_path
        if [ -d "$wp_path" ]; then
            sudo -u www-data wp maintenance-mode activate --path="$wp_path" --allow-root
            echo "✔ Maintenance Mode AKTIF."
        else
            echo "❌ Folder tidak ditemukan!"
        fi
        ;;
    3)
        read -p "Masukkan path absolut folder WordPress: " wp_path
        if [ -d "$wp_path" ]; then
            sudo -u www-data wp maintenance-mode deactivate --path="$wp_path" --allow-root
            echo "✔ Maintenance Mode NONAKTIF."
        else
            echo "❌ Folder tidak ditemukan!"
        fi
        ;;
    *)
        echo "Opsi batal."
        ;;
esac