# Yetenek Avcısı - Talent Hunter Platform

Futbolcu yetenek analiz ve scout platformu için modern REST API ve Flutter mobil uygulaması.

## 🚀 Özellikler

### Backend (FastAPI)
- **Modern API**: FastAPI ile yüksek performanslı REST API
- **Veritabanı**: PostgreSQL ve SQLite desteği (Alembic migrations)
- **AI Analiz**: Google Gemini ile video analiz
- **Cloud Storage**: AWS S3 ve yerel depolama desteği
- **Cache**: Redis ile performans optimizasyonu
- **Rate Limiting**: API koruma ve kullanım limitleri
- **Authentication**: JWT tabanlı güvenlik
- **Dokümantasyon**: Otomatik OpenAPI/Swagger dokümantasyonu
- **Testing**: Pytest ile kapsamlı test suit'i

### Frontend (Flutter)
- **Modern UI**: Material Design 3
- **Çift Dil**: Türkçe/İngilizce desteği
- **Video İşleme**: Kamera kayıt ve galeri desteği
- **Real-time Analiz**: AI destekli oyuncu değerlendirme
- **Social Features**: Scout network ve iletişim

## 📋 Gereksinimler

### Backend
- Python 3.8+
- PostgreSQL (production) veya SQLite (development)
- Redis (cache için)
- Google Gemini API Key

### Frontend
- Flutter 3.11.5+
- Dart SDK

## 🛠 Kurulum

### Backend

1. **Repository clone'la:**
```bash
git clone <repository-url>
cd yetenek-avcisi
```

2. **Python environment oluştur:**
```bash
python -m venv venv
source venv/bin/activate  # Windows için venv\Scripts\activate
```

3. **Dependencies kur:**
```bash
pip install -r requirements.txt
```

4. **Environment variables ayarla:**
```bash
cp .env.example .env
# .env dosyasını düzenle:
# - DATABASE_URL
# - GEMINI_API_KEY
# - REDIS_URL (opsiyonel)
# - AWS credentials (opsiyonel)
```

5. **Veritabanı migrations çalıştır:**
```bash
alembic upgrade head
```

6. **Server'ı başlat:**
```bash
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

1. **Flutter dependencies kur:**
```bash
cd yetenek_avcisi
flutter pub get
```

2. **Uygulamayı çalıştır:**
```bash
flutter run
```

## 📚 API Dokümantasyonu

Server çalıştığında aşağıdaki adreslerden erişebilirsiniz:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## 🗄 Veritabanı Schema

### Users
- Kullanıcı profilleri (Scout/Futbolcu)
- JWT authentication
- Telefon ve email bilgileri

### Players
- Oyuncu profilleri ve istatistikler
- AI analiz sonuçları
- Pozisyon spesifik metrikler

### Ratings
- Community değerlendirmeleri
- FIFA benzeri 6 ana metrik
- Scout yorumları

## 🔧 Development

### Testing

```bash
# Backend testleri
python -m pytest tests/ -v

# Flutter testleri
cd yetenek_avcisi
flutter test
```

### Database Migrations

```bash
# Yeni migration oluştur
alembic revision --autogenerate -m "Migration description"

# Migration çalıştır
alembic upgrade head

# Migration geri al
alembic downgrade -1
```

### Code Quality

```bash
# Python formatting
black backend/
isort backend/

# Flutter analiz
cd yetenek_avcisi
flutter analyze
```

## 🚀 Deployment

### Production Setup

1. **Environment Variables:**
```bash
DATABASE_URL=postgresql://user:pass@localhost:5432/yetenek_avcisi
SECRET_KEY=your-secret-key
GEMINI_API_KEY=your-gemini-key
REDIS_URL=redis://localhost:6379
```

2. **Docker Deployment:**
```bash
docker-compose up -d
```

3. **Cloud Deployment:**
- AWS ECS/EKS
- Google Cloud Run
- Azure Container Instances

## 📊 Monitoring

### Health Check
- `GET /` - API health status
- Request ID tracking
- Performance metrics

### Logging
- Structured logging
- Request/Response logging
- Error tracking

## 🔒 Security

- JWT token authentication
- Rate limiting (100 req/min)
- CORS protection
- Security headers
- Input validation
- SQL injection prevention

## 🤝 Katkı

1. Fork yap
2. Feature branch oluştur (`git checkout -b feature/amazing-feature`)
3. Commit yap (`git commit -m 'Add amazing feature'`)
4. Push yap (`git push origin feature/amazing-feature`)
5. Pull request aç

## 📝 Lisans

Bu proje MIT Lisansı ile lisanslanmıştır. [LICENSE](LICENSE) dosyasına bakın.

## 📞 İletişim

- Email: info@yetenekavcisi.com
- GitHub: [repository-url]

## 🗺 Roadmap

### v2.1 (Yakında)
- [ ] Advanced AI analiz özellikleri
- [ ] Social network integration
- [ ] Performance dashboard
- [ ] Mobile offline support

### v2.2 (Gelecek)
- [ ] Microservices mimari
- [ ] Real-time notifications
- [ ] Video streaming
- [ ] International expansion

---

**Yetenek Avcısı** - Futbolcu yeteneklerini keşfetmek için en modern platform 🏆⚽
