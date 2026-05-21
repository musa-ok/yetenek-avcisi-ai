import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_services.dart';
 
const Color _kScaffoldDark = Color(0xFF0B0F19);
const Color _kElevatedCard = Color(0xFF151C2B);
const Color _kPitchGreen = Color(0xFF00FF87);
 
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
 
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
 
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _error;
 
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
 
  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Lütfen e-posta adresinizi girin.');
      return;
    }
 
    setState(() {
      _sending = true;
      _error = null;
    });
 
    try {
      await BackendApi.forgotPassword(email: email);
      if (!mounted) return;
 
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: email),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kScaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.lock_reset_rounded, color: _kPitchGreen, size: 48),
              const SizedBox(height: 20),
              const Text(
                'Şifremi Unuttum',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kayıtlı e-posta adresinizi girin, size şifre sıfırlama kodu gönderelim.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: _kElevatedCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'E-posta adresiniz',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendResetCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPitchGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Kod Gönder',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
 
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});
 
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}
 
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _resetting = false;
  String? _error;
  String? _successMessage;
 
  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
 
  String get _code => _codeControllers.map((c) => c.text).join();
 
  Future<void> _resetPassword() async {
    final code = _code;
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;
 
    if (code.length != 6) {
      setState(() => _error = 'Lütfen 6 haneli kodu girin.');
      return;
    }
    if (newPwd.isEmpty) {
      setState(() => _error = 'Yeni şifrenizi girin.');
      return;
    }
    if (newPwd.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }
    if (newPwd != confirmPwd) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }
 
    setState(() {
      _resetting = true;
      _error = null;
    });
 
    try {
      await BackendApi.resetPassword(
        email: widget.email,
        code: code,
        newPassword: newPwd,
      );
      if (!mounted) return;
 
      setState(() => _successMessage = 'Şifreniz başarıyla güncellendi!');
 
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kScaffoldDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.vpn_key_rounded, color: _kPitchGreen, size: 48),
            const SizedBox(height: 20),
            const Text(
              'Şifre Sıfırla',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.email} adresine gönderilen 6 haneli kodu girin ve yeni şifrenizi belirleyin.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
 
            // 6 haneli kod girişi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => _buildCodeBox(i)),
            ),
            const SizedBox(height: 24),
 
            // Yeni şifre
            Container(
              decoration: BoxDecoration(
                color: _kElevatedCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Yeni Şifre',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),
 
            // Şifre tekrar
            Container(
              decoration: BoxDecoration(
                color: _kElevatedCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Şifre Tekrar',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.verified_user_outlined, color: Colors.white54),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white70,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
 
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _successMessage!,
                style: const TextStyle(color: _kPitchGreen, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
 
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _resetting ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPitchGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _resetting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Şifreyi Güncelle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }
 
  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: _kElevatedCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _codeControllers[index].text.isNotEmpty
                ? _kPitchGreen
                : Colors.white12,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _codeControllers[index],
          focusNode: _codeFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {});
            if (value.isNotEmpty && index < 5) {
              _codeFocusNodes[index + 1].requestFocus();
            }
            if (value.isEmpty && index > 0) {
              _codeFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
