// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_airtable/otel_airtable.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_airtable-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Orders.create records CLIENT span', () async {
    await tracedAirtable<String>(
      baseId: 'appXXX',
      tableName: 'Orders',
      action: 'create',
      recordId: 'rec-1',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('airtable Orders.create')!);
    expect(a['airtable.base.id'], 'appXXX');
    expect(a['airtable.table'], 'Orders');
    expect(a['airtable.action'], 'create');
    expect(a['airtable.operation'], 'Orders.create');
    expect(a['airtable.record.id'], 'rec-1');
  });

  test('suppression skips spans', () async {
    await runWithoutAirtableInstrumentationAsync(() async {
      await tracedAirtable<String>(
        baseId: 'b',
        tableName: 't',
        action: 'a',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('airtable '), isEmpty);
  });
}
