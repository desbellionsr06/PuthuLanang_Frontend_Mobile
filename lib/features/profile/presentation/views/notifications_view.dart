import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/app_state.dart';
import '../../../../widgets/app_card.dart';
import '../viewmodels/profile_view_model.dart';

class NotificationsView extends StatefulWidget {
  final AppState state;
  final ProfileViewModel? viewModel;

  const NotificationsView({
    super.key,
    required this.state,
    this.viewModel,
  });

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final ProfileViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? getIt<ProfileViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.syncAndReadNotifications(widget.state);
    });
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
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
                onPressed: _viewModel.isRefreshing
                    ? null
                    : () => _viewModel.syncAndReadNotifications(widget.state),
                icon: const Icon(Icons.refresh, color: gold),
              ),
            ],
          ),
          body: Column(
            children: [
              if (_viewModel.errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _viewModel.errorMessage!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 11),
                  ),
                ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Belum ada notifikasi dari Manajer Gerai.\nPembaruan status pesanan dan verifikasi AI akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: muted, fontSize: 13, height: 1.5),
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
                                  child: const Icon(Icons.notifications_active,
                                      color: gold, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: const TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                            height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

