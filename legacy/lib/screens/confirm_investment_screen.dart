import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/investment_parser.dart';
import '../services/json_storage_service.dart';
import '../utils/cred_theme.dart';

class ConfirmInvestmentScreen extends StatefulWidget {
  final String category;
  final Map<String, dynamic> parsedData;
  final String inputMethod;

  const ConfirmInvestmentScreen({
    super.key,
    required this.category,
    required this.parsedData,
    required this.inputMethod,
  });

  @override
  State<ConfirmInvestmentScreen> createState() => _ConfirmInvestmentScreenState();
}

class _ConfirmInvestmentScreenState extends State<ConfirmInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = JsonStorageService();
  
  late Map<String, dynamic> _data;
  late List<String> _missingFields;
  bool _isSaving = false;

  // Controllers for mandatory fields
  late TextEditingController _descriptionController;  // Product description (free text)
  late TextEditingController _weightController;       // Net weight (mandatory)
  late TextEditingController _finalAmountController;  // Final price (mandatory)
  
  // Controllers for optional fields
  late TextEditingController _purityController;
  late TextEditingController _vendorController;
  late TextEditingController _grossWeightController;
  late TextEditingController _stoneWeightController;
  late TextEditingController _stoneCostController;
  late TextEditingController _goldRateController;

  // Valid purity values for dropdown
  static const List<String> _validPurities = [
    '24K', '22K', '18K', '14K', '10K',
    '950 Platinum', '900 Platinum',
    '999 Silver', '925 Silver', '900 Silver',
  ];

  // Normalize product type to match dropdown values
  String? _normalizeProductType(String? type) {
    if (type == null) return null;
    
    final normalized = type.trim();
    final lowerType = normalized.toLowerCase();
    
    // Map common variations to dropdown values
    final typeMap = {
      'earring': 'Earrings',
      'earrings': 'Earrings',
      'ring': 'Ring',
      'chain': 'Chain',
      'necklace': 'Necklace',
      'bangle': 'Bangle',
      'bracelet': 'Bracelet',
      'pendant': 'Pendant',
      'anklet': 'Anklet',
      'mangalsutra': 'Mangalsutra',
      'nose pin': 'Nose Pin',
      'nosepin': 'Nose Pin',
      'coin': 'Coin',
      'bar': 'Bar',
      'biscuit': 'Biscuit',
      'idol': 'Idol',
    };
    
    return typeMap[lowerType] ?? normalized;
  }

  // Normalize purity to match dropdown values
  String? _normalizePurity(String? purity) {
    if (purity == null || purity.isEmpty) return null;
    
    final normalized = purity.trim().toUpperCase().replaceAll(' ', '');
    
    // Map common variations
    final purityMap = {
      'GOLD': '22K', // Default gold to 22K
      '916': '22K',
      '916GOLD': '22K',
      '22K': '22K',
      '22KT': '22K',
      '22KARAT': '22K',
      '750': '18K',
      '750GOLD': '18K',
      '18K': '18K',
      '18KT': '18K',
      '18KARAT': '18K',
      '585': '14K',
      '14K': '14K',
      '14KT': '14K',
      '14KARAT': '14K',
      '999': '24K',
      '24K': '24K',
      '24KT': '24K',
      '24KARAT': '24K',
      '417': '10K',
      '10K': '10K',
      '10KT': '10K',
      'PLATINUM': '950 Platinum',
      '950PT': '950 Platinum',
      '950PLATINUM': '950 Platinum',
      '900PT': '900 Platinum',
      '900PLATINUM': '900 Platinum',
      'SILVER': '925 Silver',
      '925': '925 Silver',
      '925SILVER': '925 Silver',
      '999SILVER': '999 Silver',
      '900SILVER': '900 Silver',
    };
    
    // Check direct map
    if (purityMap.containsKey(normalized)) {
      return purityMap[normalized];
    }
    
    // Check if it's already a valid value
    for (final valid in _validPurities) {
      if (valid.toUpperCase().replaceAll(' ', '') == normalized) {
        return valid;
      }
    }
    
    // Try to extract just the number + K pattern
    final kMatch = RegExp(r'(\d+)K').firstMatch(normalized);
    if (kMatch != null) {
      final k = '${kMatch.group(1)}K';
      if (_validPurities.contains(k)) {
        return k;
      }
    }
    
    print('⚠️ Unknown purity value: $purity (normalized: $normalized)');
    // Return null if not valid (will show as unselected)
    return null;
  }

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.parsedData);
    
    // Debug: Print received data
    print('🔍 ConfirmInvestmentScreen received data:');
    print('   Category: ${widget.category}');
    print('   Input Method: ${widget.inputMethod}');
    print('   Parsed Data Keys: ${_data.keys.toList()}');
    print('   Full Data: $_data');
    
    // Normalize purity if present
    if (_data['purity'] != null) {
      _data['purity'] = _normalizePurity(_data['purity'].toString());
    }
    
    // Use productDescription from bill, or productType as fallback
    String description = _data['productDescription']?.toString() ?? 
                         _data['productType']?.toString() ?? '';
    
    _missingFields = InvestmentParser.getMissingFields(_data);
    print('   Missing Fields: $_missingFields');

    // Initialize mandatory field controllers
    _descriptionController = TextEditingController(text: description);
    _weightController = TextEditingController(text: _data['weight']?.toString() ?? _data['netWeight']?.toString() ?? '');
    _finalAmountController = TextEditingController(text: _data['finalAmount']?.toString() ?? '');
    
    // Initialize optional field controllers
    _purityController = TextEditingController(text: _data['purity']?.toString() ?? '');
    _vendorController = TextEditingController(text: _data['vendor']?.toString() ?? '');
    _grossWeightController = TextEditingController(text: _data['grossWeight']?.toString() ?? '');
    
    // For Gold Jewellery: If stone fields are empty but diamond fields have data,
    // use diamond data as stones (since user said no diamonds in gold jewellery)
    // Note: Stone weight is in grams, cost is calculated from carats but we just store the final cost
    double? stoneWt = _data['stoneWeight'] as double?;
    double? stoneCt = _data['stoneCost'] as double?;
    
    // If no stone weight but diamondCarats has value, convert carats to grams (1 carat = 0.2g)
    if (stoneWt == null && _data['diamondCarats'] != null) {
      double carats = (_data['diamondCarats'] as double?) ?? 0;
      stoneWt = carats * 0.2; // Convert carats to grams
      _data['stoneWeight'] = stoneWt;
    }
    // If no stone cost but diamondCost has value, use that
    if (stoneCt == null && _data['diamondCost'] != null) {
      stoneCt = _data['diamondCost'] as double?;
      _data['stoneCost'] = stoneCt;
    }
    
    _stoneWeightController = TextEditingController(text: stoneWt != null && stoneWt > 0 ? stoneWt.toStringAsFixed(2) : '');
    _stoneCostController = TextEditingController(text: stoneCt?.toString() ?? '');
    _goldRateController = TextEditingController(text: _data['goldRate']?.toString() ?? '');
    
    // Debug: Print controller values
    print('   Controllers initialized:');
    print('     - Description: ${_descriptionController.text}');
    print('     - Net Weight: ${_weightController.text}');
    print('     - Final Amount: ${_finalAmountController.text}');
    print('     - Purity (raw): ${widget.parsedData['purity']} -> normalized: ${_data['purity']}');
    print('     - Vendor: ${_vendorController.text}');
    print('     - Stone Weight (g): ${_stoneWeightController.text}');
    print('     - Stone Cost: ${_stoneCostController.text}');
    print('     - Gold Rate: ${_goldRateController.text}');

    // If all mandatory fields present (weight + finalAmount), auto-save to avoid manual input
    final hasWeight = (_data['weight'] != null && (_data['weight'] is num ? (_data['weight'] as num) > 0 : double.tryParse(_data['weight'].toString()) != null));
    final hasAmount = (_data['finalAmount'] != null && (_data['finalAmount'] is num ? (_data['finalAmount'] as num) > 0 : double.tryParse(_data['finalAmount'].toString()) != null));

    if (hasWeight && hasAmount && widget.inputMethod != 'Text') {
      // Schedule auto-save shortly after init so UI can render
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          print('⚡ Auto-saving parsed investment (no manual input required)');
          _saveInvestment();
        }
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _weightController.dispose();
    _finalAmountController.dispose();
    _purityController.dispose();
    _vendorController.dispose();
    _grossWeightController.dispose();
    _stoneWeightController.dispose();
    _stoneCostController.dispose();
    _goldRateController.dispose();
    super.dispose();
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Update data from controllers
    _data['productDescription'] = _descriptionController.text.trim();
    _data['productType'] = _descriptionController.text.trim(); // For backward compatibility
    _data['weight'] = double.tryParse(_weightController.text) ?? 0;
    _data['netWeight'] = double.tryParse(_weightController.text) ?? 0;
    _data['finalAmount'] = double.tryParse(_finalAmountController.text) ?? 0;
    _data['purity'] = _purityController.text.trim();
    _data['vendor'] = _vendorController.text.trim();
    _data['grossWeight'] = double.tryParse(_grossWeightController.text);
    _data['stoneWeight'] = double.tryParse(_stoneWeightController.text);
    _data['stoneCost'] = double.tryParse(_stoneCostController.text);
    _data['goldRate'] = double.tryParse(_goldRateController.text);

    setState(() => _isSaving = true);

    try {
      // Build the investment data structure
      final investmentData = {
        'date': _data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
        'inputMethod': widget.inputMethod,
        'productDescription': _data['productDescription'],
        'productType': _data['productType'], // For backward compatibility
        'weight': _data['weight'],
        'netWeight': _data['netWeight'],
        'weightUnit': _data['weightUnit'] ?? 'grams',
        'purity': _data['purity'],
        'metalType': _data['metalType'] ?? 'Gold',
        'finalAmount': _data['finalAmount'],
        'vendor': _data['vendor'],
        'billNumber': _data['billNumber'],
        'gstin': _data['gstin'],
        'grossWeight': _data['grossWeight'],
        'stoneWeight': _data['stoneWeight'],
        'stoneCost': _data['stoneCost'],
        'diamondCarats': _data['diamondCarats'],
        'diamondCost': _data['diamondCost'],
        'diamondClarity': _data['diamondClarity'],
        'diamondColor': _data['diamondColor'],
        'diamondCut': _data['diamondCut'],
        'certificateNumber': _data['certificateNumber'],
        'certificateAgency': _data['certificateAgency'],
        'goldRate': _data['goldRate'],
        'makingCharges': _data['makingCharges'],
        'gst': _data['gst'],
        'discount': _data['discount'],
        'rawOcrText': _data['rawOcrText'],
        'lineItems': _data['lineItems'],
        'billImagePath': _data['billImagePath'],
        'ocrText': _data['ocrText'],
        'originalInput': _data['originalInput'],
      };

      // Remove null values
      investmentData.removeWhere((key, value) => value == null);

      // Determine category based on product type or use provided category
      String category = widget.category;
      if (category == 'auto') {
        // Auto-determine category based on product type
        final productType = _data['productType']?.toString().toLowerCase() ?? '';
        final metalType = _data['metalType']?.toString().toLowerCase() ?? 'gold';
        
        if (metalType == 'silver') {
          category = 'silver';
        } else if (productType.contains('coin') || productType.contains('bar') || 
                   productType.contains('biscuit')) {
          category = 'bullion';
        } else if (productType.contains('chain') || productType.contains('ring') || 
            productType.contains('bangle') || productType.contains('necklace') ||
            productType.contains('earring') || productType.contains('bracelet') ||
            productType.contains('pendant') || productType.contains('anklet')) {
          // Check if it has diamonds (usually 18K or 14K)
          if (metalType == 'gold' && (_data['purity'] == '18K' || _data['purity'] == '14K')) {
            category = 'diamond_jewellery';
          } else {
            category = 'gold_jewellery';
          }
        } else {
          category = 'gold_jewellery'; // Default for gold items
        }
      }

      await _storageService.saveInvestment(investmentData, category);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Investment saved successfully!'),
            backgroundColor: CredTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: CredTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    String? prefix,
    String? suffix,
    bool isRequired = false,
    bool isMissing = false,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      labelStyle: TextStyle(
        color: isMissing ? CredTheme.warning : CredTheme.textSecondary,
        fontSize: 14,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        color: CredTheme.textTertiary.withOpacity(0.5),
        fontSize: 14,
      ),
      prefixText: prefix,
      prefixStyle: const TextStyle(
        color: CredTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      suffixText: suffix,
      suffixStyle: const TextStyle(
        color: CredTheme.textSecondary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isMissing 
          ? CredTheme.warning.withOpacity(0.1) 
          : CredTheme.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isMissing ? CredTheme.warning.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CredTheme.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CredTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CredTheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CredTheme.background,
      appBar: AppBar(
        backgroundColor: CredTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CredTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm Investment',
          style: TextStyle(
            color: CredTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, 
                    color: CredTheme.accent,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: CredTheme.accent),
              onPressed: _saveInvestment,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Input method badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CredTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CredTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.inputMethod == 'OCR' || widget.inputMethod == 'PDF' 
                        ? Icons.document_scanner_outlined 
                        : widget.inputMethod == 'Voice' 
                            ? Icons.mic_outlined
                            : Icons.edit_outlined,
                    color: CredTheme.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Input Method: ${widget.inputMethod}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: CredTheme.accent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Missing fields warning
            if (_missingFields.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CredTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CredTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: CredTheme.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Missing Information',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: CredTheme.warning,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please provide: ${_missingFields.join(', ')}',
                            style: TextStyle(
                              color: CredTheme.warning.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Mandatory Fields Section
            _buildSectionHeader('Mandatory Fields', Icons.star_rounded),
            const SizedBox(height: 16),

            // Net Weight (Pure Gold) - MANDATORY
            TextFormField(
              controller: _weightController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Net Gold Weight',
                hint: 'Pure gold weight (excluding stones)',
                suffix: 'grams',
                isRequired: true,
                isMissing: _missingFields.contains('Net Weight'),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) {
                setState(() {
                  _data['weight'] = double.tryParse(value);
                  _data['netWeight'] = double.tryParse(value);
                  _missingFields = InvestmentParser.getMissingFields(_data);
                });
              },
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Final Price - MANDATORY (amount paid after tax/discounts)
            TextFormField(
              controller: _finalAmountController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Final Price Paid',
                hint: 'Amount paid (after GST, discounts)',
                prefix: '₹ ',
                isRequired: true,
                isMissing: _missingFields.contains('Final Price'),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              onChanged: (value) {
                setState(() {
                  _data['finalAmount'] = double.tryParse(value);
                  _missingFields = InvestmentParser.getMissingFields(_data);
                });
              },
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid amount';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Optional Details Section
            _buildSectionHeader('Item Details', Icons.info_outline_rounded),
            const SizedBox(height: 16),

            // Product Description (free text from bill)
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Product Description',
                hint: 'e.g., 22K Gold Chain, Diamond Earrings, Gold Coin 10g',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  _data['productDescription'] = value.trim();
                });
              },
            ),

            const SizedBox(height: 16),

            // Purity Dropdown (optional)
            DropdownButtonFormField<String>(
              value: _data['purity'],
              dropdownColor: CredTheme.cardBackground,
              style: const TextStyle(
                color: CredTheme.textPrimary,
                fontSize: 16,
              ),
              decoration: _buildInputDecoration(
                label: 'Purity',
                hint: 'Select purity',
              ),
              items: _validPurities.map((purity) => DropdownMenuItem(
                value: purity, 
                child: Text(purity, style: const TextStyle(color: CredTheme.textPrimary)),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _data['purity'] = value;
                  _purityController.text = value ?? '';
                });
              },
            ),

            const SizedBox(height: 16),

            // Vendor/Store
            TextFormField(
              controller: _vendorController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Vendor/Store',
                hint: 'e.g., GRT, Tanishq, CaratLane',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                setState(() {
                  _data['vendor'] = value.trim();
                });
              },
            ),

            const SizedBox(height: 16),

            // Gross Weight (total weight including stones)
            TextFormField(
              controller: _grossWeightController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Gross Weight',
                hint: 'Total weight including stones',
                suffix: 'grams',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) {
                setState(() {
                  _data['grossWeight'] = double.tryParse(value);
                });
              },
            ),

            const SizedBox(height: 32),

            // Stone Details Section
            _buildSectionHeader('Stone Details', Icons.blur_circular_outlined),
            const SizedBox(height: 8),
            Text(
              'Stones can be measured in grams OR carats - fill whichever is on your bill',
              style: TextStyle(
                color: CredTheme.textTertiary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Stone Weight (in grams)
            TextFormField(
              controller: _stoneWeightController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Stone Weight',
                hint: 'Weight of stones',
                suffix: 'g',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (value) {
                setState(() {
                  _data['stoneWeight'] = double.tryParse(value);
                });
              },
            ),

            const SizedBox(height: 16),

            // Stone Cost
            TextFormField(
              controller: _stoneCostController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Stone Cost',
                hint: 'Value of stones',
                prefix: '₹ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              onChanged: (value) {
                setState(() {
                  _data['stoneCost'] = double.tryParse(value);
                });
              },
            ),

            const SizedBox(height: 32),

            // Gold Rate Section
            _buildSectionHeader('Gold Rate', Icons.currency_rupee_rounded),
            const SizedBox(height: 8),
            Text(
              'Gold price per gram as per the bill',
              style: TextStyle(
                color: CredTheme.textTertiary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Gold Rate per gram
            TextFormField(
              controller: _goldRateController,
              style: const TextStyle(color: CredTheme.textPrimary, fontSize: 16),
              decoration: _buildInputDecoration(
                label: 'Gold Rate',
                hint: 'Price per gram on bill date',
                prefix: '₹ ',
                suffix: '/gram',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              onChanged: (value) {
                setState(() {
                  _data['goldRate'] = double.tryParse(value);
                });
              },
            ),

            const SizedBox(height: 32),

            // Extracted data summary
            if (_data.isNotEmpty) ...[
              _buildSectionHeader('Bill Summary', Icons.receipt_long_outlined),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CredTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CredTheme.divider),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Metal Type', _data['metalType'], Icons.category_outlined),
                    _buildSummaryRow('Vendor', _data['vendor'], Icons.store_outlined),
                    _buildSummaryRow('Bill Number', _data['billNumber'], Icons.tag_outlined),
                    _buildSummaryRow('GSTIN', _data['gstin'], Icons.receipt_outlined),
                    _buildSummaryRow('Date', _data['date'], Icons.calendar_today_outlined),
                    if (_data.containsKey('ocrText')) ...[
                      const SizedBox(height: 12),
                      const Divider(color: CredTheme.divider),
                      const SizedBox(height: 8),
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text(
                            'View Extracted Text',
                            style: TextStyle(
                              color: CredTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          iconColor: CredTheme.textSecondary,
                          collapsedIconColor: CredTheme.textSecondary,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CredTheme.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _data['ocrText'],
                                style: const TextStyle(
                                  fontSize: 11, 
                                  fontFamily: 'monospace',
                                  color: CredTheme.textTertiary,
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

            const SizedBox(height: 32),

            // Save button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CredTheme.goldJewellery, Color(0xFFD4A843)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CredTheme.goldJewellery.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveInvestment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: CredTheme.background,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: CredTheme.background),
                          SizedBox(width: 8),
                          Text(
                            'Save Investment',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              color: CredTheme.background,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: CredTheme.accent, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CredTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, dynamic value, IconData icon) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: CredTheme.textTertiary, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: CredTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                color: CredTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
