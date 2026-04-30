#!/bin/bash
# PCAPdroid Headless - Kullanım Komutları

PKG="com.emanuelef.remote_capture.headless.debug"
RECEIVER="com.emanuelef.remote_capture.CaptureControlReceiver"
API_KEY="PCAPdroid-2024-Static-Key-12345"

# Target app package name (boş bırakılırsa tüm uygulamalar capture edilir)
TARGET_APP="com.instagram.android"  # Örnek: "com.whatsapp" veya "com.instagram.android"

# Capture başlat (HTTP server modu)
start_capture() {
    echo "Starting capture..."
    if [ -n "$TARGET_APP" ]; then
        echo "Filtering app: $TARGET_APP"
        adb shell am broadcast \
            -n ${PKG}/${RECEIVER} \
            -a com.emanuelef.remote_capture.START_CAPTURE \
            --es api_key "${API_KEY}" \
            --es pcap_dump_mode "http_server" \
            --ei http_server_port 8080 \
            --es app_filter "$TARGET_APP"
    else
        echo "Capturing all apps..."
        adb shell am broadcast \
            -n ${PKG}/${RECEIVER} \
            -a com.emanuelef.remote_capture.START_CAPTURE \
            --es api_key "${API_KEY}" \
            --es pcap_dump_mode "http_server" \
            --ei http_server_port 8080
    fi
}

# Capture başlat (Dosyaya kaydet - HIZLI)
start_capture_file() {
    echo "Starting capture (file mode - faster download)..."
    PCAP_FILE="/sdcard/Download/pcapdroid_$(date +%Y%m%d_%H%M%S).pcap"
    echo "PCAP file: $PCAP_FILE"
    
    if [ -n "$TARGET_APP" ]; then
        echo "Filtering app: $TARGET_APP"
        adb shell am broadcast \
            -n ${PKG}/${RECEIVER} \
            -a com.emanuelef.remote_capture.START_CAPTURE \
            --es api_key "${API_KEY}" \
            --es pcap_dump_mode "pcap_file" \
            --es pcap_uri "file://${PCAP_FILE}" \
            --es pcap_name "$(basename ${PCAP_FILE})" \
            --es app_filter "$TARGET_APP"
    else
        echo "Capturing all apps..."
        adb shell am broadcast \
            -n ${PKG}/${RECEIVER} \
            -a com.emanuelef.remote_capture.START_CAPTURE \
            --es api_key "${API_KEY}" \
            --es pcap_dump_mode "pcap_file" \
            --es pcap_uri "file://${PCAP_FILE}" \
            --es pcap_name "$(basename ${PCAP_FILE})"
    fi
    
    echo "PCAP_FILE=${PCAP_FILE}" > /tmp/pcapdroid_current.txt
}

# Capture durdur
stop_capture() {
    echo "Stopping capture..."
    adb shell am broadcast \
        -n ${PKG}/${RECEIVER} \
        -a com.emanuelef.remote_capture.STOP_CAPTURE \
        --es api_key "${API_KEY}"
}

# Status kontrol
get_status() {
    adb shell am broadcast \
        -n ${PKG}/${RECEIVER} \
        -a com.emanuelef.remote_capture.GET_STATUS \
        --es api_key "${API_KEY}"
}

# Port forwarding
setup_port() {
    echo "Setting up port forwarding..."
    adb forward tcp:8080 tcp:8080
}

# PCAP indir
download_pcap() {
    echo "Downloading PCAP..."
    curl http://localhost:8080/pcap_download -o capture_$(date +%Y%m%d_%H%M%S).pcap
}

# PCAP pull (dosya modundan - hızlı)
pull_pcap() {
    if [ -f /tmp/pcapdroid_current.txt ]; then
        source /tmp/pcapdroid_current.txt
        echo "Pulling PCAP from phone..."
        adb pull "${PCAP_FILE}" ./
        echo "Done! File: $(basename ${PCAP_FILE})"
    else
        echo "No active file capture. Use 'start-file' first."
        echo "Or manually: adb pull /sdcard/Download/pcapdroid_*.pcap ./"
    fi
}

# Logları göster
show_logs() {
    adb logcat -s CaptureControlReceiver:* CaptureService:* VpnPermissionActivity:*
}

# Belirli app için capture
capture_app() {
    APP_PACKAGE=$1
    if [ -z "$APP_PACKAGE" ]; then
        echo "Usage: capture_app <package_name>"
        return 1
    fi
    
    echo "Capturing traffic for: $APP_PACKAGE"
    adb shell am broadcast \
        -n ${PKG}/${RECEIVER} \
        -a com.emanuelef.remote_capture.START_CAPTURE \
        --es api_key "${API_KEY}" \
        --es pcap_dump_mode "http_server" \
        --ei http_server_port 8080 \
        --es app_filter "$APP_PACKAGE"
}

# VPN izni ver (manuel - notification'dan önce)
grant_vpn() {
    echo "Opening VPN permission dialog..."
    echo "Please tap 'OK' on your phone to grant VPN permission"
    adb shell am start -n ${PKG}/com.emanuelef.remote_capture.VpnPermissionActivity
}

# Komut listesi
case "$1" in
    start)
        start_capture
        ;;
    start-file)
        start_capture_file
        ;;
    stop)
        stop_capture
        ;;
    status)
        get_status
        ;;
    port)
        setup_port
        ;;
    download)
        download_pcap
        ;;
    pull)
        pull_pcap
        ;;
    logs)
        show_logs
        ;;
    app)
        capture_app $2
        ;;
    grant)
        grant_vpn
        ;;
    *)
        echo "PCAPdroid Headless Kullanımı:"
        echo ""
        echo "  ./HEADLESS_KOMUTLAR.sh grant         - VPN izni ver (ilk seferinde)"
        echo "  ./HEADLESS_KOMUTLAR.sh start         - Capture başlat (HTTP server)"
        echo "  ./HEADLESS_KOMUTLAR.sh start-file    - Capture başlat (dosyaya kaydet - HIZLI)"
        echo "  ./HEADLESS_KOMUTLAR.sh stop          - Capture durdur"
        echo "  ./HEADLESS_KOMUTLAR.sh status        - Durum kontrol"
        echo "  ./HEADLESS_KOMUTLAR.sh port          - Port forwarding (HTTP modu için)"
        echo "  ./HEADLESS_KOMUTLAR.sh download      - PCAP indir (HTTP modu - yavaş)"
        echo "  ./HEADLESS_KOMUTLAR.sh pull          - PCAP çek (dosya modu - HIZLI)"
        echo "  ./HEADLESS_KOMUTLAR.sh logs          - Logları göster"
        echo "  ./HEADLESS_KOMUTLAR.sh app <pkg>     - Belirli app capture et"
        echo ""
        echo "Hızlı Workflow - ÖNERİLEN:"
        echo "  1. ./HEADLESS_KOMUTLAR.sh grant"
        echo "  2. ./HEADLESS_KOMUTLAR.sh start-file"
        echo "  3. Instagram kullan, trafik üret"
        echo "  4. ./HEADLESS_KOMUTLAR.sh stop"
        echo "  5. ./HEADLESS_KOMUTLAR.sh pull"
        ;;
esac
