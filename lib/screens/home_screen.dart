import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPortfolio,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Worth Card
              _buildNetWorthCard(),
              const SizedBox(height: 20),
              
              // Today's Change
              _buildTodaysChangeCard(),
              const SizedBox(height: 24),
              
              // Category Breakdown
              const Text(
                'Portfolio Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                'Mutual Funds',
                Icons.trending_up,
                AppTheme.mutualFundColor,
                '₹0',
                '0%',
                true,
              ),
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                'Digital Gold',
                Icons.stars,
                AppTheme.digitalGoldColor,
                '₹0',
                '0%',
                true,
              ),
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                'Physical Gold',
                Icons.star,
                AppTheme.physicalGoldColor,
                '₹0',
                '0%',
                true,
              ),
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                'Diamond Jewellery',
                Icons.diamond,
                AppTheme.diamondColor,
                '₹0',
                '0%',
                true,
              ),
              const SizedBox(height: 12),
              
              _buildCategoryCard(
                'Precious Metals',
                Icons.currency_exchange,
                AppTheme.preciousMetalsColor,
                '₹0',
                '0%',
                true,
              ),
              
              const SizedBox(height: 24),
              
              // Gold Price Today
              _buildGoldPriceCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInvestmentMenu,
        icon: const Icon(Icons.add),
        label: const Text('Add Investment'),
      ),
    );
  }

  Widget _buildNetWorthCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Net Worth',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '₹0.00',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: ${DateTime.now().toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysChangeCard() {
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Change',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.arrow_upward,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹0.00 (0.00%)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color color,
    String amount,
    String returns,
    bool isPositive,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to category details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                    size: 24,
                  ),
                  Text(
                    returns,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldPriceCard() {
    return Card(
      color: AppTheme.digitalGoldColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.donut_small, color: AppTheme.digitalGoldColor),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gold Price Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '24K',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Text(
              '₹7,200/g',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.digitalGoldColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPortfolio() async {
    // TODO: Refresh portfolio data
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showAddInvestmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Investment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.trending_up, color: AppTheme.mutualFundColor),
              title: const Text('Mutual Fund'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Add MF screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Mutual Fund - Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.stars, color: AppTheme.digitalGoldColor),
              title: const Text('Digital Gold'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Add Digital Gold screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Digital Gold - Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: AppTheme.physicalGoldColor),
              title: const Text('Physical Gold'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Add Physical Gold screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Physical Gold - Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.diamond, color: AppTheme.diamondColor),
              title: const Text('Diamond Jewellery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Add Diamond Jewellery screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Diamond Jewellery - Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.currency_exchange, color: AppTheme.preciousMetalsColor),
              title: const Text('Precious Metals'),
              subtitle: const Text('Platinum, silver, copper'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Add Precious Metals screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Precious Metals - Coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
