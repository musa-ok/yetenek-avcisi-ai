import os
import time
import json
from dotenv import load_dotenv

try:
    import google.generativeai as genai
except Exception:
    genai = None

# ── API Key ───────────────────────────────────────────────────────────────────
_env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
GEMINI_API_KEY = None  # type: str | None

try:
    with open(_env_path, 'r') as _f:
        for _line in _f:
            if _line.strip().startswith('GEMINI_API_KEY='):
                GEMINI_API_KEY = _line.strip().split('=', 1)[1].strip()
                break
except Exception:
    pass

if not GEMINI_API_KEY:
    load_dotenv(_env_path)
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')

if genai and GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    print(f"[VISION] Gemini hazır. Key: {GEMINI_API_KEY[:20]}...")
else:
    print('[VISION] ⚠️  Gemini API Key bulunamadı!')

# ── Model ─────────────────────────────────────────────────────────────────────
_model = None
if genai and GEMINI_API_KEY:
    _model = genai.GenerativeModel(
        model_name='gemini-2.5-flash',
        generation_config={
            'temperature': 0.4,
            'top_p': 0.95,
            'max_output_tokens': 8192,
            'response_mime_type': 'application/json',
        },
    )

# ── Constants ─────────────────────────────────────────────────────────────────
_INT_FIELDS = [
    'overall_rating', 'pace', 'finishing', 'passing', 'dribbling',
    'defending', 'strength', 'technical_ability', 'physical_attributes',
    'tactical_awareness', 'mental_attributes',
]

_ERROR_RESULT = {
    'overall_rating': 10, 'pace': 10, 'finishing': 10, 'passing': 10,
    'dribbling': 10, 'defending': 10, 'strength': 10, 'technical_ability': 10,
    'physical_attributes': 10, 'tactical_awareness': 10, 'mental_attributes': 10,
    'ai_strengths': ['Analiz tamamlanamadı.'],
    'ai_improvements': ['Teknik sorun nedeniyle analiz yapılamadı.'],
    'ai_scout_report': '⚠️ HATA: Analiz sırasında teknik bir sorun oluştu.',
}

MISMATCH_REPORT_PREFIX = 'Uyumsuz video'
MISMATCH_USER_MESSAGE = (
    'Uyumsuz video: Yüklediğiniz görüntü seçilen mevki veya yetenek testi ile '
    'uyuşmuyor. Lütfen doğru videoyu yükleyin.'
)


def _normalize_mismatch_message(raw: str) -> str:
    text = (raw or '').strip()
    if not text:
        return MISMATCH_USER_MESSAGE
    if text.lower().startswith('uyumsuz video'):
        return text
    return f'{MISMATCH_REPORT_PREFIX}: {text}'

# ── Helpers ───────────────────────────────────────────────────────────────────
def _upload_and_wait(path: str):
    """Upload video to Gemini Files API and block until ACTIVE."""
    import shutil, uuid
    clean_path = f'/tmp/upload_{uuid.uuid4().hex}.mp4'
    shutil.copy2(path, clean_path)
    try:
        file = genai.upload_file(clean_path, mime_type='video/mp4')
    finally:
        try:
            os.remove(clean_path)
        except Exception:
            pass
    while True:
        state = genai.get_file(file.name).state.name
        if state == 'ACTIVE':
            return file
        if state != 'PROCESSING':
            raise RuntimeError(f'Dosya işlenemedi: {file.name} (state={state})')
        time.sleep(2)

