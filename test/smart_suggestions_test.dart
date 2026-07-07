import 'dart:io';
import 'dart:typed_data';

import 'package:ai_core_codespark/ai_core_codespark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

/// A deterministic, model-free embedder. Maps known words to category
/// directions so cosine ranking reproduces validated behavior without
/// downloading a model.
class FakeEmbedder implements SuggestionEmbedder {
  bool _ready = false;
  int batchCalls = 0;

  // [vehicle, fruit, medical, tech]
  static const _lex = {
    'car': [1.0, 0, 0, 0],
    'automobile': [1.0, 0, 0, 0.1],
    'vehicle': [1.0, 0, 0, 0],
    'banana': [0.0, 1, 0, 0],
    'fruit': [0.0, 1, 0, 0],
    'smoothie': [0.0, 1, 0, 0],
    'doctor': [0.0, 0, 1, 0],
    'physician': [0.0, 0, 1, 0],
    'nurse': [0.0, 0, 1, 0.2],
    'engineer': [0.0, 0, 0.1, 1],
    'flutter': [0.0, 0, 0, 1],
  };

  @override
  Future<void> initialize({ProgressCallback? onProgress}) async {
    onProgress?.call(100, 100);
    _ready = true;
  }

  @override
  bool get isInitialized => _ready;

  @override
  int get dimension => 4;

  @override
  Future<Float32List> embed(String text) async => _vec(text);

  @override
  Future<List<Float32List>> embedBatch(List<String> texts) async {
    batchCalls++;
    return [for (final t in texts) _vec(t)];
  }

  Float32List _vec(String text) {
    final acc = <double>[0, 0, 0, 0];
    for (final w in text.toLowerCase().split(RegExp(r'[^a-z]+'))) {
      final base = _lex[w];
      if (base == null) continue;
      for (var i = 0; i < 4; i++) {
        acc[i] += base[i];
      }
    }
    final v = Float32List.fromList(acc);
    return Pooling.l2Normalize(v);
  }

  @override
  Future<void> dispose() async => _ready = false;
}

