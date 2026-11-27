import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/app_state.dart';
import '../../../../widgets/app_card.dart';
import '../viewmodels/ai_insight_view_model.dart';

class AiInsightView extends StatefulWidget {
  final AppState appState;
  final AiInsightViewModel? viewModel;

  const AiInsightView({
    super.key,
    required this.appState,
    this.viewModel,
  });

  @override
  State<AiInsightView> createState() => _AiInsightViewState();
}

class _AiInsightViewState extends State<AiInsightView> {
  late final AiInsightViewModel _viewModel;
  late final bool _ownsViewModel;

  final List<String> _slots = const [
    '16:00 - 16:30',
    '16:30 - 17:00',
    '17:00 - 17:30',
    '18:00 - 18:30',
    '18:30 - 19:00',
  ];

  String _selectedSlot = '17:00 - 17:30';

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? getIt<AiInsightViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadVerifiedInsight();
      _viewModel.analyzeQueueWithGps(
        timeSlot: _selectedSlot,
        token: widget.appState.jwtToken,
      );
    });
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _addRecommendedItemsToCart(Map<String, dynamic>? menuInsight) {
    final items = menuInsight?['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return;

    int added = 0;
    for (final it in items) {
      final id = it['id']?.toString() ?? '';
      final name = (it['nama'] ?? it['name'] ?? '').toString().toLowerCase();
      final qty = int.tryParse('${it['qty']}') ?? 1;

      final match = widget.appState.menu.cast<dynamic>().firstWhere(
            (m) =>
                m.id == id ||
                m.name.toString().toLowerCase().contains(name) ||
                name.contains(m.name.toString().toLowerCase()),
            orElse: () => widget.appState.menu.isNotEmpty
                ? widget.appState.menu.first
                : null,
          );

      if (match != null) {
        for (int i = 0; i < qty; i++) {
          widget.appState.add(match);
        }
        added += qty;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('$added porsi paket rekomendasi AI ditambahkan ke keranjang.'),
        backgroundColor: green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final verified = _viewModel.verifiedInsight;

        Color statusColor = gold;
        if (verified?.crowdColor == 'green') {
          statusColor = const Color(0xFF4CAF50);
        }
        if (verified?.crowdColor == 'orange') statusColor = Colors.orangeAccent;

        return Scaffold(
          backgroundColor: brown,
          appBar: AppBar(
            backgroundColor: brown2,
            foregroundColor: cream,
            title: const Text(
              'Insight AI & Antrean Cerdas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: _viewModel.loadVerifiedInsight,
                icon: const Icon(Icons.refresh, color: gold),
                tooltip: 'Sinkronkan Status Verifikasi',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_viewModel.errorMessage != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _viewModel.errorMessage!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],

              // --- 1. INPUT PERANGKAT KERAS: GPS GEOLOCATOR ---
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.my_location, color: gold, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Input Cepat Lokasi (Hardware GPS)',
                            style: TextStyle(
                                color: cream,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _viewModel.locationResult != null
                          ? 'Jarak Anda ke Gerai Celaket: ${_viewModel.locationResult!.distanceKm} km (${_viewModel.locationResult!.latitude.toStringAsFixed(4)}, ${_viewModel.locationResult!.longitude.toStringAsFixed(4)})'
                          : 'Aktifkan GPS perangkat untuk mengukur jarak otomatis ke dapur Puthu Lanang Malang.',
                      style: TextStyle(
                        color: _viewModel.locationResult != null ? gold : muted,
                        fontSize: 12,
                      ),
                    ),
                    if (_viewModel.gpsError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Info GPS: ${_viewModel.gpsError} (menggunakan koordinat default gerai)',
                        style: const TextStyle(
                            color: Colors.orangeAccent, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slots.map((slot) {
                        final isSelected = slot == _selectedSlot;
                        return ChoiceChip(
                          label:
                              Text(slot, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          selectedColor: green,
                          backgroundColor: brown,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : muted,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedSlot = slot);
                            _viewModel.analyzeQueueWithGps(
                              timeSlot: slot,
                              token: widget.appState.jwtToken,
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _viewModel.isLoadingGps
                            ? null
                            : () => _viewModel.analyzeQueueWithGps(
                                  timeSlot: _selectedSlot,
                                  token: widget.appState.jwtToken,
                                ),
                        icon: const Icon(Icons.gps_fixed, size: 18),
                        label: Text(
                          _viewModel.isLoadingGps
                              ? 'Mengkalkulasi GPS & AI...'
                              : 'Ambil Lokasi GPS & Cek Antrean',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // --- 2. BANNER STATUS AUDIT (JIKA MASIH PENDING DI WEB ADMIN) ---
              if (_viewModel.isPendingAudit) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gold.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.pending_actions, color: gold, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimasi Baru Menunggu Verifikasi Web Admin',
                              style: TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kalkulasi GPS Anda telah dicatat di database. Sesuai arsitektur, aplikasi hanya menampilkan insight resmi yang disetujui Manajer.',
                              style: TextStyle(
                                  color: cream, fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // --- 3. TAMPILAN HASIL AI KHUSUS YANG TELAH TERVALIDASI MANAJER ---
              if (verified != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brown2,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.55), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              color: Color(0xFF81C784), size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Insight Antrean Tervalidasi',
                              style: TextStyle(
                                  color: cream,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Disetujui Manajer',
                              style: TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Perkiraan Tunggu Resmi',
                                  style: TextStyle(color: muted, fontSize: 11)),
                              Text(
                                verified.estimatedWait,
                                style: const TextStyle(
                                    color: cream,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              verified.crowdLevel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(verified.confidenceScore,
                              style:
                                  const TextStyle(color: muted, fontSize: 11)),
                          Text('${verified.peakPercentage}% Padat',
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (verified.peakPercentage / 100).clamp(0.0, 1.0),
                          backgroundColor: brown,
                          color: statusColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: brown,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                color: gold, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                verified.tips,
                                style: const TextStyle(
                                    color: muted, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (verified.verificationNotes != null &&
                          verified.verificationNotes!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: green.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.shield_outlined,
                                  color: Color(0xFF81C784), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Catatan Audit Manajer: ${verified.verificationNotes}',
                                  style: const TextStyle(
                                      color: cream, fontSize: 11, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brown2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: muted, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Belum ada hasil estimasi yang disetujui Manajer untuk gerai Celaket saat ini. Notifikasi akan masuk otomatis begitu data diverifikasi di Web Admin.',
                          style: TextStyle(
                              color: muted, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // --- 4. KURASI REKOMENDASI MENU AI ---
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kurasi Rekomendasi Menu AI',
                      style: TextStyle(
                          color: cream,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih selera Anda untuk memperoleh kurasi paket kuliner warisan dari Gemini AI:',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Hampers Besek'),
                          onPressed: () => _viewModel.loadMenuRecommendation(
                            preference: 'hampers besek oleh-oleh',
                            token: widget.appState.jwtToken,
                          ),
                        ),
                        ActionChip(
                          label: const Text('Manis Legit Aren'),
                          onPressed: () => _viewModel.loadMenuRecommendation(
                            preference: 'manis gula aren legit',
                            token: widget.appState.jwtToken,
                          ),
                        ),
                        ActionChip(
                          label: const Text('Keluarga Ramai'),
                          onPressed: () => _viewModel.loadMenuRecommendation(
                            preference: 'paket keluarga porsi rame',
                            token: widget.appState.jwtToken,
                          ),
                        ),
                      ],
                    ),
                    if (_viewModel.isLoadingMenu) ...[
                      const SizedBox(height: 12),
                      const Center(
                          child: CircularProgressIndicator(color: gold)),
                    ] else if (_viewModel.menuInsight != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: brown,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: gold.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _viewModel.menuInsight!['recommendation_title']
                                      ?.toString() ??
                                  'Paket Rekomendasi',
                              style: const TextStyle(
                                  color: cream,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _viewModel.menuInsight!['reason']?.toString() ??
                                  '',
                              style:
                                  const TextStyle(color: muted, fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _addRecommendedItemsToCart(
                                    _viewModel.menuInsight),
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 16),
                                label: const Text('Tambah ke Keranjang',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: gold,
                                    foregroundColor: brown),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
