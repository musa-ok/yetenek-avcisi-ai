# MVP telefon bildirimi (push) — kurulum

## Hangi olaylar telefona gider?

| Kind | Olay |
|------|------|
| `analysis_done` | AI analiz bitti (futbolcu) |
| `analysis_failed` | Analiz hata (futbolcu) |
| `rating` | Yeni scout puanı |
| `rating_updated` | Scout puanı güncellendi |
| `scout_note` | Scout notu |
| `scout_approved` | Scout onay |
| `scout_rejected` | Scout red |
| `admin_pending_scout` | Admin: yeni başvuru |

Diğerleri (kota, OVR, videolar tamam, güvenlik vb.) **sadece** uygulama içi **Bildirimler** listesinde.

Kod: `backend/services/notifications.py` → `PUSH_NOTIFICATION_KINDS`

---

## 1. Firebase (bir kez)

Detay: [FIREBASE_FCM_SETUP.md](./FIREBASE_FCM_SETUP.md)

```bash
cd yetenek_avcisi
flutterfire configure
```

iOS: Xcode → Push Notifications + APNs `.p8` Firebase Console’a.

---

## 2. DigitalOcean (backend)

App → Environment Variables:

```env
FCM_ENABLED=true
FIREBASE_CREDENTIALS_JSON={"type":"service_account",...}
```

(JSON = Firebase service account tek satır)

Deploy / redeploy.

---

## 3. Uygulama build

TestFlight için yeni build (`pubspec.yaml` build numarasını artır).

Kullanıcı: **Profil → Ayarlar** → Bildirimler **açık** → giriş.

Debug log: `[FCM] token backend'e kaydedildi`

---

## 4. Test

| Rol | Tetikleyici |
|-----|-------------|
| Futbolcu | Finalize → analiz bitti |
| Futbolcu | Scout puan / not (2. hesap) |
| Scout | Admin onay (admin panel) |
| Admin | Scout belge yükledi |

Uygulama **arka planda veya kapalı** iken banner beklenir.

---

## Sorun giderme

| Belirti | Çözüm |
|---------|--------|
| Liste dolu, push yok | `FCM_ENABLED`, JSON, token log |
| iOS push yok | APNs key, gerçek cihaz, production build |
| Sadece ön planda yok | iOS 10+ foreground banner `setForegroundNotificationPresentationOptions` (kodda var) |
