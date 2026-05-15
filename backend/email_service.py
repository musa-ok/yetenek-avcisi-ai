"""
Email Service for Yetenek Avcısı
Handles approval notifications and system emails
"""
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
# import json  # Resend HTTP - şu an kullanılmıyor
# import urllib.request  # Resend HTTP - şu an kullanılmıyor
from typing import Optional
import logging

# Brevo SMTP (Render'da çalışır - güvenilir relay)
BREVO_SMTP_LOGIN = os.getenv("BREVO_SMTP_LOGIN", "ab712f001@smtp-brevo.com")
BREVO_SMTP_KEY = os.getenv("BREVO_SMTP_KEY", "")
BREVO_SMTP_HOST = "smtp-relay.brevo.com"
BREVO_SMTP_PORT = 587
SENDER_EMAIL = os.getenv("SENDER_EMAIL", "info.yetenekavcisi@gmail.com")

# Resend API - şu an kullanılmıyor (domain doğrulaması gerekiyor)
# RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
# RESEND_FROM = os.getenv("RESEND_FROM", "Yetenek Avcısı <onboarding@resend.dev>")

# Gmail SMTP - Render'da outbound port bloklı
# SENDER_PASSWORD = os.getenv("SENDER_PASSWORD", "")
# SMTP_HOST = "smtp.gmail.com"
# SMTP_PORT = 587

logger = logging.getLogger(__name__)


def _send_via_brevo(to_email: str, subject: str, html_body: str) -> bool:
    """Brevo SMTP relay ile email gönder"""
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"Yetenek Avcısı <{BREVO_SMTP_LOGIN}>"
        msg["To"] = to_email
        msg.attach(MIMEText(html_body, "html", "utf-8"))

        with smtplib.SMTP(BREVO_SMTP_HOST, BREVO_SMTP_PORT) as server:
            server.starttls()
            server.login(BREVO_SMTP_LOGIN, BREVO_SMTP_KEY)
            server.sendmail(BREVO_SMTP_LOGIN, to_email, msg.as_string())

        logger.info(f"✅ Brevo email sent to {to_email}")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send Brevo email: {e}")
        return False


