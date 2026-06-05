import 'domain_events.dart';

class DomainEventEnvelope {
  final String eventId;
  final String correlationId;
  final DomainEvent event;

  const DomainEventEnvelope({
    required this.eventId,
    required this.correlationId,
    required this.event,
  });
}
