import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to fetch and cache market rates for gold, silver, etc.
/// Rates are fetched daily at 10:30 AM IST (after market opens)
/// Historical rates are stored in JSON format
class MarketRatesService {
  static const String _cacheKey = 'market_rates_cache';
  static const String _cacheTimeKey = 'market_rates_cache_time';
  static const String _cacheDateKey = 'market_rates_cache_date';
  static const String _rateHistoryKey = 'market_rates_history';
  
  // Daily refresh time: 10:30 AM IST
  static const int _refreshHour = 10;
  static const int _refreshMinute = 30;
  
  // IST offset from UTC (+5:30)
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);
  
  // Diamond rates per carat based on Clarity and Size
  // Clarity grades: IF/VVS > VS > SI > I
  // Color grades: D-E-F (colorless) > G-H-I-J (near colorless) > K+ (faint)
  // Common retail grades: EF-VVS, FG-VS, GH-SI, IJ-SI
  static const Map<String, Map<String, double>> _diamondRates = {
    // Premium clarity (EF-VVS, D-VVS) - Investment grade
    'ef_vvs': {
      'small': 45000.0,     // < 0.25 ct
      'medium': 120000.0,   // 0.25 - 0.5 ct
      'large': 280000.0,    // 0.5 - 1 ct
      'premium': 650000.0,  // > 1 ct
    },
    // Good clarity (FG-VS, GH-VS)
    'fg_vs': {
      'small': 35000.0,
      'medium': 85000.0,
      'large': 180000.0,
      'premium': 420000.0,
    },
    // Standard clarity (FG-SI, GH-SI) - Most common in retail
    'fg_si': {
      'small': 25000.0,
      'medium': 55000.0,
      'large': 115000.0,
      'premium': 280000.0,
    },
    // Commercial clarity (IJ-SI, I-SI)
    'ij_si': {
      'small': 18000.0,
      'medium': 40000.0,
      'large': 85000.0,
      'premium': 200000.0,
    },
    // Lower clarity (I1-I2)
    'i_clarity': {
      'small': 12000.0,
      'medium': 28000.0,
      'large': 55000.0,
      'premium': 120000.0,
    },
  };
  
  /// Get current time in IST
  DateTime _getCurrentIST() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(_istOffset);
  }
  
  /// Get today's date string in IST (YYYY-MM-DD)
  String _getTodayIST() {
    final ist = _getCurrentIST();
    return '${ist.year}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
  }
  
  /// Check if we should refresh rates (past 10:30 AM IST today and haven't fetched today)
  Future<bool> _shouldRefreshRates() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_cacheDateKey);
    final todayIST = _getTodayIST();
    final istNow = _getCurrentIST();
    
    // If no cache exists, definitely refresh
    if (cachedDate == null) {
      print('📊 No cached rates found, will fetch fresh');
      return true;
    }
    
    // If cache is from today after 10:30 AM, use it
    if (cachedDate == todayIST) {
      print('📊 Rates already fetched today ($cachedDate)');
      return false;
    }
    
    // If current time is past 10:30 AM IST, refresh
    final isPast1030 = istNow.hour > _refreshHour || 
                       (istNow.hour == _refreshHour && istNow.minute >= _refreshMinute);
    
    if (isPast1030) {
      print('📊 Past 10:30 AM IST, refreshing rates (last fetch: $cachedDate)');
      return true;
    }
    
    // Before 10:30 AM, use yesterday's rates
    print('📊 Before 10:30 AM IST, using cached rates from $cachedDate');
    return false;
  }
  
  /// Get current market rates
  /// Automatically refreshes daily at 10:30 AM IST
  Future<Map<String, double>> getRates() async {
    // Check if we need to refresh (daily at 10:30 AM IST)
    final shouldRefresh = await _shouldRefreshRates();
    
    if (!shouldRefresh) {
      // Use cached rates
      final cachedRates = await _getCachedRatesWithoutExpiry();
      if (cachedRates != null) {
        return cachedRates;
      }
    }
    
    // Fetch fresh rates from API
    try {
      final rates = await _fetchRatesFromAPI();
      if (rates == null) {
        throw Exception('Failed to fetch rates from all API sources');
      }
      await _cacheRates(rates);
      return rates;
    } catch (e) {
      print('❌ Error fetching rates: $e');
      // Try to return cached rates even if expired
      final cachedRates = await _getCachedRatesWithoutExpiry();
      if (cachedRates != null) {
        print('⚠️ Using stale cached rates');
        return cachedRates;
      }
      // No cached rates and API failed - throw error
      throw Exception('Unable to fetch gold rates. Please check your internet connection and try again.');
    }
  }
  
  /// Get cached rates without checking expiry
  Future<Map<String, double>?> _getCachedRatesWithoutExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson == null) return null;
      
      final Map<String, dynamic> decoded = jsonDecode(cacheJson);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return null;
    }
  }
  
  /// Calculate current value of an investment
  Future<double> calculateCurrentValue({
    required double weight,
    required String purity,
    required String metalType,
    String? category,
    double? diamondCarats,
    String? diamondClarity,
    double? diamondPurchaseValue,
    double? stonePurchaseValue,
  }) async {
    final rates = await getRates();
    
    // Calculate metal value
    String rateKey = _getRateKey(metalType, purity);
    final metalRate = rates[rateKey] ?? rates['gold_22k']!;
    double metalValue = weight * metalRate;
    
    // Category-specific calculations
    if (category == 'diamond_jewellery') {
      // Diamond jewellery: Gold + Diamond value
      double diamondValue = 0;
      if (diamondCarats != null && diamondCarats > 0) {
        final diamondRate = _getDiamondRate(diamondCarats, diamondClarity);
        diamondValue = diamondCarats * diamondRate;
      } else if (diamondPurchaseValue != null && diamondPurchaseValue > 0) {
        // Diamonds hold value well, use 95-100% of purchase price
        diamondValue = diamondPurchaseValue * 0.98;
      }
      return metalValue + diamondValue;
    } else if (category == 'gold_jewellery') {
      // Gold jewellery: Only Gold value (stones don't appreciate)
      // Stones have negligible resale value
      return metalValue;
    } else {
      // Default: Just metal value
      return metalValue;
    }
  }
  
  /// Get diamond rate based on carat size and clarity
  double _getDiamondRate(double carats, String? clarity) {
    // Determine clarity grade key
    String clarityKey = _normalizeClarityGrade(clarity);
    
    // Get rates for this clarity, default to FG-SI (most common)
    final clarityRates = _diamondRates[clarityKey] ?? _diamondRates['fg_si']!;
    
    // Determine size category
    if (carats >= 1.0) {
      return clarityRates['premium']!;
    } else if (carats >= 0.5) {
      return clarityRates['large']!;
    } else if (carats >= 0.25) {
      return clarityRates['medium']!;
    } else {
      return clarityRates['small']!;
    }
  }
  
  /// Normalize clarity grade string to our key format
  String _normalizeClarityGrade(String? clarity) {
    if (clarity == null || clarity.isEmpty) {
      return 'fg_si'; // Default to most common retail grade
    }
    
    final c = clarity.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
    
    // Check for premium grades
    if (c.contains('VVS') && (c.contains('D') || c.contains('E') || c.contains('F'))) {
      return 'ef_vvs';
    }
    if (c.contains('EFVVS') || c.contains('DVVS')) {
      return 'ef_vvs';
    }
    
    // Check for good grades (VS clarity)
    if (c.contains('VS') && !c.contains('VVS')) {
      if (c.contains('F') || c.contains('G') || c.contains('H')) {
        return 'fg_vs';
      }
    }
    if (c.contains('FGVS') || c.contains('GHVS')) {
      return 'fg_vs';
    }
    
    // Check for standard grades (SI clarity)
    if (c.contains('SI')) {
      if (c.contains('I') && c.contains('J')) {
        return 'ij_si'; // IJ-SI
      }
      if (c.contains('F') || c.contains('G') || c.contains('H')) {
        return 'fg_si'; // FG-SI or GH-SI
      }
      return 'fg_si'; // Default SI
    }
    
    // Check for lower grades
    if (c.contains('I1') || c.contains('I2') || c.contains('I3')) {
      return 'i_clarity';
    }
    
    // Default to standard retail grade
    return 'fg_si';
  }
  
  /// Calculate diamond jewellery value with full breakdown
  Future<Map<String, double>> calculateDiamondJewelleryValue({
    required double goldWeight,
    required String purity,
    double? diamondCarats,
    String? diamondClarity,
    double? diamondPurchaseValue,
  }) async {
    final rates = await getRates();
    
    // Gold value
    String rateKey = _getRateKey('Gold', purity);
    final goldRate = rates[rateKey] ?? rates['gold_18k']!; // 18K common for diamond jewellery
    final goldValue = goldWeight * goldRate;
    
    // Diamond value
    double diamondValue = 0;
    double diamondRate = 0;
    if (diamondCarats != null && diamondCarats > 0) {
      diamondRate = _getDiamondRate(diamondCarats, diamondClarity);
      diamondValue = diamondCarats * diamondRate;
    } else if (diamondPurchaseValue != null && diamondPurchaseValue > 0) {
      diamondValue = diamondPurchaseValue * 1.05;
    }
    
    return {
      'goldValue': goldValue,
      'goldRate': goldRate,
      'diamondValue': diamondValue,
      'diamondRate': diamondRate,
      'totalValue': goldValue + diamondValue,
    };
  }
  
  /// Get rate key based on metal type and purity
  String _getRateKey(String metalType, String purity) {
    final metal = metalType.toLowerCase();
    final pur = purity.toLowerCase();
    
    if (metal.contains('silver')) {
      return 'silver';
    } else if (metal.contains('platinum')) {
      return 'platinum';
    }
    
    // Gold purity mapping
    if (pur.contains('24k') || pur.contains('999')) {
      return 'gold_24k';
    } else if (pur.contains('22k') || pur.contains('916')) {
      return 'gold_22k';
    } else if (pur.contains('18k') || pur.contains('750')) {
      return 'gold_18k';
    } else if (pur.contains('14k') || pur.contains('585')) {
      return 'gold_14k';
    }
    
    // Default to 22K gold
    return 'gold_22k';
  }
  
  /// Cache rates with date stamp and save to history
  Future<void> _cacheRates(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayIST = _getTodayIST();
      
      await prefs.setString(_cacheKey, jsonEncode(rates));
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
      await prefs.setString(_cacheDateKey, todayIST);
      
      // Save to history
      await _saveToHistory(todayIST, rates);
      
      print('💾 Rates cached for $todayIST:');
      print('   24K: ₹${rates['gold_24k']?.toStringAsFixed(0)}/g');
      print('   22K: ₹${rates['gold_22k']?.toStringAsFixed(0)}/g');
      print('   18K: ₹${rates['gold_18k']?.toStringAsFixed(0)}/g');
      print('   14K: ₹${rates['gold_14k']?.toStringAsFixed(0)}/g');
    } catch (e) {
      print('Error caching rates: $e');
    }
  }
  
  /// Save rates to historical JSON storage
  /// Format: [{"date": "2026-01-26", "country": "India", "24kt": 7800, "22kt": 7150, "18kt": 5850, "14kt": 4560}, ...]
  Future<void> _saveToHistory(String date, Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_rateHistoryKey);
      
      List<Map<String, dynamic>> history = [];
      if (historyJson != null && historyJson.isNotEmpty) {
        final decoded = jsonDecode(historyJson) as List;
        history = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      // Check if entry for this date already exists
      final existingIndex = history.indexWhere((entry) => entry['date'] == date);
      
      final newEntry = {
        'date': date,
        'country': 'India',
        '24kt': rates['gold_24k']?.round() ?? 0,
        '22kt': rates['gold_22k']?.round() ?? 0,
        '18kt': rates['gold_18k']?.round() ?? 0,
        '14kt': rates['gold_14k']?.round() ?? 0,
      };
      
      if (existingIndex >= 0) {
        // Update existing entry
        history[existingIndex] = newEntry;
      } else {
        // Add new entry
        history.add(newEntry);
      }
      
      // Sort by date (newest first)
      history.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      
      // Save back to storage
      await prefs.setString(_rateHistoryKey, jsonEncode(history));
      print('📜 Rate history updated (${history.length} records)');
    } catch (e) {
      print('Error saving to history: $e');
    }
  }
  
  /// Get all historical rates as JSON
  Future<List<Map<String, dynamic>>> getRateHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_rateHistoryKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      
      final decoded = jsonDecode(historyJson) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error reading history: $e');
      return [];
    }
  }
  
  /// Export rate history as JSON string
  Future<String> exportHistoryAsJson() async {
    final history = await getRateHistory();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': history.length,
      'rates': history,
    });
  }
  
  /// Export rate history as CSV string
  Future<String> exportHistoryAsCsv() async {
    final history = await getRateHistory();
    
    // CSV Header
    final csv = StringBuffer();
    csv.writeln('Date,Country,24kt,22kt,18kt,14kt');
    
    // CSV Rows
    for (final entry in history) {
      csv.writeln('${entry['date']},${entry['country']},${entry['24kt']},${entry['22kt']},${entry['18kt']},${entry['14kt']}');
    }
    
    return csv.toString();
  }
  
  /// Get rate for a specific date from history
  Future<Map<String, dynamic>?> getRateForDate(String date) async {
    final history = await getRateHistory();
    try {
      return history.firstWhere((entry) => entry['date'] == date);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear rate history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rateHistoryKey);
    print('🗑️ Rate history cleared');
  }
  
  /// Fetch live rates from multiple API sources
  /// Fetches 24K, 22K, 18K, 14K gold rates
  Future<Map<String, double>?> _fetchRatesFromAPI() async {
    print('🔄 Fetching live gold rates (24K, 22K, 18K, 14K)...');
    
    // Try multiple sources in order of preference
    
    // 1. Try Gold Price India API (free, no key required)
    try {
      final rates = await _fetchFromGoldPriceIndia();
      if (rates != null) {
        print('✅ Fetched live rates from Gold Price API');
        return rates;
      }
    } catch (e) {
      print('Gold Price API failed: $e');
    }
    
    // 2. Try MetalPriceAPI (free tier)
    try {
      final rates = await _fetchFromMetalPriceAPI();
      if (rates != null) {
        print('✅ Fetched live rates from Metal Price API');
        return rates;
      }
    } catch (e) {
      print('Metal Price API failed: $e');
    }
    
    // 3. Try fetching international gold price and convert to INR
    try {
      final rates = await _fetchFromInternationalAPI();
      if (rates != null) {
        print('✅ Fetched live rates from International API');
        return rates;
      }
    } catch (e) {
      print('International API failed: $e');
    }
    
    print('❌ All APIs failed - no rates available');
    return null;
  }
  
  /// Fetch from Gold Price India (web scraping approach as backup)
  Future<Map<String, double>?> _fetchFromGoldPriceIndia() async {
    // Using a CORS-friendly JSON API endpoint
    final response = await http.get(
      Uri.parse('https://api.metals.dev/v1/latest?api_key=demo&currency=INR&unit=gram'),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extract gold price per gram in INR (this is international spot)
      final gold24kSpot = (data['metals']?['gold'] as num?)?.toDouble();
      
      if (gold24kSpot != null && gold24kSpot > 0) {
        // API returns international spot, apply small adjustment for Indian retail
        // Indian retail = spot price * ~1.08 (import duty ~6%, GST ~3%, small margin)
        final gold24kIndian = gold24kSpot * 1.08;
        return _calculateAllRatesFromBase(gold24kIndian);
      }
    }
    return null;
  }
  
  /// Fetch from MetalPriceAPI.com (free tier available)
  Future<Map<String, double>?> _fetchFromMetalPriceAPI() async {
    // Free tier: 100 requests/month
    // Gold price in INR per gram
    final response = await http.get(
      Uri.parse('https://api.metalpriceapi.com/v1/latest?api_key=demo&base=INR&currencies=XAU,XAG,XPT'),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // XAU is gold, XAG is silver, XPT is platinum
      // These are in troy ounces, need to convert to grams
      // 1 troy ounce = 31.1035 grams
      final xauRate = data['rates']?['INRXAU'] as num?; // INR per troy oz
      final xagRate = data['rates']?['INRXAG'] as num?;
      final xptRate = data['rates']?['INRXPT'] as num?;
      
      if (xauRate != null && xauRate > 0) {
        final gold24kSpot = xauRate / 31.1035;
        final silverPerGram = xagRate != null ? xagRate / 31.1035 : 100.0;
        final platinumPerGram = xptRate != null ? xptRate / 31.1035 : 3400.0;
        
        // Apply small adjustment for Indian retail (~8% for duties, GST, margin)
        final gold24kIndian = gold24kSpot * 1.08;
        
        return _calculateAllRatesFromBase(gold24kIndian, 
            silverRate: silverPerGram.toDouble(), 
            platinumRate: platinumPerGram.toDouble());
      }
    }
    return null;
  }
  
  /// Fetch international gold price and convert using exchange rate
  Future<Map<String, double>?> _fetchFromInternationalAPI() async {
    try {
      // Fetch gold price in USD from free API
      final goldResponse = await http.get(
        Uri.parse('https://api.coinbase.com/v2/prices/XAU-USD/spot'),
      ).timeout(const Duration(seconds: 10));
      
      // Fetch USD to INR exchange rate
      final forexResponse = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 10));
      
      if (goldResponse.statusCode == 200 && forexResponse.statusCode == 200) {
        final goldData = jsonDecode(goldResponse.body);
        final forexData = jsonDecode(forexResponse.body);
        
        final goldUsdPerOz = double.tryParse(goldData['data']?['amount']?.toString() ?? '0');
        final usdToInr = (forexData['rates']?['INR'] as num?)?.toDouble();
        
        if (goldUsdPerOz != null && goldUsdPerOz > 0 && usdToInr != null) {
          // Convert to INR per gram
          // Gold price is per troy ounce (31.1035 grams)
          final gold24kSpot = (goldUsdPerOz * usdToInr) / 31.1035;
          
          // Apply small adjustment for Indian retail (~8% for duties, GST, margin)
          final gold24kIndian = gold24kSpot * 1.08;
          return _calculateAllRatesFromBase(gold24kIndian);
        }
      }
    } catch (e) {
      print('International API error: $e');
    }
    return null;
  }
  
  /// Calculate all purity rates from 24K base rate
  /// Indian retail gold prices already include import duty, GST, and making charges
  Map<String, double> _calculateAllRatesFromBase(double gold24kPerGram, {
    double? silverRate,
    double? platinumRate,
  }) {
    // For Indian market:
    // 22K is typically ~91.6% of 24K price
    // 18K is typically ~75% of 24K price
    // 14K is typically ~58.5% of 24K price
    
    return {
      'gold_24k': _roundToNearest(gold24kPerGram, 1),
      'gold_22k': _roundToNearest(gold24kPerGram * 0.9167, 1),  // 22/24 = 0.9167
      'gold_18k': _roundToNearest(gold24kPerGram * 0.75, 1),    // 18/24 = 0.75
      'gold_14k': _roundToNearest(gold24kPerGram * 0.585, 1),   // 14/24 = 0.585
      'silver': silverRate ?? 100.0,
      'platinum': platinumRate ?? 3400.0,
    };
  }
  
  /// Round to nearest multiple
  double _roundToNearest(double value, int multiple) {
    return (value / multiple).round() * multiple.toDouble();
  }
  
  /// Manually update rates (for user override)
  Future<void> setManualRates(Map<String, double> rates) async {
    await _cacheRates(rates);
  }
  
  /// Clear cached rates to force refresh
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    await prefs.remove(_cacheDateKey);
    print('🔄 Rate cache cleared');
  }
  
  /// Force refresh rates from API
  Future<Map<String, double>> refreshRates() async {
    await clearCache();
    return await getRates();
  }
  
  /// Get rate display name
  static String getRateDisplayName(String key) {
    switch (key) {
      case 'gold_24k': return '24K Gold';
      case 'gold_22k': return '22K Gold';
      case 'gold_18k': return '18K Gold';
      case 'gold_14k': return '14K Gold';
      case 'silver': return 'Silver';
      case 'platinum': return 'Platinum';
      default: return key;
    }
  }
  
  /// Check if rates are from cache
  Future<bool> areRatesCached() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cacheKey);
  }
  
  /// Get the date when rates were last fetched
  Future<String?> getLastFetchDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheDateKey);
  }
  
  /// Get cache age
  Future<Duration?> getCacheAge() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    if (cacheTimeStr == null) return null;
    
    final cacheTime = DateTime.parse(cacheTimeStr);
    return DateTime.now().difference(cacheTime);
  }
  
  /// Get rate info for display (with source and date)
  Future<Map<String, dynamic>> getRateInfo() async {
    final rates = await getRates();
    final lastFetch = await getLastFetchDate();
    final cacheAge = await getCacheAge();
    
    return {
      'rates': rates,
      'lastFetchDate': lastFetch,
      'cacheAgeMinutes': cacheAge?.inMinutes,
      'gold_24k': rates['gold_24k'],
      'gold_22k': rates['gold_22k'],
      'gold_18k': rates['gold_18k'],
      'gold_14k': rates['gold_14k'],
    };
  }
}
