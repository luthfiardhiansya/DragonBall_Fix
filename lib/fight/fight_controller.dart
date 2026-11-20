import '../models/dragonball.dart';

const double kidBuuKi = 7150000;
const String kidBuuKiLabel = '7.150.000';

enum FightOutcome { win, lose, draw }

class FightResult {
  const FightResult({required this.outcome, required this.playerKi});

  final FightOutcome outcome;
  final double playerKi;

  bool get isWin => outcome == FightOutcome.win;
  bool get isLose => outcome == FightOutcome.lose;
}

class FightResultCalculator {
  const FightResultCalculator._();

  static FightResult calculate(Item player) {
    final playerKi = parseKi(player.ki);
    final double safePlayerKi = playerKi.isFinite ? playerKi : 0.0;
    final outcome = safePlayerKi.compareTo(kidBuuKi);
    return FightResult(
      playerKi: safePlayerKi,
      outcome: outcome > 0
          ? FightOutcome.win
          : outcome < 0
          ? FightOutcome.lose
          : FightOutcome.draw,
    );
  }

  static double parseKi(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'unknown') return 0;

    final match = RegExp(r'[\d.,]+').firstMatch(normalized);
    if (match == null) return 0;
    final number = _parseNumber(match.group(0)!);
    if (normalized.contains('infinite')) return double.infinity;

    const multipliers = <String, double>{
      'thousand': 1e3,
      'million': 1e6,
      'billion': 1e9,
      'trillion': 1e12,
      'quadrillion': 1e15,
      'quintillion': 1e18,
      'sextillion': 1e21,
      'septillion': 1e24,
      'octillion': 1e27,
      'nonillion': 1e30,
      'decillion': 1e33,
    };
    for (final entry in multipliers.entries) {
      if (normalized.contains(entry.key)) return number * entry.value;
    }
    return number;
  }

  static double _parseNumber(String value) {
    final hasDot = value.contains('.');
    final hasComma = value.contains(',');
    var normalized = value;

    if (hasDot && hasComma) {
      final lastDot = value.lastIndexOf('.');
      final lastComma = value.lastIndexOf(',');
      final decimalIndex = lastDot > lastComma ? lastDot : lastComma;
      final decimalDigits = value.length - decimalIndex - 1;
      if (decimalDigits == 3) {
        normalized = value.replaceAll('.', '').replaceAll(',', '');
      } else {
        final integerPart = value
            .substring(0, decimalIndex)
            .replaceAll('.', '')
            .replaceAll(',', '');
        final decimalPart = value.substring(decimalIndex + 1);
        normalized = '$integerPart.$decimalPart';
      }
    } else if (hasDot || hasComma) {
      final separator = hasDot ? '.' : ',';
      final parts = value.split(separator);
      final isThousandsFormat =
          parts.length > 1 && parts.skip(1).every((part) => part.length == 3);
      normalized = isThousandsFormat
          ? value.replaceAll(separator, '')
          : value.replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }

  static String formatKi(num value) {
    if (!value.isFinite) return '∞';
    final rounded = value.round();
    final digits = rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
