import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/models/models.dart';
import '../services/alert_sound.dart';

class NotificationPoller extends ChangeNotifier {
  NotificationPoller(this._client);

  final ApiClient _client;
  final List<GmsAlert> alerts = [];
  int _sinceId = 0;
  bool running = false;
  String filter = 'all';

  List<GmsAlert> get visible {
    if (filter == 'all') return alerts;
    return alerts.where((a) => a.type == filter).toList();
  }

  Future<void> start() async {
    running = true;
    await _loadInitial();
    unawaited(_loop());
  }

  void stop() {
    running = false;
  }

  Future<void> _loadInitial() async {
    try {
      final data = await _client.get('notifications', query: {'limit': '40'});
      final rows = (data['data'] as List<dynamic>? ?? [])
          .map((e) => GmsAlert.fromJson(e as Map<String, dynamic>))
          .toList();
      alerts
        ..clear()
        ..addAll(rows.reversed);
      if (alerts.isNotEmpty) {
        _sinceId = alerts.map((e) => e.id).reduce((a, b) => a > b ? a : b);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('GMS alerts load: $e');
    }
  }

  Future<void> _loop() async {
    while (running) {
      try {
        final data = await _client.poll(
          'poll',
          query: {'since_id': '$_sinceId'},
        );
        final rows = (data['data'] as List<dynamic>? ?? [])
            .map((e) => GmsAlert.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final alert in rows) {
          if (alert.id <= _sinceId) continue;
          alerts.insert(0, alert);
          _sinceId = alert.id;
          await AlertSound.play(alert);
        }
        if (rows.isNotEmpty) notifyListeners();
      } catch (e) {
        debugPrint('GMS poll: $e');
        await Future<void>.delayed(const Duration(seconds: 4));
      }
    }
  }

  void setFilter(String value) {
    filter = value;
    notifyListeners();
  }
}
