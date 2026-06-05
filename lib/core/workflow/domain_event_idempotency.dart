abstract class DomainEventIdempotencyStore {
  bool hasProcessed(String eventId);
  void markProcessed(String eventId);
}

class InMemoryDomainEventIdempotencyStore
    implements DomainEventIdempotencyStore {
  final Set<String> _processedEventIds = <String>{};

  @override
  bool hasProcessed(String eventId) => _processedEventIds.contains(eventId);

  @override
  void markProcessed(String eventId) {
    _processedEventIds.add(eventId);
  }
}
