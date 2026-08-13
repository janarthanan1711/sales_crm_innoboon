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

/// True when moving a deal into [stage] needs a reason. The API requires
/// `cold_reason` for cold stages *and* Closed Lost specifically
/// (`ColdReasonRequiredError`, `deal_service.py`) — `DealStage` only exposes
/// `isCold`, so Closed Lost needs a name check the same way the backend does.
bool dealStageRequiresReason(DealStageDef stage) =>
    stage.isCold || stage.name == 'Closed Lost';