def send_approval_email(user_email: str, user_name: str) -> bool:
    """
    Send professional approval email to newly approved scout
    
    Args:
        user_email: Scout's email address
        user_name: Scout's full name
        
    Returns:
        bool: True if email sent successfully, False otherwise
    """
    try:
        subject = "🎉 Tebrikler! Scout Onayınız Tamamlandı - Yetenek Avcısı"

        # Professional HTML email template
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {{ font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                          padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .header h1 {{ color: white; margin: 0; font-size: 24px; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .highlight {{ background: #fff; padding: 20px; border-left: 4px solid #667eea; 
                             margin: 20px 0; border-radius: 5px; }}
                .cta-button {{ display: inline-block; background: #667eea; color: white; 
                             padding: 15px 30px; text-decoration: none; border-radius: 25px; 
                             margin: 20px 0; font-weight: bold; }}
                .footer {{ text-align: center; margin-top: 30px; font-size: 12px; color: #666; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎯 Yetenek Avcısı</h1>
                </div>
                <div class="content">
                    <h2>Sayın {user_name},</h2>
                    
                    <p>Tebrikler! Scout başvurunuz onaylanmıştır.</p>
                    
                    <div class="highlight">
                        <strong>✅ Onay Durumu:</strong> AKTİF<br>
                        <strong>👤 Rol:</strong> Scout<br>
                        <strong>📅 Onay Tarihi:</strong> Bugün
                    </div>
                    
                    <p>Artık Yetenek Avcısı platformunda:</p>
                    <ul>
                        <li>Futbolcu profillerini görüntüleyebilir</li>
                        <li>Video analizleri inceleyebilir</li>
                        <li>Oyuncuları derecelendirebilir</li>
                        <li>Kulübünüz için yeni yetenekler keşfedebilirsiniz</li>
                    </ul>
                    
                    <center>
                        <a href="https://yetenekavcisi.com/login" class="cta-button">
                            Uygulamaya Git →
                        </a>
                    </center>
                    
                    <p>Herhangi bir sorunuz olursa, bizimle iletişime geçmekten çekinmeyin.</p>
                    
                    <p>Saygılarımızla,<br>
                    <strong>Yetenek Avcısı Ekibi</strong></p>
                </div>
                <div class="footer">
                    <p>Bu e-posta otomatik olarak gönderilmiştir. Lütfen yanıtlamayınız.</p>
                    <p>© 2024 Yetenek Avcısı. Tüm hakları saklıdır.</p>
                </div>
            </div>
        </body>
        </html>
        """

        # Plain text fallback
        text_body = f"""
        Tebrikler {user_name}!
        
        Scout başvurunuz onaylanmıştır. Artık Yetenek Avcısı platformunda aktif olarak kullanabilirsiniz.
        
        Onay Durumu: AKTİF
        Rol: Scout
        
        Uygulamaya giriş yapmak için: https://yetenekavcisi.com
        
        Saygılarımızla,
        Yetenek Avcısı Ekibi
        """

        return _send_via_brevo(user_email, subject, html_body)

        # --- SMTP (Render'da çalışmıyor - ilerisi için) ---
        # with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        #     server.starttls()
        #     server.login(SENDER_EMAIL, SENDER_PASSWORD)
        #     server.sendmail(SENDER_EMAIL, user_email, msg.as_string())

    except Exception as e:
        logger.error(f"❌ Failed to send approval email to {user_email}: {str(e)}")
        return False


def send_pending_notification_to_admin(user_name: str, user_email: str) -> bool:
    """
    Notify admin when a new scout uploads documents and needs approval
    
    Args:
        user_name: Pending scout's name
        user_email: Pending scout's email
        
    Returns:
        bool: True if notification sent successfully
    """
    try:
        admin_email = SENDER_EMAIL  # Send to same email for now
        subject = f"🔔 Yeni Scout Onay Bekliyor - {user_name}"

        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .alert {{ background: #fff3cd; border: 1px solid #ffeaa7; padding: 20px; 
                        border-radius: 5px; margin: 20px 0; }}
                .info {{ background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h2>🔔 Yeni Scout Onay Bekliyor</h2>
                
                <div class="alert">
                    <strong>Bir kullanıcı belge yükledi ve onay bekliyor!</strong>
                </div>
                
                <div class="info">
                    <p><strong>Ad Soyad:</strong> {user_name}</p>
                    <p><strong>Email:</strong> {user_email}</p>
                    <p><strong>Durum:</strong> Belge Yüklendi - Onay Bekliyor</p>
                </div>
                
                <p>Admin panelinden onay işlemini gerçekleştirebilirsiniz.</p>
                
                <p>Sistem Bildirimi</p>
            </div>
        </body>
        </html>
        """

        return _send_via_brevo(admin_email, subject, html_body)

        # --- SMTP (Render'da çalışmıyor - ilerisi için) ---
        # with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        #     server.starttls()
        #     server.login(SENDER_EMAIL, SENDER_PASSWORD)
        #     server.sendmail(SENDER_EMAIL, admin_email, msg.as_string())

    except Exception as e:
        logger.error(f"❌ Failed to send admin notification: {str(e)}")
        return False


def send_otp_email(email: str, otp_code: str) -> bool:
    """
    Kullanıcı kayıt olduğunda OTP kodu gönderir
    """
    try:
        subject = "Yetenek Avcısı - E-posta Doğrulama Kodunuz"

        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {{
                    font-family: 'Segoe UI', Arial, sans-serif;
                    background-color: #0B0F19;
                    color: #ffffff;
                    line-height: 1.6;
                }}
                .container {{
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 40px 20px;
                    background-color: #151C2B;
                    border-radius: 12px;
                }}
                .header {{
                    text-align: center;
                    margin-bottom: 30px;
                }}
                .logo {{
                    font-size: 28px;
                    font-weight: bold;
                    color: #00FF87;
                }}
                .code-box {{
                    background-color: #0B0F19;
                    border: 2px solid #00FF87;
                    border-radius: 12px;
                    padding: 30px;
                    text-align: center;
                    margin: 30px 0;
                }}
                .otp-code {{
                    font-size: 42px;
                    font-weight: bold;
                    color: #00FF87;
                    letter-spacing: 8px;
                }}
                .info {{
                    background-color: #1a2332;
                    padding: 15px;
                    border-radius: 8px;
                    margin-top: 20px;
                    font-size: 14px;
                    color: #a0a0a0;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="logo">⚽ Yetenek Avcısı</div>
                </div>
                
                <p>Merhaba,</p>
                
                <p>Hesabınızı doğrulamak için aşağıdaki 6 haneli kodu kullanın:</p>
                
                <div class="code-box">
                    <div class="otp-code">{otp_code}</div>
                </div>
                
                <div class="info">
                    <p><strong>Önemli:</strong> Bu kod 10 dakika içinde geçerliliğini yitirecektir.</p>
                    <p>Kodu sizden başka kimseyle paylaşmayın.</p>
                </div>
                
                <p style="margin-top: 30px;">İyi günler dileriz,<br><strong>Yetenek Avcısı Ekibi</strong></p>
            </div>
        </body>
        </html>
        """

        return _send_via_brevo(email, subject, html_body)

        # --- SMTP (Render'da çalışmıyor - ilerisi için) ---
        # with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        #     server.starttls()
        #     server.login(SENDER_EMAIL, SENDER_PASSWORD)
        #     server.sendmail(SENDER_EMAIL, email, msg.as_string())

    except Exception as e:
        logger.error(f"❌ Failed to send OTP email: {str(e)}")
        return False
