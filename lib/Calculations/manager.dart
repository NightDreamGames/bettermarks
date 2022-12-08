// Project imports:
import '../Misc/compatibility.dart';
import '../Misc/storage.dart';
import '../UI/Utilities/hints.dart';
import 'calculator.dart';
import 'subject.dart';
import 'term.dart';
import 'test.dart';
import 'year.dart';

class Manager {
  static List<Year> years = [];
  static List<Subject> termTemplate = [];
  static int currentYear = 0;

  static int _currentTerm = 0;
  static int get currentTerm => _currentTerm;
  static set currentTerm(int newValue) {
    Storage.setPreference<int>("current_term", newValue);
    _currentTerm = newValue;
  }

  static int _lastTerm = 0;
  static int get lastTerm => _lastTerm;
  static set lastTerm(int newValue) {
    Storage.setPreference<int>("last_term", newValue);
    _lastTerm = newValue;
  }

  static bool deserializationError = false;

  static Future<void> init() async {
    await Compatibility.upgradeDataVersion();
    currentTerm = Storage.getPreference<int>("current_term");

    Manager.calculate();
  }

  static void calculate() {
    for (Year y in years) {
      y.calculate();
    }

    sortAll();
  }

  static void clear() {
    years.clear();
    years.add(Year());
    Manager.currentTerm = 0;

    calculate();
  }

  static Year getCurrentYear() {
    if (years.isEmpty) {
      Storage.deserialize();
    }

    if (years.isEmpty) {
      years.add(Year());
    }

    return years[currentYear];
  }

  static Term getCurrentTerm() {
    if (currentTerm == -1) {
      Year currentYear = getCurrentYear();
      Term yearTerm = Term();
      Manager.sortSubjectsAZ();

      for (int i = 0; i < currentYear.terms.length; i++) {
        for (int j = 0; j < currentYear.terms[i].subjects.length; j++) {
          double? subjectResult = currentYear.terms[i].subjects[j].result;

          yearTerm.subjects[j].addTest(
              Test(subjectResult ?? 0, Storage.getPreference<double>("total_grades"), getTitle(termOverride: i), isEmpty: subjectResult == null),
              calculate: false);
        }
      }

      yearTerm.calculate();
      Calculator.sortObjects(yearTerm.subjects, 1);

      return yearTerm;
    }

    return getCurrentYear().terms[currentTerm];
  }

  static void sortAll() {
    for (Year y in years) {
      for (Term p in y.terms) {
        for (Subject s in p.subjects) {
          s.sort();
        }
        p.sort();
      }
    }

    Calculator.sortObjects(termTemplate, 3);

    Storage.serialize();
  }

  static void sortSubjectsAZ() {
    for (Year y in years) {
      for (Term p in y.terms) {
        p.sort(sortModeOverride: 0);
      }
    }

    Calculator.sortObjects(termTemplate, 0, sortModeOverride: 0);
  }

  Map<String, dynamic> toJson() => {"years": years, "term_template": termTemplate};
}
