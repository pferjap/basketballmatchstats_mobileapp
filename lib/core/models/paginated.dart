/// A page of results plus its pagination metadata.
///
/// Wraps a REST list response (`data` + `meta.page/limit/total`) so callers can
/// page through matches, events, etc. without re-parsing the envelope. Kept in
/// `core` so any feature can reuse it from the domain layer.
class Paginated<T> {
  const Paginated({
    required this.items,
    this.page,
    this.limit,
    this.total,
  });

  /// The items on the current page.
  final List<T> items;

  /// 1-based page index, when reported by the backend.
  final int? page;

  /// Requested page size, when reported by the backend.
  final int? limit;

  /// Total number of items across all pages, when reported by the backend.
  final int? total;

  /// Whether more pages are expected after this one.
  bool get hasMore {
    final page = this.page;
    final limit = this.limit;
    final total = this.total;
    if (page == null || limit == null || total == null) {
      return false;
    }
    return page * limit < total;
  }

  /// Returns a new [Paginated] with each item mapped by [convert].
  Paginated<R> map<R>(R Function(T item) convert) => Paginated<R>(
        items: items.map(convert).toList(growable: false),
        page: page,
        limit: limit,
        total: total,
      );
}
