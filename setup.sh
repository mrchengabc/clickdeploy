#!/bin/bash
# setup.sh - ClickDeploy Orchestrator

# Mengambil lokasi absolut dari folder tempat script ini berada
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# ==========================================
# FUNGSI CEK UPDATE OTOMATIS DARI GITHUB (VERSI AMAN)
# ==========================================
check_for_updates() {
    if [ -d "$DIR/.git" ]; then
        echo "Memeriksa pembaruan dari GitHub..."
        
        # Mengambil informasi perubahan terbaru secara senyap
        git fetch >/dev/null 2>&1
        
        # Mendapatkan ID commit lokal dan remote
        LOCAL=$(git rev-parse HEAD 2>/dev/null)
        REMOTE=$(git rev-parse @{u} 2>/dev/null)
        
        # Jika versi berbeda dan remote tidak kosong
        if [ "$LOCAL" != "$REMOTE" ] && [ ! -z "$REMOTE" ]; then
            echo "=========================================="
            echo "   Mendeteksi VERSI BARU di GitHub!      "
            echo "      Sedang mengunduh pembaruan...      "
            echo "=========================================="
            
            # SOLUSI: Reset paksa semua perubahan lokal sebelum pull untuk menghindari konflik
            git reset --hard HEAD >/dev/null 2>&1
            
            # Tarik pembaruan dari branch yang aktif saat ini
            CURRENT_BRANCH=$(git branch --show-current)
            if git pull origin "$CURRENT_BRANCH" >/dev/null 2>&1; then
                # Berikan kembali izin eksekusi
                chmod +x "$DIR/setup.sh" "$DIR/modules"/*.sh 2>/dev/null
                
                echo "✔ Update berhasil diterapkan!"
                echo "Memulai ulang script dengan versi terbaru..."
                sleep 1.5
                
                # Memulai ulang script
                exec "$DIR/setup.sh" "$@"
                exit 0
            else
                echo "❌ Gagal menarik pembaruan otomatis dari GitHub."
                echo "Melanjutkan menggunakan versi lokal yang ada..."
                sleep 2
            fi
        fi
    fi
}

# Jalankan pengecekan update sebelum menampilkan menu utama
check_for_updates

# --- SELESAI BAGIAN AUTO-UPDATE ---
# ... (lanjutkan ke fungsi run_module, sub-menu, dan menu utama seperti sebelumnya) ...

# Fungsi helper untuk menjalankan modul dengan aman
run_module() {
    local module_name="$1"
    local module_path="$DIR/modules/$module_name"
    
    if [ -f "$module_path" ]; then
        chmod +x "$module_path"
        bash "$module_path"
    else
        echo "❌ Error: Modul '$module_name' tidak ditemukan di folder modules/."
        echo "   Pastikan file $module_path sudah Anda upload ke GitHub."
    fi
    echo ""
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# --- SUB-MENU 1: SETUP & KEAMANAN DASAR ---
menu_server_setup() {
    while true; do
        clear
        echo "=========================================="
        echo "     [1] SETUP & KEAMANAN UTAMA SERVER    "
        echo "=========================================="
        echo "1) Install Nginx Web Server"
        echo "2) Aktifkan Firewall & Keamanan (UFW & Fail2Ban)"
        echo "3) Ubah Port SSH dari 22 ke 2222"
		echo "4) Tambah / Atur SWAP File"
        echo "5) Hardening Nginx (XML-RPC Block & Security Headers)"
        echo "6) Kembali ke Menu Utama"
        echo "=========================================="
        read -p "Pilih opsi [1-5]: " sub_opt
        
        case $sub_opt in
            1) run_module "install_nginx.sh" ;;
            2) run_module "secure_vps.sh" ;;
            3) run_module "change_ssh_port.sh" ;;
			4) run_module "create_swap.sh" ;;  
            5) run_module "security_hardening.sh" ;;
            6) break ;;
            *) echo "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

# --- SUB-MENU 2: MANAJEMEN WEBSITE ---
menu_website_mgmt() {
    while true; do
        clear
        echo "=========================================="
        echo "       [2] MANAJEMEN WEBSITE & DOMAIN     "
        echo "=========================================="
        echo "1) Tambah Website Baru (HTML, PHP, WordPress + Database)"
        echo "2) Hapus Website (Hapus File, Nginx Vhost, & Database)"
        echo "3) Pasang SSL Let's Encrypt (HTTPS)"
        echo "4) Utilitas WordPress (Permissions, Maintenance Mode)"
        echo "5) Kembali ke Menu Utama"
        echo "=========================================="
        read -p "Pilih opsi [1-5]: " sub_opt
        
        case $sub_opt in
            1) run_module "website_add.sh" ;;
            2) run_module "website_delete.sh" ;;
            3) run_module "nginx_ssl.sh" ;;
            4) run_module "wordpress_utils.sh" ;;
            5) break ;;
            *) echo "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

# --- SUB-MENU 3: OPTIMASI PERFORMA ---
menu_performance() {
    while true; do
        clear
        echo "=========================================="
        echo "          [3] OPTIMASI PERFORMA           "
        echo "=========================================="
        echo "1) Install & Konfigurasi Performa"
        echo "   (Redis Cache, OPcache, Nginx Gzip, FastCGI Cache)"
        echo "2) Kembali ke Menu Utama"
        echo "=========================================="
        read -p "Pilih opsi [1-2]: " sub_opt
        
        case $sub_opt in
            1) run_module "performance_tuning.sh" ;;
            2) break ;;
            *) echo "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

# --- SUB-MENU 4: BACKUP, MIGRASI & TRANSFER ---
menu_backup_migrate() {
    while true; do
        clear
        echo "=========================================="
        echo "     [4] BACKUP, MIGRASI & TRANSFER       "
        echo "=========================================="
        echo "1) Monitor Server & Backup Lokal (Rotasi 7 Hari)"
        echo "2) Ekspor Domain untuk Migrasi (Kompres File & Dump DB)"
        echo "3) Restore Domain dari Backup"
        echo "4) Kirim File Migrasi ke VPS Lain (Rsync)"
        echo "5) Kembali ke Menu Utama"
        echo "=========================================="
        read -p "Pilih opsi [1-5]: " sub_opt
        
        case $sub_opt in
            1) run_module "backup_healthcheck.sh" ;;
            2) run_module "website_migrate.sh" ;;
            3) run_module "website_restore.sh" ;;
            4) run_module "rsync_transfer.sh" ;;
            5) break ;;
            *) echo "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

# --- MENU UTAMA ---
while true; do
    clear
    echo "=========================================="
    echo "       CLICKDEPLOY - PANEL AUTOMATION     "
    echo "=========================================="
    echo "1) Setup & Keamanan Utama Server"
    echo "2) Manajemen Website & Domain"
    echo "3) Optimasi Performa Server"
    echo "4) Backup, Migrasi & Transfer Data"
    echo "5) Keluar"
    echo "=========================================="
    read -p "Pilih Menu [1-5]: " main_opt
    
    case $main_opt in
        1) menu_server_setup ;;
        2) menu_website_mgmt ;;
        3) menu_performance ;;
        4) menu_backup_migrate ;;
        5) 
            echo "Keluar dari ClickDeploy. Sampai jumpa!"
            exit 0 
            ;;
        *) 
            echo "Pilihan tidak valid!"; sleep 1 
            ;;
    esac
done