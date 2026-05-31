"""Mevki/slot bazlı değerlendirme rubrikleri (prompt için)."""
from __future__ import annotations

from position_skills_config import KOSU_FLAT_LABEL, KOSU_UPHILL_LABEL


def _base_rubric(skill_focus: str, criteria: str) -> str:
    return f"""
Evaluate ONLY this test: **{skill_focus}**
Scoring 1-100 (elite academy standard):
{criteria}
Ignore unrelated skills in the clip. If clip is wrong test → compatible=false.
"""


RUBRICS: dict[str, str] = {
    "refleks": _base_rubric(
        "Kaleci refleksleri",
        "90+: çok hızlı yan tepki, temiz kurtarış\n"
        "70-89: iyi reaksiyon, ara sıra geç kalma\n"
        "50-69: yavaş ilk adım\n"
        "<50: test ile uyumsuz veya zayıf",
    ),
    "top tutma": _base_rubric(
        "Kaleci top tutma",
        "90+: güvenli yakalama, ikinci top kontrolü\n70-89: çoğunlukla temiz\n<70: kaçırma / zayıf teknik",
    ),
    "kaleci vuruşu": _base_rubric(
        "Kaleci dağıtım (atış/fırlatma)",
        "90+: uzun ve isabetli dağıtım\n70-89: orta isabet\n<70: kısa veya hatalı",
    ),
    "hava top": _base_rubric(
        "Hava topu / kafa",
        "90+: güçlü kafa, timing iyi\n70-89: orta\n<50: zayıf timing",
    ),
    "markaj": _base_rubric(
        "Markaj ve pozisyon",
        "90+: rakibi kapatır, doğru mesafe\n70-89: genelde iyi\n<50: geç kalma",
    ),
    "fiziksel": _base_rubric(
        "Fiziksel güç / ikili mücadele",
        "90+: üstünlük, denge\n70-89: rekabetçi\n<50: zayıf",
    ),
    "orta": _base_rubric(
        "Orta / crossing",
        "90+: isabetli orta, çeşitlilik\n70-89: orta kalite\n<50: isabetsiz",
    ),
    "hız": _base_rubric(
        "Sürat / ivme (genel)",
        "90+: patlayıcı ivme, düzgün form\n70-89: iyi hız\n<50: yavaş ivme",
    ),
    "defansif": _base_rubric(
        "Defansif pozisyon / geri koşu",
        "90+: doğru çizgi, geri dönüş hızlı\n70-89: kabul edilebilir\n<50: pozisyon hatası",
    ),
    "pas": _base_rubric(
        "Pas aralığı / pas kalitesi",
        "90+: kısa/uzun isabet, tempo\n70-89: orta\n<50: çok hata",
    ),
    "top kapma": _base_rubric(
        "Top kapma / pres",
        "90+: agresif ve temiz müdahale\n70-89: orta\n<50: geç veya faul riski",
    ),
    "oyun görüşü": _base_rubric(
        "Oyun görüşü / ara pas",
        "90+: doğru karar, ara pas\n70-89: orta\n<50: kötü seçim",
    ),
    "yaratıcılık": _base_rubric(
        "Yaratıcılık / son pas",
        "90+: kilit pas, yaratıcı çözüm\n70-89: orta\n<50: öngörülebilir",
    ),
    "şut": _base_rubric(
        "Şut gücü / teknik",
        "90+: sert ve çerçeve, iyi teknik\n70-89: orta\n<50: zayıf",
    ),
    "dripling": _base_rubric(
        "Dripling / top kontrolü",
        "90+: sıkı kontrol, yön değiştirme\n70-89: orta\n<50: top kaybı",
    ),
    "1'e 1": _base_rubric(
        "1'e 1 rakip geçme",
        "90+: geçiş başarısı yüksek\n70-89: orta\n<50: başarısız denemeler",
    ),
    "uzaktan": _base_rubric(
        "Uzaktan şut",
        "90+: isabet + güç\n70-89: orta\n<50: hedef dışı",
    ),
    "bitiricilik": _base_rubric(
        "Bitiricilik / kale önü",
        "90+: soğukkanlı bitiriş, çeşitlilik\n70-89: orta\n<50: kaçan fırsatlar",
    ),
    KOSU_FLAT_LABEL.lower(): _base_rubric(
        KOSU_FLAT_LABEL,
        "Değerlendir SADECE koşu formu: ivme, gövde pozisyonu, diz lift.\n"
        "Süre ayrı video analizi ile ölçülür — timing_sec her zaman null, timing_estimated=false.\n"
        "90+: elit form\n70-89: iyi\n<50: zayıf form veya yanlış test",
    ),
    KOSU_UPHILL_LABEL.lower(): _base_rubric(
        KOSU_UPHILL_LABEL,
        "Değerlendir SADECE yokuş koşu formu ve ivme.\n"
        "timing_sec null bırak.\n"
        "90+: güçlü yokuş çıkışı\n<50: yetersiz",
    ),
}


def get_rubric_for_label(skill_label: str, position: str) -> str:
    """skill_label: 'Hız' veya 'Hız — 20 Metre Düz Koşu'."""
    raw = (skill_label or "").strip().lower()
    if KOSU_FLAT_LABEL.lower() in raw:
        return RUBRICS[KOSU_FLAT_LABEL.lower()]
    if KOSU_UPHILL_LABEL.lower() in raw:
        return RUBRICS[KOSU_UPHILL_LABEL.lower()]
    for key, rubric in RUBRICS.items():
        if key in raw:
            return rubric
    return _base_rubric(
        skill_label or "Genel yetenek",
        "90+: üst seviye bu test için\n70-89: iyi\n50-69: gelişmeli\n<50: zayıf veya uyumsuz",
    )
