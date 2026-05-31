# Scoutiq (Yetenek Avcısı) — Proje notları

Tek kaynak: yol haritası, mimari özet, birleşik OVR, backlog ve ölçekleme notları.

Detaylı stack listesi: kök `TECHNICAL_DOCS.md`. Kurulum: kök `README.md`.

---

## Backend mimarisi (özet)

```
backend/
  main.py              # Uvicorn girişi
  app_factory.py       # FastAPI + router kayıtları
  config.py            # ENVIRONMENT, AUTO_CREATE_TABLES
  deps.py              # auth / scout / admin
  database.py
  services/            # analiz, rating, keşfet, combined_rating, …
  routers/
    auth.py
    api_routes.py
```

- **Geliştirme:** `ENVIRONMENT=development`, `AUTO_CREATE_TABLES=true` → tablolar otomatik.
- **Production:** `ENVIRONMENT=production` → yalnızca `alembic upgrade head`; `/setup/*` kapalı.
- Çalışan uygulama `app_factory` üzerinden; eski tek dosya monolith kaldırıldı.

---

## Tamamlanan analiz yol haritası

| # | Konu | Durum |
|---|------|--------|
| 1 | Slot bazlı finalize (`slot_v1`, rubrik + ağırlıklı OVR) | ✅ |
| 2 | Yüklemede sıkı doğrulama | ✅ |
| 3 | Koşu: OpenCV + sanal kapı + yükleme kalite kontrolü | ✅ |
| 4 | Rubrik kütüphanesi (`slot_rubrics.py`) | ✅ |
| 5 | Şeffaflık (`slot_breakdown` UI) | ✅ |
| 6 | Scout + AI birleşik OVR | ✅ `combined_rating.py` |
| — | Forvet dripling tek video; çift video yalnızca **Hız** | ✅ |

### Veri kaynakları

| Kaynak | Nerede | Alanlar |
|--------|--------|---------|
| AI | `players_multivideo.overall_rating`, `skill_scores` | OVR, PAC…PHY, `slot_breakdown` |
| Scout | community rating | PAC…PHY, `rating_count` |
| Koşu | `kosu_videos_by_slot` | `timing_sec`, `timing_source` |

---

## 6. adım — Birleşik OVR (uygulandı)

**Sorun:** AI OVR ile scout topluluk puanı ayrı gösteriliyordu.

**Çözüm:** `backend/services/combined_rating.py`

| Scout sayısı | Ağırlık |
|--------------|---------|
| 0 | %100 AI |
| 1–2 | %70 AI + %30 topluluk |
| ≥3 | %45 AI + %55 topluluk |

**API alanları:** `overall_rating` (görünür/birleşik), `ai_ovr`, `community_ovr`, `combined_ovr`, `combined_rating`, `community_rating`.

**Keşfet:** Liste `overall_rating` ile sıralanır (birleşik); `min_ovr` / `max_ovr` filtreleri birleşik skora göre sonradan uygulanır.

**Flutter:** `CombinedOvrStrip` — oyuncu detayda AI · Topluluk · Birleşik.

DB’deki `overall_rating` yalnızca AI kalır; birleşik skor yanıtta hesaplanır.

---

## Production / DevOps (5–6–7 uygulandı)

| Alan | Durum |
|------|--------|
| Refresh token + revoke (DB) | ✅ `/auth/refresh`, `/auth/logout` |
| Env validation (prod/staging) | ✅ `config.validate_settings()` |
| `/setup/*` prod kapalı | ✅ |
| Upload rate limit | ✅ `UploadRateLimitMiddleware` |
| KVKK silme + export | ✅ `DELETE/GET /users/me` |
| Scout belge magic-byte | ✅ `file_validation.py` |
| CI (pytest + flutter test) | ✅ `.github/workflows/ci.yml` |
| Docker Compose | ✅ `docker-compose.yml` |
| Seed admin/scout/futbolcu | ✅ `seed_data.py` |
| Sentry (opsiyonel) | ✅ `SENTRY_DSN` |
| API v1 prefix | ✅ `/api/v1/...` + kök uyumlu |
| FIFA watermark + deep link | ✅ paylaşım + `yetenekavcisi://` |
| Scout referral | ✅ `/auth/me/referral` |
| Story 9:16 export | ✅ paylaşım seçeneği |
| Crashlytics | ✅ Firebase (yapılandırma varsa) |

**Prod env örneği:** `ENVIRONMENT=production`, `SECRET_KEY=...`, `DATABASE_URL=postgresql://...`, `GEMINI_API_KEY=...`

---

## Sonraki işler (backlog)

### Koşu — Faz 2

- [ ] Koşu çekim ekranı: kadraj overlay, geri sayım
- [ ] MediaPipe Pose ile çizgi geçişi
- [ ] Gemini + CV hibrit koni/çizgi
- [ ] `flat_timing_sec` tam API + liste UI
- [ ] İsteğe bağlı scout onaylı manuel süre düzeltme

### Analiz — Faz 3

- [ ] Rubrik v2 + mevki genişletme
- [ ] Çapraz doğrulama (yüksek OVR)
- [ ] Yaş/cinsiyet norm tablosu
- [ ] Eski kayıtlar için toplu re-finalize

### Altyapı

- [ ] `analyze_multiple_videos` legacy temizliği
- [ ] Celery/RQ kuyruk (aşağıda)

### Ürün / UX

- [ ] Kartlarda “AI tahmini” kısa uyarı
- [ ] Keşfet: min birleşik OVR, min scout sayısı filtresi

### Öncelik önerisi

1. Koşu kamera overlay  
2. MediaPipe / hibrit CV  
3. Rubrik v2 + re-finalize  

---

## Analiz kuyruğu — ölçeklenince

**Şu an (MVP):** `BackgroundTasks` → `run_multivideo_finalize` (`analysis_worker.py`); Flutter `analysis-status` poll.

**Ne zaman yükselt:** çok eşzamanlı analiz, restart’ta kayıp iş, çoklu API instance, Gemini timeout.

**Hedef:**

```
API → Redis job → 202
Worker → run_multivideo_finalize → analysis_status
```

**Dokunulacaklar:** `api_routes.py` finalize, `analysis_worker.py`, `multi_upload_service.dart` poll, env `REDIS_URL`.

---

## Geliştirme komutları

```bash
cd backend && pip install -r requirements.txt
DATABASE_URL=sqlite:///./scout_app.db ENVIRONMENT=development AUTO_CREATE_TABLES=true \
  uvicorn main:app --host 0.0.0.0 --port 8000 --reload

cd yetenek_avcisi && flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Eski analizler için oyuncuda **yeniden finalize** gerekir (`slot_v1`, OpenCV timing).

---

*Son güncelleme: 6. adım birleşik OVR + dokümantasyon birleştirme.*
