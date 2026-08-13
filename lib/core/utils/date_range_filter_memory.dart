/// Remembers a list page's last-applied custom date-range filter across
/// visits.
///
/// Each list page's bloc is a fresh instance every time you navigate to it
/// (GoRouter tears the page down when you leave, same as `DashboardBloc`), so
/// without this, coming back always drops the date range you picked back to
/// "no filter". One plain singleton per feature (not a bloc), registered in
/// `injector.dart`, so it survives that -- mirrors `DashboardFilterMemory`,
/// which solves the same problem for the dashboard's period toggle.
class DateRangeFilterMemory {
  DateTime? dateFrom;
  DateTime? dateTo;
}

class LeadsFilterMemory extends DateRangeFilterMemory {}

class AccountsFilterMemory extends DateRangeFilterMemory {}

class ContactsFilterMemory extends DateRangeFilterMemory {}

class DealsFilterMemory extends DateRangeFilterMemory {}

class UsersFilterMemory extends DateRangeFilterMemory {}
