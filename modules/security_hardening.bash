#!/bin/bash
# modules/security_hardening.sh

echo "=========================================="
echo "  [Module] Mengaktifkan Keamanan Nginx... "
echo "=========================================="

# Membuat direktori snippet jika belum ada
sudo mkdir -p /etc/nginx/snippets

# 1. Buat file snippet keamanan wordpress & php execution
cat << 'EOF' | sudo tee /etc/nginx/snippets/security-hardened.conf > /dev/null
# Blokir akses ke xmlrpc.php (sering jadi sasaran DDoS/Brute Force)
location = /xmlrpc.php {
    deny all;
    access_log off;
    log_not_found off;
}

# Blokir eksekusi file PHP di folder upload (mencegah backdoor/shell upload)
location ~* ^/wp-content/uploads/.*\.php$ {
    deny all;
    access_log off;
    log_not_found off;
}

# Tambahkan Security Headers global
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "upgrade-insecure-requests; block-all-mixed-content" always;
EOF

sudo systemctl reload nginx
echo "✔ Snippet keamanan berhasil dibuat di /etc/nginx/snippets/security-hardened.conf"
echo "  (Anda bisa menyertakan file ini pada blok server domain Anda nanti)"