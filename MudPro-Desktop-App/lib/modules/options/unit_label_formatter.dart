class UnitLabelFormatter {
  static String canonicalize(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('(') && value.endsWith(')') && value.length > 1) {
      value = value.substring(1, value.length - 1);
    }

    return value
        .replaceAll('Â', '')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('⁻', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(' ', '')
        .toLowerCase();
  }

  static String normalize(
    String raw, {
    Iterable<String> preferredOptions = const [],
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed == '-') {
      return trimmed;
    }

    final canonical = canonicalize(trimmed);
    for (final option in preferredOptions) {
      if (canonicalize(option) == canonical) {
        return option;
      }
    }

    var display = trimmed
        .replaceAll('Â', '')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('⁻', '-')
        .trim();

    if (!display.startsWith('(')) {
      display = '($display)';
    }

    return display;
  }

  static List<String> uniqueNormalized(Iterable<String> units) {
    final seen = <String>{};
    final normalized = <String>[];

    for (final unit in units) {
      final cleaned = normalize(unit);
      if (cleaned.isEmpty) {
        continue;
      }

      final key = canonicalize(cleaned);
      if (seen.add(key)) {
        normalized.add(cleaned);
      }
    }

    return normalized;
  }
}
