import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gold_jewellery_investment.dart';
import '../services/gold_jewellery_repository.dart';
import '../services/json_storage_service.dart';
import '../services/market_rates_service.dart';
import '../utils/cred_theme.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;
  final String title;
  final Color color;
  final IconData icon;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final JsonStorageService _storageService = JsonStorageService();
  final MarketRatesService _marketRates = MarketRatesService();
  List<Map<String, dynamic>> _investments = [];
  Map<String, double> _currentValues = {};
  bool _isLoading = true;
  double _totalInvested = 0;
  double _totalCurrentValue = 0;
  late final GoldJewelleryRepository _goldRepo;

  @override
  void initState() {
    super.initState();
    _goldRepo = GoldJewelleryRepository(_storageService);
    _loadInvestments();
  }

  Future<void> _loadInvestments() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> investments;
      if (widget.category == 'gold_jewellery') {
        final gold = await _goldRepo.getAll();
        investments = gold.map((g) => g.toJson()).toList();
      } else {
        investments = await _storageService.getInvestmentsByCategory(widget.category);
      }
      double totalInvested = 0;
      double totalCurrentValue = 0;
      Map<String, double> currentValues = {};
      
      for (final inv in investments) {
        // Get invested amount
        final invested = (inv['totalAmountPaid'] ?? inv['finalAmount'] ?? 0).toDouble();
        totalInvested += invested;
        
        // Calculate current value based on weight and rates
        final weight = _getWeight(inv);
        final purity = inv['purityKarat'] != null
            ? '${inv['purityKarat']}K'
            : (inv['purity']?.toString() ?? '22K');
        final metalType = inv['metalType']?.toString() ?? 'Gold';
        
        // Extract diamond data
        final diamondCarats = _getNumber(inv, 'diamondCarats');
        final diamondClarity = inv['diamondClarity']?.toString();
        final diamondCost = _getNumber(inv, 'diamondCost');
        
        if (_isPreciousMetalCategory()) {
          final currentValue = await _marketRates.calculateCurrentValue(
            weight: weight,
            purity: purity,
            metalType: metalType,
            category: widget.category,
            diamondCarats: diamondCarats,
            diamondClarity: diamondClarity,
            diamondPurchaseValue: diamondCost,
          );
          currentValues[inv['id']] = currentValue;
          totalCurrentValue += currentValue;
        } else {
          currentValues[inv['id']] = invested;
          totalCurrentValue += invested;
        }
      }
      
      setState(() {
        _investments = investments;
        _currentValues = currentValues;
        _totalInvested = totalInvested;
        _totalCurrentValue = totalCurrentValue;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading investments: $e');
      setState(() => _isLoading = false);
    }
  }
  
  bool _isPreciousMetalCategory() {
    return ['gold_jewellery', 'diamond_jewellery', 'silver', 'bullion', 'digital_gold', 'sgb']
        .contains(widget.category);
  }
  
  double _getWeight(Map<String, dynamic> inv) {
    for (final key in ['netWeight', 'weight', 'grossWeight']) {
      if (inv.containsKey(key) && inv[key] != null) {
        final weight = inv[key];
        if (weight is num) return weight.toDouble();
        if (weight is String) return double.tryParse(weight) ?? 0;
      }
    }
    return 0;
  }
  
  double? _getNumber(Map<String, dynamic> inv, String key) {
    if (!inv.containsKey(key) || inv[key] == null) return null;
    final value = inv[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _deleteInvestment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: const Text('Are you sure you want to delete this investment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deleteInvestment(id, widget.category);
      _loadInvestments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investment deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CredTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: CredTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title.toLowerCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CredTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CredTheme.gold))
          : _investments.isEmpty
              ? _buildEmptyState()
              : _buildInvestmentList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              widget.icon,
              size: 48,
              color: widget.color.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'no ${widget.title.toLowerCase()} yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CredTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'add your first investment to get started',
            style: TextStyle(
              fontSize: 14,
              color: CredTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentList() {
    final change = _totalCurrentValue - _totalInvested;
    final changePercent = _totalInvested > 0 
        ? ((change) / _totalInvested) * 100 
        : 0.0;
    final isProfit = change >= 0;
    
    return Column(
      children: [
        // Summary Card with Invested, Current, Change
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CredTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Current Value (Main)
              Text(
                'Current Value',
                style: TextStyle(
                  fontSize: 12,
                  color: CredTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatAmount(_totalCurrentValue),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              if (_totalInvested > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 16,
                      color: isProfit ? CredTheme.success : CredTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isProfit ? '+' : ''}${_formatAmount(change)} (${changePercent.abs().toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isProfit ? CredTheme.success : CredTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(height: 1, color: CredTheme.cardBorder),
              const SizedBox(height: 16),
              // Invested and Items row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Invested',
                        style: TextStyle(fontSize: 11, color: CredTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(_totalInvested),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CredTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 32, color: CredTheme.cardBorder),
                  Column(
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(fontSize: 11, color: CredTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_investments.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CredTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Investment List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInvestments,
            color: CredTheme.gold,
            backgroundColor: CredTheme.cardDark,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _investments.length,
              itemBuilder: (context, index) {
                final investment = _investments[index];
                return _buildInvestmentCard(investment);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentCard(Map<String, dynamic> investment) {
    final productType = investment['productType'] ?? 'Unknown';
    final vendor = investment['vendor'] ?? 'Unknown Vendor';
    final weight = investment['weight'] ?? investment['netWeight'];
    final purity = investment['purity'] ?? '';
    final invested = (investment['finalAmount'] ?? 0).toDouble();
    final currentValue = _currentValues[investment['id']] ?? invested;
    final change = currentValue - invested;
    final changePercent = invested > 0 ? (change / invested) * 100 : 0.0;
    final isProfit = change >= 0;
    final date = _formatDate(investment['date']);
    final billNumber = investment['billNumber'] ?? '';
    final id = investment['id'] ?? '';

    return GestureDetector(
      onTap: () => _showInvestmentDetails(investment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CredTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CredTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProductIcon(productType),
                          color: widget.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productType,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: CredTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vendor,
                              style: const TextStyle(
                                color: CredTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: CredTheme.textMuted, size: 20),
                  color: CredTheme.cardLight,
                  onSelected: (value) {
                    if (value == 'delete') {
                      HapticFeedback.mediumImpact();
                      _deleteInvestment(id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: CredTheme.error, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: CredTheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: CredTheme.cardBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailChip('${weight}g', Icons.scale_outlined),
                _buildDetailChip(purity, Icons.verified_outlined),
                if (date.isNotEmpty) _buildDetailChip(date, Icons.calendar_today_outlined),
              ],
            ),
            const SizedBox(height: 16),
            // Price section with Invested, Current, Change
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CredTheme.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Invested
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invested',
                          style: TextStyle(fontSize: 10, color: CredTheme.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${invested.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CredTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Current',
                          style: TextStyle(fontSize: 10, color: CredTheme.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${currentValue.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Change
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Returns',
                          style: TextStyle(fontSize: 10, color: CredTheme.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isProfit ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isProfit ? CredTheme.success : CredTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CredTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CredTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CredTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'ring':
        return Icons.radio_button_checked_outlined;
      case 'chain':
        return Icons.link_rounded;
      case 'necklace':
        return Icons.auto_awesome_outlined;
      case 'earrings':
        return Icons.earbuds_outlined;
      case 'bangle':
        return Icons.circle_outlined;
      case 'bracelet':
        return Icons.watch_outlined;
      case 'pendant':
        return Icons.favorite_outline_rounded;
      case 'coin':
        return Icons.monetization_on_outlined;
      case 'bar':
        return Icons.rectangle_outlined;
      default:
        return Icons.diamond_outlined;
    }
  }

  void _showInvestmentDetails(Map<String, dynamic> investment) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: CredTheme.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CredTheme.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getProductIcon(investment['productType'] ?? ''),
                        color: widget.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investment['productType'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: CredTheme.textPrimary,
                            ),
                          ),
                          Text(
                            investment['vendor'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: CredTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: CredTheme.cardBorder),
                const SizedBox(height: 16),
                _buildDetailRow('Net Weight', '${investment['weight'] ?? investment['netWeight'] ?? '-'} grams'),
                if (investment['grossWeight'] != null)
                  _buildDetailRow('Gross Weight', '${investment['grossWeight']} grams'),
                _buildDetailRow('Purity', investment['purity'] ?? '-'),
                _buildDetailRow('Metal Type', investment['metalType'] ?? 'Gold'),
                _buildDetailRow('Purchase Price', '₹${(investment['finalAmount'] ?? 0).toStringAsFixed(0)}'),
                if (investment['billNumber'] != null)
                  _buildDetailRow('Bill Number', investment['billNumber']),
                if (investment['date'] != null)
                  _buildDetailRow('Purchase Date', _formatDate(investment['date'])),
                if (investment['stoneWeight'] != null)
                  _buildDetailRow('Stone Weight', '${investment['stoneWeight']} grams'),
                if (investment['diamondWeight'] != null)
                  _buildDetailRow('Diamond Weight', '${investment['diamondWeight']} grams'),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toLowerCase(),
            style: const TextStyle(
              fontSize: 14,
              color: CredTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CredTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
