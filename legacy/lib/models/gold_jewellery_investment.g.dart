// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gold_jewellery_investment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoldJewelleryInvestment _$GoldJewelleryInvestmentFromJson(
        Map<String, dynamic> json) =>
    GoldJewelleryInvestment(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'gold_jewellery',
      dateOfPurchase: DateTime.parse(json['dateOfPurchase'] as String),
      weightGrams: (json['weightGrams'] as num).toDouble(),
      purityKarat: (json['purityKarat'] as num).toInt(),
      purchaseRatePerGram: (json['purchaseRatePerGram'] as num).toDouble(),
      makingCharges: (json['makingCharges'] as num).toDouble(),
      totalAmountPaid: (json['totalAmountPaid'] as num).toDouble(),
      storeName: json['storeName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GoldJewelleryInvestmentToJson(
        GoldJewelleryInvestment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'dateOfPurchase': instance.dateOfPurchase.toIso8601String(),
      'weightGrams': instance.weightGrams,
      'purityKarat': instance.purityKarat,
      'purchaseRatePerGram': instance.purchaseRatePerGram,
      'makingCharges': instance.makingCharges,
      'totalAmountPaid': instance.totalAmountPaid,
      'storeName': instance.storeName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
