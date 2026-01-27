import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/cred_theme.dart';
import '../services/json_storage_service.dart';
import 'smart_input_screen.dart';
import 'add_gold_jewellery_screen.dart';
import 'add_diamond_screen.dart';
import 'category_detail_screen.dart';
import 'rate_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final JsonStorageService _storageService = JsonStorageService();
  
  Map<String, double> _categoryTotals = {};
  Map<String, int> _categoryCounts = {};
  PortfolioSummary? _portfolioSummary;
  double _totalNetWorth = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  
  // Category definitions
  static const List<_CategoryGroup> _categoryGroups = [
    _CategoryGroup(
      title: 'Precious Metals & Jewellery',
      icon: Icons.diamond_outlined,
      categories: [
        _Category('Gold Jewellery', 'gold_jewellery', Icons.hexagon_outlined, CredTheme.goldJewellery, 'Chains, bangles, rings'),
        _Category('Diamond Jewellery', 'diamond_jewellery', Icons.diamond_outlined, CredTheme.diamondJewellery, 'Solitaires, diamond sets'),
        _Category('Silver', 'silver', Icons.blur_circular_outlined, CredTheme.silverCategory, 'Jewellery, utensils, pooja'),
        _Category('Bullion', 'bullion', Icons.toll_outlined, CredTheme.bullion, 'Gold/Silver coins & bars'),
        _Category('Digital Gold', 'digital_gold', Icons.bolt_outlined, CredTheme.digitalGold, 'PhonePe, Paytm, Google Pay'),
      ],
    ),
    _CategoryGroup(
      title: 'Market Investments',
      icon: Icons.trending_up_rounded,
      categories: [
        _Category('Mutual Funds', 'mutual_funds', Icons.pie_chart_outline_rounded, CredTheme.mutualFunds, 'SIPs, Equity, Debt, ELSS'),
        _Category('Stocks', 'stocks', Icons.candlestick_chart_outlined, CredTheme.stocks, 'Direct equity, IPOs'),
        _Category('Bonds', 'bonds', Icons.receipt_long_outlined, CredTheme.bonds, 'Govt & corporate bonds'),
        _Category('SGBs', 'sgb', Icons.military_tech_outlined, CredTheme.sgb, 'Sovereign Gold Bonds'),
        _Category('Cryptocurrency', 'crypto', Icons.currency_bitcoin_outlined, CredTheme.crypto, 'Bitcoin, Ethereum, Altcoins'),
      ],
    ),
    _CategoryGroup(
      title: 'Fixed Income',
      icon: Icons.account_balance_outlined,
      categories: [
        _Category('Fixed Deposits', 'fixed_deposits', Icons.savings_outlined, CredTheme.fixedDeposits, 'Bank FDs, RDs, Post Office'),
        _Category('Provident Fund', 'provident_fund', Icons.lock_outline_rounded, CredTheme.providentFund, 'PPF, EPF, VPF, NPS'),
      ],
    ),
    _CategoryGroup(
      title: 'Assets',
      icon: Icons.home_work_outlined,
      categories: [
        _Category('Real Estate', 'real_estate', Icons.apartment_outlined, CredTheme.realEstate, 'Property, Land, REITs'),
        _Category('Insurance', 'insurance', Icons.shield_outlined, CredTheme.insurance, 'LIC, ULIPs, Endowment'),
      ],
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadPortfolioData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPortfolioData() async {
    setState(() => _isLoading = true);
    
    try {
      final totals = await _storageService.getCategoryTotals();
      final counts = await _storageService.getCategoryCounts();
      final summary = await _storageService.getPortfolioSummary();
      double total = 0;
      totals.forEach((key, value) => total += value);
      
      setState(() {
        _categoryTotals = totals;
        _categoryCounts = counts;
        _portfolioSummary = summary;
        _totalNetWorth = total;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      print('Error loading portfolio: $e');
      setState(() => _isLoading = false);
    }
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
  
  double _getGroupTotal(List<_Category> categories) {
    double total = 0;
    for (final cat in categories) {
      total += _categoryTotals[cat.key] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CredTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPortfolioData,
          color: CredTheme.gold,
          backgroundColor: CredTheme.cardDark,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader()),
              
              // Net Worth Card
              SliverToBoxAdapter(child: _buildNetWorthCard()),
              
              // Quick Actions
              SliverToBoxAdapter(child: _buildQuickActions()),
              
              // Category Groups
              ..._categoryGroups.map((group) => SliverToBoxAdapter(
                child: _buildCategoryGroup(group),
              )),
              
              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 14,
                  color: CredTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Investment Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CredTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CredTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CredTheme.cardBorder),
                ),
                child: IconButton(
                  icon: const Icon(Icons.currency_rupee_rounded),
                  color: CredTheme.goldJewellery,
                  tooltip: 'Gold Rates',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RateHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: CredTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CredTheme.cardBorder),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: CredTheme.textSecondary,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard() {
    final summary = _portfolioSummary;
    final invested = summary?.totalInvested ?? 0;
    final currentValue = summary?.totalCurrentValue ?? 0;
    final change = summary?.totalChange ?? 0;
    final changePercent = summary?.totalChangePercent ?? 0;
    final isProfit = change >= 0;
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF141414)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CredTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [CredTheme.gold.withOpacity(0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Value (Main)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Value',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CredTheme.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      if (invested > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isProfit 
                                ? CredTheme.success.withOpacity(0.15) 
                                : CredTheme.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                                size: 12, 
                                color: isProfit ? CredTheme.success : CredTheme.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${changePercent.abs().toStringAsFixed(1)}%', 
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w600, 
                                  color: isProfit ? CredTheme.success : CredTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator(color: CredTheme.gold, strokeWidth: 2)),
                        )
                      : AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Text(
                              _formatAmount(currentValue * _animationController.value),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: CredTheme.textPrimary,
                                letterSpacing: -1,
                              ),
                            );
                          },
                        ),
                  
                  // Change Amount
                  if (invested > 0 && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${isProfit ? '+' : ''}${_formatAmount(change)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isProfit ? CredTheme.success : CredTheme.error,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  Container(height: 1, color: CredTheme.cardBorder),
                  const SizedBox(height: 16),
                  
                  // Invested vs Current breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _buildValueStat(
                          'Invested', 
                          _formatAmount(invested), 
                          CredTheme.textSecondary,
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: CredTheme.cardBorder,
                      ),
                      Expanded(
                        child: _buildValueStat(
                          'Returns', 
                          '${isProfit ? '+' : ''}${_formatAmount(change)}',
                          isProfit ? CredTheme.success : CredTheme.error,
                          isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildValueStat(String label, String value, Color valueColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: CredTheme.textMuted),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: CredTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildActionButton(Icons.camera_alt_outlined, 'Scan Bill', () => _addInvestment('scan'))),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton(Icons.mic_none_rounded, 'Voice', () => _addInvestment('voice'))),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton(Icons.edit_outlined, 'Manual', () => _addInvestment('text'))),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CredTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CredTheme.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: CredTheme.textSecondary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: CredTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(_CategoryGroup group) {
    // Calculate group totals from portfolio summary
    double groupInvested = 0;
    double groupCurrentValue = 0;
    for (final cat in group.categories) {
      final summary = _portfolioSummary?.categorySummaries[cat.key];
      groupInvested += summary?.invested ?? 0;
      groupCurrentValue += summary?.currentValue ?? 0;
    }
    final groupChange = groupCurrentValue - groupInvested;
    final hasValue = groupInvested > 0;
    final isProfit = groupChange >= 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(group.icon, size: 16, color: CredTheme.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CredTheme.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _formatAmount(groupCurrentValue),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? CredTheme.textPrimary : CredTheme.textMuted,
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${isProfit ? '+' : ''}${_formatAmount(groupChange)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isProfit ? CredTheme.success : CredTheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        ...group.categories.map((cat) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: _buildCategoryTile(cat),
        )),
      ],
    );
  }

  Widget _buildCategoryTile(_Category category) {
    final summary = _portfolioSummary?.categorySummaries[category.key];
    final invested = summary?.invested ?? 0;
    final currentValue = summary?.currentValue ?? 0;
    final change = summary?.change ?? 0;
    final changePercent = summary?.changePercent ?? 0;
    final count = summary?.itemCount ?? 0;
    final hasValue = invested > 0;
    final isProfit = change >= 0;
    
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              category: category.key,
              title: category.name,
              color: category.color,
              icon: category.icon,
            ),
          ),
        );
        _loadPortfolioData();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CredTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasValue ? category.color.withOpacity(0.3) : CredTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CredTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count > 0 ? '$count item${count > 1 ? 's' : ''}' : category.subtitle,
                    style: const TextStyle(fontSize: 12, color: CredTheme.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(currentValue),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasValue ? CredTheme.textPrimary : CredTheme.textMuted,
                  ),
                ),
                if (hasValue) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${isProfit ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isProfit ? CredTheme.success : CredTheme.error,
                    ),
                  ),
                ] else
                  const SizedBox(height: 4),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: CredTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: CredTheme.goldGradient,
        boxShadow: [
          BoxShadow(color: CredTheme.gold.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        backgroundColor: Colors.transparent,
        foregroundColor: CredTheme.background,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: CredTheme.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: CredTheme.cardBorder, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'add new investment',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CredTheme.textSecondary, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _categoryGroups.map((group) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Row(
                          children: [
                            Icon(group.icon, size: 14, color: CredTheme.textMuted),
                            const SizedBox(width: 8),
                            Text(
                              group.title,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CredTheme.textMuted, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      ...group.categories.map((cat) => _buildAddOption(cat)),
                    ],
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(_Category category) {
    return ListTile(
      onTap: () async {
        Navigator.pop(context);
        bool? result;
        if (category.key == 'gold_jewellery') {
          result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddGoldJewelleryScreen(),
            ),
          );
        } else {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SmartInputScreen(category: category.key, title: 'Add ${category.name}'),
            ),
          );
        }
        if (result == true) _loadPortfolioData();
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: category.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(category.icon, color: category.color, size: 20),
      ),
      title: Text(category.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: CredTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: CredTheme.textMuted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  void _addInvestment(String method) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartInputScreen(category: 'gold_jewellery', title: 'Add Investment', initialMethod: method),
      ),
    );
    if (result == true) _loadPortfolioData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good morning';
    if (hour < 17) return 'good afternoon';
    return 'good evening';
  }

  int _getTotalItems() {
    int total = 0;
    _categoryCounts.forEach((key, value) => total += value);
    return total;
  }
}

class _CategoryGroup {
  final String title;
  final IconData icon;
  final List<_Category> categories;
  
  const _CategoryGroup({required this.title, required this.icon, required this.categories});
}

class _Category {
  final String name;
  final String key;
  final IconData icon;
  final Color color;
  final String subtitle;
  
  const _Category(this.name, this.key, this.icon, this.color, this.subtitle);
}
