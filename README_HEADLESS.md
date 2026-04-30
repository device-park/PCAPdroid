# PCAPdroid Headless Edition

Network packet capture servisi - GUI yok, sadece ADB kontrolü.

## 🚀 Hızlı Başlangıç

```bash
# 1. APK'yı kur (releases/ klasöründe)
adb install releases/pcapdroid-headless.apk

# 2. VPN izni ver (ilk seferinde)
./HEADLESS_KOMUTLAR.sh grant

# 3. Capture başlat
./HEADLESS_KOMUTLAR.sh start-file

# 4. Instagram kullan (trafik üret)

# 5. Durdur ve PCAP çek
./HEADLESS_KOMUTLAR.sh stop
./HEADLESS_KOMUTLAR.sh pull
```

## 📋 Özellikler

- ✅ Headless (launcher'da görünmez)
- ✅ ADB broadcast kontrolü
- ✅ Static API key (her cihazda aynı)
- ✅ App-specific filtering (örn: sadece Instagram)
- ✅ Hızlı PCAP indirme (adb pull)
- ✅ VPN izni (bir kere)
- ✅ 15MB APK boyutu

## 🎯 Tüm Komutlar

```bash
./HEADLESS_KOMUTLAR.sh grant         # VPN izni ver
./HEADLESS_KOMUTLAR.sh start-file    # Capture başlat (dosya)
./HEADLESS_KOMUTLAR.sh start         # Capture başlat (HTTP)
./HEADLESS_KOMUTLAR.sh stop          # Durdur
./HEADLESS_KOMUTLAR.sh pull          # PCAP çek (hızlı)
./HEADLESS_KOMUTLAR.sh download      # PCAP indir (HTTP - yavaş)
./HEADLESS_KOMUTLAR.sh status        # Durum kontrol
./HEADLESS_KOMUTLAR.sh logs          # Logları göster
```

## ⚙️ Yapılandırma

`HEADLESS_KOMUTLAR.sh` dosyasını düzenleyin:

```bash
# Target app (boş = tüm uygulamalar)
TARGET_APP="com.instagram.android"

# API Key
API_KEY="PCAPdroid-2024-Static-Key-12345"
```

## 🔧 Yeniden Build Etmek İçin

```bash
# Clean build
./gradlew clean assembleHeadlessDebug

# APK konumu
app/build/outputs/apk/headless/debug/app-headless-debug.apk

# Releases'e kopyala
cp app/build/outputs/apk/headless/debug/app-headless-debug.apk releases/pcapdroid-headless.apk
```

## 📦 Değişiklikler

### Kod Değişiklikleri
1. `Prefs.java` - Static API key eklendi
2. `CaptureControlReceiver.java` - Broadcast receiver oluşturuldu
3. `VpnPermissionActivity.java` - VPN permission yönetimi
4. `app/src/headless/AndroidManifest.xml` - Headless variant
5. `app/build.gradle` - Headless flavor eklendi

### Build Flavors
- **headless**: GUI yok, sadece service (15MB)
- **standard**: Orijinal uygulama (23MB)
- **withoutUshark**: uShark olmadan (15MB)

## 📊 Dosya Boyutları

- APK: 15MB
- PCAP (Instagram 1dk): ~2-5MB
- Git repo: 761MB (submodules dahil)

## 🐛 Sorun Giderme

**VPN izni gelmiyor:**
```bash
./HEADLESS_KOMUTLAR.sh grant
# Telefonda "OK" tıklayın
```

**Capture başlamıyor:**
```bash
./HEADLESS_KOMUTLAR.sh logs
# Logları kontrol edin
```

**PCAP boş:**
```bash
# Instagram'ı kullanın (trafik üretin)
# VPN aktif mi kontrol edin: Settings > VPN
```

## 📝 Notlar

- İlk kullanımda VPN permission dialog açılır
- Sonraki kullanımlarda otomatik başlar
- APK launcher'da görünmez
- Sadece ADB ile kontrol edilir
- Root **gerekli değil**

## 🔗 Orijinal Proje

[PCAPdroid](https://github.com/emanuele-f/PCAPdroid) - Emanuele Faranda
