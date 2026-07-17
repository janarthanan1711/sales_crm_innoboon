import 'package:equatable/equatable.dart';

abstract class ChecklistEvent extends Equatable {
  const ChecklistEvent();
  @override
  List<Object?> get props => [];
}

class ChecklistLoadForDealRequested extends ChecklistEvent {
  final String dealId;
  const ChecklistLoadForDealRequested(this.dealId);
  @override
  List<Object?> get props => [dealId];
}

class ChecklistItemToggled extends ChecklistEvent {
  final String itemId;
  final bool isCompleted;
  const ChecklistItemToggled(this.itemId, this.isCompleted);
  @override
  List<Object?> get props => [itemId, isCompleted];
}
