import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../config/constants.dart';
import '../services/api_service.dart';

class VisitorDayStat {
  final String shortDay; // contoh: 'Sen'
  final String label; // contoh: 'Senin'
  final int count;

  VisitorDayStat({
    required this.shortDay,
    required this.label,
    required this.count,
  });

  /// Sesuaikan mapping ini dengan struktur JSON dari backend Anda
  factory VisitorDayStat.fromJson(Map<String, dynamic> json) {
    return VisitorDayStat(
      shortDay: json['short_day'] ?? json['day'] ?? '',
      label: json['label'] ?? json['nama_hari'] ?? '',
      count: int.tryParse('${json['count'] ?? json['total'] ?? 0}') ?? 0,
    );
  }
}

class AdminVisitorStatsPage extends StatelessWidget {
  const AdminVisitorStatsPage({Key? key}) : super(key: key);

  Future<List<VisitorDayStat>> _fetchWeeklyVisitors() async {
    final res = await ApiService.get(
      AppConstants.visitorStatsWeeklyEndpoint,
      needsAuth: true,
    );

    if (res['status'] == true || res['status'] == 200) {
      final rawData = res['data'] ?? res['result'];

      List<dynamic> rows;
      if (rawData is Map && rawData['data'] is List) {
        // Bentuk: { data: [ ... ], pagination: {...} }
        rows = rawData['data'] as List;
      } else if (rawData is List) {
        // Bentuk: [ ... ]
        rows = rawData;
      } else {
        rows = const [];
      }

      if (rows.isEmpty) return [];

      // Hitung statistik per hari (Senin–Minggu) untuk 7 hari terakhir
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 6));

      // key: weekday (1=Mon .. 7=Sun), value: count
      final Map<int, int> countsPerWeekday = {
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
        6: 0,
        7: 0,
      };

      for (final row in rows) {
        if (row is! Map) continue;
        final checkInStr = row['check_in'] as String?;
        if (checkInStr == null || checkInStr.isEmpty) continue;

        DateTime? checkIn;
        try {
          checkIn = DateTime.parse(checkInStr);
        } catch (_) {
          // Jika format tidak standar, biarkan saja baris ini
          continue;
        }

        // Ambil tanggal saja (tanpa jam)
        final dateOnly = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final startOnly =
            DateTime(startDate.year, startDate.month, startDate.day);
        final endOnly = DateTime(now.year, now.month, now.day);

        if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
          continue; // di luar 7 hari terakhir
        }

        final weekday = dateOnly.weekday; // 1=Mon .. 7=Sun
        countsPerWeekday[weekday] = (countsPerWeekday[weekday] ?? 0) + 1;
      }

      const shortNames = {
        1: 'Sen',
        2: 'Sel',
        3: 'Rab',
        4: 'Kam',
        5: 'Jum',
        6: 'Sab',
        7: 'Min',
      };

      const fullNames = {
        1: 'Senin',
        2: 'Selasa',
        3: 'Rabu',
        4: 'Kamis',
        5: 'Jumat',
        6: 'Sabtu',
        7: 'Minggu',
      };

      final List<VisitorDayStat> result = [];
      for (var i = 1; i <= 7; i++) {
        result.add(
          VisitorDayStat(
            shortDay: shortNames[i] ?? '',
            label: fullNames[i] ?? '',
            count: countsPerWeekday[i] ?? 0,
          ),
        );
      }

      return result;
    } else {
      final message = res['message'] ?? 'Gagal memuat data statistik';
      throw Exception(message);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Pengunjung'),
      ),
      body: Container(
        decoration: AppDecorations.primaryGradient,
        child: SafeArea(
          child: FutureBuilder<List<VisitorDayStat>>(
            future: _fetchWeeklyVisitors(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat statistik',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snapshot.data ?? [];

              if (data.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Belum ada data pengunjung untuk 7 hari terakhir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              final maxCount = data
                  .map((e) => e.count)
                  .fold<int>(0, (prev, el) => el > prev ? el : prev);

              final total =
                  data.fold<int>(0, (sum, e) => sum + (e.count));
              final average = total / (data.isEmpty ? 1 : data.length);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Statistik 7 Hari Terakhir',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                'Ringkasan pengunjung komplek selama seminggu',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSummaryCards(
                              total,
                              average.round(),
                              maxCount,
                            ),
                            const SizedBox(height: 20),
                            _buildBarChart(data, maxCount),
                            const SizedBox(height: 20),
                            _buildDetailList(data),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(int total, int avg, int max) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Mingguan',
            value: '$total',
            icon: Icons.group_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Rata-rata / Hari',
            value: '$avg',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Hari Tersibuk',
            value: '$max',
            icon: Icons.star_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<VisitorDayStat> data, int maxCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Kunjungan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Perbandingan jumlah pengunjung per hari',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final count = item.count;
                final ratio =
                    maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 140 * ratio,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.shortDay,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailList(List<VisitorDayStat> data) {
    return Container(
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Detail Per Hari',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ringkasan jumlah pengunjung tiap hari dalam seminggu',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ...data.map(
            (item) => _DayDetailTile(
              label: item.label,
              count: item.count,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

class _DayDetailTile extends StatelessWidget {
  final String label;
  final int count;

  const _DayDetailTile({
    Key? key,
    required this.label,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}


