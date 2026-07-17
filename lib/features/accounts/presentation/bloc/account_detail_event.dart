import 'package:equatable/equatable.dart';

abstract class AccountDetailEvent extends Equatable {
  const AccountDetailEvent();
  @override
  List<Object?> get props => [];
}

class AccountDetailLoadRequested extends AccountDetailEvent {
  final String id;
  const AccountDetailLoadRequested(this.id);
  @override
  List<Object?> get props => [id];
}
