# 📄 Yetenek Avcısı — Teknik Döküman

## 🏗️ Genel Mimari

```
Flutter (iOS/Android) ──► FastAPI Backend ──► PostgreSQL
                                │
                    ┌───────────┼────────────┐
                 Cloudinary   Gemini AI    Brevo
                (Video/Foto)  (Analiz)    (Email)
```

---

## 📱 Frontend — Flutter

| Alan | Teknoloji |
|---|---|
| Framework | Flutter 3.x (Dart SDK ^3.11.5) |
| Versiyon | 1.0.2+4 |
| Platform | iOS & Android |

### State Management
- **flutter_bloc** ^9.1.1 — Auth akışı
- **ValueNotifier** (`currentUserNotifier`) — Global kullanıcı state
- **SharedPreferences** — Session kalıcı depolama (`SessionStore`)

### Navigation
- **go_router** ^17.2.3

### UI / Görsel
- **flutter_animate** ^4.5.0 — Animasyonlar (splash, geçişler)
- **fl_chart** ^0.70.0 — Oyuncu rating grafikleri
- **blur** ^4.0.0 — Glassmorphism efektler
- **percent_indicator** ^4.2.3
- **google_fonts** ^8.1.0
- **font_awesome_flutter** ^10.8.0
- **cupertino_icons** ^1.0.8

### Sosyal Login
- **google_sign_in** ^6.2.2
- **sign_in_with_apple** ^6.1.2

### Medya & Dosya
- **video_player** ^2.11.1
- **image_picker** ^1.2.2
- **file_picker** ^11.0.2
- **share_plus** ^11.1.0
- **path_provider** ^2.1.5

### Ağ
- **http** ^1.6.0 — Backend API çağrıları
- **dio** ^5.8.0

---

## 🖥️ Backend — Python / FastAPI

| Alan | Teknoloji |
|---|---|
| Framework | FastAPI |
| Sunucu | Uvicorn (ASGI) |
| Dil | Python 3.14 |
| ORM | SQLAlchemy |
| Migration | Alembic |
| Auth | JWT (python-jose) + bcrypt (passlib) |

### Veritabanı
- **PostgreSQL** — Ana veritabanı
- **psycopg2-binary** — PostgreSQL driver

### Modüller
| Dosya | Görev |
|---|---|
| `main.py` | Ana API endpoint'leri |
| `models.py` | User, Player tabloları |
| `models_multivideo.py` | MultiVideoPlayer tablosu |
| `schemas.py` | Pydantic request/response şemaları |
| `auth.py` | JWT token üretimi/doğrulama |
| `email_service.py` | OTP email gönderimi (Brevo) |
| `otp_service.py` | OTP üretimi/doğrulama |
| `storage.py` | Cloudinary video/foto upload |
| `vision.py` | Video analizi |
| `step_analyzer.py` | AI step-by-step analiz |
| `position_skills_config.py` | Pozisyon bazlı skill konfigürasyonu |
| `cache.py` | Redis cache |
| `rate_limiter.py` | Rate limiting |
| `middleware.py` | Custom middleware |

### Router'lar
- `routers/auth.py` — Register, login, OTP, sosyal login

---

## ☁️ Altyapı & Servisler

| Servis | Kullanım |
|---|---|
| **DigitalOcean App Platform** | Backend hosting |
| **PostgreSQL (DigitalOcean)** | Veritabanı |
| **Cloudinary** | Video ve profil fotoğrafı depolama |
| **Google Gemini AI** | Oyuncu video analizi & AI rapor |
| **Brevo (eski Sendinblue)** | OTP & transactional email |
| **Apple Sign In** | iOS sosyal giriş |
| **Google Sign In** | Android/iOS sosyal giriş |

### Environment Variables
```
DATABASE_URL          — PostgreSQL bağlantısı
CLOUDINARY_CLOUD_NAME — Cloudinary hesabı
CLOUDINARY_API_KEY    — Cloudinary API
CLOUDINARY_API_SECRET — Cloudinary secret
GEMINI_API_KEY        — Google Gemini AI
BREVO_API_KEY         — Email servisi
SENDER_EMAIL          — Gönderici email
SECRET_KEY            — JWT imzalama
ADMIN_SECRET          — Admin endpoint koruma
```

---

## 🔐 Güvenlik

- **JWT Bearer Token** — Tüm korumalı endpoint'ler
- **OTP Email Doğrulama** — Kayıt zorunlu
- **bcrypt** — Şifre hashleme
- **Rate Limiting** — API abuse koruması
- **CORS** — Cross-origin kontrolü
- **Admin Secret Key** — Admin işlemleri

---

## 📊 Veri Modeli (Özet)

```
User
├── id, email, full_name, phone_number
├── birth_date, age, role
├── hashed_password, is_verified, is_active
├── profile_image_url
├── provider, provider_id (sosyal login)
└── otp_code, otp_expires_at

Player (eski sistem)
├── user_id → User
├── position, overall_rating
└── 15+ skill puanı

MultiVideoPlayer (yeni sistem)
├── user_id → User
├── position, position_code
├── overall_rating, skill_scores (JSON)
├── ai_summary_report, ai_strengths, ai_improvements
└── videos[] (3 slot)
```

---

## 📲 Uygulama Akışı

```
Kayıt → OTP Email → Doğrulama → Ana Ekran
Giriş (email/şifre) → Ana Ekran
Giriş (Google/Apple) → Profil Tamamla → Ana Ekran

Futbolcu: Profil → 3 Video Yükle → AI Analiz → Skor
Scout:    Keşfet → Oyuncuları Gör → Değerlendir
Admin:    Admin Panel → Kullanıcı Yönetimi
```

---

**Versiyon:** 1.0.2 | **Build:** 4 | **Son güncelleme:** Mayıs 2026
