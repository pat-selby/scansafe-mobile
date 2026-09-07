import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/scan_result.dart';

/// Layer 6 — local scan history.
///
/// On-device only. Nothing is synced, uploaded, or shared: the privacy promise
/// in the architecture document is that a scan never leaves the phone, and
/// history is the one place that promise could quietly be broken.
class ScanHistoryStore {
  ScanHistoryStore({SharedPreferences? preferences}) : _prefs = preferences;

  static const String storageKey = 'scansafe.history.v1';

  /// Cap from the architecture document. Oldest entries are dropped first.
  static const int maxEntries = 50;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Most recent scan first.
  Future<List<ScanResult>> load() async {
    final prefs = await _preferences;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      // A corrupt or older-format blob should not brick the history screen.
      await prefs.remove(storageKey);
      return [];
    }
  }

  /// Prepend [result] and persist, trimming to [maxEntries].
  Future<List<ScanResult>> add(ScanResult result) async {
    final history = await load();
    final updated = [result, ...history];
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    await _persist(updated);
    return updated;
  }

  Future<List<ScanResult>> removeAt(int index) async {
    final history = await load();
    if (index < 0 || index >= history.length) return history;
    history.removeAt(index);
    await _persist(history);
    return history;
  }

  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(storageKey);
  }

  Future<void> _persist(List<ScanResult> history) async {
    final prefs = await _preferences;
    await prefs.setString(
      storageKey,
      jsonEncode(history.map((r) => r.toJson()).toList()),
    );
  }
}