def validate_slot_video(video_path: str, position: str, skill_name: str) -> dict:
    """
    Tek slot yüklemeden önce: video bu test ile uyumlu mu?
    Returns: {"compatible": bool, "message": str}
    """
    if not _model or not video_path or not os.path.exists(video_path):
        return {'compatible': True, 'message': 'OK'}

    uploaded = None
    try:
        uploaded = _upload_and_wait(video_path)
        prompt = f"""
You are validating ONE upload for a football scouting app.
Position: **{position}**
Required test for this slot: **{skill_name}**

Rules:
- "20 Metre Düz Koşu": video MUST show a straight-line sprint (~20m), NOT shooting, dribbling, or goalkeeper drills.
- "10 Metre Yokuş Yukarı Koşu": video MUST show uphill sprint, NOT flat skill drills unrelated to running uphill.
- Goalkeeper skills: must show goalkeeper actions.
- Striker/winger skills: must show attacking actions, NOT pure GK.
- If the clip is another sport, unrelated activity, or clearly the WRONG test for "{skill_name}" → compatible=false.

Return ONLY JSON:
{{
  "compatible": true or false,
  "message": "OK" or "Uyumsuz video: <short Turkish reason>"
}}
"""
        response = _model.generate_content(
            [uploaded, prompt],
            request_options={'timeout': 120},
        )
        raw = (
            response.text.replace('```json', '').replace('```', '').strip()
        )
        data = json.loads(raw)
        compatible = data.get('compatible', True) is True
        message = str(data.get('message') or 'OK')
        if not compatible:
            message = _normalize_mismatch_message(message)
        return {'compatible': compatible, 'message': message}
    except Exception as exc:
        print(f'[VISION] Slot validate failed (strict): {exc}')
        return {
            'compatible': False,
            'message': 'Video doğrulanamadı. Lütfen net çekimle tekrar yükleyin.',
        }
    finally:
        if uploaded:
            try:
                genai.delete_file(uploaded.name)
            except Exception:
                pass


