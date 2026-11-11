import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../widgets/app_card.dart';

class AiInsightPage extends StatefulWidget {
  final AppState state;

  const AiInsightPage({super.key, required this.state});

  @override
  State<AiInsightPage> createState() => _AiInsightPageState();
}

class _AiInsightPageState extends State<AiInsightPage> {
  final List<String> _slots = const [
    '16:00 - 16:30',
    '16:30 - 17:00',
    '17:00 - 17:30',
    '18:00 - 18:30',
    '18:30 - 19:00',
  ];

  String _selectedSlot = '17:00 - 17:30';
  LocationResult? _locationResult;
  Map<String, dynamic>? _queueInsight;
  Map<String, dynamic>? _menuInsight;
  String? _gpsError;
  bool _loadingQueue = false;
  bool _loadingMenu = false;

  @override
  void initState() {
    super.initState();
    _analyzeQueueWithGps();
  }

  Future<void> _analyzeQueueWithGps() async {
    setState(() {
      _loadingQueue = true;
      _gpsError = null;
    });

    double? distanceKm = _locationResult?.distanceKm;
    try {
      final loc = await LocationService.getCurrentLocationToOutlet();
      _locationResult = loc;
      distanceKm = loc.distanceKm;
    } catch (e) {
      _gpsError = e.toString().replaceFirst('Exception: ', '');
    }

    final result = await ApiService.getAiQueueEstimate(
      outlet: 'Gerai Pusat Celaket',
      day: 'Hari Ini',
      timeSlot: _selectedSlot,
      token: widget.state.jwtToken,
      distanceKm: distanceKm,
    );

    if (mounted) {
      setState(() {
        _queueInsight = result;
        _loadingQueue = false;
      });
    }
  }

  Future<void> _fetchMenuInsight(String preference) async {
    setState(() => _loadingMenu = true);
    final res = await ApiService.getAiRecommendation(
      preference: preference,
      token: widget.state.jwtToken,
    );
    if (mounted) {
      setState(() {
        _menuInsight = res;
        _loadingMenu = false;
      });
    }
  }

