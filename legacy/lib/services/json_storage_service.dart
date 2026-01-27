import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart' if (dart.library.html) 'package:investment_tracker/services/stub_path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'market_rates_service.dart';

/// JSON-based storage service for investments
/// Uses SharedPreferences for web, file system for mobile/desktop
class JsonStorageService {
    static const String _backupKey = 'investment_tracker_backup';
  static const String _investmentsDir = 'investments';
  static const String _webStoragePrefix = 'investment_tracker_';
  static const Uuid _uuid = Uuid();
  
  // Cache SharedPreferences instance
  static SharedPreferences? _prefsInstance;
  
  /// Get or create SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    _prefsInstance ??= await SharedPreferences.getInstance();
    return _prefsInstance!;
  }
  
  /// Force reload SharedPreferences (useful after hot restart)
  static Future<void> reloadPrefs() async {
    _prefsInstance = await SharedPreferences.getInstance();
    // On web, reload to get fresh data from localStorage
    if (kIsWeb) {
      await _prefsInstance!.reload();
    }
    print('🔄 SharedPreferences reloaded');
  }
  
  /// All investment categories
  static const List<String> allCategories = [
    // Precious Metals & Jewellery
    'gold_jewellery',
    'diamond_jewellery', 
    'silver',
    'bullion',
    'digital_gold',
    // Market Investments
    'mutual_funds',
    'stocks',
    'bonds',
    'sgb',
    'crypto',
    // Fixed Income
    'fixed_deposits',
    'provident_fund',
    // Assets
    'real_estate',
    'insurance',
  ];

  /// Get the investments directory path (for non-web platforms)
  Future<dynamic> get _investmentsDirectory async {
    if (kIsWeb) return null;
    final appDir = await getApplicationDocumentsDirectory();
    final investmentsPath = Directory('${appDir.path}/$_investmentsDir');

    if (!await investmentsPath.exists()) {
      await investmentsPath.create(recursive: true);
    }

    return investmentsPath;
  }

  /// Get web storage key for a category
  String _getWebStorageKey(String category) {
    return '${_webStoragePrefix}$category';
  }
  
  /// Get all investments from web storage for a category
  Future<Map<String, Map<String, dynamic>>> _getWebCategoryData(String category) async {
    final prefs = await _getPrefs();
    final key = _getWebStorageKey(category);
    final jsonString = prefs.getString(key);
    
    print('📦 Loading category "$category" from key "$key"');
    print('   Data exists: ${jsonString != null && jsonString.isNotEmpty}');
    
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      print('   Found ${data.length} investments');
      return data.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    } catch (e) {
      print('Error parsing web storage for $category: $e');
      return {};
    }
  }
  
  /// Save all investments to web storage for a category
  Future<void> _saveWebCategoryData(String category, Map<String, Map<String, dynamic>> data) async {
    final prefs = await _getPrefs();
    final key = _getWebStorageKey(category);
    final jsonString = jsonEncode(data);
    await prefs.setString(key, jsonString);
    print('💾 Saved ${data.length} investments to "$key" (${jsonString.length} chars)');
  }

  /// Generate a unique ID for new investment
  String generateId() {
    return _uuid.v4();
  }

  /// Save an investment
  Future<String> saveInvestment(Map<String, dynamic> data, String category) async {
    // Ensure ID exists
    if (!data.containsKey('id') || data['id'] == null || (data['id'] is String && data['id'].isEmpty)) {
      data['id'] = generateId();
    }
    
    // Add metadata
    data['createdAt'] = data['createdAt'] ?? DateTime.now().toIso8601String();
    data['updatedAt'] = DateTime.now().toIso8601String();
    data['category'] = category;

    if (kIsWeb) {
      // Web: Use SharedPreferences
      final categoryData = await _getWebCategoryData(category);
      categoryData[data['id']] = data;
      await _saveWebCategoryData(category, categoryData);
      // After every save, backup all data
      await backupAllInvestments();
    } else {
      // Mobile/Desktop: Use file system
      final dir = await _investmentsDirectory;
      final categoryDir = Directory('${dir.path}/$category');
      
      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }

      final fileName = '${data['id']}.json';
      final file = File('${categoryDir.path}/$fileName');
      await file.writeAsString(jsonEncode(data));
      // After every save, backup all data (optional for mobile)
      await backupAllInvestments();
    }
    
    return data['id'];
  }

  /// Read a single investment by ID and category
  Future<Map<String, dynamic>?> getInvestment(String id, String category) async {
    try {
      if (kIsWeb) {
        final categoryData = await _getWebCategoryData(category);
        return categoryData[id];
      } else {
        final dir = await _investmentsDirectory;
        final file = File('${dir.path}/$category/$id.json');
        
        if (!await file.exists()) {
          return null;
        }

        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
    } catch (e) {
      print('Error reading investment: $e');
      return null;
    }
  }

  /// Get all investments for a category
  Future<List<Map<String, dynamic>>> getInvestmentsByCategory(String category) async {
    try {
      List<Map<String, dynamic>> investments;
      
      if (kIsWeb) {
        final categoryData = await _getWebCategoryData(category);
        investments = categoryData.values.toList();
      } else {
        final dir = await _investmentsDirectory;
        final categoryDir = Directory('${dir.path}/$category');
        
        if (!await categoryDir.exists()) {
          return [];
        }

        final files = await categoryDir.list().toList();
        investments = <Map<String, dynamic>>[];

        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            final contents = await file.readAsString();
            investments.add(jsonDecode(contents));
          }
        }
      }

      // Sort by date (most recent first)
      investments.sort((a, b) {
        final dateA = DateTime.parse(a['date'] ?? a['createdAt']);
        final dateB = DateTime.parse(b['date'] ?? b['createdAt']);
        return dateB.compareTo(dateA);
      });

      return investments;
    } catch (e) {
      print('Error reading investments: $e');
      return [];
    }
  }

  /// Get all investments across all categories
  Future<List<Map<String, dynamic>>> getAllInvestments() async {
    final categories = allCategories;
    
    final allInvestments = <Map<String, dynamic>>[];
    
    for (final category in categories) {
      final categoryInvestments = await getInvestmentsByCategory(category);
      allInvestments.addAll(categoryInvestments);
    }

    // Sort by date
    allInvestments.sort((a, b) {
      final dateA = DateTime.parse(a['date'] ?? a['createdAt']);
      final dateB = DateTime.parse(b['date'] ?? b['createdAt']);
      return dateB.compareTo(dateA);
    });

    return allInvestments;
  }

  /// Update an existing investment
  Future<void> updateInvestment(String id, String category, Map<String, dynamic> data) async {
    data['id'] = id;
    data['updatedAt'] = DateTime.now().toIso8601String();
    await saveInvestment(data, category);
  }

  /// Delete an investment
  Future<bool> deleteInvestment(String id, String category) async {
    try {
      if (kIsWeb) {
        final categoryData = await _getWebCategoryData(category);
        if (categoryData.containsKey(id)) {
          categoryData.remove(id);
          await _saveWebCategoryData(category, categoryData);
          // Update backup after deletion
          await backupAllInvestments();
          return true;
        }
        return false;
      } else {
        final dir = await _investmentsDirectory;
        final file = File('${dir.path}/$category/$id.json');
        
        if (await file.exists()) {
          await file.delete();
          // Update backup after deletion
          await backupAllInvestments();
          return true;
        }
        return false;
      }
    } catch (e) {
      print('Error deleting investment: $e');
      return false;
    }
  }

  /// Get total count by category
  Future<Map<String, int>> getCategoryCounts() async {
    final counts = <String, int>{};
    final categories = allCategories;
    
    for (final category in categories) {
      final investments = await getInvestmentsByCategory(category);
      counts[category] = investments.length;
    }
    
    return counts;
  }

  /// Get total invested amount by category
  Future<Map<String, double>> getCategoryTotals() async {
    final totals = <String, double>{};
    final categories = allCategories;
    
    for (final category in categories) {
      final investments = await getInvestmentsByCategory(category);
      double total = 0;
      
      for (final investment in investments) {
        // Try to get final amount from various possible field names
        if (investment.containsKey('finalAmount')) {
          final amount = investment['finalAmount'];
          if (amount is num) {
            total += amount.toDouble();
          } else if (amount is String) {
            total += double.tryParse(amount.replaceAll(',', '')) ?? 0;
          }
        } else if (investment.containsKey('totalAmount')) {
          if (investment['totalAmount'] is Map) {
            total += (investment['totalAmount']['finalAmount'] ?? 0).toDouble();
          } else {
            total += (investment['totalAmount'] ?? 0).toDouble();
          }
        } else if (investment.containsKey('amount')) {
          final amount = investment['amount'];
          if (amount is num) {
            total += amount.toDouble();
          }
        }
      }
      
      totals[category] = total;
    }
    
    return totals;
  }

  /// Search investments across all categories
  Future<List<Map<String, dynamic>>> searchInvestments(String query) async {
    final allInvestments = await getAllInvestments();
    final searchQuery = query.toLowerCase();
    
    return allInvestments.where((investment) {
      final jsonString = jsonEncode(investment).toLowerCase();
      return jsonString.contains(searchQuery);
    }).toList();
  }

  /// Export all data as JSON
  Future<String> exportAllData() async {
    final allInvestments = await getAllInvestments();
    return jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'totalInvestments': allInvestments.length,
      'investments': allInvestments,
    });
  }

  /// Import data from JSON string
  Future<int> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      final investments = data['investments'] as List;
      int imported = 0;
      
      for (final investment in investments) {
        final category = investment['category'] ?? 'gold_jewellery';
        await saveInvestment(investment, category);
        imported++;
      }
      
      return imported;
    } catch (e) {
      print('Error importing data: $e');
      return 0;
    }
  }
  
  /// Get portfolio summary with invested, current value, and change
  Future<PortfolioSummary> getPortfolioSummary() async {
    final marketRates = MarketRatesService();
    final rates = await marketRates.getRates();
    
    double totalInvested = 0;
    double totalCurrentValue = 0;
    final categorySummaries = <String, CategorySummary>{};
    
    for (final category in allCategories) {
      final investments = await getInvestmentsByCategory(category);
      double categoryInvested = 0;
      double categoryCurrentValue = 0;
      
      for (final inv in investments) {
        // Get invested amount
        final invested = _extractAmount(inv);
        categoryInvested += invested;
        
        // Calculate current value based on weight and current rates
        if (_isPreciousMetal(category)) {
          final weight = _extractWeight(inv);
          final purity = inv['purity']?.toString() ?? '22K';
          final metalType = inv['metalType']?.toString() ?? 'Gold';
          
          // Extract diamond data for diamond jewellery
          final diamondCarats = _extractNumber(inv, 'diamondCarats');
          final diamondClarity = inv['diamondClarity']?.toString();
          final diamondCost = _extractNumber(inv, 'diamondCost');
          
          final currentValue = await marketRates.calculateCurrentValue(
            weight: weight,
            purity: purity,
            metalType: metalType,
            category: category,
            diamondCarats: diamondCarats,
            diamondClarity: diamondClarity,
            diamondPurchaseValue: diamondCost,
          );
          categoryCurrentValue += currentValue;
        } else {
          // For non-physical assets, current = invested (no live rates)
          categoryCurrentValue += invested;
        }
      }
      
      totalInvested += categoryInvested;
      totalCurrentValue += categoryCurrentValue;
      
      categorySummaries[category] = CategorySummary(
        invested: categoryInvested,
        currentValue: categoryCurrentValue,
        itemCount: investments.length,
      );
    }
    
    return PortfolioSummary(
      totalInvested: totalInvested,
      totalCurrentValue: totalCurrentValue,
      categorySummaries: categorySummaries,
      rates: rates,
    );
  }
  
  /// Check if category is precious metal/jewellery
  bool _isPreciousMetal(String category) {
    return ['gold_jewellery', 'diamond_jewellery', 'silver', 'bullion', 'digital_gold', 'sgb']
        .contains(category);
  }
  
  /// Extract amount from investment data
  double _extractAmount(Map<String, dynamic> investment) {
    if (investment.containsKey('finalAmount')) {
      final amount = investment['finalAmount'];
      if (amount is num) return amount.toDouble();
      if (amount is String) return double.tryParse(amount.replaceAll(',', '')) ?? 0;
    }
    if (investment.containsKey('totalAmount')) {
      if (investment['totalAmount'] is Map) {
        return (investment['totalAmount']['finalAmount'] ?? 0).toDouble();
      }
      return (investment['totalAmount'] ?? 0).toDouble();
    }
    if (investment.containsKey('amount')) {
      final amount = investment['amount'];
      if (amount is num) return amount.toDouble();
    }
    return 0;
  }
  
  /// Extract weight from investment data
  double _extractWeight(Map<String, dynamic> investment) {
    // Priority: netWeight > weight > grossWeight
    for (final key in ['netWeight', 'weight', 'grossWeight']) {
      if (investment.containsKey(key)) {
        final weight = investment[key];
        if (weight is num) return weight.toDouble();
        if (weight is String) return double.tryParse(weight) ?? 0;
      }
    }
    return 0;
  }
  
  /// Extract a numeric value by key
  double? _extractNumber(Map<String, dynamic> investment, String key) {
    if (!investment.containsKey(key) || investment[key] == null) {
      return null;
    }
    final value = investment[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Backup all investments to a single JSON key
  Future<void> backupAllInvestments() async {
    final allInvestments = await getAllInvestments();
    final prefs = await _getPrefs();
    await prefs.setString(_backupKey, jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'totalInvestments': allInvestments.length,
      'investments': allInvestments,
    }));
    print('🗄️  Backup saved with ${allInvestments.length} investments');
  }

  /// Restore all investments from backup if all categories are empty
  Future<void> restoreFromBackupIfNeeded() async {
    // Check if all categories are empty
    bool allEmpty = true;
    for (final category in allCategories) {
      final data = await _getWebCategoryData(category);
      if (data.isNotEmpty) {
        allEmpty = false;
        break;
      }
    }
    if (allEmpty) {
      final prefs = await _getPrefs();
      final backup = prefs.getString(_backupKey);
      if (backup != null && backup.isNotEmpty) {
        try {
          final decoded = jsonDecode(backup);
          final investments = decoded['investments'] as List?;
          if (investments != null) {
            for (final inv in investments) {
              final category = inv['category'] ?? 'gold_jewellery';
              await saveInvestment(Map<String, dynamic>.from(inv), category);
            }
            print('✅ Restored ${investments.length} investments from backup');
          }
        } catch (e) {
          print('❌ Error restoring from backup: $e');
        }
      }
    }
  }

  /// Debug helper: return raw backup JSON string if present (web)
  Future<String?> getBackupString() async {
    try {
      final prefs = await _getPrefs();
      final backup = prefs.getString(_backupKey);
      return backup;
    } catch (e) {
      print('Error reading backup string: $e');
      return null;
    }
  }
}

/// Summary for the entire portfolio
class PortfolioSummary {
  final double totalInvested;
  final double totalCurrentValue;
  final Map<String, CategorySummary> categorySummaries;
  final Map<String, double> rates;
  
  PortfolioSummary({
    required this.totalInvested,
    required this.totalCurrentValue,
    required this.categorySummaries,
    required this.rates,
  });
  
  double get totalChange => totalCurrentValue - totalInvested;
  double get totalChangePercent => totalInvested > 0 
      ? ((totalCurrentValue - totalInvested) / totalInvested) * 100 
      : 0;
  bool get isProfit => totalChange >= 0;
}

/// Summary for a single category
class CategorySummary {
  final double invested;
  final double currentValue;
  final int itemCount;
  
  CategorySummary({
    required this.invested,
    required this.currentValue,
    required this.itemCount,
  });
  
  double get change => currentValue - invested;
  double get changePercent => invested > 0 
      ? ((currentValue - invested) / invested) * 100 
      : 0;
  bool get isProfit => change >= 0;
}
