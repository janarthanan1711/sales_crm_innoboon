import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';

abstract class DealDetailState extends Equatable {
  const DealDetailState();
  @override
  List<Object?> get props => [];
}

class DealDetailInitial extends DealDetailState {
  const DealDetailInitial();
}

class DealDetailLoading extends DealDetailState {
  const DealDetailLoading();
}

class DealDetailLoaded extends DealDetailState {
  final Deal deal;
  const DealDetailLoaded(this.deal);
  @override
  List<Object?> get props => [deal];
}

class DealDetailError extends DealDetailState {
  final String message;
  const DealDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
