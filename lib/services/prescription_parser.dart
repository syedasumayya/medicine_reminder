/// One medicine found inside prescription text.
class ParsedMedicine {
  final String name;
  final String dose;
  final List<int> hours; // hours of the day to take it, like [8, 21]
  final bool timesGuessed; // true if the text had no timing and we guessed

  const ParsedMedicine({
    required this.name,
    required this.dose,
    required this.hours,
    required this.timesGuessed,
  });
}

/// Reads prescription text and finds the medicines in it.
class PrescriptionParser {
  // "1) " or "2. " at the start of a line
  static final RegExp _numberPrefix = RegExp(r'^\s*\d+\s*[\).]\s+');

  // A medicine line starts with its form: Tab, Cap, Syp, Inj ...
  static final RegExp _formPrefix = RegExp(
    r'^(tablets?|tabs?|capsules?|caps?|syrup|syp|inj(?:ection)?|drops?|ointment|oint|cream)\b\.?\s*',
    caseSensitive: false,
  );

  // 500mg, 5ml, 2.5 g ...
  static final RegExp _strength = RegExp(
    r'(\d+(?:\.\d+)?)\s*(mg|mcg|ml|iu|g)\b',
    caseSensitive: false,
  );

  // 1+0+1 or 1-0-1 or 1+1
  static final RegExp _pattern = RegExp(
    r'\b(\d)\s*[+\-]\s*(\d)(?:\s*[+\-]\s*(\d))?\b',
  );

  // OD, BD, TDS ...
  static final RegExp _abbreviation = RegExp(
    r'\b(od|qd|bd|bid|tds|tid|qid|hs)\b',
    caseSensitive: false,
  );

  // x 5 days, for 7 days, x 2 weeks
  static final RegExp _duration = RegExp(
    r'\b(?:x|for)\s*\d+\s*(?:days?|d|weeks?|wks?)\b',
    caseSensitive: false,
  );

  static final RegExp _trailingJunk = RegExp(r'[\s,;:\-\.]+$');

  /// Goes through the text line by line and returns every medicine it finds.
  static List<ParsedMedicine> parse(String text) {
    final results = <ParsedMedicine>[];
    for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
      final parsed = _parseLine(rawLine);
      if (parsed != null) results.add(parsed);
    }
    return results;
  }

  static ParsedMedicine? _parseLine(String rawLine) {
    final line = rawLine.trim().replaceFirst(_numberPrefix, '');

    // Lines that do not start with Tab/Cap/Syp... are not medicines
    // (for example the doctor's name or the date).
    final formMatch = _formPrefix.firstMatch(line);
    if (formMatch == null) return null;

    final form = formMatch.group(1)!.toLowerCase();
    final rest = line.substring(formMatch.end).trim();

    final String unit;
    if (form.startsWith('tab')) {
      unit = 'tablet';
    } else if (form.startsWith('cap')) {
      unit = 'capsule';
    } else {
      unit = 'dose';
    }

    final strengthMatch = _strength.firstMatch(rest);
    final patternMatch = _pattern.firstMatch(rest);
    final abbreviationMatch = _abbreviation.firstMatch(rest);
    final durationMatch = _duration.firstMatch(rest);

    // The name is everything before the first "detail"
    // (strength, timing or duration).
    var cut = rest.length;
    for (final m in [
      strengthMatch,
      patternMatch,
      abbreviationMatch,
      durationMatch,
    ]) {
      if (m != null && m.start < cut) cut = m.start;
    }
    var name = rest.substring(0, cut).replaceAll(_trailingJunk, '').trim();
    if (name.isEmpty) return null;
    if (strengthMatch != null) {
      final number = strengthMatch.group(1);
      final strengthUnit = strengthMatch.group(2)!.toLowerCase();
      name = '$name $number$strengthUnit';
    }

    // Work out when to take it.
    var hours = <int>[];
    var amount = 1;
    if (patternMatch != null) {
      final numbers = [
        patternMatch.group(1),
        patternMatch.group(2),
        patternMatch.group(3),
      ].whereType<String>().map(int.parse).toList();

      if (numbers.length == 3) {
        if (numbers[0] > 0) hours.add(8); // morning
        if (numbers[1] > 0) hours.add(14); // afternoon
        if (numbers[2] > 0) hours.add(21); // night
      } else {
        if (numbers[0] > 0) hours.add(8);
        if (numbers[1] > 0) hours.add(20);
      }
      amount = numbers.firstWhere((n) => n > 0, orElse: () => 1);
    } else if (abbreviationMatch != null) {
      hours = _hoursForAbbreviation(abbreviationMatch.group(1)!.toLowerCase());
    }

    final guessed = hours.isEmpty;
    if (guessed) hours = [8];

    final dose = '$amount ${amount == 1 ? unit : '${unit}s'}';

    return ParsedMedicine(
      name: name,
      dose: dose,
      hours: hours,
      timesGuessed: guessed,
    );
  }

  static List<int> _hoursForAbbreviation(String abbreviation) {
    switch (abbreviation) {
      case 'od':
      case 'qd':
        return [8];
      case 'bd':
      case 'bid':
        return [8, 20];
      case 'tds':
      case 'tid':
        return [8, 14, 21];
      case 'qid':
        return [8, 12, 16, 20];
      case 'hs':
        return [22];
      default:
        return [];
    }
  }
}
