import 'domain_event_envelope.dart';
import 'domain_event_idempotency.dart';
import 'domain_events.dart';

typedef DomainEventHandler = void Function(DomainEventEnvelope envelope);

class DomainEventDispatcher {
  DomainEventDispatcher._();

  static final Map<String, List<DomainEventHandler>> _handlersByType =
      <String, List<DomainEventHandler>>{};
  static DomainEventIdempotencyStore _idempotencyStore =
      InMemoryDomainEventIdempotencyStore();

  static void configureIdempotencyStore(DomainEventIdempotencyStore store) {
    _idempotencyStore = store;
  }

  static void register(String eventType, DomainEventHandler handler) {
    final handlers = _handlersByType.putIfAbsent(
      eventType,
      () => <DomainEventHandler>[],
    );
    handlers.add(handler);
  }

  static void clearHandlers({String? eventType}) {
    if (eventType == null) {
      _handlersByType.clear();
      return;
    }
    _handlersByType.remove(eventType);
  }

  static void dispatch(
    DomainEvent event, {
    String? eventId,
    String? correlationId,
  }) {
    final envelope = DomainEventEnvelope(
      eventId: eventId ?? _buildEventId(event),
      correlationId: correlationId ?? _buildCorrelationId(event),
      event: event,
    );
    if (_idempotencyStore.hasProcessed(envelope.eventId)) return;
    _idempotencyStore.markProcessed(envelope.eventId);

    final handlers = _handlersByType[event.eventType];
    if (handlers == null || handlers.isEmpty) return;
    for (final handler in handlers) {
      handler(envelope);
    }
  }

  static String _buildEventId(DomainEvent event) {
    return '${event.eventType}-${event.occurredAt.microsecondsSinceEpoch}';
  }

  static String _buildCorrelationId(DomainEvent event) {
    return 'corr-${event.occurredAt.millisecondsSinceEpoch}';
  }
}
