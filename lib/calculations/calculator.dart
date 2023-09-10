// Dart imports:
import "dart:math";

// Package imports:
import "package:collection/collection.dart";

// Project imports:
import "package:graded/calculations/calculation_object.dart";
import "package:graded/calculations/manager.dart";
import "package:graded/calculations/test.dart";
import "package:graded/misc/default_values.dart";
import "package:graded/misc/enums.dart";
import "package:graded/misc/storage.dart";

class Calculator {
  static void sortObjects(
    List<CalculationObject> data, {
    required int sortType,
    int? sortModeOverride,
    int? sortDirectionOverride,
    List<CalculationObject>? comparisonData,
  }) {
    if (data.length < 2) return;

    final int sortDirection = sortDirectionOverride ?? getPreference<int>("sort_direction$sortType");
    int sortMode = getPreference<int>("sort_mode$sortType");
    if (sortModeOverride != null && sortMode != SortMode.custom) {
      sortMode = sortModeOverride;
    }

    switch (sortMode) {
      case SortMode.name:
        insertionSort(
          data,
          compare: (CalculationObject a, CalculationObject b) {
            int result = compareNatural(a.asciiName, b.asciiName);
            if (result == 0) {
              result = compareNatural(a.name, b.name);
            }
            return sortDirection * result;
          },
        );
      case SortMode.result:
        insertionSort(
          data,
          compare: (CalculationObject a, CalculationObject b) {
            if (a.result == null && b.result == null) {
              return 0;
            } else if (b.result == null) {
              return -1;
            } else if (a.result == null) {
              return 1;
            }

            return sortDirection * a.result!.compareTo(b.result!);
          },
        );
      case SortMode.coefficient:
        insertionSort(data, compare: (CalculationObject a, CalculationObject b) => sortDirection * a.coefficient.compareTo(b.coefficient));
      case SortMode.custom:
        final compare = comparisonData ?? getCurrentYear().termTemplate;
        data.sort((a, b) {
          return compare.indexWhere((element) => a.name == element.name) - compare.indexWhere((element) => b.name == element.name);
        });
      case SortMode.timestamp:
        if (data.first is! Test) throw UnimplementedError("Timestamp sorting is only implemented for tests");

        insertionSort(
          data,
          compare: (CalculationObject a, CalculationObject b) {
            int result = (a as Test).timestamp.compareTo((b as Test).timestamp);
            if (result == 0) {
              result = a.asciiName.compareTo(b.asciiName);
            }
            return result * sortDirection;
          },
        );
    }
  }

  static double? calculate(Iterable<CalculationObject> data, {int bonus = 0, bool precise = false, double speakingWeight = 1}) {
    final bool isNullFilled = data.every((element) => element.numerator == null || element.denominator == 0);

    if (data.isEmpty || isNullFilled) return null;

    final double maxGrade = Manager.years.isNotEmpty ? getCurrentYear().maxGrade : getPreference("max_grade");

    double totalNumerator = 0;
    double totalDenominator = 0;
    double totalNumeratorSpeaking = 0;
    double totalDenominatorSpeaking = 0;

    for (final CalculationObject c in data.where((element) => element.numerator != null && element.denominator != 0)) {
      if (c is Test && c.isSpeaking) {
        totalNumeratorSpeaking += c.numerator! * c.coefficient;
        totalDenominatorSpeaking += c.denominator * c.coefficient;
      } else {
        totalNumerator += c.numerator! * c.coefficient;
        totalDenominator += c.denominator * c.coefficient;
      }
    }

    double result = totalNumerator * (maxGrade / totalDenominator);
    double resultSpeaking = totalNumeratorSpeaking * (maxGrade / totalDenominatorSpeaking);
    if (result.isNaN) result = resultSpeaking;
    if (resultSpeaking.isNaN) resultSpeaking = result;

    final double totalResult = (result * speakingWeight + resultSpeaking) / (speakingWeight + 1) + bonus;

    return round(totalResult, roundToMultiplier: precise ? defaultValues["precise_round_to_multiplier"] as int : 1);
  }

  static double round(double n, {String? roundingModeOverride, int? roundToOverride, int roundToMultiplier = 1}) {
    final String roundingMode = roundingModeOverride ?? (Manager.years.isNotEmpty ? getCurrentYear().roundingMode : getPreference("rounding_mode"));
    int roundTo = roundToOverride ?? (Manager.years.isNotEmpty ? getCurrentYear().roundTo : getPreference<int>("round_to"));
    roundTo *= roundToMultiplier;

    final double round = n * roundTo;

    switch (roundingMode) {
      case RoundingMode.up:
        return round.ceilToDouble() / roundTo;
      case RoundingMode.down:
        return round.floorToDouble() / roundTo;
      case RoundingMode.halfUp:
        final double base = round.floorToDouble();
        final double decimals = n - base;

        return (decimals < 0.5 ? base : base + 1) / roundTo;
      case RoundingMode.halfDown:
        final double base = round.floorToDouble();
        final double decimals = n - base;

        return (decimals <= 0.5 ? base : base + 1) / roundTo;
      default:
        return n;
    }
  }

  static double? tryParse(String? input) {
    if (input == null) return null;
    return double.tryParse(input.replaceAll(",", ".").replaceAll(" ", ""));
  }

  static String format(double? n, {bool addZero = true, int? roundToOverride, int roundToMultiplier = 1}) {
    if (n == null || n.isNaN) return "-";

    final int roundTo = roundToOverride ?? (Manager.years.isNotEmpty ? getCurrentYear().roundTo : getPreference<int>("round_to")) * roundToMultiplier;
    String result;

    int nbDecimals = log(roundTo) ~/ log(10);
    if (n % 1 != 0) {
      nbDecimals = max(n.toString().split(".")[1].length, nbDecimals);
    }

    result = n.toStringAsFixed(nbDecimals);

    if (addZero && nbDecimals == 0 && n > 0 && n < 10) {
      result = "0$result";
    }
    return result;
  }
}
