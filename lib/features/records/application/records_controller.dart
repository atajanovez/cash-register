import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_providers.dart';
import '../data/records_repository.dart';
import '../domain/cash_record.dart';
import '../domain/record_type.dart';

/// Filters for a register's record list, kept per register.
final recordQueryProvider = NotifierProvider.autoDispose
    .family<RecordQueryNotifier, RecordQuery, String>(
      (_) => RecordQueryNotifier(),
    );

class RecordQueryNotifier extends Notifier<RecordQuery> {
  @override
  RecordQuery build() => const RecordQuery();

  void update(RecordQuery Function(RecordQuery) change) =>
      state = change(state);

  void reset() => state = const RecordQuery();
}

/// Openings of [type] in a register that still have something left to
/// settle, oldest deadline first. Feeds the settlement picker.
final unsettledOpeningsProvider = FutureProvider.autoDispose
    .family<List<CashRecord>, ({String registerId, RecordType type})>((
      ref,
      args,
    ) async {
      ref.watch(dataRevisionProvider);
      final records = await ref
          .watch(recordsRepositoryProvider)
          .list(
            args.registerId,
            RecordQuery(type: args.type, onlyUnsettled: true),
            limit: 200,
          );
      return records.where((r) => r.remaining > 0).toList()..sort(
        (a, b) =>
            (a.deadline ?? a.createdAt).compareTo(b.deadline ?? b.createdAt),
      );
    });

class RecordsPage {
  const RecordsPage({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<CashRecord> items;
  final bool hasMore;
  final bool loadingMore;
  final ApiException? loadMoreError;

  RecordsPage copyWith({
    List<CashRecord>? items,
    bool? hasMore,
    bool? loadingMore,
    ApiException? Function()? loadMoreError,
  }) => RecordsPage(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
  );
}

/// Records of one register, paged. Rebuilds from the first page whenever the
/// register's [RecordQuery] changes.
final recordsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<RecordsController, RecordsPage, String>(RecordsController.new);

class RecordsController extends AsyncNotifier<RecordsPage> {
  RecordsController(this.registerId);

  final String registerId;

  RecordsRepository get _repo => ref.read(recordsRepositoryProvider);

  @override
  Future<RecordsPage> build() async {
    ref.watch(dataRevisionProvider);
    final query = ref.watch(recordQueryProvider(registerId));
    // When local data changes, keep as many rows as were already shown so
    // the list does not jump back to the first page.
    final shown = state.value?.items.length ?? 0;
    final limit = max(RecordsRepository.pageSize, shown);
    final items = await _repo.list(registerId, query, limit: limit);
    return RecordsPage(items: items, hasMore: items.length == limit);
  }

  Future<void> loadMore() async {
    final page = state.value;
    if (page == null || !page.hasMore || page.loadingMore) return;
    state = AsyncData(
      page.copyWith(loadingMore: true, loadMoreError: () => null),
    );
    try {
      final next = await _repo.list(
        registerId,
        ref.read(recordQueryProvider(registerId)),
        offset: page.items.length,
      );
      state = AsyncData(
        page.copyWith(
          items: [...page.items, ...next],
          hasMore: next.length == RecordsRepository.pageSize,
          loadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      state = AsyncData(
        page.copyWith(loadingMore: false, loadMoreError: () => e),
      );
    }
  }
}
