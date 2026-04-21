/// Wraps DRF's standard paginated response shape.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });

  final int count;
  final List<T> results;
  final String? next;
  final String? previous;

  bool get hasMore => next != null;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      PaginatedResponse(
        count: json['count'] as int? ?? 0,
        next: json['next'] as String?,
        previous: json['previous'] as String?,
        results: (json['results'] as List<dynamic>)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
