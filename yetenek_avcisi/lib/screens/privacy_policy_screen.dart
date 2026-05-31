import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Premium Dark Theme renkleri - Ana uygulama ile uyumlu
const Color kScaffoldDark = Color(0xFF0B0F19);
const Color kElevatedCard = Color(0xFF151C2B);
const Color _kPrivacyGreen = Color(0xFF00FF87);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldDark,
      appBar: AppBar(
        backgroundColor: kScaffoldDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Gizlilik Politikası',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            // Başlık ve İkon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kElevatedCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 48,
                    color: _kPrivacyGreen.withOpacity(0.9),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verileriniz Güvende',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Son güncelleme: 24 Mayıs 2026',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Maddeler
            _buildSection(
              icon: Icons.storage_outlined,
              title: '1. Veri Saklama ve Güvenlik',
              content: 'Tüm kullanıcı verileriniz (kişisel bilgiler, video kayıtları ve analiz sonuçları) şifrelenmiş olarak güvenli sunucularımızda saklanır. Verilerinize sadece siz ve yetkilendirdiğiniz scoutlar erişebilir.',
            ),
            _buildSection(
              icon: Icons.visibility_off_outlined,
              title: '2. Gizlilik ve Görünürlük',
              content: 'Futbolcu hesapları varsayılan olarak gizlidir. Videolarınız ve analizleriniz sizin onayınız olmadan scoutlar tarafından görülemez. Keşfet bölümünde paylaşmayı tercih ettiğiniz içerikler herkese açık olur.',
            ),
            _buildSection(
              icon: Icons.analytics_outlined,
              title: '3. AI Analiz ve Raporlama',
              content: 'Google Gemini AI teknolojisi kullanılarak oluşturulan analiz raporları otomatik olarak veritabanımıza kaydedilir. Bu raporlar platformunuzun scout değerlendirme süreçlerinde kullanılabilir.',
            ),
            _buildSection(
              icon: Icons.delete_outline,
              title: '4. Veri Silme Hakkı',
              content: 'Hesabınızı istediğiniz zaman silebilirsiniz. Hesap silme işlemi gerçekleştirildiğinde tüm video kayıtları ve analizler kalıcı olarak silinir. Bu işlem geri alınamaz.',
            ),
            _buildSection(
              icon: Icons.smart_toy_outlined,
              title: '5. Yapay Zeka Veri Paylaşımı',
              content: 'Kullanıcıların yüklediği videolar ve profil verileri, yetenek analizi yapılabilmesi amacıyla üçüncü taraf yapay zeka servisleriyle (Google Gemini AI) paylaşılmakta ve işlenmektedir. Bu veriler analiz amacı dışında kullanılmaz ve üçüncü taraflarca saklanmaz. Uygulamayı kullanmaya devam ederek bu işlemeye onay vermiş sayılırsınız.',
            ),
            _buildSection(
              icon: Icons.share_outlined,
              title: '6. Diğer Üçüncü Taraf Paylaşımı',
              content: 'Video analizi dışında verileriniz herhangi bir üçüncü taraf şirket veya kuruluşla paylaşılmaz. Sosyal medya paylaşımları tamamen sizin kontrolünüzdedir.',
            ),
            _buildSection(
              icon: Icons.verified_user_outlined,
              title: '7. KVKK ve Yasal Uyum',
              content: 'Tüm veri işleme faaliyetlerimiz 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) ve ilgili mevzuata uygun olarak yürütülmektedir. Profil ayarlarından hesabınızı silebilir veya "Verilerimi İndir" ile JSON export alabilirsiniz (API: GET /users/me/export).',
            ),
            
            const SizedBox(height: 32),
            
            // İletişim Bilgisi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kElevatedCard.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Text(
                    'Sorularınız mı var?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'info.yetenekavcisi@gmail.com',
                    style: TextStyle(
                      color: _kPrivacyGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrivacyGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _kPrivacyGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
