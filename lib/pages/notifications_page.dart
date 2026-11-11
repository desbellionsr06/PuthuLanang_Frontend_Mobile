import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../widgets/app_card.dart';

class NotificationsPage extends StatefulWidget {
  final AppState state;

  const NotificationsPage({super.key, required this.state});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _syncAndRead();
  }

  Future<void> _syncAndRead() async {
    setState(() => _refreshing = true);
    await widget.state.refreshNotifications();
    await widget.state.markAllNotificationsRead();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.state.notifications;

    return Scaffold(
      backgroundColor: brown,
      appBar: AppBar(
        backgroundColor: brown2,
        foregroundColor: cream,
        title: const Text(
          'Notifikasi & Pembaruan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _syncAndRead,
            icon: const Icon(Icons.refresh, color: gold),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada notifikasi dari Manajer Gerai.\nPembaruan status pesanan dan verifikasi AI akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active, color: gold, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['title'] ?? 'Pembaruan Gerai'}',
                              style: const TextStyle(
                                color: cream,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['body'] ?? ''}',
                              style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

