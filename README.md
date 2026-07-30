# PCAPdroid Headless

Network packet capture servisi - GUI yok, sadece ADB kontrolü.

Bu repo bir **builder** olarak kullanılır: `build_headless_pcapdroid.sh` çalıştırılır, headless APK üretilir.

## 🔨 APK Üretmek

```bash
./build_headless_pcapdroid.sh
# ==> Tamam: releases/pcapdroid-headless.apk (15M)
```

Script sırasıyla:
1. Android SDK'yı bulur (`ANDROID_HOME` set değilse `~/Library/Android/sdk` ve Homebrew yollarına bakar)
2. Native kod submodule'leri eksikse `git submodule update --init --recursive` çalıştırır
3. `./gradlew assembleHeadlessDebug` çalıştırır
4. Çıktıyı `releases/pcapdroid-headless.apk` olarak kopyalar

### Gereksinimler

| | |
|---|---|
| JDK | 17 |
| Android SDK | compileSdk 35 |
| NDK | 28.2.13676358 |
| CMake | 3.22.1 |

Repo `--recursive` klonlanmalı (6 submodule native kod içeriyor):

```bash
git clone --recursive git@github.com:device-park/device-park-pcapdroid-android-app.git
```

> Submodule'ler repo'da gitlink olarak kayıtlıdır (`.gitmodules`), içerikleri repo'ya
> dahil değildir. `--recursive` unutulursa script `git submodule update --init --recursive`
> çalıştırarak kendisi çeker; bunun için `.git` dizini ve internet erişimi gerekir.

### Üretilen APK

| | |
|---|---|
| Paket | `com.emanuelef.remote_capture.headless.debug` |
| versionName | `1.9.1-headless-beta` |
| Boyut | ~15 MB |
| ABI | arm64-v8a, armeabi-v7a, x86, x86_64 |
| İmza | debug keystore (`~/.android/debug.keystore`) |
| Launcher | görünmez (headless) |

## 🐳 Docker ile Build

### Gereksinimler

| | |
|---|---|
| Mimari | **linux/amd64** — Android NDK ve `aapt2` için Linux ARM64 host binary'leri yok. Apple Silicon'da `--platform=linux/amd64` (emülasyon, build ~3-4x yavaşlar) |
| Base image | JDK 17 (`eclipse-temurin:17-jdk`) |
| Paketler | `git`, `curl`, `unzip` (submodule çekme + SDK kurulumu için) |
| SDK bileşenleri | `platform-tools`, `platforms;android-35`, `build-tools;35.0.0`, `ndk;28.2.13676358`, `cmake;3.22.1` |
| Disk | ~8 GB (NDK tek başına 2.8 GB) + gradle cache için ~2 GB |
| RAM | 4 GB+ (gradle daemon + 4 ABI için native derleme) |
| Ağ | Gradle 9.2.1 wrapper, bağımlılıklar ve submodule'ler build sırasında indirilir |

### Örnek Dockerfile

```dockerfile
FROM --platform=linux/amd64 eclipse-temurin:17-jdk

RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl unzip && rm -rf /var/lib/apt/lists/*

ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# cmdline-tools (guncel surum: https://developer.android.com/studio#command-tools)
RUN mkdir -p "$ANDROID_HOME/cmdline-tools" && \
    curl -sSLo /tmp/tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip -q /tmp/tools.zip -d "$ANDROID_HOME/cmdline-tools" && \
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" && \
    rm /tmp/tools.zip

RUN yes | sdkmanager --licenses > /dev/null && \
    sdkmanager --install \
      "platform-tools" \
      "platforms;android-35" \
      "build-tools;35.0.0" \
      "ndk;28.2.13676358" \
      "cmake;3.22.1"

WORKDIR /src
CMD ["./build_headless_pcapdroid.sh"]
```

### Kullanım

```bash
docker build --platform=linux/amd64 -t pcapdroid-builder .

docker run --rm --platform=linux/amd64 \
  -v "$PWD":/src \
  -v pcapdroid-gradle:/root/.gradle \
  -v "$HOME/.android":/root/.android \
  pcapdroid-builder
# APK: releases/pcapdroid-headless.apk
```

