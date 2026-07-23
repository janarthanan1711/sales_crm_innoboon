import '../../domain/entities/deal_stage_def.dart';

DealStageDef dealStageDefFromJson(Map<String, dynamic> json) {
  return DealStageDef(
    id: json['id'] as int,
    companyId: json['company_id'] as int?,
    name: json['name'] as String? ?? 'Stage ${json['id']}',
    sortOrder: json['sort_order'] as int? ?? 0,
    isCold: json['is_cold'] as bool? ?? false,
  );
}
