import 'package:json_annotation/json_annotation.dart';

part 'gold_jewellery_investment.g.dart';

@JsonSerializable()
class GoldJewelleryInvestment {
  final String id;
  final String name;
  final String category;
  final DateTime dateOfPurchase;
  final double weightGrams;
  final int purityKarat;
  final double purchaseRatePerGram;
  final double makingCharges;
  final double totalAmountPaid;
  final String? storeName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoldJewelleryInvestment({
    required this.id,
    required this.name,
    this.category = 'gold_jewellery',
    required this.dateOfPurchase,
    required this.weightGrams,
    required this.purityKarat,
    required this.purchaseRatePerGram,
    required this.makingCharges,
    required this.totalAmountPaid,
    this.storeName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoldJewelleryInvestment.create({
    required String id,
    required String name,
    required DateTime dateOfPurchase,
    required double weightGrams,
    required int purityKarat,
    required double purchaseRatePerGram,
    required double makingCharges,
    required double totalAmountPaid,
    String? storeName,
  }) {
    final now = DateTime.now();
    return GoldJewelleryInvestment(
      id: id,
      name: name,
      dateOfPurchase: dateOfPurchase,
      weightGrams: weightGrams,
      purityKarat: purityKarat,
      purchaseRatePerGram: purchaseRatePerGram,
      makingCharges: makingCharges,
      totalAmountPaid: totalAmountPaid,
      storeName: storeName,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory GoldJewelleryInvestment.fromJson(Map<String, dynamic> json) =>
      _$GoldJewelleryInvestmentFromJson(json);

  Map<String, dynamic> toJson() => _$GoldJewelleryInvestmentToJson(this);
}