# ── Public API ────────────────────────────────────────────────────────────────
def analyze_multiple_videos(
    video_paths: list,
    position: str,
    skill_names: list = None,
) -> dict:
    """
    Upload up to 3 football videos and return a structured JSON analysis.
    Mismatch (clearly wrong position) → all scores = 10, report starts with ⚠️ HATA.
    """
    if not _model:
        return dict(_ERROR_RESULT)

    uploaded: list = []
    try:
        for path in video_paths:
            if path and os.path.exists(path):
                print(f'[VISION] Yükleniyor → {path}')
                uploaded.append(_upload_and_wait(path))

        if not uploaded:
            print('[VISION] ⚠️  Geçerli video bulunamadı.')
            return dict(_ERROR_RESULT)

        from position_skills_config import (
            get_attributes_for_position,
            get_position_code,
            get_skills_for_position,
            get_kosu_slot_numbers,
        )

        pos_code = get_position_code(position)
        skills_cfg = get_skills_for_position(position) or []
        attrs = get_attributes_for_position(position) or []
        kosu_slots = get_kosu_slot_numbers(position)
        skill_lines = "\n".join(
            f"- Slot {s['slot']}: {s['name']} — {s['description']}"
            + (
                " (2 video: 20m düz koşu + 10m yokuş yukarı)"
                if s.get("is_kosu_slot")
                else ""
            )
            for s in skills_cfg
        )
        attrs_line = ", ".join(attrs) if attrs else "general football skills"
        sprint_block = ""
        if kosu_slots:
            sprint_block = f"""
=== HIZ SLOTS ({kosu_slots}) ===
Each marked slot needs TWO clips: 20m flat sprint then 10m uphill sprint.
Other slots: one normal skill video. Wrong clip → "Uyumsuz video".
"""

        prompt = f"""
You are a strict, elite professional football scout AI (prompt version: position_{pos_code}_v2).
You are analyzing {len(uploaded)} video clip(s) of a player claiming to play in the following position: **{position}** (code: {pos_code})

=== POSITION SKILL VIDEOS (from app config) ===
The player should demonstrate these skills in the uploaded clips:
{skill_lines or '- General position-appropriate actions'}
{sprint_block}
Primary attributes to evaluate: {attrs_line}.

=== STEP 1: STRICT POSITION VERIFICATION ===
Before analyzing any skills, you MUST verify if the player's actions in the videos match the requested '{position}' role.
- 'Kaleci' (Goalkeeper): You MUST see goalkeeping actions (diving, saving, using hands, wearing gloves, being in goal). If the player is exclusively shooting goals, dribbling, or doing striker drills -> THIS IS A MISMATCH.
- 'Forvet' (Striker) / 'Kanat' (Winger): You MUST see attacking and finishing actions. If the player is catching balls with their hands -> THIS IS A MISMATCH.
- 'Stoper' (Defender) / 'Bek' (Fullback): You MUST see defending, tackling, or clearing.
- 'Orta Saha' / 'CM' / 'On Numara' (Midfielder): You MUST see passing, playmaking, or ball control.
Note: Basic running/fitness drills are acceptable for any position, but performing completely different specialized football skills is NOT acceptable.

=== STEP 2: IF MISMATCH DETECTED ===
If the videos show a COMPLETELY DIFFERENT football position than '{position}' or show non-football activities, you MUST fail the analysis.
You must return EXACTLY this JSON output (scores set to 10, and specific Turkish error messages):
{{
    "overall_rating": 10,
    "pace": 10, "finishing": 10, "passing": 10, "dribbling": 10,
    "defending": 10, "strength": 10, "technical_ability": 10,
    "physical_attributes": 10, "tactical_awareness": 10, "mental_attributes": 10,
    "ai_strengths": ["Hata: Uyumsuz mevki tespit edildi."],
    "ai_improvements": ["Lütfen seçilen mevkiye uygun video yükleyin."],
    "ai_scout_report": "Uyumsuz video: Yüklenen videolar seçilen '{position}' mevkisi veya yüklenen test türü ile uyuşmuyor."
}}

=== STEP 3: IF VALID MATCH (NORMAL CASE) ===
If the videos generally match the '{position}' role, score the football skills objectively on a scale of 1 to 100.
Return this JSON structure:
{{
    "overall_rating": <int>,
    "pace": <int>,
    "finishing": <int>,
    "passing": <int>,
    "dribbling": <int>,
    "defending": <int>,
    "strength": <int>,
    "technical_ability": <int>,
    "physical_attributes": <int>,
    "tactical_awareness": <int>,
    "mental_attributes": <int>,
    "ai_strengths": [
        "Hız: XX/100 - [Detailed observation written in Turkish]",
        "Teknik: XX/100 - [Detailed observation written in Turkish]"
    ],
    "ai_improvements": [
        "Pas: XX/100 - [Area for improvement written in Turkish]",
        "Defans: XX/100 - [Area for improvement written in Turkish]"
    ],
    "ai_scout_report": "[A detailed, professional scout report written entirely in TURKISH evaluating the player's performance in the {position} role.]"
}}

CRITICAL RULE: ALL TEXT VALUES IN THE JSON OUTPUT (reports, strengths, improvements) MUST BE WRITTEN IN TURKISH. RETURN ONLY VALID JSON FORMAT.
"""
        response = _model.generate_content(
            uploaded + [prompt],
            request_options={'timeout': 600},
        )

        raw = (
            response.text
            .replace('```json', '').replace('```JSON', '').replace('```', '')
            .strip()
        )
        result: dict = json.loads(raw)

        # Normalize integer fields
        for field in _INT_FIELDS:
            try:
                result[field] = max(1, min(100, int(result.get(field, 40))))
            except (TypeError, ValueError):
                result[field] = 40

        # Ensure list fields
        if not isinstance(result.get('ai_strengths'), list) or not result['ai_strengths']:
            result['ai_strengths'] = ['Genel performans değerlendirildi.']
        if not isinstance(result.get('ai_improvements'), list) or not result['ai_improvements']:
            result['ai_improvements'] = ['Gelişime açık alanlar tespit edildi.']
        if not result.get('ai_scout_report'):
            result['ai_scout_report'] = 'Analiz tamamlandı.'

        report_lower = (result.get('ai_scout_report') or '').lower()
        mismatch_hit = any(
            w in report_lower
            for w in ('uyumsuz', 'mismatch', 'eşleşmiyor', '⚠️ hata')
        )
        if mismatch_hit or (
            result.get('overall_rating', 100) <= 10 and 'hata' in report_lower
        ):
            result['ai_scout_report'] = _normalize_mismatch_message(
                result.get('ai_scout_report', '')
            )
            result['overall_rating'] = 10

        print(f'[VISION] ✅ Analiz bitti. Overall: {result["overall_rating"]}')
        return result

    except Exception as exc:
        print(f'[VISION ERROR] {type(exc).__name__}: {exc}')
        return dict(_ERROR_RESULT)

    finally:
        for vf in uploaded:
            try:
                genai.delete_file(vf.name)
            except Exception:
                pass


