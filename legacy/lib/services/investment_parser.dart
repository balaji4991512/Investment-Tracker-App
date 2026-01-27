import 'dart:convert';

/// Parses natural language input for investment data
class InvestmentParser {
  /// Parse text/voice input for jewelry investment
  /// Example: "Purchased 10gm of Gold Chain 22kt in GRT today for 65000"
  static Map<String, dynamic> parseInput(String input) {
    final data = <String, dynamic>{};
    final lowerInput = input.toLowerCase();
    
    // Extract weight
    final weightRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:gm|gram|grams|g)');
    final weightMatch = weightRegex.firstMatch(lowerInput);
    if (weightMatch != null) {
      data['weight'] = double.tryParse(weightMatch.group(1)!);
      data['weightUnit'] = 'grams';
    }
    
    // Extract purity (22kt, 18K, 24 karat, etc.)
    final purityRegex = RegExp(r'(\d+)\s*(?:kt|k|karat|carat)', caseSensitive: false);
    final purityMatch = purityRegex.firstMatch(input);
    if (purityMatch != null) {
      final purityValue = purityMatch.group(1)!;
      data['purity'] = '${purityValue}K';
    }
    
    // Extract platinum purity (950, 900, etc.)
    final platinumRegex = RegExp(r'(?:platinum|pt)\s*(\d{3})', caseSensitive: false);
    final platinumMatch = platinumRegex.firstMatch(input);
    if (platinumMatch != null) {
      data['purity'] = '${platinumMatch.group(1)!} Platinum';
      data['metalType'] = 'Platinum';
    }
    
    // Extract silver purity (925, 999, etc.)
    final silverRegex = RegExp(r'(?:silver|ag)\s*(\d{3})', caseSensitive: false);
    final silverMatch = silverRegex.firstMatch(input);
    if (silverMatch != null) {
      data['purity'] = '${silverMatch.group(1)!} Silver';
      data['metalType'] = 'Silver';
    }
    