void main() {
  late SmartSuggestions suggestions;

  setUp(() async {
    suggestions = SmartSuggestions.withEmbedder(FakeEmbedder());
    await suggestions.initialize();
  });

  group('suggest() over strings', () {
    test('ranks similar items above unrelated ones', () async {
      final hits = await suggestions.suggest(
        anchor: 'car',
        candidates: ['automobile', 'banana', 'vehicle'],
      );
      expect(hits.first.item, anyOf('automobile', 'vehicle'));
      expect(hits.last.item, 'banana');
    });

    test('doctor finds physician, not car/engineer', () async {
      final hits = await suggestions.suggest(
        anchor: 'doctor',
        candidates: ['physician', 'car', 'engineer'],
      );
      expect(hits.first.item, 'physician');
    });

    test('topK caps the number of results', () async {
      final hits = await suggestions.suggest(
        anchor: 'car',
        candidates: ['automobile', 'vehicle', 'banana', 'fruit'],
        topK: 2,
      );
      expect(hits.length, 2);
    });

    test('threshold filters weak matches', () async {
      final hits = await suggestions.suggest(
        anchor: 'car',
        candidates: ['automobile', 'banana'],
        threshold: 0.5,
      );
      expect(hits.map((h) => h.item), isNot(contains('banana')));
      expect(hits.map((h) => h.item), contains('automobile'));
    });

    test('result carries original index and a score', () async {
      final hits = await suggestions.suggest(
        anchor: 'car',
        candidates: ['banana', 'automobile'],
      );
      final top = hits.first;
      expect(top.item, 'automobile');
      expect(top.index, 1);
      expect(top.score, greaterThan(0.8));
    });
  });

  group('suggestFor<T>()', () {
    test('suggests typed objects via textOf and returns them', () async {
      final products = [
        (id: 1, name: 'banana smoothie'),
        (id: 2, name: 'family automobile'),
      ];
      final hits = await suggestions.suggestFor(
        anchor: 'car',
        candidates: products,
        textOf: (p) => p.name,
      );
      expect(hits.first.item.id, 2);
    });
  });

  group('suggestLike() multi-anchor', () {
    test('blends multiple anchors to find similar items', () async {
      final hits = await suggestions.suggestLike(
        anchors: ['doctor', 'physician'],
        candidates: ['nurse', 'car', 'banana'],
        textOf: (s) => s,
      );
      expect(hits.first.item, 'nurse');
    });

    test('returns empty for empty anchors', () async {
      final hits = await suggestions.suggestLike(
        anchors: [],
        candidates: ['car', 'banana'],
        textOf: (s) => s,
      );
      expect(hits, isEmpty);
    });
  });

  group('createIndex()', () {
    test('embeds the corpus once, then queries reuse it', () async {
      final fake = FakeEmbedder();
      final s = SmartSuggestions.withEmbedder(fake);
      await s.initialize();

      final index = await s.createIndex(
        items: ['automobile', 'banana', 'physician'],
        textOf: (x) => x,
      );
      final before = fake.batchCalls;

      await index.suggestFor('car');
      await index.suggestFor('doctor');

      expect(fake.batchCalls, before,
          reason: 'queries must not re-embed the corpus');
      final docHit = await index.suggestFor('doctor', topK: 1);
      expect(docHit.first.item, 'physician');
    });

    test('handles an empty corpus', () async {
      final index =
          await suggestions.createIndex<String>(items: [], textOf: (x) => x);
      expect(await index.suggestFor('anything'), isEmpty);
    });
  });

  group('SuggestionIndex.similarTo()', () {
    test('finds items in same category, excludes self', () async {
      final index = await suggestions.createIndex(
        items: ['car', 'automobile', 'banana', 'physician'],
        textOf: (x) => x,
      );
      final hits = await index.similarTo(0, topK: 2);
      expect(hits.map((h) => h.item), contains('automobile'));
      expect(hits.map((h) => h.item), isNot(contains('car')));
    });

    test('respects topK', () async {
      final index = await suggestions.createIndex(
        items: ['car', 'automobile', 'vehicle', 'banana'],
        textOf: (x) => x,
      );
      final hits = await index.similarTo(0, topK: 1);
      expect(hits.length, 1);
    });

    test('throws IndexOutOfRangeException for invalid index', () async {
      final index = await suggestions.createIndex(
        items: ['car', 'banana'],
        textOf: (x) => x,
      );
      expect(
        () => index.similarTo(5),
        throwsA(isA<IndexOutOfRangeException>()),
      );
    });
  });

  group('SuggestionIndex.suggestLike()', () {
    test('averages anchors and ranks by centroid', () async {
      final index = await suggestions.createIndex(
        items: ['car', 'banana', 'nurse', 'engineer'],
        textOf: (x) => x,
      );
      final hits = await index.suggestLike(['doctor', 'physician'], topK: 1);
      expect(hits.first.item, 'nurse');
    });
  });

  group('SuggestionIndex.suggestDiverse()', () {
    test('returns results (MMR mode)', () async {
      final index = await suggestions.createIndex(
        items: ['car', 'automobile', 'vehicle', 'banana'],
        textOf: (x) => x,
      );
      final hits = await index.suggestDiverse('car', topK: 3);
      expect(hits.length, 3);
      expect(hits.first.item, anyOf('car', 'automobile', 'vehicle'));
    });
  });

  group('SuggestionIndex.add()', () {
    test('appends new items without re-embedding existing ones', () async {
      final index =
          await suggestions.createIndex<String>(items: ['banana'], textOf: (x) => x);
      await index.add(['automobile'], textOf: (x) => x);
      expect(index.length, 2);
      final hits = await index.suggestFor('car', topK: 1);
      expect(hits.first.item, 'automobile');
    });
  });

  test('suggesting before initialize throws EngineNotInitializedException',
      () async {
    final s = SmartSuggestions.withEmbedder(FakeEmbedder());
    expect(
      () => s.suggest(anchor: 'x', candidates: ['y']),
      throwsA(isA<EngineNotInitializedException>()),
    );
  });

  group('SmartSuggestions.createWithEmbedder()', () {
    test('factory creates and initializes in one call', () async {
      final s = await SmartSuggestions.createWithEmbedder(FakeEmbedder());
      expect(s.isInitialized, isTrue);
      await s.dispose();
    });

    test('factory instance is ready for suggestions', () async {
      final s = await SmartSuggestions.createWithEmbedder(FakeEmbedder());
      final hits = await s.suggest(
        anchor: 'car',
        candidates: ['automobile', 'banana'],
      );
      expect(hits.first.item, 'automobile');
      await s.dispose();
    });
  });

  group('persistence', () {
    test('save/restore round-trips typed items and ranks correctly', () async {
      final index = await suggestions.createIndex<Map<String, dynamic>>(
        items: [
          {'id': 'a', 'text': 'automobile'},
          {'id': 'b', 'text': 'banana'},
        ],
        textOf: (m) => m['text'] as String,
      );

      final dir = await Directory.systemTemp.createTemp('sscs_suggest_test');
      final path = '${dir.path}/index.json';
      await index.save(path, encode: (m) => m);

      final fake2 = FakeEmbedder();
      final s2 = SmartSuggestions.withEmbedder(fake2);
      await s2.initialize();
      final before = fake2.batchCalls;

      final restored = await s2.loadIndex<Map<String, dynamic>>(
        path: path,
        decode: (json) => json,
      );

      expect(restored.length, 2);
      expect(fake2.batchCalls, before,
          reason: 'restore must not re-embed the corpus');

      final hits = await restored.suggestFor('car', topK: 1);
      expect(hits.first.item['id'], 'a');

      await dir.delete(recursive: true);
    });

    test('restore rejects a dimension mismatch', () async {
      final index =
          await suggestions.createIndex<String>(items: ['car'], textOf: (x) => x);
      final dir = await Directory.systemTemp.createTemp('sscs_dim');
      final path = '${dir.path}/i.json';
      await index.save(path, encode: (s) => {'t': s});

      final f = File(path);
      final json = (await f.readAsString())
          .replaceFirst('"dimension":4', '"dimension":999');
      await f.writeAsString(json);

      expect(
        () => suggestions.loadIndex<String>(
            path: path, decode: (j) => j['t'] as String),
        throwsA(isA<IndexDimensionMismatchException>()),
      );
      await dir.delete(recursive: true);
    });
  });

  group('SuggestionsList widget', () {
    testWidgets('shows suggestions for a text anchor', (tester) async {
      final index = await suggestions.createIndex<String>(
        items: ['automobile', 'banana'],
        textOf: (x) => x,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SuggestionsList<String>(
            index: index,
            anchor: 'car',
            itemBuilder: (c, r) => ListTile(title: Text(r.item)),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.text('automobile'), findsOneWidget);
    });

    testWidgets('shows suggestions for an anchor index', (tester) async {
      final index = await suggestions.createIndex<String>(
        items: ['car', 'automobile', 'banana'],
        textOf: (x) => x,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SuggestionsList<String>(
            index: index,
            anchorIndex: 0,
            itemBuilder: (c, r) => ListTile(title: Text(r.item)),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(find.text('automobile'), findsOneWidget);
      expect(find.text('car'), findsNothing);
    });
  });
}
