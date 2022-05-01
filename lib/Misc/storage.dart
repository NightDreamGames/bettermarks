import 'dart:convert';
import 'dart:developer';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import '../Calculations/manager.dart';
import '../Calculations/subject.dart';
import '../Calculations/year.dart';
import 'compatibility.dart';

final Map<String, dynamic> defaultValues = {
  "data": "[{}]",
  "default_data": "[{}]",
  "rounding_mode": "rounding_up",
  "round_to": 1,
  "language": "default",
  "dark_theme": "auto",
  "total_grades": 60,
  "variant": "basic",
  "term": 2,
  "school_system": "lux",
  "class": "7C",
  "current_term": 0,
  "sort_mode1": 0,
  "sort_mode2": 0,
  "sort_mode3": 0,
};

// ignore: constant_identifier_names
const DATA_VERSION = 3;

class Storage {
  static void serialize() {
    setPreference("data", jsonEncode(Manager.years));
    setPreference("default_data", jsonEncode(Manager.termTemplate));
  }

  static String serializeString(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  static Future<void> deserialize() async {
    //try {
    await Compatibility.importPreferences();

    /*} catch (e) {
      log("Error while importing old data: " + e.toString());
    }*/

    if (existsPreference("data")) {
      var data = jsonDecode(getPreference<String>("data", "")) as List;
      List<Year> _years = data.map((yearJson) => Year.fromJson(yearJson)).toList();
      Manager.years = _years;

      var _termTemplate = jsonDecode(getPreference<String>("default_data", "")) as List;
      List<Subject> __termTemplate = _termTemplate.map((templateJson) => Subject.fromJson(templateJson)).toList();
      Manager.termTemplate = __termTemplate;
    }
  }

  static void setPreference(String key, dynamic value) {
    Settings.setValue(key, value);
  }

  static T getPreference<T>(String key, dynamic defaultValue) {
    return Settings.getValue<T>(key, defaultValue);
  }

  static bool existsPreference(String key) {
    return Settings.containsKey(key)!;
  }
}
