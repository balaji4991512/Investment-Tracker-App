import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/gold_jewellery_investment.dart';
import '../services/gold_jewellery_repository.dart';
import '../services/json_storage_service.dart';
import '../utils/cred_theme.dart';

class AddGoldJewelleryScreen extends StatefulWidget {
  const AddGoldJewelleryScreen({super.key});

  @override
  State<AddGoldJewelleryScreen> createState() => _AddGoldJewelleryScreenState();
}

class _AddGoldJewelleryScreenState extends State<AddGoldJewelleryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _rateController = TextEditingController();
  final _makingController = TextEditingController();
  final _totalController = TextEditingController();
  final _storeController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  int _purityKarat = 22;
  bool _isSaving = false;

  late final GoldJewelleryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = GoldJewelleryRepository(JsonStorageService());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _rateController.dispose();
    _makingController.dispose();
    _totalController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final uuid = const Uuid();
      final investment = GoldJewelleryInvestment.create(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        dateOfPurchase: _purchaseDate,
        weightGrams: double.parse(_weightController.text.trim()),
        purityKarat: _purityKarat,
        purchaseRatePerGram: double.parse(_rateController.text.trim()),
        makingCharges: double.parse(_makingController.text.trim()),
        totalAmountPaid: double.parse(_totalController.text.trim()),
        storeName: _storeController.text.trim().isEmpty ? null : _storeController.text.trim(),
      );

      await _repository.add(investment);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save investment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM yyyy').format(_purchaseDate);

    return Scaffold(
      backgroundColor: CredTheme.background,
      appBar: AppBar(
        title: const Text('Add Gold Jewellery'),
        backgroundColor: CredTheme.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Item name',
                  hint: 'e.g. 22K Necklace 30g',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                _buildDateField(dateText),
                const SizedBox(height: 12),
                _buildPurityChips(),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _weightController,
                  label: 'Weight (grams)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _rateController,
                  label: 'Purchase rate / gram (₹)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _makingController,
                  label: 'Making charges (₹)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _totalController,
                  label: 'Total amount paid (₹)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberValidator,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _storeController,
                  label: 'Store name (optional)',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CredTheme.gold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: CredTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDateField(String dateText) {
    return GestureDetector(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Purchase date'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateText, style: const TextStyle(color: CredTheme.textPrimary)),
            const Icon(Icons.calendar_today, size: 18, color: CredTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPurityChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Purity', style: TextStyle(color: CredTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [18, 22, 24].map((karat) {
            final selected = karat == _purityKarat;
            return ChoiceChip(
              label: Text('${karat}K'),
              selected: selected,
              onSelected: (_) => setState(() => _purityKarat = karat),
            );
          }).toList(),
        ),
      ],
    );
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final v = double.tryParse(value.trim());
    if (v == null || v <= 0) return 'Enter a valid number';
    return null;
  }
}
