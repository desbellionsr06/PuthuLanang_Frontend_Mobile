import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import 'orders_page.dart';
import 'takeaway_page.dart';

class TicketPage extends StatefulWidget {
  final AppState state;

  const TicketPage({super.key, required this.state});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  AppState get state => widget.state;
  bool _completing = false;

  // Konfirmasi -> PATCH status 'Selesai' di backend -> buka Riwayat Transaksi
  Future<void> _confirmComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: brown2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Pesanan Selesai',
          style: TextStyle(color: cream, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Pastikan pesanan sudah Anda terima dari kasir. Status pesanan akan diubah menjadi "Selesai".',
          style: TextStyle(color: muted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Selesai', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _completing = true);

    try {
      await state.completeOrder();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Pesanan ditandai selesai. Terima kasih!'), backgroundColor: green),
      );
      navigator.push(
        MaterialPageRoute(builder: (_) => OrdersPage(state: state)),
      );
    } on SessionExpiredException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  // Garis putus-putus pembatas struk kuliner otentik
  Widget _buildDashedDivider({Color color = border, double height = 1}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = state.ticket;

    // KONDISI 1: Jika belum ada pesanan aktif (t == null)
    if (t == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: brown2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: gold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Ada Pesanan Aktif',
                style: TextStyle(
                  color: cream,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yuk, pesan menu Puthu Lanang favoritmu sekarang dan ambil tanpa mengantre!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => state.setTab(1),
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Buka Menu Jajanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Parsing data pesanan untuk struk
    final orderId = (t['order_id'] ?? t['id'] ?? 'PL-0000').toString();
    final antrean = t['antrean']?.toString() ?? '79';
    final tokenCode = (t['qr_code_token'] ?? orderId).toString();
    final payStatus = (t['payment_status'] ?? '').toString().toLowerCase();
    final payMethod = (t['payment_method'] ?? 'cash').toString().toLowerCase();
    final isPaid = payStatus == 'settlement' || payStatus == 'paid' || payStatus == 'success';
    final isPendingCash = payMethod == 'cash';

    final rawStatus = (t['status'] ?? 'Diproses').toString().toLowerCase();
    final isProcessing = rawStatus == 'diproses' || rawStatus == 'processing' || rawStatus == 'sedang dikukus';
    final estMinutes = t['estimated_minutes'] ?? 15;
    final estReadyAt = t['estimated_ready_at']?.toString();

    final totalInt = int.tryParse('${t['total'] ?? t['total_harga'] ?? 20000}') ?? 20000;
    final summaryItems = (t['summary_items'] ?? '1x Puthu / Paket Pilihan').toString();
    final notes = (t['notes'] ?? '').toString();

    // KONDISI 2: Jika sudah ada pesanan (t != null), tampilkan Struk/Invoice Autentik
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // --- HEADER ATAS BRANDING PUTHU LANANG 1935 ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: const Text('PL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Puthu Lanang 1935', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Struk Pembayaran & Pengambilan', style: TextStyle(color: muted, fontSize: 10)),
                  ],
                ),
              ],
            ),
            // Tombol Riwayat Pesanan
            IconButton(
              icon: const Icon(Icons.history, color: gold, size: 22),
              tooltip: 'Riwayat Pesanan',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrdersPage(state: state)),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 14),

        // --- KARTU UTAMA STRUK / INVOICE KULINER AUTENTIK ---
        Container(
          decoration: BoxDecoration(
            color: brown2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header Struk Resmi
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(
                  children: [
                    const Text(
                      'PUTHU LANANG MALANG',
                      style: TextStyle(color: cream, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Resep Pusaka Nusantara Sejak 1935',
                      style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Jl. Jaksa Agung Suprapto No. 73, Klojen, Malang',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                    const SizedBox(height: 12),

                    // Badge Status Pembayaran
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? green.withValues(alpha: 0.2)
                            : gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPaid ? green : gold,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle : Icons.hourglass_top,
                            color: isPaid ? green : gold,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPaid
                                ? '✓ LUNAS (Midtrans)'
                                : (isPendingCash ? '⏳ PENDING (Bayar di Kasir)' : '⏳ MENUNGGU PEMBAYARAN'),
                            style: TextStyle(
                              color: isPaid ? green : gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Dashed divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDashedDivider(),
              ),

              // 2. Order ID dengan Tombol Salin (Copy)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: brown,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tag, color: gold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'ORDER ID: $orderId',
                            style: const TextStyle(
                              color: cream,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: orderId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order ID $orderId berhasil disalin ke clipboard!'),
                              backgroundColor: green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: gold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.copy, color: gold, size: 12),
                              SizedBox(width: 4),
                              Text('Salin', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Highlight Estimasi Menit Pemrosesan (Requirement 6)
              if (isProcessing) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.soup_kitchen_rounded, color: gold, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesanan sedang dikukus/diproses • Estimasi siap ±$estMinutes menit',
                                style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                              if (estReadyAt != null && estReadyAt.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Perkiraan siap diambil: $estReadyAt',
                                  style: const TextStyle(color: cream, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 4. Nomor Antrean & QR Code Kasir
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3822),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: green.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'NOMOR ANTREAN PENGAMBILAN',
                      style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ANTREAN-$antrean',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: tokenCode,
                        size: 150,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'TOKEN: $tokenCode',
                      style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                    ),
                  ],
                ),
              ),

              // Dashed divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildDashedDivider(),
              ),

              // 5. Rincian Slot & Menu Dipesan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slot Waktu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Slot Pengambilan:', style: TextStyle(color: muted, fontSize: 11)),
                        Text(
                          '${t['pickup_date'] ?? 'Hari Ini'} • ${t['pickup_time'] ?? '17:30 - 18:00'}',
                          style: const TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Metode Bayar:', style: TextStyle(color: muted, fontSize: 11)),
                        Text(
                          payMethod.toUpperCase(),
                          style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildDashedDivider(),
                    const SizedBox(height: 10),

                    const Text(
                      'ITEM PESANAN:',
                      style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            summaryItems,
                            style: const TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rupiah(totalInt),
                          style: const TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: brown,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          'Catatan: $notes',
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    _buildDashedDivider(),
                    const SizedBox(height: 10),

                    // Total Tagihan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL PEMBAYARAN:',
                          style: TextStyle(color: cream, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        Text(
                          rupiah(totalInt),
                          style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- 6. TOMBOL AKSI: PESAN LAGI (Point 5) ---
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              state.reorderFromMap(t);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TakeawayPage(state: state),
                ),
              );
            },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Pesan Lagi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), // Hijau Pandan
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // --- 7. TOMBOL NAVIGASI: LIHAT PESANAN & KEMBALI KE BERANDA ---
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrdersPage(state: state)),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Lihat Pesanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: const BorderSide(color: gold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  state.setTab(0);
                },
                icon: const Icon(Icons.home, size: 16),
                label: const Text('Ke Beranda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cream,
                  side: const BorderSide(color: border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // --- 8. TOMBOL KONFIRMASI PESANAN SELESAI ---
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _completing ? null : _confirmComplete,
            icon: _completing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: green),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              _completing ? 'Memproses...' : 'Tandai Pesanan Selesai Diterima',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: green,
              side: const BorderSide(color: green),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // --- 9. WIDGET AI SMART EXPIRY & FRESHNESS PREDICTOR ---
        _buildAiFreshnessCard(t),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAiFreshnessCard(Map<String, dynamic> t) {
    final bestBefore = _calculateBestBefore(t);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brown2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: green.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco_outlined, color: green, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Freshness & Quality Predictor',
                  style: TextStyle(
                    color: cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: green.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  '0% Pengawet Kimia',
                  style: TextStyle(color: green, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brown,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waktu Santap Optimal (Golden Window):',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sebelum $bestBefore (±4 Jam)',
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '100% Segar',
                    style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'CATATAN KESEGARAN BAHAN ALAMI:',
            style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puthu Lanang menggunakan kelapa parut segar kukus & gula aren asli tanpa zat pengawet. Kualitas terbaik dinikmati selagi hangat.',
            style: TextStyle(color: muted, fontSize: 11, height: 1.4),
          ),

          const SizedBox(height: 12),
          _buildDashedDivider(),
          const SizedBox(height: 8),

          const Text(
            'TIPS PENYIMPANAN CERDAS BERBASIS AI:',
            style: TextStyle(color: cream, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          _buildTipRow(
            Icons.restaurant,
            'Nikmati Hangat Segera',
            'Tekstur puthu dan letupan gula aren paling lembut dalam 4 jam setelah pengambilan.',
          ),
          const SizedBox(height: 6),
          _buildTipRow(
            Icons.kitchen,
            'Simpan di Kulkas (Chiller)',
            'Jika belum disantap, pisahkan juruh aren & kelapa, simpan tertutup rapat di kulkas tahan hingga 24 jam.',
          ),
          const SizedBox(height: 6),
          _buildTipRow(
            Icons.soup_kitchen,
            'Kukus Ulang 3 Menit',
            'Kukus kembali selama 2-3 menit sebelum disajikan agar kelapa dan adonan kembali pulen gurih.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: gold, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: cream, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              Text(desc, style: const TextStyle(color: muted, fontSize: 10, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateBestBefore(Map<String, dynamic> t) {
    try {
      final pickupTime = t['pickup_time']?.toString() ?? '17:30';
      final parts = pickupTime.split('-');
      final targetStr = (parts.length > 1 ? parts[1] : parts[0]).trim();
      final timeParts = targetStr.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        int expiryHour = (hour + 4) % 24;
        return '${expiryHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} WIB';
      }
    } catch (_) {}
    final now = DateTime.now().add(const Duration(hours: 4));
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
  }
}
