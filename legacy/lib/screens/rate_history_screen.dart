import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/cred_theme.dart';
import '../services/market_rates_service.dart';

class RateHistoryScreen extends StatefulWidget {
  const RateHistoryScreen({super.key});

  @override
  State<RateHistoryScreen> createState() => _RateHistoryScreenState();
}

class _RateHistoryScreenState extends State<RateHistoryScreen> {
  final MarketRatesService _ratesService = MarketRatesService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _lastFetchDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    final history = await _ratesService.getRateHistory();
    final lastFetch = await _ratesService.getLastFetchDate();
    
    setState(() {
      _history = history;
      _lastFetchDate = lastFetch;
      _isLoading = false;
    });
  }

  Future<void> _refreshRates() async {
    setState(() => _isLoading = true);
    
    try {
      await _ratesService.refreshRates();
      await _loadHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rates refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _exportAsJson() async {
    final json = await _ratesService.exportHistoryAsJson();
    await Clipboard.setData(ClipboardData(text: json));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 JSON copied to clipboard'),
          backgroundColor: CredTheme.goldJewellery,
        ),
      );
    }
  }

  Future<void> _exportAsCsv() async {
    final csv = await _ratesService.exportHistoryAsCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 CSV copied to clipboard'),
          backgroundColor: CredTheme.goldJewellery,
        ),
      );
    }
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CredTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Export Rate History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CredTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildExportOption(
              icon: Icons.code,
              title: 'Export as JSON',
              subtitle: 'Structured data format',
              onTap: () {
                Navigator.pop(context);
                _exportAsJson();
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.table_chart,
              title: 'Export as CSV',
              subtitle: 'Open in Excel/Sheets',
              onTap: () {
                Navigator.pop(context);
                _exportAsCsv();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CredTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CredTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CredTheme.goldJewellery.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: CredTheme.goldJewellery),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CredTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CredTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CredTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CredTheme.background,
      appBar: AppBar(
        backgroundColor: CredTheme.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CredTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gold Rate History',
          style: TextStyle(
            color: CredTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: CredTheme.goldJewellery),
            onPressed: _refreshRates,
            tooltip: 'Refresh rates now',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: CredTheme.goldJewellery),
            onPressed: _history.isEmpty ? null : _showExportDialog,
            tooltip: 'Export history',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CredTheme.goldJewellery),
            )
          : Column(
              children: [
                // Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CredTheme.goldJewellery.withOpacity(0.2),
                        CredTheme.goldJewellery.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CredTheme.goldJewellery.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CredTheme.goldJewellery.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: CredTheme.goldJewellery,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Rates @ 10:30 AM IST',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: CredTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lastFetchDate != null
                                  ? 'Last fetch: $_lastFetchDate'
                                  : 'No rates fetched yet',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CredTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${_history.length} days recorded',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CredTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: CredTheme.cardBackground,
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CredTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '24K',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CredTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '22K',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CredTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '18K',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CredTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '14K',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CredTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1, color: CredTheme.divider),
                
                // Rate List
                Expanded(
                  child: _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: CredTheme.textTertiary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No rate history yet',
                                style: TextStyle(
                                  color: CredTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Rates will be recorded daily at 10:30 AM IST',
                                style: TextStyle(
                                  color: CredTheme.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _refreshRates,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Fetch Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CredTheme.goldJewellery,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: CredTheme.divider,
                          ),
                          itemBuilder: (context, index) {
                            final entry = _history[index];
                            final isToday = entry['date'] == _lastFetchDate;
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              color: isToday
                                  ? CredTheme.goldJewellery.withOpacity(0.05)
                                  : null,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Text(
                                          entry['date'] ?? '-',
                                          style: TextStyle(
                                            color: isToday
                                                ? CredTheme.goldJewellery
                                                : CredTheme.textPrimary,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (isToday) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CredTheme.goldJewellery,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'TODAY',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₹${entry['24kt']}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: CredTheme.textPrimary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₹${entry['22kt']}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: CredTheme.textPrimary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₹${entry['18kt']}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: CredTheme.textPrimary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₹${entry['14kt']}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: CredTheme.textPrimary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
