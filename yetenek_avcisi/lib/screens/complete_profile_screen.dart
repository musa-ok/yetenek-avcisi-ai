import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yetenek_avcisi/core/utils/social_auth_helper.dart';
import '../app_services.dart';
import '../main.dart';

// Premium Dark Theme renkleri - Ana uygulama ile uyumlu
const Color kScaffoldDark = Color(0xFF0B0F19);
const Color kElevatedCard = Color(0xFF151C2B);
const Color kPitchGreen = Color(0xFF00FF87);
const Color kGlassWhite = Color(0x20FFFFFF);
const Color kGlassBorder = Color(0x30FFFFFF);

/// Sosyal medya ile giriş yapan kullanıcıların
/// eksik bilgilerini tamamlaması için ekran
class CompleteProfileScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String provider; // 'apple', 'google'
  final String? providerId;

  const CompleteProfileScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.provider,
    this.providerId,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _phoneController = TextEditingController();
  late final TextEditingController _nameController;
  late final bool _needsName;
  String _selectedRole = 'Futbolcu';
  bool _submitting = false;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _needsName = SocialAuthHelper.needsManualNameEntry(widget.fullName, widget.email);
    final initialName = SocialAuthHelper.sanitizeDisplayName(
      fullName: widget.fullName,
      email: widget.email,
      fallback: '',
    );
    _nameController = TextEditingController(text: _needsName ? '' : initialName);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _providerLabel =>
      widget.provider.toLowerCase() == 'apple' ? 'Apple' : 'Google';

  String get _introText {
    if (_needsName) {
      return '$_providerLabel ile giriş yaptınız. Kaydı tamamlamak için adınızı ve birkaç bilgiyi girmeniz gerekiyor.';
    }
    final name = SocialAuthHelper.sanitizeDisplayName(
      fullName: widget.fullName,
      email: widget.email,
    );
    return '$name olarak $_providerLabel ile giriş yaptınız. Kaydı tamamlamak için son birkaç bilgiye ihtiyacımız var.';
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: kPitchGreen,
            onPrimary: Colors.black,
            surface: kElevatedCard,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submitProfile() async {
    if (_submitting) return;

    final resolvedName = _needsName
        ? _nameController.text.trim()
        : SocialAuthHelper.sanitizeDisplayName(
            fullName: widget.fullName,
            email: widget.email,
            fallback: _nameController.text.trim(),
          );

    if (resolvedName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir ad soyad girin (en az 2 karakter).'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    final phoneRegex = RegExp(r'^[0-9]+$');

    if (phone.isNotEmpty && (!phoneRegex.hasMatch(phone) || phone.length < 10)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir telefon numarası giriniz veya boş bırakınız.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen doğum tarihinizi seçin.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final roleToSend = _selectedRole == 'Scout' ? 'pending_scout' : _selectedRole;

      final session = await BackendApi.socialRegister(
        email: widget.email,
        fullName: resolvedName,
        phoneNumber: phone,
        role: roleToSend,
        provider: widget.provider,
        providerId: widget.providerId,
        birthDate: _birthDate?.toIso8601String(),
      );

      if (!mounted) return;

      await SessionStore.save(session);
      currentAccessTokenNotifier.value = session.accessToken;
      currentUserNotifier.value = session.user;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SessionRouter()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = (width * 0.07).clamp(20.0, 30.0);

    return Scaffold(
      backgroundColor: kScaffoldDark,
      appBar: AppBar(
        backgroundColor: kScaffoldDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
            children: [
              _buildSocialIcon(),
              const SizedBox(height: 24),
              const Text(
                'Profilinizi Tamamlayın',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _introText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kElevatedCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.5), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        SocialAuthHelper.formatEmailForDisplay(widget.email),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.check_circle, color: kPitchGreen, size: 20),
                  ],
                ),
              ),
              if (_needsName) ...[
                const SizedBox(height: 20),
                _buildNameField(),
              ],
              const SizedBox(height: 20),
              _buildRoleSelector(),
              const SizedBox(height: 20),
              _buildBirthDateField(),
              const SizedBox(height: 20),
              _buildPhoneField(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Ad Soyad *',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSocialIcon() {
    IconData icon;
    Color color;

    switch (widget.provider.toLowerCase()) {
      case 'apple':
        icon = FontAwesomeIcons.apple;
        color = Colors.white;
        break;
      case 'google':
        icon = FontAwesomeIcons.google;
        color = const Color(0xFFEA4335);
        break;
      default:
        icon = Icons.link;
        color = kPitchGreen;
    }

    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: kElevatedCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _selectedRole,
        backgroundColor: Colors.transparent,
        thumbColor: kPitchGreen,
        onValueChanged: (value) {
          if (value == null) return;
          setState(() => _selectedRole = value);
        },
        children: {
          'Scout': Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Scout',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _selectedRole == 'Scout' ? Colors.black : Colors.white,
              ),
            ),
          ),
          'Futbolcu': Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Futbolcu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _selectedRole == 'Futbolcu' ? Colors.black : Colors.white,
              ),
            ),
          ),
        },
      ),
    );
  }

  Widget _buildBirthDateField() {
    return GestureDetector(
      onTap: _selectBirthDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: kElevatedCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _birthDate != null ? kPitchGreen.withOpacity(0.5) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined,
                color: _birthDate != null ? kPitchGreen : Colors.white.withOpacity(0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _birthDate != null
                    ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}  (${_calculateAge(_birthDate!)} yaş)'
                    : 'Doğum Tarihi *',
                style: TextStyle(
                  color: _birthDate != null ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                color: Colors.white.withOpacity(0.4), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Telefon Numarası',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(Icons.phone_android_rounded, color: Colors.white.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submitProfile,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: kPitchGreen,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledForegroundColor: Colors.black54,
          disabledBackgroundColor: kPitchGreen.withOpacity(0.5),
        ),
        child: _submitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.black87,
                  strokeWidth: 2.2,
                ),
              )
            : const Text(
                'Devam Et',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
