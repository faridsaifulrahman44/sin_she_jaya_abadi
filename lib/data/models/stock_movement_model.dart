import '../../core/utils/parsers.dart';

class StockMovementModel {
  const StockMovementModel({
    required this.id,
    required this.idObat,
    required this.qty,
    required this.movementType,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
    required this.createdBy,
  });

  final int id;
  final int idObat;
  final int qty;
  final String movementType;
  final String? referenceType;
  final int? referenceId;
  final DateTime createdAt;
  final int createdBy;

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: parseInt(map['id']),
      idObat: parseInt(map['id_obat']),
      qty: parseInt(map['qty']),
      movementType: parseString(map['movement_type'], fallback: 'ADJUSTMENT'),
      referenceType: parseNullableString(map['reference_type']),
      referenceId: parseNullableInt(map['reference_id']),
      createdAt: parseDate(map['created_at']),
      createdBy: parseInt(map['created_by']),
    );
  }
}
