"""
OTP (One-Time Password) Service
Email doğrulama kodları için geçici depolama + Gmail SMTP ile gönderim
"""

import os
from dotenv import load_dotenv
load_dotenv()
import random
import string
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime, timedelta
from typing import Dict, Optional

# Geçici OTP depolama - prod'da Redis kullanılmalı
# Format: {email: {"code": "123456", "expires_at": datetime, "attempts": 0}}
_otp_storage: Dict[str, dict] = {}


def generate_otp(length: int = 6) -> str:
    """Rastgele 6 haneli OTP kodu üretir"""
    return ''.join(random.choices(string.digits, k=length))


def store_otp(email: str, expires_in_minutes: int = 10) -> str:
    """
    Email için yeni OTP kodu üretir ve saklar
    
    Args:
        email: Kullanıcı email adresi
        expires_in_minutes: Kodun geçerlilik süresi (dakika)
    
    Returns:
        Üretilen OTP kodu
    """
    code = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=expires_in_minutes)
    
    _otp_storage[email.lower()] = {
        "code": code,
        "expires_at": expires_at,
        "attempts": 0,
        "created_at": datetime.utcnow(),
    }
    
    return code


def verify_otp(email: str, code: str, max_attempts: int = 3) -> tuple[bool, Optional[str]]:
    """
    OTP kodunu doğrular
    
    Args:
        email: Kullanıcı email adresi
        code: Doğrulanacak kod
        max_attempts: Maksimum deneme sayısı
    
    Returns:
        (success, error_message) tuple'ı
    """
    email = email.lower()
    otp_data = _otp_storage.get(email)
    
    if not otp_data:
        return False, "OTP kodu bulunamadı. Lütfen yeni kod talep edin."
    
    # Süre kontrolü
    if datetime.utcnow() > otp_data["expires_at"]:
        del _otp_storage[email]
        return False, "OTP kodunun süresi doldu. Lütfen yeni kod talep edin."
    
    # Deneme sayısı kontrolü
    if otp_data["attempts"] >= max_attempts:
        del _otp_storage[email]
        return False, "Çok fazla başarısız deneme. Lütfen yeni kod talep edin."
    
    # Kod kontrolü
    if otp_data["code"] != code:
        otp_data["attempts"] += 1
        remaining = max_attempts - otp_data["attempts"]
        if remaining <= 0:
            del _otp_storage[email]
            return False, "Çok fazla başarısız deneme. Lütfen yeni kod talep edin."
        return False, f"Geçersiz kod. Kalan deneme hakkı: {remaining}"
    
    # Başarılı doğrulama - temizle
    del _otp_storage[email]
    return True, None


def clear_otp(email: str) -> None:
    """Email için OTP kaydını temizler"""
    email = email.lower()
    if email in _otp_storage:
        del _otp_storage[email]


def get_otp_info(email: str) -> Optional[dict]:
    """Email için mevcut OTP bilgisini döndürür (debug için)"""
    return _otp_storage.get(email.lower())


def cleanup_expired() -> int:
    """Süresi dolmuş OTP kayıtlarını temizler"""
    now = datetime.utcnow()
    expired = [
        email for email, data in _otp_storage.items()
        if now > data["expires_at"]
    ]
    for email in expired:
        del _otp_storage[email]
    return len(expired)


def send_password_reset_email(target_email: str, code: str) -> bool:
    """Şifre sıfırlama kodu gönderir."""
    sender_email = os.getenv("SENDER_EMAIL", "")
    sender_password = os.getenv("SENDER_PASSWORD", "")

    if not sender_email or not sender_password:
        print(f"[EMAIL RESET] {target_email}: {code}  (SENDER_EMAIL/PASSWORD .env'de eksik)")
        return True

    html_body = f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head><meta charset="UTF-8"></head>
    <body style="margin:0;padding:0;background:#0d1117;font-family:Arial,sans-serif;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td align="center" style="padding:40px 20px;">
            <table width="480" cellpadding="0" cellspacing="0"
                   style="background:#161b22;border-radius:16px;overflow:hidden;
                          border:1px solid #21262d;">
              <tr>
                <td align="center"
                    style="background:linear-gradient(135deg,#ff6b35,#ff9f1c);
                           padding:32px 40px;">
                  <div style="font-size:36px;font-weight:900;color:#000;
                               letter-spacing:-1px;">🔐 Yetenek Avcısı</div>
                  <div style="color:#00000099;font-size:14px;margin-top:6px;">
                    Şifre Sıfırlama
                  </div>
                </td>
              </tr>
              <tr>
                <td style="padding:36px 40px;">
                  <p style="color:#c9d1d9;font-size:16px;margin:0 0 24px;">
                    Şifrenizi sıfırlamak için aşağıdaki kodu kullanın:
                  </p>
                  <div style="text-align:center;margin:0 0 28px;">
                    <div style="display:inline-block;background:#0d1117;
                                border:2px solid #ff9f1c;border-radius:12px;
                                padding:18px 40px;">
                      <span style="font-size:40px;font-weight:900;
                                   letter-spacing:12px;color:#ff9f1c;">
                        {code}
                      </span>
                    </div>
                  </div>
                  <p style="color:#8b949e;font-size:14px;margin:0 0 8px;">
                    ⏱ Bu kod <strong style="color:#c9d1d9;">10 dakika</strong>
                    içinde geçerliliğini yitirir.
                  </p>
                  <p style="color:#8b949e;font-size:13px;margin:0;">
                    Bu işlemi siz yapmadıysanız bu e-postayı görmezden gelebilirsiniz.
                  </p>
                </td>
              </tr>
              <tr>
                <td style="padding:16px 40px 24px;border-top:1px solid #21262d;">
                  <p style="color:#484f58;font-size:12px;text-align:center;margin:0;">
                    © 2025 Yetenek Avcısı · Tüm hakları saklıdır.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Yetenek Avcısı – Şifre Sıfırlama Kodunuz"
    msg["From"] = f"Yetenek Avcısı <{sender_email}>"
    msg["To"] = target_email
    msg.attach(MIMEText(f"Şifre sıfırlama kodunuz: {code}  (10 dakika geçerli)", "plain", "utf-8"))
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, target_email, msg.as_string())
        print(f"[EMAIL RESET] Gönderildi → {target_email}")
        return True
    except Exception as exc:
        print(f"[EMAIL RESET] Gönderim hatası ({target_email}): {exc}")
        return False


