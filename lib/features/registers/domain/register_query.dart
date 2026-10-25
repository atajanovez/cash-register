import 'cash_register.dart';

enum RegisterFilter { all, open, checked, closed, unsettled }

enum RegisterSort {
  createdAt('created_at'),
  currentAmount('current_amount'),
  realAmount('real_amount'),
  checkedAt('checked_at'),
  closedAt('closed_at');

  const RegisterSort(this.wire);
  final String wire;
}

class RegisterQuery {
  const RegisterQuery({
    this.search = '',
    this.filter = RegisterFilter.all,
    this.sort = RegisterSort.createdAt,
    this.descending = true,
  });

  final String search;
  final RegisterFilter filter;
  final RegisterSort sort;
  final bool descending;

  RegisterQuery copyWith({
    String? search,
    RegisterFilter? filter,
    RegisterSort? sort,
    bool? descending,
  }) => RegisterQuery(
    search: search ?? this.search,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    descending: descending ?? this.descending,
  );

  /// The server has `only_checked` (which includes closed) and `only_closed`,
  /// but no "open only" or "checked but not closed"; those are narrowed in
  /// [applyLocally].
  Map<String, Object> toParams() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (filter == RegisterFilter.checked) 'only_checked': true,
    if (filter == RegisterFilter.closed) 'only_closed': true,
    if (filter == RegisterFilter.unsettled) 'unsettled': true,
    'sort': sort.wire,
    'order': descending ? 'desc' : 'asc',
  };

  /// Also moves pinned registers to the top (the server does not), keeping
  /// the chosen sort within the pinned and the unpinned groups.
  List<CashRegister> applyLocally(List<CashRegister> registers) {
    final filtered = switch (filter) {
      RegisterFilter.open => registers.where(
        (r) => r.status == RegisterStatus.open,
      ),
      RegisterFilter.checked => registers.where(
        (r) => r.status == RegisterStatus.checked,
      ),
      _ => registers,
    };
    return [
      ...filtered.where((r) => r.isPinned),
      ...filtered.where((r) => !r.isPinned),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is RegisterQuery &&
      other.search == search &&
      other.filter == filter &&
      other.sort == sort &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(search, filter, sort, descending);
}
