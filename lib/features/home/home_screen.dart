import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../providers/auth_state.dart';
import '../../providers/notification_poller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NotificationPoller? _poller;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>().auth;
    _poller = NotificationPoller(auth.client)..start();
  }

  @override
  void dispose() {
    _poller?.stop();
    _poller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.auth.user;

    return ChangeNotifierProvider.value(
      value: _poller!,
      child: Consumer<NotificationPoller>(
        builder: (context, poller, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('GMS Alerts'),
              actions: [
                IconButton(
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: Column(
              children: [
                if (user != null)
                  ListTile(
                    title: Text(user.name),
                    subtitle: Text(
                      user.students.isEmpty
                          ? user.role
                          : user.students.map((s) => s.name).join(', '),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _chip(poller, 'all', 'All'),
                      _chip(poller, 'invoice', 'Fees'),
                      _chip(poller, 'exam', 'Exams'),
                      _chip(poller, 'assignment', 'Assignments'),
                      _chip(poller, 'liveclass', 'Classes'),
                      _chip(poller, 'attendance', 'Attendance'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: poller.visible.isEmpty
                      ? const Center(child: Text('Waiting for alerts… keep this app open.'))
                      : ListView.separated(
                          itemCount: poller.visible.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) => _tile(poller.visible[i]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(NotificationPoller poller, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilterChip(
        label: Text(label),
        selected: poller.filter == value,
        onSelected: (_) => poller.setFilter(value),
      ),
    );
  }

  Widget _tile(GmsAlert alert) {
    return ListTile(
      leading: Icon(_icon(alert.type)),
      title: Text(alert.title),
      subtitle: Text(alert.body),
      trailing: Text(
        alert.createdAt.replaceFirst(' ', '\n'),
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'invoice':
        return Icons.receipt_long;
      case 'exam':
        return Icons.school;
      case 'assignment':
        return Icons.assignment;
      case 'liveclass':
        return Icons.videocam;
      case 'attendance':
        return Icons.fingerprint;
      default:
        return Icons.notifications;
    }
  }
}
