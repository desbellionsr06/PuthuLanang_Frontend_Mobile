import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/app_state.dart';
import '../../../../widgets/app_card.dart';
import '../../../ai_insight/presentation/views/ai_insight_view.dart';
import '../../../orders/presentation/views/orders_view.dart';
import '../viewmodels/profile_view_model.dart';
import 'notifications_view.dart';

class ProfileView extends StatefulWidget {
  final AppState state;
  final ProfileViewModel? viewModel;

  const ProfileView({
    super.key,
    required this.state,
    this.viewModel,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? getIt<ProfileViewModel>();
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _showVipPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: brown2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Aktifkan / Perpanjang VIP Member',
          style: TextStyle(color: cream, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Nikmati prioritas antrean dan berbagai keuntungan eksklusif Puthu Lanang.\n\nBiaya Langganan: Rp 10.000',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: green),
            onPressed: () {
              Navigator.pop(context);
              _viewModel.activateVip();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran Rp 10.000 Berhasil! Status VIP Aktif.'),
                  backgroundColor: green,
                ),
              );
            },
            child: const Text('Bayar Rp 10.000', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: brown2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: cream, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: muted, fontSize: 13, height: 1.4)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: green),
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData i, String s, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(i, color: gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s,
                style: const TextStyle(
                  color: cream,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: muted, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          children: [
            const Text(
              'Profil Pelanggan',
              style: TextStyle(
                color: cream,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Informasi akun & pengalaman Puthu Lanang.',
              style: TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),

            // KARTU PROFIL & VIP BUTTON
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: green,
                    child: Text(
                      widget.state.userName.isEmpty
                          ? 'P'
                          : widget.state.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.state.userName.isEmpty
                              ? 'Pecinta Kuliner'
                              : widget.state.userName,
                          style: const TextStyle(
                            color: cream,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          widget.state.phone,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _showVipPaymentDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: gold.withValues(alpha: 0.4)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _viewModel.isVip
                                    ? '★ VIP Member (Aktif)'
                                    : '☆ Upgrade ke VIP Member (Rp 10.000)',
                                maxLines: 1,
                                style: const TextStyle(
                                  color: gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // AI SMART QUEUE ESTIMATOR -> AiInsightView (MVVM)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiInsightView(appState: widget.state),
                ),
              ),
              borderRadius: BorderRadius.circular(18),
              child: const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: gold),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI Smart Queue & Menu Insight',
                            style: TextStyle(color: cream, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: gold, size: 18),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cek prediksi antrean berbasis lokasi GPS & kurasi menu Gemini AI.',
                      style: TextStyle(color: muted, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // MENU INTERAKTIF
            AppCard(
              child: Column(
                children: [
                  _row(
                    Icons.notifications_none,
                    'Notifikasi Gerai (${widget.state.unreadNotificationCount} baru)',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsView(state: widget.state),
                      ),
                    ),
                  ),
                  _row(
                    Icons.history,
                    'Riwayat Transaksi',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrdersView(state: widget.state),
                      ),
                    ),
                  ),
                  _row(
                    Icons.local_offer_outlined,
                    'Kupon Promo',
                    () => _showInfoDialog(
                      context,
                      'Kupon Promo Heritage 1935',
                      'Kode: PUTHUHEMAT10\n\nDiskon Spesial VIP Member\nPotongan Rp 10.000 dengan minimal transaksi Rp 50.000.',
                    ),
                  ),
                  _row(
                    Icons.shield_outlined,
                    'Ketentuan & Privasi',
                    () => _showInfoDialog(
                      context,
                      'Ketentuan & Privasi',
                      'Puthu Lanang Malang menjaga kerahasiaan data nomor WhatsApp dan transaksi Anda demi kenyamanan layanan pemesanan smart takeaway.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // TOMBOL KELUAR
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.state.logout(),
                icon: const Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

