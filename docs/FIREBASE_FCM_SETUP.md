# Firebase FCM — Adim Adim Kurulum (Yetenek Avcisi)

Bu rehber hem **Flutter (cihaz)** hem **backend (push gonderimi)** icin gecerlidir.

---

## On bilgi: Paket kimlikleri

Projede su an:

| Platform | Kimlik |
|----------|--------|
| **Android** | `com.example.yetenek_avcisi` |
| **iOS** | `com.musaok.yetenekavcisi` |

Firebase'de **iki ayri uygulama** (Android + iOS) kaydetmeniz gerekir. Ileride tek kimlik kullanmak isterseniz Android `applicationId` ile iOS bundle ID'yi eslestirin.

---

## Bolum A — Firebase Console (tek seferlik)

### 1. Proje olustur

1. [Firebase Console](https://console.firebase.google.com) acin.
2. **Add project** / **Proje ekle**.
3. Proje adi: ornegin `Yetenek Avcisi`.
4. Google Analytics istege bagli (FCM icin sart degil).

### 2. Android uygulamasi ekle

1. Proje ana sayfasinda **Android** ikonuna tiklayin.
2. **Android package name:** `com.example.yetenek_avcisi`
3. App nickname: `Yetenek Avcisi Android` (istege bagli).
4. **Register app** → **Download google-services.json** indirin (flutterfire bunu otomatik yapacak; manuel de olur).
5. Sonraki adimlari simdilik atlayabilirsiniz.

### 3. iOS uygulamasi ekle

1. Ayni Firebase projesinde **Add app** → **iOS**.
2. **Apple bundle ID:** `com.musaok.yetenekavcisi`
3. **Register app** → **GoogleService-Info.plist** indirin (yine flutterfire otomatik koyar).

### 4. Cloud Messaging

Firebase Console → **Build** → **Cloud Messaging** — ekstra acma gerekmez; proje olusturunca hazirdir.

### 5. iOS icin APNs anahtari (sadece iPhone push icin)

Apple push icin Firebase'e APNs bilgisi vermeniz gerekir:

1. [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles** → **Keys**.
2. **+** ile yeni key → **Apple Push Notifications service (APNs)** isaretleyin.
3. Key indirin (`.p8` dosyasi). **Key ID** ve **Team ID** not alin.
4. Firebase Console → Proje **Settings** (disli) → **Cloud Messaging** sekmesi → **Apple app configuration**.
5. **APNs Authentication Key** yukleyin: `.p8`, Key ID, Team ID.

Simulator'da push sinirlidir; gercek cihazda test edin.

---

## Bolum B — Flutter (`flutterfire configure`)

### 1. CLI kur

```bash
dart pub global activate flutterfire_cli
```

PATH'e ekleyin (gerekirse):

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### 2. Firebase'e giris

```bash
firebase login
```

Firebase CLI yoksa: `npm install -g firebase-tools` veya [Firebase CLI](https://firebase.google.com/docs/cli).

### 3. Flutter projesinde yapilandir

```bash
cd yetenek_avcisi
flutterfire configure
```

Sorular:

- Firebase projenizi secin (`Yetenek Avcisi`).
- Platform: **Android** ve **iOS** isaretleyin.
- Android package: `com.example.yetenek_avcisi`
- iOS bundle: `com.musaok.yetenekavcisi`

**Olusturulan / guncellenen dosyalar:**

| Dosya | Konum |
|-------|--------|
| `firebase_options.dart` | `yetenek_avcisi/lib/` |
| `google-services.json` | `yetenek_avcisi/android/app/` |
| `GoogleService-Info.plist` | `yetenek_avcisi/ios/Runner/` |
| Gradle ayarlari | Android `build.gradle` dosyalari |

### 4. iOS — Xcode capability

```bash
open ios/Runner.xcworkspace
```

1. Sol panel **Runner** → **Signing & Capabilities**.
2. **+ Capability** → **Push Notifications**.
3. (Onerilir) **Background Modes** → **Remote notifications** isaretleyin.

### 5. Calistir ve token kontrolu

```bash
cd yetenek_avcisi
flutter pub get
flutter run
```

1. Uygulamaya **scout veya futbolcu** olarak giris yapin.
2. Debug konsolda su loglari arayin:
   - `[FCM] token backend'e kaydedildi` → basarili
   - `[FCM] init atlandi` → Firebase dosyalari / configure eksik

Token backend'de `users.fcm_device_token` alanina yazilir.

---

## Bolum C — Backend (push gonderimi)

Backend, **service account JSON** ile FCM'e push atar (telefon tarafindaki `google-services.json` ile karistirmayin).

### 1. Service account anahtari indir

1. Firebase Console → **Project settings** (disli).
2. **Service accounts** sekmesi.
3. **Generate new private key** → JSON indir.
4. Guvenli bir yere koyun, ornegin:
   `backend/secrets/firebase-service-account.json`
5. **Bu dosyayi Git'e commit etmeyin.**

`.gitignore` ornegi:

```
backend/secrets/
*.json
!package.json
```

(Projenizde sadece `secrets/` klasorunu ignore etmek daha guvenli.)

### 2. Python bagimliligi

```bash
cd backend
pip install firebase-admin
# veya
pip install -r requirements.txt
```

### 3. Ortam degiskenleri

**Yerel gelistirme** (`backend/.env` veya shell):

```bash
FCM_ENABLED=true
FIREBASE_CREDENTIALS_PATH=/Users/SENIN_KULLANICI/Projects/yetenek-avcisi/backend/secrets/firebase-service-account.json
```

Alternatif (Docker / cloud icin tek satir):

```bash
FCM_ENABLED=true
FIREBASE_CREDENTIALS_JSON='{"type":"service_account","project_id":"...", ...}'
```

### 4. Backend'i baslat

```bash
cd backend
ENVIRONMENT=development uvicorn main:app --reload
```

### 5. Test push

1. Flutter'da giris yapip token kaydoldugundan emin olun.
2. Bir scout oyuncuya puan versin **veya** admin scout onaylasin **veya** analiz finalize olsun.
3. In-app bildirim + (FCM aciksa) telefon bildirimi gelmeli.

Manuel test icin Python REPL:

```python
from services.fcm_push import send_push
send_push("CIHAZ_FCM_TOKEN_BURAYA", title="Test", body="Merhaba")
```

---

## Bolum D — DigitalOcean / production

1. Service account JSON icerigini platform **secret** olarak ekleyin.
2. Ornek:
   - `FCM_ENABLED=true`
   - `FIREBASE_CREDENTIALS_JSON` = JSON'un tam metni (tek satir)
3. Backend deploy sonrasi loglarda `FCM push gonderildi` arayin.

---

## Sik karsilasilan sorunlar

| Sorun | Cozum |
|-------|--------|
| `[FCM] init atlandi` | `flutterfire configure` calistirin; `lib/firebase_options.dart` var mi kontrol edin |
| Android build hatasi `google-services` | `flutterfire configure` Gradle plugin'lerini ekler; tekrar calistirin |
| iOS'ta token yok | Gercek cihaz, Push capability, APNs key Firebase'de yuklu mu |
| Backend push atmiyor | `FCM_ENABLED=true`, JSON yolu dogru, `pip install firebase-admin` |
| Token kayitli ama push yok | Firebase Console'da Cloud Messaging acik; cihaz bildirim izni verdi mi |

---

## Ozet checklist

- [ ] Firebase projesi olusturuldu
- [ ] Android (`com.example.yetenek_avcisi`) eklendi
- [ ] iOS (`com.musaok.yetenekavcisi`) eklendi
- [ ] `flutterfire configure` calistirildi
- [ ] iOS Push Notifications capability eklendi
- [ ] iOS APNs key Firebase'e yuklendi
- [ ] Uygulamada giris → `[FCM] token backend'e kaydedildi`
- [ ] Backend: `FCM_ENABLED=true` + service account JSON
- [ ] Test bildirimi geldi
