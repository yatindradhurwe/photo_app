import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle hidden / private media items
class HiddenMediaService {
  static const String _hiddenKey = 'photoapp_hidden_media_ids';

  /// Get all hidden media IDs
  static Future<Set<String>> getHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_hiddenKey) ?? [];
    return list.toSet();
  }

  /// Hide media IDs
  static Future<void> hideItems(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_hiddenKey) ?? []).toSet();
    current.addAll(ids);
    await prefs.setStringList(_hiddenKey, current.toList());
  }

  /// Unhide / restore media IDs to normal gallery
  static Future<void> unhideItems(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_hiddenKey) ?? []).toSet();
    current.removeAll(ids);
    await prefs.setStringList(_hiddenKey, current.toList());
  }

  /// Check if an item is hidden
  static Future<bool> isHidden(String id) async {
    final hidden = await getHiddenIds();
    return hidden.contains(id);
  }
}
