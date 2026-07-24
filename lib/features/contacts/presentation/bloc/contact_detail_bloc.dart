import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/contact.dart';
import '../../domain/usecases/contact_usecases.dart';

// ─── Events ─────────────────────────────────────────────
abstract class ContactDetailEvent extends Equatable {
  const ContactDetailEvent();
  @override
  List<Object?> get props => [];
}

class ContactDetailLoadRequested extends ContactDetailEvent {
  final int id;
  const ContactDetailLoadRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// ─── States ─────────────────────────────────────────────
abstract class ContactDetailState extends Equatable {
  const ContactDetailState();
  @override
  List<Object?> get props => [];
}

class ContactDetailLoading extends ContactDetailState {
  const ContactDetailLoading();
}

class ContactDetailLoaded extends ContactDetailState {
  final ContactOverview overview;
  final List<ContactDeal> deals;
  const ContactDetailLoaded({required this.overview, required this.deals});
  @override
  List<Object?> get props => [overview, deals];
}

class ContactDetailError extends ContactDetailState {
  final String message;
  const ContactDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───────────────────────────────────────────────
class ContactDetailBloc extends Bloc<ContactDetailEvent, ContactDetailState> {
  final GetContactOverviewUseCase getContactOverviewUseCase;
  final GetContactDealsUseCase getContactDealsUseCase;

  ContactDetailBloc({
    required this.getContactOverviewUseCase,
    required this.getContactDealsUseCase,
  }) : super(const ContactDetailLoading()) {
    on<ContactDetailLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(ContactDetailLoadRequested event, Emitter<ContactDetailState> emit) async {
    emit(const ContactDetailLoading());
    final overviewResult = await getContactOverviewUseCase(event.id);
    await overviewResult.fold(
      (f) async => emit(ContactDetailError(f.message)),
      (overview) async {
        // Deals are secondary — a failure there shouldn't blank the page.
        final dealsResult = await getContactDealsUseCase(event.id);
        final deals = dealsResult.fold((_) => <ContactDeal>[], (d) => d);
        emit(ContactDetailLoaded(overview: overview, deals: deals));
      },
    );
  }
}
