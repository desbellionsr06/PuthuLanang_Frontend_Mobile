import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/app_state.dart';
import '../../domain/entities/checkout_entity.dart';
import '../viewmodels/checkout_view_model.dart';

class CheckoutView extends StatefulWidget {
  final AppState appState;
  final CheckoutViewModel? viewModel;

  const CheckoutView({
    super.key,
    required this.appState,
    this.viewModel,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late final CheckoutViewModel _viewModel;
  late final bool _ownsViewModel;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  static const String _couponTitle = 'Diskon Spesial VIP Member';
  static const int _couponDiscount = CheckoutEntity.promoDiscountAmount;
  static const int _couponMinTotal = CheckoutEntity.promoMinTransaction;
  bool _useCoupon = false;

  bool get _couponEligible => widget.appState.totalPrice >= _couponMinTotal;
  bool get _couponApplied => _useCoupon && _couponEligible;
  int get _discountAmount => _couponApplied ? _couponDiscount : 0;
  int get _finalTotal => (widget.appState.totalPrice - _discountAmount)
      .clamp(0, widget.appState.totalPrice)
      .toInt();

  late final List<Map<String, String>> _dateOptions;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? getIt<CheckoutViewModel>();

    _nameController.text = widget.appState.userName;
    _phoneController.text = widget.appState.phone;

    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    String pad(int n) => n.toString().padLeft(2, '0');

    _dateOptions = List.generate(3, (index) {
      final date = now.add(Duration(days: index));
      final label = index == 0
          ? 'Hari Ini'
          : index == 1
              ? 'Besok'
              : '${date.day} ${months[date.month - 1]}';
      final iso = '${date.year}-${pad(date.month)}-${pad(date.day)}';
      return {'title': label, 'iso': iso};
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    OutlineInputBorder borderStyle(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: brown2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: borderStyle(border),
      enabledBorder: borderStyle(border),
      focusedBorder: borderStyle(gold),
      errorBorder: borderStyle(Colors.redAccent),
      focusedErrorBorder: borderStyle(Colors.redAccent),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  void _showOperatingHoursDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: brown2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.access_time_filled, color: gold, size: 36),
        ),
        title: const Text(
          'Jam Operasional Puthu Lanang',
          style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Pemesanan hanya dibuka pada jam operasional Puthu Lanang pukul 17:30 – 21:30 WIB.\n\nSilakan kembali pada jam buka untuk menikmati sajian jajanan tradisional hangat kami.',
          style: TextStyle(color: muted, fontSize: 13, height: 1.4),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProcessCheckout() async {
    if (!widget.appState.isOperatingHours) {
      _showOperatingHoursDialog();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi data nama dan nomor telepon pengambil.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final takerName = _nameController.text.trim();
    final takerPhone = _phoneController.text.trim();
    final customNotes = _notesController.text.trim();

    String formattedNotes = customNotes;
    if (takerName.isNotEmpty || takerPhone.isNotEmpty) {
      final taker = 'Pengambil: $takerName ($takerPhone)';
      formattedNotes = customNotes.isNotEmpty ? '$customNotes | $taker' : taker;
    }

    if (_couponApplied) {
      final couponNote = 'Kupon: $_couponTitle (-${rupiah(_couponDiscount)})';
      formattedNotes = formattedNotes.isNotEmpty ? '$formattedNotes | $couponNote' : couponNote;
    }

    final result = await _viewModel.submitCheckout(
      appState: widget.appState,
      notes: formattedNotes,
      discount: _discountAmount,
      promoCode: _couponApplied ? CheckoutEntity.promoCodeVip : null,
    );

    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      final msg = _viewModel.errorMessage!;
      if (msg.contains('17:30') || msg.contains('operasional') || msg.contains('jam operasional')) {
        _showOperatingHoursDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.paymentMethod == PaymentMethodType.cash
                ? 'Pesanan berhasil dibuat! Silakan bayar di kasir.'
                : 'Membuka jendela pembayaran digital Midtrans...',
          ),
          backgroundColor: green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: brown,
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout & Smart Takeaway',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Jam Operasional: 17:30 - 21:30 WIB',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
            backgroundColor: brown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                if (!widget.appState.isOperatingHours)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E1E16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.storefront_outlined, color: Colors.amberAccent, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gerai Sedang Tutup',
                                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Pemesanan hanya dibuka pada jam operasional Puthu Lanang pukul 17:30 – 21:30 WIB.',
                                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Informasi Gerai Pusat
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: brown2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storefront, color: gold, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gerai Pusat Celaket — Puthu Lanang',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Jl. Jaksa Agung Suprapto No. 73, Klojen, Kota Malang',
                              style: TextStyle(color: muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Pilih Tanggal Pengambilan
                const Text(
                  'Tanggal Pengambilan',
                  style: TextStyle(color: cream, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _dateOptions.map((opt) {
                    final isSelected = _viewModel.selectedDate == opt['title'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _viewModel.setDate(
                            title: opt['title']!,
                            isoDate: opt['iso']!,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? gold : brown2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? gold : border),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                opt['title']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 3. Slot Waktu Pengambilan (Interval 30 menit antara 17:30 - 21:30)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slot Jam Pengambilan',
                      style: TextStyle(color: cream, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Interval 30 Menit',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih jadwal saat jajanan Puthu hangat siap diambil di kasir:',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: CheckoutEntity.pickupTimeSlots.map((slot) {
                    final isSelected = _viewModel.selectedTimeSlot == slot;
                    return GestureDetector(
                      onTap: () => _viewModel.setTimeSlot(slot),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? green : brown2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? green : border),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              slot,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[300],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                // 4. METODE PEMBAYARAN
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(color: cream, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tersedia pembayaran di tempat atau non-tunai melalui Midtrans:',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 10),

                _buildPaymentMethodTile(
                  type: PaymentMethodType.cash,
                  icon: Icons.payments_outlined,
                  selectedMethod: _viewModel.paymentMethod,
                  onSelect: () => _viewModel.setPaymentMethod(PaymentMethodType.cash),
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodTile(
                  type: PaymentMethodType.qris,
                  icon: Icons.qr_code_scanner,
                  selectedMethod: _viewModel.paymentMethod,
                  onSelect: () => _viewModel.setPaymentMethod(PaymentMethodType.qris),
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodTile(
                  type: PaymentMethodType.transfer,
                  icon: Icons.account_balance_outlined,
                  selectedMethod: _viewModel.paymentMethod,
                  onSelect: () => _viewModel.setPaymentMethod(PaymentMethodType.transfer),
                ),

                const SizedBox(height: 22),

                // 5. Data Pengambil Pesanan
                const Text(
                  'Informasi Pengambil Pesanan',
                  style: TextStyle(color: cream, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('Nama Lengkap Pengambil'),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Nama pengambil wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('Nomor WhatsApp Pengambil (08xx)'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nomor WhatsApp wajib diisi';
                    }
                    if (val.trim().length < 8) {
                      return 'Nomor WhatsApp minimal 8 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Catatan Khusus (cth: Gula aren dipisah, kelapa banyak)'),
                ),

                const SizedBox(height: 20),

                // 6. Kupon Diskon Spesial
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: brown2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_num_outlined, color: gold, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              _couponTitle,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              'Hemat ${rupiah(_couponDiscount)} (min. transaksi ${rupiah(_couponMinTotal)})',
                              style: const TextStyle(color: muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useCoupon,
                        activeTrackColor: gold,
                        onChanged: _couponEligible
                            ? (val) => setState(() => _useCoupon = val)
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 7. Rincian Pembayaran
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brown2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal Menu (${widget.appState.cart.length} item)', style: const TextStyle(color: muted, fontSize: 13)),
                          Text(rupiah(widget.appState.totalPrice), style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                      if (_couponApplied) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Potongan Kupon', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13)),
                            Text('-${rupiah(_discountAmount)}', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                      const Divider(color: border, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            rupiah(_finalTotal),
                            style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 8. Tombol Submit Pesanan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_viewModel.isProcessing || !widget.appState.isOperatingHours)
                        ? null
                        : _handleProcessCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _viewModel.isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            !widget.appState.isOperatingHours
                                ? 'Tutup (Buka 17:30 – 21:30 WIB)'
                                : (_viewModel.paymentMethod == PaymentMethodType.cash
                                    ? 'Buat Pesanan (Bayar di Kasir)'
                                    : 'Lanjut ke Pembayaran Midtrans'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodTile({
    required PaymentMethodType type,
    required IconData icon,
    required PaymentMethodType selectedMethod,
    required VoidCallback onSelect,
  }) {
    final isSelected = selectedMethod == type;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? gold.withValues(alpha: 0.12) : brown2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? gold : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? gold : muted,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: TextStyle(
                      color: isSelected ? gold : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.subtitle,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected ? gold : muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
