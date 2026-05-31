import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../app_services.dart';
import '../app_theme.dart';
import '../main.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

enum _UploadStatus { idle, uploading, success, error }

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  File? _selectedFile;
  String? _selectedFileName;
  _UploadStatus _status = _UploadStatus.idle;
  String? _errorMessage;

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _selectedFileName = picked.name;
        _status = _UploadStatus.idle;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _selectedFileName = picked.name;
        _status = _UploadStatus.idle;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _selectedFileName = picked.name;
        _status = _UploadStatus.idle;
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitDocument() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce bir belge seçin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _status = _UploadStatus.uploading;
      _errorMessage = null;
    });

    try {
      final token = currentAccessTokenNotifier.value;
      if (token == null || token.isEmpty) throw Exception('Oturum bulunamadı.');

      final uri = Uri.parse('$kApiBaseUrl/upload-document');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

      final response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() => _status = _UploadStatus.success);
      } else {
        final body = await response.stream.bytesToString();
        setState(() {
          _status = _UploadStatus.error;
          _errorMessage = 'Yükleme başarısız. Lütfen tekrar deneyin.';
        });
        debugPrint('[PendingApproval] Upload error: $body');
      }
    } catch (e) {
      setState(() {
        _status = _UploadStatus.error;
        _errorMessage = 'Bağlantı hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // İkon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.4), width: 2),
                ),
                child: Icon(Icons.verified_user_outlined, color: AppColors.accentGreen, size: 44),
              ),
              const SizedBox(height: 24),

              // Başlık
              Text(
                'Scout Onay Bekliyor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Açıklama
              Text(
                'Kayıt ve e-posta doğrulamanız tamamlandı. Scout hesabınızın tam olarak açılması için yönetici onayı gerekiyor; lütfen Scout olduğunuzu kanıtlayan belgenizi yükleyin.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.55),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'TFF Lisansı, Kulüp Kartı veya PFSA Sertifikası kabul edilmektedir.',
                style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              if (_status == _UploadStatus.success) ...[
                _buildSuccessBanner(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ] else ...[
                // Dosya seçme kartı
                _buildFilePickerCard(),
                const SizedBox(height: 24),

                // Hata mesajı
                if (_status == _UploadStatus.error && _errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Gönder butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _status == _UploadStatus.uploading ? null : _submitDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _status == _UploadStatus.uploading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black87,
                            ),
                          )
                        : const Text(
                            'Belgeyi Gönder',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedFile != null
              ? AppColors.accentGreen.withOpacity(0.5)
              : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          if (_selectedFile != null) ...[
            Icon(Icons.insert_drive_file_rounded, color: AppColors.accentGreen, size: 40),
            const SizedBox(height: 10),
            Text(
              _selectedFileName ?? 'Seçilen dosya',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ] else ...[
            Icon(Icons.upload_file_outlined, color: Colors.white38, size: 44),
            const SizedBox(height: 10),
            Text(
              'Belge seçmek için aşağıdaki seçenekleri kullanın',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildPickButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Galeri',
                  onTap: _pickFromGallery,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPickButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Kamera',
                  onTap: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPickButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  onTap: _pickDocument,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await SessionStore.clear();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SessionRouter()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Çıkış Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 56),
          const SizedBox(height: 16),
          Text(
            'Belgeniz Gönderildi!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Belgeniz inceleniyor. Onaylandığında hesabınız aktif edilecek ve bilgilendirileceksiniz.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Ortalama onay süresi: 24–48 saat',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