def send_email_otp(target_email: str, code: str) -> bool:
    """
    Gmail SMTP üzerinden HTML şablonlu doğrulama kodu gönderir.

    Args:
        target_email: Alıcı email adresi
        code: Gönderilecek 6 haneli OTP kodu

    Returns:
        Gönderim başarılı mı?
    """
    sender_email = os.getenv("SENDER_EMAIL", "")
    sender_password = os.getenv("SENDER_PASSWORD", "")

    if not sender_email or not sender_password:
        print(f"[EMAIL OTP - DEV] {target_email}: {code}  (SENDER_EMAIL/PASSWORD .env'de eksik)")
        return True

    html_body = f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head><meta charset="UTF-8"></head>
    <body style="margin:0;padding:0;background:#0d1117;font-family:Arial,sans-serif;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td align="center" style="padding:40px 20px;">
            <table width="480" cellpadding="0" cellspacing="0"
                   style="background:#161b22;border-radius:16px;overflow:hidden;
                          border:1px solid #21262d;">
              <!-- Header -->
              <tr>
                <td align="center"
                    style="background:linear-gradient(135deg,#00c853,#00e676);
                           padding:32px 40px;">
                  <div style="font-size:36px;font-weight:900;color:#000;
                               letter-spacing:-1px;">⚽ Yetenek Avcısı</div>
                  <div style="color:#00000099;font-size:14px;margin-top:6px;">
                    E-posta Doğrulama
                  </div>
                </td>
              </tr>
              <!-- Body -->
              <tr>
                <td style="padding:36px 40px;">
                  <p style="color:#c9d1d9;font-size:16px;margin:0 0 24px;">
                    Merhaba, hesabınızı doğrulamak için aşağıdaki kodu kullanın:
                  </p>
                  <!-- OTP Box -->
                  <div style="text-align:center;margin:0 0 28px;">
                    <div style="display:inline-block;background:#0d1117;
                                border:2px solid #00e676;border-radius:12px;
                                padding:18px 40px;">
                      <span style="font-size:40px;font-weight:900;
                                   letter-spacing:12px;color:#00e676;">
                        {code}
                      </span>
                    </div>
                  </div>
                  <p style="color:#8b949e;font-size:14px;margin:0 0 8px;">
                    ⏱ Bu kod <strong style="color:#c9d1d9;">10 dakika</strong>
                    içinde geçerliliğini yitirir.
                  </p>
                  <p style="color:#8b949e;font-size:13px;margin:0;">
                    Bu kodu kimseyle paylaşmayın. Siz istemediyseniz bu e-postayı
                    görmezden gelebilirsiniz.
                  </p>
                </td>
              </tr>
              <!-- Footer -->
              <tr>
                <td style="padding:16px 40px 24px;border-top:1px solid #21262d;">
                  <p style="color:#484f58;font-size:12px;text-align:center;margin:0;">
                    © 2025 Yetenek Avcısı · Tüm hakları saklıdır.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Yetenek Avcısı – E-posta Doğrulama Kodunuz"
    msg["From"] = f"Yetenek Avcısı <{sender_email}>"
    msg["To"] = target_email
    msg.attach(MIMEText(f"Doğrulama kodunuz: {code}  (10 dakika geçerli)", "plain", "utf-8"))
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, target_email, msg.as_string())
        print(f"[EMAIL OTP] Gönderildi → {target_email}")
        return True
    except Exception as exc:
        print(f"[EMAIL OTP] Gönderim hatası ({target_email}): {exc}")
        return False
