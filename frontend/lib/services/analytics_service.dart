import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final List<Map<String, dynamic>> _queue = [];
  Timer? _flushTimer;

  void init() {
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => _flush());
  }

  void trackScreen(String screenName) {
    _addEvent('screen_view', screenName);
  }

  void trackAction(String action, {Map<String, dynamic>? metadata}) {
    _addEvent('action', action, metadata: metadata);
  }

  void trackError(String error, {String? context}) {
    _addEvent('error', error, metadata: context != null ? {'context': context} : null);
  }

  void _addEvent(String type, String name, {Map<String, dynamic>? metadata}) {
    _queue.add({
      'event_type': type,
      'event_name': name,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_queue.length >= 20) _flush();
  }

  Future<void> _flush() async {
    if (_queue.isEmpty || AppConfig.apiUrl.isEmpty) return;

    final events = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();

    try {
      for (final event in events) {
        final uri = Uri.parse('${AppConfig.apiUrl}/analytics');
        await HttpClient()
            .postUrl(uri)
            .then((req) {
              req.headers.set('Content-Type', 'application/json');
              req.write(jsonEncode(event));
              return req.close();
            })
            .then((res) => res.drain());
      }
    } catch (_) {
      _queue.addAll(events);
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _flush();
  }
}
