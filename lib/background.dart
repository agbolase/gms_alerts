import 'package:workmanager/workmanager.dart';
import 'core/models/models.dart';
import 'services/alert_api.dart';
import 'services/alert_sound.dart';

const gmsBackgroundTask = 'gms_alert_poll';

@pragma('vm:entry-point')
void gmsBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final token = await AlertApi.token();
      if (token.isEmpty) return true;
      var since = await AlertApi.sinceId();
      final data = await AlertApi.poll(token: token, sinceId: since);
      final rows = (data['data'] as List<dynamic>? ?? []);
      final unread = int.tryParse('${data['unread_count'] ?? 0}') ?? 0;
      await AlertSound.init();
      await AlertSound.setBadge(unread);
      for (final row in rows) {
        if (row is! Map) continue;
        final alert = GmsAlert.fromJson(Map<String, dynamic>.from(row));
        if (alert.id <= since) continue;
        since = alert.id;
        await AlertSound.play(alert, unread: unread);
      }
      await AlertApi.setSinceId(since);
    } catch (_) {}
    return true;
  });
}

Future<void> startBackgroundAlerts() async {
  await Workmanager().initialize(gmsBackgroundDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    gmsBackgroundTask,
    gmsBackgroundTask,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