def analyze_slot_video(
    video_path: str,
    position: str,
    skill_label: str,
    *,
    slot: int | None = None,
    phase: str | None = None,
) -> dict:
    """
    Tek slot / tek klip analizi. Rubrik odaklı puan.
    Returns: score, confidence, compatible, message, observation, timing_sec, timing_estimated
    """
    from services.slot_rubrics import get_rubric_for_label
    from services.slot_scoring import attribute_for_label

    fallback = {
        'score': 40,
        'confidence': 0.3,
        'compatible': False,
        'message': MISMATCH_USER_MESSAGE,
        'observation': 'Analiz tamamlanamadı.',
        'timing_sec': None,
        'timing_estimated': False,
        'attribute': attribute_for_label(skill_label),
        'slot': slot,
        'phase': phase,
        'label': skill_label,
        'skill': skill_label.split('—')[0].strip() if '—' in skill_label else skill_label,
    }
    if not _model or not video_path or not os.path.exists(video_path):
        return fallback

    uploaded = None
    try:
        uploaded = _upload_and_wait(video_path)
        rubric = get_rubric_for_label(skill_label, position)
        prompt = f"""
You are scoring ONE football scouting test clip.
Position: **{position}**
Test label: **{skill_label}**
Slot: {slot or 'N/A'} | Phase: {phase or 'skill'}

{rubric}

Return ONLY JSON:
{{
  "compatible": true or false,
  "message": "OK" or "Uyumsuz video: <short Turkish reason>",
  "score": <int 1-100>,
  "confidence": <float 0.0-1.0>,
  "observation": "<2-3 sentences Turkish, this test only>",
  "timing_sec": <float or null>,
  "timing_estimated": true or false
}}
"""
        response = _model.generate_content(
            [uploaded, prompt],
            request_options={'timeout': 180},
        )
        raw = response.text.replace('```json', '').replace('```', '').strip()
        data = json.loads(raw)
        compatible = data.get('compatible', True) is True
        message = str(data.get('message') or 'OK')
        if not compatible:
            message = _normalize_mismatch_message(message)
            return {
                **fallback,
                'compatible': False,
                'message': message,
                'observation': message,
            }
        try:
            score = max(1, min(100, int(data.get('score', 40))))
        except (TypeError, ValueError):
            score = 40
        try:
            confidence = float(data.get('confidence', 0.7))
            confidence = max(0.0, min(1.0, confidence))
        except (TypeError, ValueError):
            confidence = 0.7
        timing = data.get('timing_sec')
        if timing is not None:
            try:
                timing = round(float(timing), 2)
            except (TypeError, ValueError):
                timing = None
        skill_short = skill_label.split('—')[0].strip() if '—' in skill_label else skill_label
        return {
            'score': score,
            'confidence': confidence,
            'compatible': True,
            'message': 'OK',
            'observation': str(data.get('observation') or '').strip() or 'Değerlendirme tamamlandı.',
            'timing_sec': timing,
            'timing_estimated': bool(data.get('timing_estimated', timing is not None)),
            'attribute': attribute_for_label(skill_label),
            'slot': slot,
            'phase': phase,
            'label': skill_label,
            'skill': skill_short,
        }
    except Exception as exc:
        print(f'[VISION] analyze_slot_video error: {exc}')
        return {**fallback, 'message': f'Analiz hatası: {exc}'}
    finally:
        if uploaded:
            try:
                genai.delete_file(uploaded.name)
            except Exception:
                pass


def analyze_player_video_advanced(video_path: str, position: str) -> dict:
    """Single-video wrapper — delegates to analyze_multiple_videos."""
    return analyze_multiple_videos([video_path], position)