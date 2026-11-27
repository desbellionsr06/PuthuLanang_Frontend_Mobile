import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/app_state.dart';
import '../viewmodels/orders_view_model.dart';
import 'ticket_view.dart';

class PaymentView extends StatefulWidget {
  final AppState state;
  final List<Map<String, dynamic>> cartItems;
  final int totalPrice;
  final String notes;
  final String pickupTime;
  final String pickupDate;
  final OrdersViewModel? viewModel;

  const PaymentView({
    super.key,
    required this.state,
    required this.cartItems,
    required this.totalPrice,
    required this.notes,
    this.pickupTime = '17:30 - 18:00',
    this.pickupDate = '',
    this.viewModel,
  });

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  late final OrdersViewModel _viewModel;
  late final bool _ownsViewModel;

  String selectedMethod = 'QRIS';

  static const Color bgDark = Color(0xFF1E1510);
  static const Color cardDark = Color(0xFF2A1E17);
  static const Color goldAmber = Color(0xFFD49B42);
  static const Color greenPandan = Color(0xFF2E7D32);

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

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? getIt<OrdersViewModel>();
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _processPayment() async {
    final err = await _viewModel.processMidtransPayment(
      appState: widget.state,
      cartItems: widget.cartItems,
      totalPrice: widget.totalPrice,
      notes: widget.notes,
      pickupTime: widget.pickupTime,
      pickupDate: widget.pickupDate,
      selectedMethod: selectedMethod,
    );

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pembayaran: $err'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jendela pembayaran Midtrans berhasil dibuka!'),
        backgroundColor: greenPandan,
      ),
    );
  }

  void _openReceipt() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TicketView(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final isProcessing = _viewModel.isProcessingPayment;
        final snapRedirectUrl = _viewModel.snapRedirectUrl;

        return Scaffold(
          backgroundColor: bgDark,
          appBar: AppBar(
            backgroundColor: cardDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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

                    if (snapRedirectUrl == null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : _processPayment,
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
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(snapRedirectUrl);
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
      },
    );
  }
}

