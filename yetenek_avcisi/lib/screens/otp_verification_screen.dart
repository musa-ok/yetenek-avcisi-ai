import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_services.dart';
import '../main.dart';

// Premium Dark Theme renkleri - Ana uygulama ile uyumlu
const Color kScaffoldDark = Color(0xFF0B0F19);
const Color kElevatedCard = Color(0xFF151C2B);
const Color kPitchGreen = Color(0xFF00FF87);
const Color kErrorRed = Color(0xFFFF5252);

/// OTP (One Time Password) Doğrulama Ekranı
/// E-posta ile gönderilen 6 haneli kodu doğrular
/// GÜVENLİK: Geri çıkma engellidir - PopScope kullanılır
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? password;
  final bool isSocialLogin;
  final VoidCallback? onVerificationComplete;
  /// false → Kayıt sırasında OTP zaten gönderildi, tekrar gönderme.
  /// true  → Login-403 gibi durumlarda ekran açılınca hemen yeni OTP gönder.
  final bool autoResendOnLoad;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.password,
    this.isSocialLogin = false,
    this.onVerificationComplete,
    this.autoResendOnLoad = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  
  bool _verifying = false;
  bool _resending = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Sadece gerekliyse yeni OTP gönder (kayıt akışında zaten gönderildi)
    if (widget.autoResendOnLoad) {
      _sendOtp();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() => _resending = true);
    try {
      // DB tabanlı endpoint - sunucu yeniden başlasa bile kod kaybolmaz
      await BackendApi.resendOtp(email: widget.email);
      debugPrint('[OTP] Yeni kod gönderildi: ${widget.email}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yeni doğrulama kodu gönderildi'),
            backgroundColor: kPitchGreen,
          ),
        );
      }
    } on ApiException catch (e) {
      debugPrint('[OTP] Gönderim hatası: ${e.message}');
      if (mounted) {
        final msg = e.message.toLowerCase();
        if (msg.contains('zaten doğrulanmış') || msg.contains('already verified')) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hesabınız zaten doğrulanmış. Giriş yapabilirsiniz.'),
              backgroundColor: kPitchGreen,
            ),
          );
        } else {
          setState(() => _errorMessage = e.message);
        }
      }
    } catch (e) {
      debugPrint('[OTP] Gönderim hatası: $e');
      if (mounted) setState(() => _errorMessage = 'Kod gönderilirken hata oluştu');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  bool _verified = false;

  Future<void> _verifyOtp() async {
    if (_verified || _verifying) return;

    final code = _controllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      setState(() => _errorMessage = 'Lütfen 6 haneli kodu girin');
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    try {
      // Verify OTP and get session
      final session = await BackendApi.verifyOtp(
        email: widget.email,
        code: code,
      );

      _verified = true;
      
      // Save session so user is logged in
      await SessionStore.save(session);
      currentUserNotifier.value = session.user;
      currentAccessTokenNotifier.value = session.accessToken;
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama başarılı! Yönlendiriliyorsunuz...'),
          backgroundColor: kPitchGreen,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      // Stack'i tamamen temizle → SessionRouter rebuild → user set → MainScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SessionRouter()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase();
        if (msg.contains('zaten doğrulanmış') || msg.contains('already verified')) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hesabınız zaten doğrulanmış. Giriş yapabilirsiniz.'),
              backgroundColor: kPitchGreen,
            ),
          );
        } else {
          setState(() => _errorMessage = e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Doğrulama başarısız');
      }
    } finally {
      if (mounted && !_verified) setState(() => _verifying = false);
    }
  }

  void _onCodeChanged(int index, String value) {
    setState(() => _errorMessage = null);
    
    // Değer girildiyse sonraki kutuya git
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Backspace ile silme - değer boşsa ve önceki kutudaysa geri git
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Tüm kutular doldurulduysa otomatik doğrula
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = (width * 0.07).clamp(20.0, 30.0);

    // GÜVENLİK: Geri çıkma engelleme - PopScope
    return PopScope(
      canPop: false, // Sistem geri tuşunu engelle
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Geri çıkmak istediğinde uyarı göster
        _showExitConfirmDialog(context);
      },
      child: Scaffold(
        backgroundColor: kScaffoldDark,
        appBar: AppBar(
          backgroundColor: kScaffoldDark,
          elevation: 0,
          // GÜVENLİK: AppBar back butonu da kontrollü
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => _showExitConfirmDialog(context),
          ),
        ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // İkon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kElevatedCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kPitchGreen.withOpacity(0.3), width: 2),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: kPitchGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              
              // Başlık
              const Text(
                'Doğrulama Kodu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Açıklama
              Text(
                '${widget.email} adresine 6 haneli doğrulama kodu gönderdik. E-postanızı kontrol edip kodu girin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // 6 Haneli Kod Girişi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return _buildCodeBox(index);
                }),
              ),
              
              // Hata mesajı
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: kErrorRed,
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Doğrula Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verifyOtp,
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
                  child: _verifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Text(
                          'Doğrula',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              
              const Spacer(),
              
              // Kodu tekrar gönder
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kod gelmedi mi? ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      '$_resendCountdown sn',
                      style: TextStyle(
                        color: kPitchGreen.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _resending ? null : () {
                        _startCountdown();
                        _sendOtp();
                      },
                      child: _resending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(kPitchGreen),
                              ),
                            )
                          : const Text(
                              'Tekrar Gönder',
                              style: TextStyle(
                                color: kPitchGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),    // PopScope kapanışı
    ));    // return kapanışı
  }

  // GÜVENLİK: Geri çıkma onay dialogu - Siyah ekran olmaması için pushAndRemoveUntil
  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kElevatedCard,
        title: const Text(
          'Kayıt İptal Edilecek',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Doğrulama kodunu girmeden çıkarsanız kayıt işlemi iptal olur ve giriş yapamazsınız.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Devam Et', style: TextStyle(color: kPitchGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Dialog kapat
              // 🛡️ GÜVENLİ NAVİGASYON: Stack'i temizle, Login'e git
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false, // Tüm geçmişi temizle
              );
            },
            child: const Text('Çık ve İptal Et', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    return Container(
      width: 48,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: kElevatedCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorMessage != null
              ? kErrorRed.withOpacity(0.5)
              : _focusNodes[index].hasFocus
                  ? kPitchGreen.withOpacity(0.5)
                  : Colors.white12,
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onCodeChanged(index, value),
      ),
    );
  }
}

