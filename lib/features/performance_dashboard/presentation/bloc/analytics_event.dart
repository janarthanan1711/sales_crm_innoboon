import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class AnalyticsLoadRequested extends AnalyticsEvent {
  final String period;
  const AnalyticsLoadRequested({this.period = 'Monthly'});
  @override
  List<Object?> get props => [period];
}
