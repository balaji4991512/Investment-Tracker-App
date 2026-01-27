import 'package:investment_tracker/models/gold_jewellery_investment.dart';
import 'json_storage_service.dart';

class GoldJewelleryRepository {
  GoldJewelleryRepository(this._storageService);

  final JsonStorageService _storageService;

  static const String _category = 'gold_jewellery';

  Future<List<GoldJewelleryInvestment>> getAll() async {
    final raw = await _storageService.getInvestmentsByCategory(_category);
    return raw
        .map((e) => GoldJewelleryInvestment.fromJson(e))
        .toList(growable: false);
  }

  Future<void> add(GoldJewelleryInvestment investment) async {
    await _storageService.saveInvestment(investment.toJson(), _category);
  }

  Future<void> update(GoldJewelleryInvestment investment) async {
    await _storageService.updateInvestment(investment.id, _category, investment.toJson());
  }

  Future<void> delete(String id) async {
    await _storageService.deleteInvestment(id, _category);
  }
}
