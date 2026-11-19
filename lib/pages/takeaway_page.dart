import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../utils/validators.dart';

class TakeawayPage extends StatefulWidget {
  final AppState state;
  const TakeawayPage({super.key, required this.state});

  @override
  State<TakeawayPage> createState() => _TakeawayPageState();
}

class _TakeawayPageState extends State<TakeawayPage> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static const List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  String selectedOutlet = 'Gerai Pusat Celaket';

  // --- Kupon promo ---
  static const String _couponCode = 'PUTHUHEMAT10';
  static const String _couponTitle = 'Diskon Spesial VIP Member';
  static const int _couponDiscount = 10000;
  static const int _couponMinTotal = 50000;
  bool useCoupon = false;

  bool get _couponEligible => widget.state.totalPrice >= _couponMinTotal;
  bool get _couponApplied => useCoupon && _couponEligible;
  int get _discountAmount => _couponApplied ? _couponDiscount : 0;
  int get _payTotal => (widget.state.totalPrice - _discountAmount).clamp(0, widget.state.totalPrice).toInt();
  late List<Map<String, String>> dateOptions;
  late String selectedDate;
  late String selectedIsoDate;
  String selectedTime = '17:30 - 18:00';
  String selectedPaymentMethod = 'cash';
  
  final notesController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool busy = false;

  Map<String, dynamic>? queueEstimate;
  bool loadingQueue = false;
  double? gpsDistanceKm;
  bool detectingGps = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.state.userName;
    phoneController.text = widget.state.phone;

    final now = DateTime.now();
    dateOptions = List.generate(3, (index) {
      final date = now.add(Duration(days: index));
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = _months[date.month - 1];

      String title;
      if (index == 0) {
        title = 'Hari Ini';
      } else if (index == 1) {
        title = 'Besok';
      } else {
        title = _days[date.weekday - 1];
      }

      final label = '$title\n$dayStr $monthStr';
      final iso = '${date.year}-${date.month.toString().padLeft(2, '0')}-$dayStr';

      return {
        'label': label,
        'iso': iso,
      };
    });

    selectedDate = dateOptions.first['label']!;
    selectedIsoDate = dateOptions.first['iso']!;
    fetchQueueEstimate();
  }

  Future<void> fetchQueueEstimate() async {
    setState(() => loadingQueue = true);
    final res = await ApiService.getAiQueueEstimate(
      outlet: selectedOutlet,
      day: selectedDate,
      timeSlot: selectedTime,
      token: widget.state.jwtToken,
      distanceKm: gpsDistanceKm,
    );
    if (mounted) {
      setState(() {
        queueEstimate = res;
        loadingQueue = false;
      });
    }
  }

  Future<void> _detectDistanceViaGps() async {
    setState(() => detectingGps = true);
    try {
      final loc = await LocationService.getCurrentLocationToOutlet();
      if (mounted) {
        setState(() => gpsDistanceKm = loc.distanceKm);
        await fetchQueueEstimate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => detectingGps = false);
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!widget.state.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk atau daftar akun terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!widget.state.isOperatingHours) {
      _showOperatingHoursDialog();
      return;
    }

    // Validasi form (nama & nomor pengambil wajib, catatan maks. 200 karakter)
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Periksa kembali data yang Anda isi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => busy = true);

    final customNotes = notesController.text.trim();
    final takerName = nameController.text.trim();
    final takerPhone = phoneController.text.trim();
    
    String formattedNotes = customNotes;
    if (takerName.isNotEmpty || takerPhone.isNotEmpty) {
      final taker = 'Pengambil: $takerName ($takerPhone)';
      formattedNotes = customNotes.isNotEmpty ? '$customNotes | $taker' : taker;
    }

    try {
      final orderResult = await widget.state.submitOrder(
        pickupTime: selectedTime,
        pickupDate: selectedIsoDate,
        notes: _couponApplied
            ? (formattedNotes.isNotEmpty
                ? '$formattedNotes | Kupon: $_couponCode (-${rupiah(_couponDiscount)})'
                : 'Kupon: $_couponCode (-${rupiah(_couponDiscount)})')
            : formattedNotes,
        discount: _discountAmount,
        paymentMethod: selectedPaymentMethod,
      );

      final redirectUrl = (orderResult['payment_url'] ?? orderResult['snap_redirect_url'])?.toString();
      if (selectedPaymentMethod != 'cash' && redirectUrl != null && redirectUrl.isNotEmpty) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        if (errText.contains('17:30') || errText.contains('operasional') || errText.contains('jam operasional')) {
          _showOperatingHoursDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errText)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brown,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Form Smart Takeaway', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Atur gerai & slot waktu pengambilan pesanan', style: TextStyle(fontSize: 12, color: muted)),
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
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Jam Operasional (Jika di luar jam buka)
          if (!widget.state.isOperatingHours)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3E1E16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_outlined, color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
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

          // --- 1. PILIHAN GERAI OUTLET ---
          const Text('📍 Pilihan Gerai Outlet', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          
          // Gerai Pusat Celaket
          GestureDetector(
            onTap: () {
              setState(() => selectedOutlet = 'Gerai Pusat Celaket');
              fetchQueueEstimate();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brown2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedOutlet == 'Gerai Pusat Celaket' ? green : border, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(selectedOutlet == 'Gerai Pusat Celaket' ? Icons.radio_button_checked : Icons.radio_button_off, color: selectedOutlet == 'Gerai Pusat Celaket' ? green : Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      const Text('Gerai Pusat Celaket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('Celaket Online', style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 26, top: 4, bottom: 8),
                    child: Text('Jl. Jaksa Agung Suprapto No. 73, Samaan, Klojen, Malang', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 26),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF1E3A1E), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Buka • Ramai Lancar', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          gpsDistanceKm != null
                              ? 'Jarak GPS: $gpsDistanceKm km'
                              : 'Estimasi Antrean: ~12 Mnt',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: OutlinedButton.icon(
                      onPressed: detectingGps ? null : _detectDistanceViaGps,
                      icon: const Icon(Icons.my_location, size: 15, color: gold),
                      label: Text(
                        detectingGps
                            ? 'Mengukur Jarak GPS...'
                            : (gpsDistanceKm != null
                                ? 'Perbarui Jarak GPS ($gpsDistanceKm km)'
                                : 'Input Cepat Jarak via GPS'),
                        style: const TextStyle(color: cream, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: border),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. TANGGAL PENGAMBILAN ---
          const Text('📅 Tanggal Pengambilan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < dateOptions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _buildDateCard(dateOptions[i]['label']!, dateOptions[i]['iso']!),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // --- 3. SLOT WAKTU PENGAMBILAN ---
          const Text('⏰ Slot Waktu Pengambilan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              '17:30 - 18:00',
              '18:00 - 18:30',
              '18:30 - 19:00',
              '19:00 - 19:30',
              '19:30 - 20:00',
              '20:00 - 20:30',
              '20:30 - 21:00',
              '21:00 - 21:30',
            ].map((timeSlot) => GestureDetector(
              onTap: () {
                setState(() => selectedTime = timeSlot);
                fetchQueueEstimate();
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedTime == timeSlot ? green : brown2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selectedTime == timeSlot ? green : border),
                ),
                child: Text(
                  timeSlot,
                  style: TextStyle(
                    color: selectedTime == timeSlot ? Colors.white : Colors.grey[300],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            )).toList(),
          ),

          // --- WIDGET AI SMART QUEUE ESTIMATOR ---
          _buildAiQueueCard(),

          const SizedBox(height: 20),

          // --- 4. CATATAN KHUSUS PESANAN ---
          const Text('✏️ Catatan Khusus Pesanan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          TextFormField(
            controller: notesController,
            maxLines: 3,
            maxLength: 200,
            validator: (v) => Validators.optionalText(v, maxLength: 200, fieldName: 'Catatan'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Catatan tambahan untuk pesanan (opsional)'),
          ),

          const SizedBox(height: 20),

          // --- 5. DATA PENGAMBIL PESANAN ---
          const Text('👤 Data Pengambil Pesanan', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          TextFormField(
            controller: nameController,
            keyboardType: TextInputType.name,
            validator: (v) => Validators.name(v, fieldName: 'Nama pengambil'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Nama Pengambil'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: Validators.digitsOnly,
            validator: (v) => Validators.phone(v, fieldName: 'Nomor telepon'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration('Nomor Telepon'),
          ),

          const SizedBox(height: 24),

          // --- 6. KUPON PROMO ---
          const Text('🎟️ Kupon Promo', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              if (!_couponEligible) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kupon hanya bisa dipakai untuk transaksi minimal ${rupiah(_couponMinTotal)}.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              setState(() => useCoupon = !useCoupon);
            },
            child: Opacity(
              opacity: _couponEligible ? 1 : 0.5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brown2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _couponApplied ? green : border, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _couponApplied ? Icons.check_circle : Icons.radio_button_off,
                      color: _couponApplied ? green : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                child: const Text(_couponCode, style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              Text('-${rupiah(_couponDiscount)}', style: TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(_couponTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            'Potongan ${rupiah(_couponDiscount)} dengan minimal transaksi ${rupiah(_couponMinTotal)}.',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          if (!_couponEligible)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Tambah ${rupiah(_couponMinTotal - widget.state.totalPrice)} lagi untuk memakai kupon ini.',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- METODE PEMBAYARAN ---
          const Text('💳 Metode Pembayaran', style: TextStyle(color: Color(0xFFE69616), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          _buildPaymentChoiceTile('cash', '💵 Bayar di Tempat (Kasir)', 'Bayar tunai di kasir gerai saat mengambil jajanan'),
          const SizedBox(height: 8),
          _buildPaymentChoiceTile('qris', '📱 QRIS (GoPay, OVO, Dana, Shopee)', 'Scan kode QR instan dari semua e-wallet & m-banking via Midtrans'),
          const SizedBox(height: 8),
          _buildPaymentChoiceTile('transfer', '🏦 Transfer Bank (Virtual Account)', 'BCA, BNI, BRI, Mandiri via Midtrans Snap'),
          const SizedBox(height: 20),

          // --- 7. TOTAL & TOMBOL BUAT TIKET ---
          if (_couponApplied) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(rupiah(widget.state.totalPrice), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Diskon Kupon ($_couponCode):', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('-${rupiah(_discountAmount)}', style: TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran:', style: TextStyle(color: Colors.white, fontSize: 13)),
              Flexible(
                child: Text(
                  rupiah(_payTotal),
                  style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (busy || !widget.state.isOperatingHours) ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.white54,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text(
                busy
                    ? 'Memproses...'
                    : (!widget.state.isOperatingHours
                        ? 'Tutup (Buka 17:30 – 21:30 WIB)'
                        : (selectedPaymentMethod == 'cash'
                            ? 'Buat Tiket (Bayar di Kasir)'
                            : 'Lanjut ke Pembayaran Midtrans')),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
        ),
      ),
    );
  }

  Widget _buildPaymentChoiceTile(String code, String title, String subtitle) {
    final isSelected = selectedPaymentMethod == code;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE69616).withValues(alpha: 0.15) : brown2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFE69616) : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFE69616) : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: muted, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFE69616) : muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // Dekorasi input seragam (termasuk tampilan pesan error validasi)
  InputDecoration _inputDecoration(String hint) {
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: brown2,
      counterStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(gold),
      errorBorder: outline(Colors.redAccent),
      focusedErrorBorder: outline(Colors.redAccent),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  Widget _buildDateCard(String label, String iso) {
    bool isSelected = selectedDate == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedDate = label;
            selectedIsoDate = iso;
          });
          fetchQueueEstimate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE69616) : brown2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFE69616) : border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiQueueCard() {
    if (queueEstimate == null && !loadingQueue) return const SizedBox.shrink();

    final crowdLevel = queueEstimate?['crowd_level'] ?? 'Ramai Lancar';
    final estWait = queueEstimate?['estimated_wait'] ?? '~8 - 12 Mnt';
    final crowdColorStr = queueEstimate?['crowd_color'] ?? 'gold';
    final tips = queueEstimate?['tips'] ?? 'Pesanan Anda disiapkan hangat dan segar saat jam pengambilan.';
    final peakPercent = (queueEstimate?['peak_percentage'] as num?)?.toDouble() ?? 60.0;
    final confidence = queueEstimate?['confidence_score'] ?? '96% Akurasi Prediksi AI';

    Color statusColor = gold;
    if (crowdColorStr == 'green') statusColor = const Color(0xFF4CAF50);
    if (crowdColorStr == 'orange') statusColor = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brown2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 14,
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
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, color: statusColor, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Smart Queue Estimator',
                  style: TextStyle(
                    color: cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    confidence,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimasi Waktu Tunggu:', style: TextStyle(color: muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: gold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        estWait,
                        style: const TextStyle(
                          color: cream,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      crowdLevel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tingkat Kepadatan Gerai', style: TextStyle(color: muted, fontSize: 10)),
                  Text('${peakPercent.toInt()}%', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: peakPercent / 100,
                  backgroundColor: brown,
                  color: statusColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brown,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: gold, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tips,
                    style: const TextStyle(color: muted, fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}