  void _addRecommendedItemsToCart() {
    final items = _menuInsight?['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return;

    int added = 0;
    for (final it in items) {
      final id = it['id']?.toString() ?? '';
      final name = (it['nama'] ?? it['name'] ?? '').toString().toLowerCase();
      final qty = int.tryParse('${it['qty']}') ?? 1;

      final match = widget.state.menu.cast<dynamic>().firstWhere(
            (m) =>
                m.id == id ||
                m.name.toString().toLowerCase().contains(name) ||
                name.contains(m.name.toString().toLowerCase()),
            orElse: () => widget.state.menu.isNotEmpty ? widget.state.menu.first : null,
          );

      if (match != null) {
        for (int i = 0; i < qty; i++) {
          widget.state.add(match);
        }
        added += qty;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$added porsi rekomendasi AI ditambahkan ke keranjang.'),
        backgroundColor: green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crowdLevel = _queueInsight?['crowd_level']?.toString() ?? '-';
    final estWait = _queueInsight?['estimated_wait']?.toString() ?? '-';
    final crowdColorStr = _queueInsight?['crowd_color']?.toString() ?? 'gold';
    final tips = _queueInsight?['tips']?.toString() ?? '';
    final confidence = _queueInsight?['confidence_score']?.toString() ?? 'Gemini AI';
    final verification = _queueInsight?['verification_status']?.toString() ?? 'pending';
    final peakPct = (_queueInsight?['peak_percentage'] as num?)?.toDouble() ?? 60.0;

    Color statusColor = gold;
    if (crowdColorStr == 'green') statusColor = const Color(0xFF4CAF50);
    if (crowdColorStr == 'orange') statusColor = Colors.orangeAccent;

    return Scaffold(
      backgroundColor: brown,
      appBar: AppBar(
        backgroundColor: brown2,
        foregroundColor: cream,
        title: const Text(
          'Insight & Rekomendasi AI',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- INPUT CEPAT HARDWARE GPS ---
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.my_location, color: gold, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Input Cepat Lokasi (GPS Perangkat)',
                        style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _locationResult != null
                      ? 'Jarak Anda ke Gerai Celaket: ${_locationResult!.distanceKm} km (${_locationResult!.latitude.toStringAsFixed(4)}, ${_locationResult!.longitude.toStringAsFixed(4)})'
                      : 'Gunakan GPS perangkat untuk mengukur jarak cepat ke Gerai Celaket Malang.',
                  style: TextStyle(
                    color: _locationResult != null ? gold : muted,
                    fontSize: 12,
                  ),
                ),
                if (_gpsError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Info GPS: $_gpsError (menggunakan estimasi default gerai)',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final selected = slot == _selectedSlot;
                    return ChoiceChip(
                      label: Text(slot, style: const TextStyle(fontSize: 11)),
                      selected: selected,
                      selectedColor: green,
                      backgroundColor: brown,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : muted,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedSlot = slot);
                        _analyzeQueueWithGps();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadingQueue ? null : _analyzeQueueWithGps,
                    icon: const Icon(Icons.gps_fixed, size: 18),
                    label: Text(
                      _loadingQueue ? 'Memproses Gemini AI...' : 'Deteksi GPS & Analisis Antrean AI',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // --- HASIL INSIGHT ANTREAN AI ---
          if (_queueInsight != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: brown2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: statusColor.withValues(alpha: 0.55), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Insight Antrean Gemini AI',
                          style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: verification == 'verified'
                              ? green.withValues(alpha: 0.25)
                              : gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          verification == 'verified' ? 'Terverifikasi Manajer' : 'Menunggu Review',
                          style: TextStyle(
                            color: verification == 'verified' ? const Color(0xFF81C784) : gold,
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
                          const Text('Perkiraan Tunggu', style: TextStyle(color: muted, fontSize: 11)),
                          Text(
                            estWait,
                            style: const TextStyle(color: cream, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          crowdLevel,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(confidence, style: const TextStyle(color: muted, fontSize: 11)),
                      Text('${peakPct.toInt()}% Padat', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (peakPct / 100).clamp(0.0, 1.0),
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
                        const Icon(Icons.lightbulb_outline, color: gold, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tips,
                            style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // --- INSIGHT REKOMENDASI MENU AI ---
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kurasi Rekomendasi Menu AI',
                  style: TextStyle(color: cream, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih suasana santap Anda untuk mendapat rekomendasi paket terbaik dari Gemini AI:',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Hampers & Oleh-Oleh'),
                      backgroundColor: brown,
                      labelStyle: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold),
                      onPressed: _loadingMenu ? null : () => _fetchMenuInsight('hampers oleh oleh'),
                    ),
                    ActionChip(
                      label: const Text('Santap Keluarga'),
                      backgroundColor: brown,
                      labelStyle: const TextStyle(color: cream, fontSize: 11, fontWeight: FontWeight.bold),
                      onPressed: _loadingMenu ? null : () => _fetchMenuInsight('keluarga rame'),
                    ),
                    ActionChip(
                      label: const Text('Manis Gula Aren'),
                      backgroundColor: brown,
                      labelStyle: const TextStyle(color: cream, fontSize: 11, fontWeight: FontWeight.bold),
                      onPressed: _loadingMenu ? null : () => _fetchMenuInsight('manis gula aren'),
                    ),
                  ],
                ),
                if (_loadingMenu)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: gold)),
                  ),
                if (!_loadingMenu && _menuInsight != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: brown,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_menuInsight!['recommendation_title'] ?? ''}',
                          style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_menuInsight!['reason'] ?? ''}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addRecommendedItemsToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'Tambah Paket (${rupiah(int.tryParse('${_menuInsight!['total_estimated'] ?? 0}') ?? 0)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
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
  }
}

