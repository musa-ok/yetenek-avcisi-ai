"""
Mevki bazlı 3 yetenek videosu konfigürasyonu
Her mevki için 3 spesifik yetenek videosu tanımlanmıştır
"""

POSITION_SKILLS_CONFIG = {
    "Kaleci": {
        "code": "GK",
        "skills": [
            {
                "slot": 1,
                "name": "Refleksler",
                "name_en": "Reflexes",
                "description": "Kaleye atılan şutlara refleks tepkiler",
                "description_en": "Quick reflex reactions to shots on goal",
                "icon": "⚡",
                "duration_sec": 10,
                "color": "#FF6B6B"
            },
            {
                "slot": 2,
                "name": "Top Tutma",
                "name_en": "Handling",
                "description": "Topu güvenle yakalama ve kontrol",
                "description_en": "Secure catching and ball control",
                "icon": "🧤",
                "duration_sec": 10,
                "color": "#4ECDC4"
            },
            {
                "slot": 3,
                "name": "Kaleci Vuruşu",
                "name_en": "Distribution",
                "description": "Atış ve fırlatma doğruluğu",
                "description_en": "Accurate throws and kicks",
                "icon": "🦶",
                "duration_sec": 10,
                "color": "#95E1D3"
            }
        ],
        "attributes": ["reflexes", "handling", "positioning", "distribution"]
    },
    
    "Stoper": {
        "code": "CB",
        "skills": [
            {
                "slot": 1,
                "name": "Hava Topları",
                "name_en": "Aerial Duels",
                "description": "Kafa vuruşu ve hava topu hakimiyeti",
                "description_en": "Heading and aerial dominance",
                "icon": "👤",
                "duration_sec": 10,
                "color": "#A8E6CF"
            },
            {
                "slot": 2,
                "name": "Markaj",
                "name_en": "Marking",
                "description": "Rakip takip ve pozisyon alma",
                "description_en": "Opponent tracking and positioning",
                "icon": "👁️",
                "duration_sec": 10,
                "color": "#DCEDC1"
            },
            {
                "slot": 3,
                "name": "Fiziksel Güç",
                "name_en": "Physical Strength",
                "description": "İkili mücadeleler ve güç kullanımı",
                "description_en": "Duels and physical presence",
                "icon": "💪",
                "duration_sec": 10,
                "color": "#FFD3B6"
            }
        ],
        "attributes": ["heading", "marking", "tackling", "strength"]
    },
    
    "Bek": {
        "code": "FB",
        "skills": [
            {
                "slot": 1,
                "name": "Orta Yapma",
                "name_en": "Crossing",
                "description": "Ceza sahasına orta yapma",
                "description_en": "Accurate crosses into the box",
                "icon": "🎯",
                "duration_sec": 10,
                "color": "#FFAAA5"
            },
            {
                "slot": 2,
                "name": "Hız",
                "name_en": "Pace",
                "description": "Kanat hücumlarına katılma hızı",
                "description_en": "Speed for overlapping runs",
                "icon": "⚡",
                "duration_sec": 10,
                "color": "#FF8B94"
            },
            {
                "slot": 3,
                "name": "Defansif Pozisyon",
                "name_en": "Defensive Position",
                "description": "Geride kalan savunma pozisyonu",
                "description_en": "Staying back defensive shape",
                "icon": "🛡️",
                "duration_sec": 10,
                "color": "#C7CEEA"
            }
        ],
        "attributes": ["crossing", "pace", "defensive_awareness", "stamina"]
    },
    
    "CDM/CM": {
        "code": "CM",
        "skills": [
            {
                "slot": 1,
                "name": "Pas Aralığı",
                "name_en": "Pass Range",
                "description": "Kısa ve uzun mesafe paslar",
                "description_en": "Short and long range passing",
                "icon": "🦶",
                "duration_sec": 10,
                "color": "#B4A7D6"
            },
            {
                "slot": 2,
                "name": "Top Kapma",
                "name_en": "Ball Recovery",
                "description": "Pres ve top kapma mücadeleleri",
                "description_en": "Pressing and ball winning",
                "icon": "🔒",
                "duration_sec": 10,
                "color": "#D4A5A5"
            },
            {
                "slot": 3,
                "name": "Oyun Görüşü",
                "name_en": "Vision",
                "description": "360 derece saha görüşü",
                "description_en": "360 degree field awareness",
                "icon": "👁️",
                "duration_sec": 10,
                "color": "#9ED2C6"
            }
        ],
        "attributes": ["passing", "tackling", "vision", "work_rate"]
    },
    
    "On Numara": {
        "code": "CAM",
        "skills": [
            {
                "slot": 1,
                "name": "Yaratıcılık",
                "name_en": "Creativity",
                "description": "Asist ve son paslar",
                "description_en": "Assists and key passes",
                "icon": "✨",
                "duration_sec": 10,
                "color": "#F7DC6F"
            },
            {
                "slot": 2,
                "name": "Şut Gücü",
                "name_en": "Shot Power",
                "description": "Dışarıdan sert şutlar",
                "description_en": "Powerful long range shots",
                "icon": "⚽",
                "duration_sec": 10,
                "color": "#BB8FCE"
            },
            {
                "slot": 3,
                "name": "Dripling",
                "name_en": "Dribbling",
                "description": "Dar alanda dripling",
                "description_en": "Close control dribbling",
                "icon": "🔄",
                "duration_sec": 10,
                "color": "#85C1E9"
            }
        ],
        "attributes": ["creativity", "shooting", "dribbling", "composure"]
    },
    
    "Kanat": {
        "code": "WING",
        "skills": [
            {
                "slot": 1,
                "name": "Hız",
                "name_en": "Pace",
                "description": "Defans arkasına kaçma",
                "description_en": "Getting in behind defense",
                "icon": "🏃",
                "duration_sec": 10,
                "color": "#F8B500"
            },
            {
                "slot": 2,
                "name": "Orta Yapma",
                "name_en": "Crossing",
                "description": "Ceza sahasına orta",
                "description_en": "Crossing into the box",
                "icon": "🎯",
                "duration_sec": 10,
                "color": "#82E0AA"
            },
            {
                "slot": 3,
                "name": "1'e 1",
                "name_en": "1v1",
                "description": "Bekle bire bir mücadele",
                "description_en": "Beating defenders 1v1",
                "icon": "⚔️",
                "duration_sec": 10,
                "color": "#F1948A"
            }
        ],
        "attributes": ["pace", "crossing", "dribbling", "acceleration"]
    },
    
    "Forvet": {
        "code": "ST",
        "skills": [
            {
                "slot": 1,
                "name": "Uzaktan Şut",
                "name_en": "Long Shot",
                "description": "Ceza sahası dışından şutlar",
                "description_en": "Shots from outside the box",
                "icon": "🚀",
                "duration_sec": 10,
                "color": "#E74C3C"
            },
            {
                "slot": 2,
                "name": "Dar Alanda Dripling",
                "name_en": "Close Control",
                "description": "Dar alanda top kontrolü",
                "description_en": "Close space ball control",
                "icon": "🎯",
                "duration_sec": 10,
                "color": "#3498DB"
            },
            {
                "slot": 3,
                "name": "Bitiricilik",
                "name_en": "Finishing",
                "description": "Kaleci ile karşı karşıya",
                "description_en": "One-on-one finishing",
                "icon": "⚽",
                "duration_sec": 10,
                "color": "#2ECC71"
            }
        ],
        "attributes": ["shooting", "dribbling", "finishing", "positioning"]
    }
}

# Pozisyon listesi (dropdown için)
POSITIONS = list(POSITION_SKILLS_CONFIG.keys())

def get_skills_for_position(position: str):
    """Mevki için 3 yetenek videosu bilgisini döndürür"""
    config = POSITION_SKILLS_CONFIG.get(position)
    if config:
        return config["skills"]
    return []

def get_attributes_for_position(position: str):
    """Mevki için analiz edilecek özellikleri döndürür"""
    config = POSITION_SKILLS_CONFIG.get(position)
    if config:
        return config["attributes"]
    return []

def get_position_code(position: str):
    """Mevki kısa kodunu döndürür"""
    config = POSITION_SKILLS_CONFIG.get(position)
    if config:
        return config["code"]
    return "UNK"