> **Keystore uyarısı:** debug APK, `~/.android/debug.keystore` ile imzalanır. Bu dosya
> container içinde yoksa Gradle her build'de **yeni** bir keystore üretir; imza
> değiştiği için cihazdaki eski sürümün üzerine `adb install -r` yapılamaz
> (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Yukarıdaki gibi kalıcı bir `.android`
> dizini mount edin veya sabit bir keystore'u imaja koyun.

> **`.git` gerekli:** submodule'ler build sırasında `git submodule update --init`
> ile çekildiği için repo'yu mount ederken `.git` dizini de gelmelidir. Alternatif
> olarak submodule'leri host'ta çekip öyle mount edin.

### CI (GitHub Actions) notu

Submodule'lerin CI'da eksik olması sorun değil; checkout adımı çeker:

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
```

Bu satır olmasa bile script `git submodule update --init --recursive` ile kendisi
çeker. Runner'da NDK/CMake sürümleri hazır gelmediği için build'den önce kurulmalıdır:

```yaml
- run: yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "ndk;28.2.13676358" "cmake;3.22.1"
- run: ./build_headless_pcapdroid.sh
```

## 🚀 Hızlı Başlangıç

```bash
# 1. APK'yı kur
adb install -r releases/pcapdroid-headless.apk

# 2. VPN izni ver (ilk seferinde - telefonda "Tamam"a bas)
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
- ✅ Root **gerekli değil**

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
./HEADLESS_KOMUTLAR.sh app <pkg>     # Belirli app capture et
```

## ⚙️ Yapılandırma

`HEADLESS_KOMUTLAR.sh` dosyasını düzenleyin:

```bash
# Paket adı (build çıktısıyla eşleşmeli)
PKG="com.emanuelef.remote_capture.headless.debug"

# Target app (boş = tüm uygulamalar)
TARGET_APP="com.instagram.android"

# API Key
API_KEY="PCAPdroid-2024-Static-Key-12345"
```

## 📦 Değişiklikler

### Kod Değişiklikleri
1. `Prefs.java` - Static API key eklendi
2. `CaptureControlReceiver.java` - Broadcast receiver oluşturuldu
3. `VpnPermissionActivity.java` - VPN permission yönetimi
4. `app/src/headless/AndroidManifest.xml` - Headless variant
5. `app/build.gradle` - Headless flavor eklendi

### Build Flavors
- **headless**: GUI yok, sadece service
- **standard**: Orijinal uygulama
- **withoutUshark**: uShark olmadan

## 🐛 Sorun Giderme

**Build "SDK location not found" diyor:**
```bash
export ANDROID_HOME=/path/to/android/sdk
./build_headless_pcapdroid.sh
```

**Build "submodules/zdtun does not contain a CMakeLists.txt" diyor:**
Submodule dizinleri boş değil ama git submodule değil (içlerinde artık dosyalar
var). Dizinleri temizleyip tekrar deneyin:
```bash
git submodule update --init --recursive
```

**VPN izni gelmiyor:**
```bash
./HEADLESS_KOMUTLAR.sh grant
# Telefonda "Tamam" tıklayın
```

**Capture başlamıyor:**
```bash
./HEADLESS_KOMUTLAR.sh logs
```

**PCAP boş:**
Hedef uygulamayı kullanın (trafik üretin) ve VPN'in aktif olduğunu kontrol edin
(Ayarlar > VPN). `TARGET_APP` filtresi yanlış paket adı içeriyorsa da PCAP boş kalır.

## 📝 Notlar

- İlk kullanımda VPN permission dialog açılır, sonraki kullanımlarda otomatik başlar
- APK launcher'da görünmez, sadece ADB ile kontrol edilir
- `pull` komutu dosya yolunu `/tmp/pcapdroid_current.txt`'ten okur, bu yüzden
  `start-file` ile aynı makineden çalıştırılmalıdır

## 🔗 Orijinal Proje

[PCAPdroid](https://github.com/emanuele-f/PCAPdroid) - Emanuele Faranda

Bu repo PCAPdroid'in headless bir varyantıdır. Orijinal proje gibi **GPL-3.0**
lisanslıdır, lisans metni için `COPYING` dosyasına bakın.
