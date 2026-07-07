import 'dart:math';
import 'dart:typed_data';

import 'package:ai_core_codespark/ai_core_codespark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

/// A fast embedder for benchmarking (deterministic, no model download).
class _BenchEmbedder implements SuggestionEmbedder {
  bool _ready = false;
  final _rng = Random(42);

  @override
  Future<void> initialize({ProgressCallback? onProgress}) async {
    _ready = true;
  }

  @override
  bool get isInitialized => _ready;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async => _randomVec();

  @override
  Future<List<Float32List>> embedBatch(List<String> texts) async =>
      [for (final _ in texts) _randomVec()];

  Float32List _randomVec() {
    final v = Float32List(384);
    for (var i = 0; i < 384; i++) {
      v[i] = _rng.nextDouble();
    }
    return Pooling.l2Normalize(v);
  }

  @override
  Future<void> dispose() async => _ready = false;
}

void main() {
  final embedder = _BenchEmbedder();
  late SmartSuggestions suggestions;

  setUp(() async {
    suggestions = SmartSuggestions.withEmbedder(embedder);
    await suggestions.initialize();
  });

  tearDown(() async {
    await suggestions.dispose();
  });

  group('benchmark', () {
    test('topK ranking on 1000 items (cold)', () async {
      final items = List.generate(1000, (i) => 'item_$i');

      final stopwatch = Stopwatch()..start();
      final hits = await suggestions.suggest(
        anchor: 'query',
        candidates: items,
        topK: 10,
      );
      stopwatch.stop();

      expect(hits, hasLength(10));
      print('  topK(1000, k=10): ${stopwatch.elapsedMilliseconds} ms');
    });

    test('topK ranking on 5000 items (cold)', () async {
      final items = List.generate(5000, (i) => 'item_$i');

      final stopwatch = Stopwatch()..start();
      final hits = await suggestions.suggest(
        anchor: 'query',
        candidates: items,
        topK: 20,
      );
      stopwatch.stop();

      expect(hits, hasLength(20));
      print('  topK(5000, k=20): ${stopwatch.elapsedMilliseconds} ms');
    });

    test('similarTo from a 1000-item index', () async {
      final items = List.generate(1000, (i) => 'item_$i');
      final index = await suggestions.createIndex(
        items: items,
        textOf: (s) => s,
      );

      final stopwatch = Stopwatch()..start();
      final hits = await index.similarTo(0, topK: 10);
      stopwatch.stop();

      expect(hits, hasLength(10));
      print('  similarTo(1000, k=10): ${stopwatch.elapsedMilliseconds} ms');
    });

    test('suggestDiverse on 1000 items', () async {
      final items = List.generate(1000, (i) => 'item_$i');
      final index = await suggestions.createIndex(
        items: items,
        textOf: (s) => s,
      );

      final stopwatch = Stopwatch()..start();
      final hits = await index.suggestDiverse('query', topK: 10, lambda: 0.5);
      stopwatch.stop();

      expect(hits, hasLength(10));
      print('  suggestDiverse(1000, k=10): ${stopwatch.elapsedMilliseconds} ms');
    });
  });
}
