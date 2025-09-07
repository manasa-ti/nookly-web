import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FilterPreferencesService {
  static const String _physicalActivenessKey = 'filter_physical_activeness';
  static const String _availabilityKey = 'filter_availability';

  static Future<List<String>> getPhysicalActivenessFilters() async {
    print('🔵 FILTER DEBUG: FilterPreferencesService.getPhysicalActivenessFilters called');
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_physicalActivenessKey);
    if (json != null) {
      final result = List<String>.from(jsonDecode(json));
      print('🔵 FILTER DEBUG: FilterPreferencesService returning Physical Activeness: $result');
      return result;
    }
    print('🔵 FILTER DEBUG: FilterPreferencesService returning empty Physical Activeness');
    return [];
  }

  static Future<List<String>> getAvailabilityFilters() async {
    print('🔵 FILTER DEBUG: FilterPreferencesService.getAvailabilityFilters called');
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_availabilityKey);
    if (json != null) {
      final result = List<String>.from(jsonDecode(json));
      print('🔵 FILTER DEBUG: FilterPreferencesService returning Availability: $result');
      return result;
    }
    print('🔵 FILTER DEBUG: FilterPreferencesService returning empty Availability');
    return [];
  }

  static Future<void> setPhysicalActivenessFilters(List<String> filters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_physicalActivenessKey, jsonEncode(filters));
  }

  static Future<void> setAvailabilityFilters(List<String> filters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_availabilityKey, jsonEncode(filters));
  }

  static Future<void> clearAllFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_physicalActivenessKey);
    await prefs.remove(_availabilityKey);
  }
}
