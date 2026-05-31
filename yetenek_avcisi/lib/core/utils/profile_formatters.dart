/// Profil alanları: API (ASCII) ↔ kullanıcı arayüzü (Türkçe).
String footFromApi(String? api) {
  switch (api) {
    case 'Sol':
      return 'Sol';
    case 'Sag':
      return 'Sağ';
    case 'Ikisi':
      return 'İkisi';
    default:
      return 'Sağ';
  }
}

String footToApi(String display) {
  switch (display) {
    case 'Sol':
      return 'Sol';
    case 'Sağ':
      return 'Sag';
    case 'İkisi':
      return 'Ikisi';
    default:
      return 'Sag';
  }
}

/// Dropdown: gösterim etiketi → API değeri.
const List<MapEntry<String, String>> preferredFootDropdownEntries = [
  MapEntry('Sol', 'Sol'),
  MapEntry('Sağ', 'Sag'),
  MapEntry('İkisi', 'Ikisi'),
];

String formatBirthDateDisplay(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  try {
    final dt = DateTime.parse(raw);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  } catch (_) {
    final dateOnly = raw.split('T').first.trim();
    final parts = dateOnly.split('-');
    if (parts.length == 3) {
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    }
    return raw;
  }
}
