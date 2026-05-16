// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_airtable_suppression.dart';

const _tracerName = 'dartastic_otel_libs_airtable';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any Airtable REST API call in a CLIENT span.
Future<T> tracedAirtable<T>({
  required String baseId,
  required String tableName,
  required String action,
  required Future<T> Function() invoke,
  String? recordId,
}) async {
  if (airtableInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'airtable.base.id': baseId,
    'airtable.table': tableName,
    'airtable.action': action,
    'airtable.operation': '$tableName.$action',
  };
  if (recordId != null) m['airtable.record.id'] = recordId;

  final span = _tracer().startSpan(
    'airtable $tableName.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
