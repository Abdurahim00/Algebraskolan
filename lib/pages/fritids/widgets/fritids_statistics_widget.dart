import 'package:flutter/material.dart';
import '../../../domain/usecases/fritids/get_fritids_statistics_usecase.dart';

class FritidsStatisticsWidget extends StatelessWidget {
  final FritidsStatistics statistics;

  const FritidsStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(245, 142, 11, 1),
            Color.fromRGBO(255, 182, 71, 1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Statistik',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Total row
          _buildStatRow(
            'Totalt',
            statistics.totalRegistrations,
            statistics.totalAlgebronor,
            isTotal: true,
          ),
          const Divider(color: Colors.white54, height: 24),
          // Group breakdown
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      '☀️ Solen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatItem('FM', statistics.solenFmCount),
                    const SizedBox(height: 4),
                    _buildStatItem('EM', statistics.solenEmCount),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: Colors.white54,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      '🌊 Havet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatItem('FM', statistics.havetFmCount),
                    const SizedBox(height: 4),
                    _buildStatItem('EM', statistics.havetEmCount),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, int algebronor,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$count registreringar',
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$algebronor algebronor',
              style: TextStyle(
                fontSize: isTotal ? 14 : 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
