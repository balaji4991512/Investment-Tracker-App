import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/json_storage_service.dart';

class AddDiamondScreen extends StatefulWidget {
  const AddDiamondScreen({super.key});

  @override
  State<AddDiamondScreen> createState() => _AddDiamondScreenState();
}

class _AddDiamondScreenState extends State<AddDiamondScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = JsonStorageService();
  
  // Date & Time
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  
  // Vendor Details
  final _billNumberController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _stateCodeController = TextEditingController();
  final _panController = TextEditingController();
  final _cinController = TextEditingController();
  
  // Product Details
  String _productType = 'Ring';
  final _productNameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  
  // Weight Details
  final _grossWeightController = TextEditingController();
  final _netWeightController = TextEditingController();
  final _stoneWeightController = TextEditingController();
  final _diamondCaratsController = TextEditingController();
  
  // Metal Details
  String _metalType = 'Gold';
  String _purity = '18K';
  final _ratePerGramController = TextEditingController();
  final _metalValueController = TextEditingController();
  
  // Diamond Details
  String _clarity = 'VS';
  String _color = 'H';
  String _cut = 'Ideal';
  final _certificateNumberController = TextEditingController();
  
  // Charges
  final _makingChargesController = TextEditingController();
  final _hallmarkChargesController = TextEditingController();
  final _stoneChargesController = TextEditingController();
  final _otherChargesController = TextEditingController();
  final _grossProductPriceController = TextEditingController();
  
  // Discounts
  final List<Map<String, dynamic>> _discounts = [];
  
  // GST Details
  final _subtotalController = TextEditingController();
  final _taxableValueController = TextEditingController();
  final _cgstController = TextEditingController();
  final _sgstController = TextEditingController();
  final _igstController = TextEditingController();
  final _gstRateController = TextEditingController(text: '3');
  final _gstTotalController = TextEditingController();
  final _tcsController = TextEditingController();
  final _roundOffController = TextEditingController();
  final _finalAmountController = TextEditingController();
  
  // Payment Details
  final List<Map<String, dynamic>> _payments = [];
  
  // Market Rates
  final _gold24KController = TextEditingController();
  final _gold22KController = TextEditingController();
  final _gold18KController = TextEditingController();
  final _gold14KController = TextEditingController();
  final _platinum95Controller = TextEditingController();
  
  // Loyalty
  final _loyaltyIdController = TextEditingController();
  
  bool _isSaving = false;

  @override
  void dispose() {
    // Dispose all controllers
    _billNumberController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _gstinController.dispose();
    _stateCodeController.dispose();
    _panController.dispose();
    _cinController.dispose();
    _productNameController.dispose();
    _productCodeController.dispose();
    _hsnCodeController.dispose();
    _quantityController.dispose();
    _grossWeightController.dispose();
    _netWeightController.dispose();
    _stoneWeightController.dispose();
    _diamondCaratsController.dispose();
    _ratePerGramController.dispose();
    _metalValueController.dispose();
    _certificateNumberController.dispose();
    _makingChargesController.dispose();
    _hallmarkChargesController.dispose();
    _stoneChargesController.dispose();
    _otherChargesController.dispose();
    _grossProductPriceController.dispose();
    _subtotalController.dispose();
    _taxableValueController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();
    _gstRateController.dispose();
    _gstTotalController.dispose();
    _tcsController.dispose();
    _roundOffController.dispose();
    _finalAmountController.dispose();
    _gold24KController.dispose();
    _gold22KController.dispose();
    _gold18KController.dispose();
    _gold14KController.dispose();
    _platinum95Controller.dispose();
    _loyaltyIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addDiscount() {
    setState(() {
      _discounts.add({
        'type': 'coupon',
        'description': '',
        'amount': 0.0,
      });
    });
  }

  void _removeDiscount(int index) {
    setState(() => _discounts.removeAt(index));
  }

  void _addPayment() {
    setState(() {
      _payments.add({
        'method': 'Cash',
        'amount': 0.0,
        'reference': '',
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
    });
  }

  void _removePayment(int index) {
    setState(() => _payments.removeAt(index));
  }

  void _calculateTotals() {
    // Calculate metal value
    if (_netWeightController.text.isNotEmpty && _ratePerGramController.text.isNotEmpty) {
      final netWeight = double.tryParse(_netWeightController.text) ?? 0;
      final rate = double.tryParse(_ratePerGramController.text) ?? 0;
      _metalValueController.text = (netWeight * rate).toStringAsFixed(2);
    }

    // Calculate subtotal
    double subtotal = 0;
    subtotal += double.tryParse(_metalValueController.text) ?? 0;
    subtotal += double.tryParse(_makingChargesController.text) ?? 0;
    subtotal += double.tryParse(_hallmarkChargesController.text) ?? 0;
    subtotal += double.tryParse(_stoneChargesController.text) ?? 0;
    subtotal += double.tryParse(_otherChargesController.text) ?? 0;
    _subtotalController.text = subtotal.toStringAsFixed(2);
    _grossProductPriceController.text = subtotal.toStringAsFixed(2);

    // Apply discounts
    double totalDiscount = 0;
    for (final discount in _discounts) {
      totalDiscount += discount['amount'] ?? 0;
    }
    
    double taxableValue = subtotal - totalDiscount;
    _taxableValueController.text = taxableValue.toStringAsFixed(2);

    // Calculate GST
    final gstRate = double.tryParse(_gstRateController.text) ?? 3.0;
    final cgst = taxableValue * (gstRate / 2) / 100;
    final sgst = taxableValue * (gstRate / 2) / 100;
    final gstTotal = cgst + sgst;
    
    _cgstController.text = cgst.toStringAsFixed(2);
    _sgstController.text = sgst.toStringAsFixed(2);
    _gstTotalController.text = gstTotal.toStringAsFixed(2);

    // Calculate final amount
    double finalAmount = taxableValue + gstTotal;
    finalAmount += double.tryParse(_tcsController.text) ?? 0;
    finalAmount += double.tryParse(_roundOffController.text) ?? 0;
    _finalAmountController.text = finalAmount.toStringAsFixed(2);
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time': _selectedTime != null 
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'vendor': {
          'billNumber': _billNumberController.text,
          'storeName': _storeNameController.text,
          'address': _storeAddressController.text.isNotEmpty ? _storeAddressController.text : null,
          'gstin': _gstinController.text.isNotEmpty ? _gstinController.text : null,
          'stateCode': _stateCodeController.text.isNotEmpty ? _stateCodeController.text : null,
          'pan': _panController.text.isNotEmpty ? _panController.text : null,
          'cin': _cinController.text.isNotEmpty ? _cinController.text : null,
        },
        'items': [
          {
            'productType': _productType,
            'productName': _productNameController.text,
            'productCode': _productCodeController.text.isNotEmpty ? _productCodeController.text : null,
            'hsnCode': _hsnCodeController.text.isNotEmpty ? _hsnCodeController.text : null,
            'quantity': int.tryParse(_quantityController.text) ?? 1,
            'weight': {
              'gross': double.tryParse(_grossWeightController.text) ?? 0,
              'net': double.tryParse(_netWeightController.text) ?? 0,
              'stone': _stoneWeightController.text.isNotEmpty 
                  ? double.tryParse(_stoneWeightController.text) : null,
              'diamondCarats': _diamondCaratsController.text.isNotEmpty 
                  ? double.tryParse(_diamondCaratsController.text) : null,
              'unit': 'grams',
            },
            'metalDetails': {
              'type': _metalType,
              'purity': _purity,
              'ratePerGram': double.tryParse(_ratePerGramController.text) ?? 0,
              'metalValue': double.tryParse(_metalValueController.text) ?? 0,
            },
            'diamondDetails': _diamondCaratsController.text.isNotEmpty ? {
              'carats': double.tryParse(_diamondCaratsController.text) ?? 0,
              'clarity': _clarity,
              'color': _color,
              'cut': _cut,
              'certificateNumber': _certificateNumberController.text.isNotEmpty 
                  ? _certificateNumberController.text : null,
            } : null,
            'charges': {
              'makingCharges': double.tryParse(_makingChargesController.text) ?? 0,
              'hallmarkCharges': _hallmarkChargesController.text.isNotEmpty 
                  ? double.tryParse(_hallmarkChargesController.text) : null,
              'stoneCharges': _stoneChargesController.text.isNotEmpty 
                  ? double.tryParse(_stoneChargesController.text) : null,
              'otherCharges': _otherChargesController.text.isNotEmpty 
                  ? double.tryParse(_otherChargesController.text) : null,
            },
            'grossProductPrice': double.tryParse(_grossProductPriceController.text) ?? 0,
          }
        ],
        'totalAmount': {
          'subtotal': double.tryParse(_subtotalController.text) ?? 0,
          'discounts': _discounts.isNotEmpty ? _discounts : null,
          'taxableValue': double.tryParse(_taxableValueController.text) ?? 0,
          'gst': {
            'cgst': double.tryParse(_cgstController.text) ?? 0,
            'sgst': double.tryParse(_sgstController.text) ?? 0,
            'igst': _igstController.text.isNotEmpty 
                ? double.tryParse(_igstController.text) : null,
            'rate': double.tryParse(_gstRateController.text) ?? 3.0,
            'total': double.tryParse(_gstTotalController.text) ?? 0,
          },
          'tcs': _tcsController.text.isNotEmpty 
              ? double.tryParse(_tcsController.text) : null,
          'roundOff': _roundOffController.text.isNotEmpty 
              ? double.tryParse(_roundOffController.text) : null,
          'finalAmount': double.tryParse(_finalAmountController.text) ?? 0,
        },
        'payments': _payments.isNotEmpty ? _payments : null,
        'loyaltyId': _loyaltyIdController.text.isNotEmpty ? _loyaltyIdController.text : null,
        'marketRates': (_gold24KController.text.isNotEmpty || 
                       _gold22KController.text.isNotEmpty ||
                       _gold18KController.text.isNotEmpty ||
                       _gold14KController.text.isNotEmpty ||
                       _platinum95Controller.text.isNotEmpty) ? {
          'gold24K': _gold24KController.text.isNotEmpty 
              ? double.tryParse(_gold24KController.text) : null,
          'gold22K': _gold22KController.text.isNotEmpty 
              ? double.tryParse(_gold22KController.text) : null,
          'gold18K': _gold18KController.text.isNotEmpty 
              ? double.tryParse(_gold18KController.text) : null,
          'gold14K': _gold14KController.text.isNotEmpty 
              ? double.tryParse(_gold14KController.text) : null,
          'platinum95': _platinum95Controller.text.isNotEmpty 
              ? double.tryParse(_platinum95Controller.text) : null,
        } : null,
      };

      await _storageService.saveInvestment(data, 'diamond_jewellery');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Diamond Jewellery'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveInvestment,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Date & Time Section
            _buildSection(
              'Date & Time',
              [
                ListTile(
                  title: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                  leading: const Icon(Icons.calendar_today),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectDate,
                ),
                ListTile(
                  title: Text(_selectedTime != null 
                      ? _selectedTime!.format(context)
                      : 'Not set (optional)'),
                  leading: const Icon(Icons.access_time),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectTime,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Vendor Details
            _buildSection(
              'Vendor Details',
              [
                _buildTextField(
                  controller: _billNumberController,
                  label: 'Bill Number *',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildTextField(
                  controller: _storeNameController,
                  label: 'Store Name *',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildTextField(
                  controller: _storeAddressController,
                  label: 'Store Address (optional)',
                  maxLines: 2,
                ),
                _buildTextField(
                  controller: _gstinController,
                  label: 'GSTIN (optional)',
                  textCapitalization: TextCapitalization.characters,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _stateCodeController,
                        label: 'State Code',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _panController,
                        label: 'PAN',
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
                _buildTextField(
                  controller: _cinController,
                  label: 'CIN (optional)',
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Product Details
            _buildSection(
              'Product Details',
              [
                DropdownButtonFormField<String>(
                  value: _productType,
                  decoration: const InputDecoration(labelText: 'Product Type'),
                  items: ['Ring', 'Necklace', 'Earrings', 'Bracelet', 'Pendant', 
                         'Bangle', 'Chain', 'Other']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _productType = value!),
                ),
                _buildTextField(
                  controller: _productNameController,
                  label: 'Product Name *',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildTextField(
                  controller: _productCodeController,
                  label: 'Product Code (optional)',
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _hsnCodeController,
                        label: 'HSN Code',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _quantityController,
                        label: 'Qty',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Weight Details
            _buildSection(
              'Weight Details',
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _grossWeightController,
                        label: 'Gross Weight (g) *',
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        onChanged: (_) => _calculateTotals(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _netWeightController,
                        label: 'Net Weight (g) *',
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        onChanged: (_) => _calculateTotals(),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _stoneWeightController,
                        label: 'Stone Weight (g)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _diamondCaratsController,
                        label: 'Diamond (carats)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Metal Details
            _buildSection(
              'Metal Details',
              [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _metalType,
                        decoration: const InputDecoration(labelText: 'Metal Type'),
                        items: ['Gold', 'Platinum', 'Silver']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (value) => setState(() => _metalType = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _purity,
                        decoration: const InputDecoration(labelText: 'Purity'),
                        items: ['24K', '22K', '18K', '14K', '10K', '950 Platinum', '925 Silver']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (value) => setState(() => _purity = value!),
                      ),
                    ),
                  ],
                ),
                _buildTextField(
                  controller: _ratePerGramController,
                  label: 'Rate per Gram (₹) *',
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => _calculateTotals(),
                ),
                _buildTextField(
                  controller: _metalValueController,
                  label: 'Metal Value (₹)',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  enabled: false,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Diamond Details (optional)
            if (_diamondCaratsController.text.isNotEmpty)
              _buildSection(
                'Diamond Details',
                [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _clarity,
                          decoration: const InputDecoration(labelText: 'Clarity'),
                          items: ['IF', 'VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2', 'I1', 'I2']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (value) => setState(() => _clarity = value!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _color,
                          decoration: const InputDecoration(labelText: 'Color'),
                          items: ['D', 'E', 'F', 'G', 'H', 'I', 'J', 'K']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (value) => setState(() => _color = value!),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _cut,
                          decoration: const InputDecoration(labelText: 'Cut'),
                          items: ['Ideal', 'Excellent', 'Very Good', 'Good', 'Fair']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (value) => setState(() => _cut = value!),
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    controller: _certificateNumberController,
                    label: 'Certificate Number (optional)',
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Charges
            _buildSection(
              'Charges',
              [
                _buildTextField(
                  controller: _makingChargesController,
                  label: 'Making Charges (₹) *',
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  onChanged: (_) => _calculateTotals(),
                ),
                _buildTextField(
                  controller: _hallmarkChargesController,
                  label: 'Hallmark Charges (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotals(),
                ),
                _buildTextField(
                  controller: _stoneChargesController,
                  label: 'Stone Charges (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotals(),
                ),
                _buildTextField(
                  controller: _otherChargesController,
                  label: 'Other Charges (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotals(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Discounts
            _buildSection(
              'Discounts',
              [
                ..._discounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final discount = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: discount['type'],
                                  decoration: const InputDecoration(
                                    labelText: 'Type',
                                    isDense: true,
                                  ),
                                  items: ['strike_through', 'coupon', 'product_discount', 
                                         'cash', 'loyalty_points', 'other']
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => discount['type'] = value!);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _removeDiscount(index),
                              ),
                            ],
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              isDense: true,
                            ),
                            onChanged: (value) => discount['description'] = value,
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Amount (₹)',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              discount['amount'] = double.tryParse(value) ?? 0;
                              _calculateTotals();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                OutlinedButton.icon(
                  onPressed: _addDiscount,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Discount'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Amount Calculation
            _buildSection(
              'Amount Calculation',
              [
                _buildTextField(
                  controller: _subtotalController,
                  label: 'Subtotal (₹)',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  enabled: false,
                ),
                _buildTextField(
                  controller: _taxableValueController,
                  label: 'Taxable Value (₹)',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  enabled: false,
                ),
                _buildTextField(
                  controller: _gstRateController,
                  label: 'GST Rate (%)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotals(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cgstController,
                        label: 'CGST (₹)',
                        keyboardType: TextInputType.number,
                        readOnly: true,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _sgstController,
                        label: 'SGST (₹)',
                        keyboardType: TextInputType.number,
                        readOnly: true,
                        enabled: false,
                      ),
                    ),
                  ],
                ),
                _buildTextField(
                  controller: _igstController,
                  label: 'IGST (₹) - for interstate',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotals(),
                ),
                _buildTextField(
                  controller: _gstTotalController,
                  label: 'Total GST (₹)',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  enabled: false,
                ),
                _buildTextField(
                  controller: _tcsController,
                  label: 'TCS (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotals(),
                ),
                _buildTextField(
                  controller: _roundOffController,
                  label: 'Round Off (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateTotals(),
                ),
                _buildTextField(
                  controller: _finalAmountController,
                  label: 'Final Amount (₹)',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                  enabled: false,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Payment Details
            _buildSection(
              'Payment Details',
              [
                ..._payments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final payment = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: payment['method'],
                                  decoration: const InputDecoration(
                                    labelText: 'Method',
                                    isDense: true,
                                  ),
                                  items: ['Cash', 'Card', 'UPI', 'Net Banking', 
                                         'Cheque', 'Gold Exchange', 'Other']
                                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => payment['method'] = value!);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _removePayment(index),
                              ),
                            ],
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Amount (₹)',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              payment['amount'] = double.tryParse(value) ?? 0;
                            },
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Reference/Transaction ID',
                              isDense: true,
                            ),
                            onChanged: (value) => payment['reference'] = value,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                OutlinedButton.icon(
                  onPressed: _addPayment,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Market Rates (optional)
            _buildSection(
              'Market Rates (optional)',
              [
                _buildTextField(
                  controller: _gold24KController,
                  label: '24K Gold Rate (₹/g)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _gold22KController,
                  label: '22K Gold Rate (₹/g)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _gold18KController,
                  label: '18K Gold Rate (₹/g)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _gold14KController,
                  label: '14K Gold Rate (₹/g)',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _platinum95Controller,
                  label: 'Platinum 950 Rate (₹/g)',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Loyalty ID
            _buildSection(
              'Loyalty Program (optional)',
              [
                _buildTextField(
                  controller: _loyaltyIdController,
                  label: 'Loyalty ID / Membership Number',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveInvestment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Investment', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    bool enabled = true,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled,
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        enabled: enabled,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        style: style,
      ),
    );
  }
}
