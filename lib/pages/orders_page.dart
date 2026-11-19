import 'package:flutter/material.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../widgets/app_card.dart';
import 'takeaway_page.dart';

/// Halaman Riwayat Transaksi.
/// Data diambil dari backend (database) saat halaman dibuka dan saat pull-to-refresh.
class OrdersPage extends StatefulWidget {
  final AppState state;

  const OrdersPage({super.key, required this.state});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? error;
    try {
      await widget.state.loadOrderHistory();
    } catch (_) {
      error = 'Tidak dapat terhubung ke server. Menampilkan data yang tersimpan di perangkat.';
    }

    if (!mounted) return;
    setState(() {
      _errorMessage = error;
      _loading = false;
    });
  }

  // ---------- Helpers format ----------

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(dynamic raw) {
    final date = DateTime.tryParse('$raw')?.toLocal();
    if (date == null) return '';
    return '${_two(date.day)}/${_two(date.month)}/${date.year} ${_two(date.hour)}:${_two(date.minute)}';
  }

  String _formatPickupDate(dynamic raw) {
    final date = DateTime.tryParse('$raw');
    if (date == null) return '$raw';
    return '${_two(date.day)}/${_two(date.month)}/${date.year}';
  }

  // Warna & label badge mengikuti status dari database
  (String, Color) _statusStyle(dynamic raw) {
    final status = (raw?.toString().trim().isNotEmpty ?? false) ? raw.toString().trim() : 'Sedang Dikukus';
    switch (status.toLowerCase()) {
      case 'selesai':
        return ('Selesai', green);
      case 'sedang dikukus':
      case 'diproses':
      case 'processing':
        return ('Sedang Dikukus', gold);
      case 'dibatalkan':
      case 'cancelled':
        return ('Dibatalkan', Colors.redAccent);
      default:
        return (status, muted);
    }
  }

  Widget _buildStatusBadge(dynamic rawStatus) {
    final (label, color) = _statusStyle(rawStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brown,
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: brown,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : RefreshIndicator(
              color: gold,
              backgroundColor: brown2,
              onRefresh: _load,
              child: _buildList(),
            ),
    );
  }

  Widget _buildList() {
    final orders = widget.state.orderHistory;

    return ListView(
      // AlwaysScrollable agar pull-to-refresh tetap bisa dipakai saat daftar kosong/pendek
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (_errorMessage != null) _buildNotice(_errorMessage!),
        if (orders.isEmpty)
          _buildEmpty()
        else
          for (final order in orders) ...[
            _buildOrderCard(order),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildNotice(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.history, color: muted, size: 48),
          SizedBox(height: 12),
          Text(
            'Belum ada transaksi tersimpan.',
            style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 6),
          Text(
            'Pesanan jajanan tradisional Puthu Lanang yang telah dibuat akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final summary = (order['summary_items']?.toString().trim().isNotEmpty ?? false)
        ? order['summary_items'].toString()
        : 'Pesanan Puthu Lanang';
    final total = int.tryParse('${order['total']}') ?? 0;
    final notes = order['notes']?.toString() ?? '';

    final rawStatus = (order['status'] ?? '').toString().toLowerCase();
    final isProcessing = rawStatus == 'diproses' || rawStatus == 'processing' || rawStatus == 'sedang dikukus';
    final estMinutes = order['estimated_minutes'];
    final estReadyAt = order['estimated_ready_at']?.toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order['id']}',
                  style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
              _buildStatusBadge(order['status']),
            ],
          ),
          const SizedBox(height: 2),
          Text(_formatDateTime(order['created_at']), style: const TextStyle(color: muted, fontSize: 11)),
          
          // Estimasi Pemrosesan (Point 6)
          if (isProcessing) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: gold.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.soup_kitchen_rounded, color: gold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan sedang dikukus • Estimasi siap ±${estMinutes ?? 15} menit',
                          style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        if (estReadyAt != null && estReadyAt.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            'Estimasi jam siap: $estReadyAt',
                            style: const TextStyle(color: cream, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(summary, style: const TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            'Ambil: ${_formatPickupDate(order['pickup_date'])} • ${order['pickup_time']}',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Catatan: $notes', style: const TextStyle(color: muted, fontSize: 11)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(color: muted, fontSize: 12)),
              Text(
                rupiah(total),
                style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tombol Pesan Lagi (Point 5)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.state.reorderFromMap(order);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TakeawayPage(state: widget.state),
                  ),
                );
              },
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: const Text('Pesan Lagi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
