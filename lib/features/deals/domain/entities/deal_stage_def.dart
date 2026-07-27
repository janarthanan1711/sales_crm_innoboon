import 'package:equatable/equatable.dart';

/// A pipeline stage — dynamic and admin-configurable per company (see
/// `/deal-stages`). Replaces the old hardcoded `DealStage` enum. `isCold`
/// marks a terminal "went cold" stage, which gates the `cold_reason`
/// requirement on deal create/update.
class DealStageDef extends Equatable {
  final int id;
  final int? companyId;
  final String name;
  final int sortOrder;
  final bool isCold;

  const DealStageDef({
    required this.id,
    this.companyId,
    required this.name,
    this.sortOrder = 0,
    this.isCold = false,
  });

  @override
  List<Object?> get props => [id, companyId, name, sortOrder, isCold];
}
