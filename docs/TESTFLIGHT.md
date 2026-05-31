# Scoutiq — TestFlight yükleme

## Otomatik build

```bash
chmod +x scripts/build_ios_testflight.sh
./scripts/build_ios_testflight.sh
```

Çıkan `.ipa` → **Transporter** veya Xcode **Organizer** ile App Store Connect’e yükle.

## Sürüm

`yetenek_avcisi/pubspec.yaml` → `version: X.Y.Z+BUILD`

Her yüklemede **+BUILD** artır (ör. `1.0.3+7`).

## Kontrol listesi

- [ ] Apple Developer + App Store Connect uygulaması (`com.musaok.yetenekavcisi`)
- [ ] Xcode Team: `67X96JGY7Z`
- [ ] `Runner.entitlements` → `aps-environment` = `production`
- [ ] TestFlight Internal Testing grubuna Apple ID ekle
- [ ] Smoke: giriş, keşfet, video, hesap silme

## Backend (isteğe bağlı, yeni API için)

DigitalOcean deploy + `ENVIRONMENT=production` + migration + isteğe bağlı `FCM_ENABLED=true`.

Canlı API: `https://stingray-app-g3o9y.ondigitalocean.app`

## Test hesapları (seed)

| Rol | E-posta | Şifre |
|-----|---------|--------|
| Admin | admin@scoutiq.local | admin123 |
| Scout | scout@avci.com | sifre123 |
