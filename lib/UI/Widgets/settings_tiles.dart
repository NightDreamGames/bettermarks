// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../Calculations/manager.dart';
import '../../Misc/storage.dart';
import '../../Translations/translations.dart';
import '../Settings/flutter_settings_screens.dart';

List<Widget> getSettingsTiles(BuildContext context, bool type) {
  return [
    SimpleSettingsTile(
      icon: Icons.subject,
      onTap: () {
        Navigator.pushNamed(context, "/subject_edit");
      },
      title: type ? Translations.add_subjects : Translations.edit_subjects,
      subtitle: Translations.edit_subjects_summary,
    ),
    RadioModalSettingsTile<int>(
      title: Translations.term,
      icon: Icons.access_time_outlined,
      settingKey: 'term',
      onChange: (var value) {
        Manager.readPreferences();
      },
      values: <int, String>{
        3: Translations.trimesters,
        2: Translations.semesters,
        1: Translations.year,
      },
      selected: defaultValues["term"],
    ),
    TextInputSettingsTile(
      title: Translations.rating_system,
      settingKey: 'total_grades_text',
      initialValue: defaultValues["total_grades"].toString(),
      icon: Icons.vertical_align_top,
      keyboardType: TextInputType.number,
      onChange: (text) {
        double d = double.parse(text);
        Storage.setPreference<double>("total_grades", d);
        Manager.totalGrades = d;

        Manager.calculate();
      },
      validator: (String? input) {
        if (input == null || input.isEmpty || double.tryParse(input) != null) {
          return null;
        }
        return Translations.invalid;
      },
    ),
    RadioModalSettingsTile<String>(
      title: Translations.rounding_mode,
      icon: Icons.arrow_upward,
      settingKey: 'rounding_mode',
      onChange: (value) {
        Manager.calculate();
      },
      values: <String, String>{
        "rounding_up": Translations.up,
        "rounding_down": Translations.down,
        "rounding_half_up": Translations.half_up,
        "rounding_half_down": Translations.half_down,
      },
      selected: defaultValues["rounding_mode"],
    ),
    RadioModalSettingsTile<int>(
      title: Translations.round_to,
      icon: Icons.cut,
      settingKey: 'round_to',
      onChange: (value) {
        Manager.calculate();
      },
      values: <int, String>{
        1: Translations.to_integer,
        10: Translations.to_10th,
        100: Translations.to_100th,
      },
      selected: defaultValues["round_to"],
    ),
  ];
}
