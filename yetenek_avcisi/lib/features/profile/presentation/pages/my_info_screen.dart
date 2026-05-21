import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../app_services.dart';

/// ==========================================
/// BİLGİLERİM EKRANI
/// Kullanıcı bilgilerini görüntüleme ve düzenleme
/// Apple Minimalist + Glassmorphism + Dark Mode
/// ==========================================

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _emailController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = currentUserNotifier.value;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  void _checkChanges() {
    final user = currentUserNotifier.value;
    if (user == null) return;
    
    final hasChanges = _emailController.text != (user.email ?? '') ||
                       _phoneController.text != (user.phoneNumber ?? '');
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    
    try {
      final token = currentAccessTokenNotifier.value;
      if (token == null) {
        throw Exception('Oturum süresi dolmuş');
      }
      
      // Backend API'sine güncelleme isteği gönder
      final updatedUser = await BackendApi.updateUserProfile(
        fullName: _emailController.text != currentUserNotifier.value?.email 
            ? currentUserNotifier.value?.fullName 
            : null,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
      );
      
      // Global state'i güncelle ve kalıcı olarak kaydet
      currentUserNotifier.value = updatedUser;
      await SessionStore.save(AuthSession(accessToken: token ?? '', user: updatedUser));
      
      // Başarılı bildirim
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Bilgileriniz güncellendi'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      
      setState(() => _hasChanges = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme başarısız: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserNotifier.value;
    
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Bilgilerim',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil Kartı
              _buildProfileCard(user),
              
              SizedBox(height: 32),
              
              // Bilgi Alanları
              Text(
                'İletişim Bilgileri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(duration: 400.ms),
              
              SizedBox(height: 16),
              
              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'E-posta',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              
              SizedBox(height: 20),
              
              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: 'Telefon Numarası',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              
              SizedBox(height: 32),
              
              // Rol Bilgisi (Read-only)
              _buildRoleCard(user?.role ?? 'Futbolcu'),
              
              SizedBox(height: 40),
              
              // Kaydet Butonu
              if (_hasChanges)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(),
              
              SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthenticatedUser? user) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                (user?.fullName ?? '?').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Misafir',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role) {
    final isScout = role == 'Scout';
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isScout 
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isScout 
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                  isScout 
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isScout ? Icons.visibility : Icons.sports_soccer,
              color: isScout ? AppColors.primary : Colors.blue,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hesap Türü',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isScout ? 'Scout - Oyuncu Değerlendir' : 'Futbolcu - Profil Oluştur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isScout 
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isScout ? AppColors.primary : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }
}
