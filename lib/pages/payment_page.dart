import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import 'ticket_page.dart';

class PaymentPage extends StatefulWidget {
  final AppState state;
  final List<Map<String, dynamic>> cartItems;
  final int totalPrice;
  final String notes;
  final String pickupTime;
  final String pickupDate;

  const PaymentPage({
    super.key,
    required this.state,
    required this.cartItems,
    required this.totalPrice,
    required this.notes,
    this.pickupTime = '17:30 - 18:00',
    this.pickupDate = '',
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'QRIS';
  bool isProcessing = false;
  String? snapRedirectUrl;
  String? createdOrderId;

  // Heritage Theme Palette
  static const Color bgDark = Color(0xFF1E1510);      // Kopi Pekat
  static const Color cardDark = Color(0xFF2A1E17);    // Coklat Gelap
  static const Color goldAmber = Color(0xFFD49B42);   // Aksen Emas/Amber
  static const Color greenPandan = Color(0xFF2E7D32); // Tombol Hijau Pandan

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'QRIS',
      'name': 'QRIS Instant (GoPay, OVO, Dana, BCA)',
      'subtitle': 'Scan barcode QRIS dari semua e-wallet & mobile banking',
      'icon': Icons.qr_code_2,
    },
    {
      'id': 'BCA',
      'name': 'Virtual Account BCA',
      'subtitle': 'Transfer via BCA Mobile, KlikBCA, atau ATM',
      'icon': Icons.account_balance,
    },
    {
      'id': 'MANDIRI',
      'name': 'Virtual Account Mandiri',
      'subtitle': 'Transfer via Livin by Mandiri atau ATM',
      'icon': Icons.account_balance,
    },
    {
      'id': 'GOPAY',
      'name': 'GoPay / GoPay Later',
      'subtitle': 'Pembayaran langsung satu ketukan via aplikasi Gojek',
      'icon': Icons.account_balance_wallet,
    },
  ];

  Future<void> processPayment() async {
    final userId = widget.state.userId;
    final token = widget.state.token;
    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final now = DateTime.now();
      final dateIso = widget.pickupDate.isNotEmpty
          ? widget.pickupDate
          : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Buat pesanan ke Backend melalui ApiService.createOrder
      final response = await ApiService.createOrder(
        userId: userId,
        token: token,
        pickupTime: widget.pickupTime,
        pickupDate: dateIso,
        items: widget.cartItems,
        total: widget.totalPrice,
        notes: '${widget.notes} [Midtrans Snap: $selectedMethod]',
        paymentMethod: selectedMethod.toLowerCase(),
      );

      final orderData = (response['data'] as Map<String, dynamic>?) ?? {};
      final redirectUrl = (orderData['snap_redirect_url'] ?? orderData['payment_url'])?.toString();
      final orderId = (orderData['order_id'] ?? orderData['id'] ?? orderData['qr_code_token'])?.toString();

      setState(() {
        snapRedirectUrl = redirectUrl;
        createdOrderId = orderId;
      });

      // Update state tiket aktif
      widget.state.ticket = orderData;
      await widget.state.recordOrderHistory(
        summaryItems: widget.cartItems
            .map((e) => '${e['quantity'] ?? 1}x ${e['nama'] ?? e['name'] ?? 'Puthu'}')
            .join(', '),
        total: widget.totalPrice,
        pickupDate: orderData['pickup_date']?.toString() ?? 'Hari Ini',
        pickupTime: orderData['pickup_time']?.toString() ?? widget.pickupTime,
        notes: widget.notes,
        orderId: orderId,
      );
      widget.state.cart.clear();

      // Buka URL Snap Midtrans (Anti-Redirect ke example.com)
      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        final Uri uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jendela pembayaran Midtrans berhasil dibuka!'),
          backgroundColor: greenPandan,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pembayaran: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _openReceipt() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TicketPage(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pembayaran Digital Midtrans',
              style: TextStyle(color: cream, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Puthu Lanang Malang • Est. 1935',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Heritage Security Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: goldAmber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: goldAmber, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Transaksi Aman & Resmi (Midtrans Snap)',
                              style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Status pembayaran terverifikasi otomatis dalam sistem',
                              style: TextStyle(color: muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Ringkasan Tagihan Transaksi
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: goldAmber.withValues(alpha: 0.4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL TAGIHAN PEMBAYARAN',
                            style: TextStyle(color: goldAmber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: goldAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: goldAmber.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Menunggu Bayar',
                              style: TextStyle(color: goldAmber, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rupiah(widget.totalPrice),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: border),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.cartItems.length} Macam Jajanan',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          Text(
                            'Ambil: ${widget.pickupTime}',
                            style: const TextStyle(color: cream, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Pilihan Metode Pembayaran
                const Text(
                  'PILIH METODE PEMBAYARAN DIGITAL',
                  style: TextStyle(color: goldAmber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),

                ...paymentMethods.map((method) {
                  final isSelected = selectedMethod == method['id'];
                  return GestureDetector(
                    onTap: isProcessing ? null : () => setState(() => selectedMethod = method['id'] as String),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? cardDark : bgDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? goldAmber : border,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? goldAmber.withValues(alpha: 0.2) : cardDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              method['icon'] as IconData,
                              color: isSelected ? goldAmber : muted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['name'] as String,
                                  style: TextStyle(
                                    color: isSelected ? cream : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  method['subtitle'] as String,
                                  style: const TextStyle(color: muted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_off,
                            color: isSelected ? goldAmber : muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // 4. Tombol Aksi Utama
                if (snapRedirectUrl == null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenPandan,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isProcessing
                            ? 'Menghubungkan Midtrans Snap...'
                            : 'Bayar Sekarang (${rupiah(widget.totalPrice)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ] else ...[
                  // Jika snap URL sudah terbit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(snapRedirectUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser, size: 20),
                      label: const Text('Buka Kembali Jendela Midtrans', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldAmber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _openReceipt,
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: const Text('Buka Struk / E-Tiket Pengambilan', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenPandan,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