    // Extract final amount
    final amountRegex = RegExp(r'(?:for|rs|₹|inr|rupees?|price)\s*(?:rs\.?|₹)?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)');
    final amountMatch = amountRegex.firstMatch(lowerInput);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)!.replaceAll(',', '');
      data['finalAmount'] = double.tryParse(amountStr);
    }
    
    // Extract product type
    data['productType'] = _extractProductType(lowerInput);
    
    // Extract metal type (if not already set)
    if (!data.containsKey('metalType')) {
      data['metalType'] = _extractMetalType(lowerInput);
    }
    
    // Extract vendor/store
    final vendorRegex = RegExp(r'(?:from|at|in)\s+([A-Z][a-zA-Z\s]+?)(?:\s+(?:today|for|on))', caseSensitive: false);
    final vendorMatch = vendorRegex.firstMatch(input);
    if (vendorMatch != null) {
      data['vendor'] = vendorMatch.group(1)!.trim();
    }
    
    // Extract date
    data['date'] = _extractDate(lowerInput);
    
    return data;
  }
  
  static String? _extractProductType(String input) {
    const productTypes = {
      'chain': 'Chain',
      'necklace': 'Necklace',
      'ring': 'Ring',
      'bangle': 'Bangle',
      'bangles': 'Bangle',
      'bracelet': 'Bracelet',
      'earring': 'Earrings',
      'earrings': 'Earrings',
      'pendant': 'Pendant',
      'anklet': 'Anklet',
      'nospin': 'Nose Pin',
      'mangalsutra': 'Mangalsutra',
      'coin': 'Coin',
      'bar': 'Bar',
      'biscuit': 'Biscuit',
      'idol': 'Idol',
      'statue': 'Statue',
    };
    
    for (final entry in productTypes.entries) {
      if (input.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
  
  static String? _extractMetalType(String input) {
    if (input.contains('gold')) return 'Gold';
    if (input.contains('platinum') || input.contains('pt')) return 'Platinum';
    if (input.contains('silver') || input.contains('ag')) return 'Silver';
    if (input.contains('diamond')) return 'Gold'; // Usually diamond jewelry has gold base
    return null;
  }
  
  static String _extractDate(String input) {
    if (input.contains('today')) {
      return DateTime.now().toIso8601String().split('T')[0];
    }
    if (input.contains('yesterday')) {
      return DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    }
    
    // Try to extract specific date (DD/MM/YYYY or DD-MM-YYYY)
    final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
    final dateMatch = dateRegex.firstMatch(input);
    if (dateMatch != null) {
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final year = dateMatch.group(3)!;
      return '$year-$month-$day';
    }
    
    return DateTime.now().toIso8601String().split('T')[0];
  }
  
  /// Check which mandatory fields are missing
  /// For Gold Jewellery: Only Net Weight and Final Amount are mandatory
  static List<String> getMissingFields(Map<String, dynamic> data) {
    final missing = <String>[];
    
    // Net Weight is the only mandatory weight field
    if (!data.containsKey('weight') || data['weight'] == null) {
      if (!data.containsKey('netWeight') || data['netWeight'] == null) {
        missing.add('Net Weight');
      }
    }
    
    // Final Amount (price paid after tax/discount) is mandatory
    if (!data.containsKey('finalAmount') || data['finalAmount'] == null) {
      missing.add('Final Price');
    }
    
    return missing;
  }
  
  /// Format parsed data into a readable string
  static String formatParsedData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    if (data.containsKey('productType') && data['productType'] != null) {
      buffer.write('${data['productType']}');
    }
    
    if (data.containsKey('weight') && data['weight'] != null) {
      buffer.write(' (${data['weight']}${data['weightUnit'] ?? 'g'})');
    }
    
    if (data.containsKey('purity') && data['purity'] != null) {
      buffer.write(' - ${data['purity']}');
    }
    
    if (data.containsKey('metalType') && data['metalType'] != null) {
      buffer.write(' ${data['metalType']}');
    }
    
    if (data.containsKey('vendor') && data['vendor'] != null) {
      buffer.write('\nFrom: ${data['vendor']}');
    }
    
    if (data.containsKey('finalAmount') && data['finalAmount'] != null) {
      buffer.write('\nAmount: ₹${data['finalAmount']}');
    }
    
    if (data.containsKey('date') && data['date'] != null) {
      buffer.write('\nDate: ${data['date']}');
    }
    
    return buffer.toString();
  }
  
  /// Parse OCR extracted text from bill
  static Map<String, dynamic> parseOCRText(String ocrText) {
    final data = <String, dynamic>{};
    final lines = ocrText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    // Extract vendor name (usually first few lines, look for company name)
    for (int i = 0; i < (lines.length > 5 ? 5 : lines.length); i++) {
      final line = lines[i].trim();
      // Look for company indicators
      if (line.contains('LIMITED') || line.contains('LTD') || 
          line.contains('COMPANY') || line.contains('JEWELLERS') ||
          line.contains('JEWELLERY') || line.contains('GOLD')) {
        // Extract just the company name, not the full address
        final companyRegex = RegExp(r'^([A-Z][A-Z\s]+(?:LIMITED|LTD|COMPANY|JEWELLERS|JEWELLERY))');
        final match = companyRegex.firstMatch(line);
        if (match != null) {
          data['vendor'] = match.group(1)!.trim();
          break;
        }
      }
    }
    
    // If no vendor found in first lines, try to find known brands
    if (!data.containsKey('vendor')) {
      final fullText = ocrText.toUpperCase();
      if (fullText.contains('TITAN') || fullText.contains('TANISHQ')) {
        data['vendor'] = 'Tanishq';
      } else if (fullText.contains('CARATL') || fullText.contains('CARAT LANE')) {
        data['vendor'] = 'CaratLane';
      } else if (fullText.contains('GRT')) {
        data['vendor'] = 'GRT';
      } else if (fullText.contains('KALYAN')) {
        data['vendor'] = 'Kalyan Jewellers';
      } else if (fullText.contains('MALABAR')) {
        data['vendor'] = 'Malabar Gold';
      } else if (fullText.contains('JOYALUKKAS')) {
        data['vendor'] = 'Joyalukkas';
      }
    }
    
    // Try to find bill number
    for (final line in lines) {
      if (line.toLowerCase().contains('invoice') || 
          line.toLowerCase().contains('bill')) {
        final billRegex = RegExp(r'[:#]?\s*([A-Z0-9]{5,})');
        final match = billRegex.firstMatch(line);
        if (match != null) {
          data['billNumber'] = match.group(1);
          break;
        }
      }
    }
    
    // Try to find GSTIN
    final gstinRegex = RegExp(r'\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}');
    for (final line in lines) {
      final match = gstinRegex.firstMatch(line);
      if (match != null) {
        data['gstin'] = match.group(0);
        break;
      }
    }
    
    // Find weights - look for lines with weight keywords
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Try multiple weight patterns
      // Pattern 1: "Gross Weight (grams) 2.751"
      if (lowerLine.contains('gross') && (lowerLine.contains('weight') || lowerLine.contains('wt'))) {
        final patterns = [
          RegExp(r'(\d+\.?\d*)\s*(?:grams?|gms?|g)\s*$', caseSensitive: false),
          RegExp(r'(?:grams?|gms?|g)\s*(\d+\.?\d*)', caseSensitive: false),
          RegExp(r'gross.*?(\d+\.?\d*)\s*(?:\d+\.?\d*)?', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final value = double.tryParse(match.group(1)!);
            if (value != null && value > 0 && value < 1000) {
              data['grossWeight'] = value;
              break;
            }
          }
        }
      }
      
      // Net weight
      if (lowerLine.contains('net') && (lowerLine.contains('weight') || lowerLine.contains('wt'))) {
        final patterns = [
          RegExp(r'(\d+\.?\d*)\s*(?:grams?|gms?|g)\s*$', caseSensitive: false),
          RegExp(r'(?:grams?|gms?|g)\s*(\d+\.?\d*)', caseSensitive: false),
          RegExp(r'net.*?(\d+\.?\d*)\s*(?:\d+\.?\d*)?', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final value = double.tryParse(match.group(1)!);
            if (value != null && value > 0 && value < 1000) {
              data['netWeight'] = value;
              break;
            }
          }
        }
      }
      
      // Stone weight
      if (lowerLine.contains('stone') && (lowerLine.contains('weight') || lowerLine.contains('wt'))) {
        final patterns = [
          RegExp(r'(\d+\.?\d*)\s*(?:grams?|gms?|g)', caseSensitive: false),
          RegExp(r'stone.*?(\d+\.?\d*)', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final value = double.tryParse(match.group(1)!);
            if (value != null && value >= 0 && value < 100) {
              data['stoneWeight'] = value;
              break;
            }
          }
        }
      }
    }
    
    // Find purity
    final purityRegex = RegExp(r'(\d{2})(?:kt|k|karat)', caseSensitive: false);
    for (final line in lines) {
      final match = purityRegex.firstMatch(line);
      if (match != null) {
        data['purity'] = '${match.group(1)}K';
        break;
      }
    }
    
    // Find final amount - look for total/amount keywords
    double? maxAmount;
    final amountCandidates = <double>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();
      
      // Look for final total indicators
      if (lowerLine.contains('total amount') || 
          lowerLine.contains('grand total') ||
          lowerLine.contains('net amount') ||
          lowerLine.contains('payable') ||
          lowerLine.contains('invoice total') ||
          (lowerLine.contains('total') && lowerLine.contains('rs'))) {
        
        // Try to find amount in this line or next line
        final linesToCheck = [line];
        if (i + 1 < lines.length) linesToCheck.add(lines[i + 1]);
        
        for (final checkLine in linesToCheck) {
          // Pattern for Indian currency format: Rs. 70,040 or ₹ 70040.00
          final patterns = [
            RegExp(r'(?:rs\.?|₹)\s*(\d{1,3}(?:,\d{2,3})*(?:\.\d{2})?)', caseSensitive: false),
            RegExp(r'(\d{1,3}(?:,\d{2,3})*(?:\.\d{2})?)\s*(?:rs|₹)?$', caseSensitive: false),
          ];
          
          for (final pattern in patterns) {
            final matches = pattern.allMatches(checkLine);
            for (final match in matches) {
              final amountStr = match.group(1)!.replaceAll(',', '');
              final amount = double.tryParse(amountStr);
              
              // Reasonable amount range for jewelry
              if (amount != null && amount >= 1000 && amount <= 10000000) {
                amountCandidates.add(amount);
              }
            }
          }
        }
      }
    }
    
    // Take the largest reasonable amount found
    if (amountCandidates.isNotEmpty) {
      amountCandidates.sort();
      maxAmount = amountCandidates.last;
    }
    
    if (maxAmount != null) {
      data['finalAmount'] = maxAmount;
    }
    
    // Extract date
    final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        final day = match.group(1)!.padLeft(2, '0');
        final month = match.group(2)!.padLeft(2, '0');
        final year = match.group(3)!;
        data['date'] = '$year-$month-$day';
        break;
      }
    }
    
    // Try to detect product type from common keywords
    final fullText = ocrText.toLowerCase();
    data['productType'] = _extractProductType(fullText);
    data['metalType'] = _extractMetalType(fullText);
    
    // Use weight from netWeight if available
    if (data.containsKey('netWeight')) {
      data['weight'] = data['netWeight'];
      data['weightUnit'] = 'grams';
    } else if (data.containsKey('grossWeight')) {
      data['weight'] = data['grossWeight'];
      data['weightUnit'] = 'grams';
    }
    
    return data;
  }
}
