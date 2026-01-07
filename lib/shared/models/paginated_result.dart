/// Generic paginated result wrapper for API responses.
/// 
/// Used to standardize pagination across all list endpoints.
/// 
/// Example usage:
/// ```dart
/// final result = PaginatedResult<Provider>(
///   items: providers,
///   total: 100,
///   page: 1,
///   limit: 20,
/// );
/// if (result.hasMore) {
///   // Load next page
/// }
/// ```
class PaginatedResult<T> {
  /// The items for the current page
  final List<T> items;
  
  /// Total number of items across all pages
  final int total;
  
  /// Current page number (1-indexed)
  final int page;
  
  /// Number of items per page
  final int limit;

  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// Total number of pages
  int get totalPages => (total / limit).ceil();

  /// Whether there are more pages available
  bool get hasMore => page < totalPages;

  /// Whether this is the first page
  bool get isFirstPage => page == 1;

  /// Whether this is the last page
  bool get isLastPage => page >= totalPages;

  /// Factory to create from a JSON response with items parser
  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonItem,
  ) {
    final items = (json['items'] as List)
        .map((item) => fromJsonItem(item as Map<String, dynamic>))
        .toList();
    
    return PaginatedResult(
      items: items,
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }

  /// Map items to a different type
  PaginatedResult<R> map<R>(R Function(T) mapper) {
    return PaginatedResult<R>(
      items: items.map(mapper).toList(),
      total: total,
      page: page,
      limit: limit,
    );
  }
}
