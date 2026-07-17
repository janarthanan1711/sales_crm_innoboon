import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';

abstract class DealsListState extends Equatable {
  const DealsListState();
  @override
  List<Object?> get props => [];
}

class DealsListInitial extends DealsListState {
  const DealsListInitial();
}

class DealsListLoading extends DealsListState {
  const DealsListLoading();
}

class DealsListLoaded extends DealsListState {
  final List<Deal> deals;
  final String? ownerFilter;
  final String? tierFilter;

  const DealsListLoaded({
    required this.deals,
    this.ownerFilter,
    this.tierFilter,
  });

  @override
  List<Object?> get props => [deals, ownerFilter, tierFilter];
}

class DealsListError extends DealsListState {
  final String message;
  const DealsListError(this.message);
  @override
  List<Object?> get props => [message];
}
