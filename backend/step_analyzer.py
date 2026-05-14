import os
import json
import time
from typing import Dict, Any, List
from fastapi import HTTPException
from vision import analyze_player_video_advanced

class StepAnalyzer:
    """Adım adım video analiz servisi"""
    
    def __init__(self):
        self.position_steps = {
            "Forvet": [
                {
                    "name": "Hız ve İvme",
                    "focus": "pace",
                    "description": "Oyuncunun hızlı başlangıçları ve sürati",
                    "duration": 15
                },
                {
                    "name": "Bitiricilik ve Şut",
                    "focus": "finishing", 
                    "description": "Kaleye şut çekme ve bitiricilik",
                    "duration": 20
                },
                {
                    "name": "Dar Alanda Dripling",
                    "focus": "dribbling_tight_spaces",
                    "description": "Dar alanda top kontrolü ve dribling",
                    "duration": 15
                },
                {
                    "name": "Hava Topları ve Kafa",
                    "focus": "heading",
                    "description": "Hava toplarında kafa vuruşları",
                    "duration": 10
                },
                {
                    "name": "Pozisyon Alma",
                    "focus": "positioning",
                    "description": "Ofsaytı kaçırma ve doğru pozisyonlar",
                    "duration": 15
                },
                {
                    "name": "Baskı Altında Soğukkanlılık",
                    "focus": "composure",
                    "description": "Baskı altında karar verme",
                    "duration": 15
                }
            ],
            "Kaleci": [
                {
                    "name": "Refleksler",
                    "focus": "gk_reflexes",
                    "description": "Şutlara karşı refleksler",
                    "duration": 15
                },
                {
                    "name": "Yanlara atış",
                    "focus": "gk_diving",
                    "description": "Yanlara doğru yatarak kurtarış",
                    "duration": 15
                },
                {
                    "name": "Topu Tutma",
                    "focus": "gk_handling",
                    "description": "Topu yakalama ve kontrol etme",
                    "duration": 15
                },
                {
                    "name": "Pozisyon",
                    "focus": "gk_positioning",
                    "description": "Açı kapatma ve başlangıç pozisyonu",
                    "duration": 15
                },
                {
                    "name": "Top Dağıtımı",
                    "focus": "gk_distribution",
                    "description": "Atış ve fırlatma doğruluğu",
                    "duration": 10
                },
                {
                    "name": "Alan Kontrolü",
                    "focus": "gk_command_area",
                    "description": "Kale alanı kontrolü ve ortalar",
                    "duration": 15
                },
                {
                    "name": "1'e 1 Durumlar",
                    "focus": "gk_1v1",
                    "description": "Hücumcuyla karşılaşma",
                    "duration": 15
                }
            ]
        }
    
    def get_analysis_steps(self, position: str) -> List[Dict[str, Any]]:
        """Pozisyona göre analiz adımlarını döndür"""
        return self.position_steps.get(position, [])
    
    def analyze_step_by_step(self, video_path: str, position: str, progress_callback=None) -> Dict[str, Any]:
        """
        Videoyu adım adım analiz eder
        Her adımda ilerlemeyi progress_callback ile bildirir
        """
        try:
            steps = self.get_analysis_steps(position)
            if not steps:
                raise ValueError(f"Bilinmeyen pozisyon: {position}")
            
            print(f"🎬 {position} pozisyonu için adım adım analiz başlatılıyor...")
            print(f"📋 Toplam {len(steps)} analiz adımı bulunuyor")
            
            results = {}
            overall_report = []
            
            for i, step in enumerate(steps):
                print(f"\n📊 Adım {i+1}/{len(steps)}: {step['name']}")
                print(f"🎯 Odak: {step['description']}")
                
                if progress_callback:
                    progress_callback(i, len(steps), step['name'])
                
                # Bu adım için özel analiz yap
                step_result = self._analyze_specific_step(
                    video_path, 
                    position, 
                    step['focus'],
                    step['description']
                )
                
                results[step['focus']] = step_result.get(step['focus'], 0)
                
                # Adım raporunu kaydet
                step_report = step_result.get('ai_scout_report', '')
                overall_report.append(f"**{step['name']}**: {step_report}")
                
                print(f"✅ {step['name']} tamamlandı - Puan: {step_result.get(step['focus'], 0)}")
                
                # Kısa bekleme (API limitlerini aşmamak için)
                time.sleep(1)
            
            # Genel raporu birleştir
            final_report = "\n\n".join(overall_report)
            
            # Ortalama puanı hesapla
            scores = [v for v in results.values() if isinstance(v, (int, float))]
            average_score = sum(scores) / len(scores) if scores else 0
            
            print(f"\n🎉 Analiz tamamlandı!")
            print(f"📈 Genel Ortalama: {average_score:.1f}/100")
            
            return {
                **results,
                "ai_scout_report": final_report,
                "average_score": average_score,
                "analysis_type": "step_by_step",
                "total_steps": len(steps)
            }
            
        except Exception as e:
            print(f"❌ Adım adım analiz hatası: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Adım adım analiz başarısız: {str(e)}")
    
    def _analyze_specific_step(self, video_path: str, position: str, focus: str, description: str) -> Dict[str, Any]:
        """
        Belirli bir adımı analiz eder
        """
        # Özel prompt oluştur
        step_prompt = f"""
        You are analyzing a {position} player for the specific skill: {focus}.
        
        Focus exclusively on: {description}
        
        Rate this specific skill on a scale of 1-100 based on the video.
        Provide a brief analysis of this particular skill only.
        
        Return JSON format:
        {{
            "{focus}": 0,
            "ai_scout_report": "Brief analysis focusing specifically on {description}"
        }}
        """
        
        try:
            # Vision servisini kullanarak analiz et
            result = analyze_player_video_advanced(video_path, position)
            
            # Sadece ilgili alanı döndür
            return {
                focus: result.get(focus, 0),
                "ai_scout_report": result.get("ai_scout_report", "Analiz yapılamadı")
            }
            
        except Exception as e:
            print(f"⚠️ {focus} analizi başarısız: {str(e)}")
            return {
                focus: 0,
                "ai_scout_report": f"{focus} analizi sırasında hata oluştu"
            }
    
    def get_step_preview(self, position: str) -> Dict[str, Any]:
        """Pozisyonun analiz adımlarını önizleme için döndür"""
        steps = self.get_analysis_steps(position)
        
        return {
            "position": position,
            "total_steps": len(steps),
            "estimated_duration": sum(step["duration"] for step in steps),
            "steps": [
                {
                    "step_number": i + 1,
                    "name": step["name"],
                    "focus": step["focus"],
                    "description": step["description"],
                    "duration": step["duration"]
                }
                for i, step in enumerate(steps)
            ]
        }

# Global analyzer instance
step_analyzer = StepAnalyzer()
