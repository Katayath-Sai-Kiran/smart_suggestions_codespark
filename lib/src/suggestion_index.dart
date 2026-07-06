import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ai_core_codespark/ai_core_codespark.dart';

import 'suggestion_embedder.dart';
import 'suggestion_result.dart';

/// A reusable, pre-embedded corpus for repeated suggestions.
///
/// Build it once (it embeds every item up front) then query it as many times
/// as you like — only the anchor is embedded per request. This is the right
/// tool when the dataset is stable and queried often (a catalog, an article
/// list, a help center).
///
/// Persist it with [save] and reload with [SmartSuggestions.loadIndex] so the
/// corpus is embedded **once, ever** — not on every app launch.
class SuggestionIndex<T> {
  final SuggestionEmbedder _embedder;
  final List<T> _items;
  final List<Float32List> _vectors;

  SuggestionIndex._(this._embedder, this._items, this._vectors);

  /// Number of indexed items.
  int get length => _items.length;

  /// The indexed items, in order (read-only view).
  List<T> get items => List.unmodifiable(_items);

  /// Embedding dimensionality (0 for an empty index).
  int get dimension => _vectors.isEmpty ? 0 : _vectors.first.length;

  /// Embeds [items] and returns a ready index.
  static Future<SuggestionIndex<T>> build<T>({
    required SuggestionEmbedder embedder,
    required List<T> items,
    required String Function(T) textOf,
  }) async {
    final vectors = items.isEmpty
        ? <Float32List>[]
        : await embedder.embedBatch([for (final it in items) textOf(it)]);
    return SuggestionIndex._(embedder, List.of(items), List.of(vectors));
  }

  /// Embeds and appends [newItems] to an existing index (no full re-embed).
  Future<void> add(
    List<T> newItems, {
    required String Function(T) textOf,
  }) async {
    if (newItems.isEmpty) return;
    final vecs =
        await _embedder.embedBatch([for (final it in newItems) textOf(it)]);
    _items.addAll(newItems);
    _vectors.addAll(vecs);
  }

  /// Finds items similar to the item at [itemIndex] in this index.
  /// The item itself is excluded from results.
  Future<List<SuggestionResult<T>>> similarTo(
    int itemIndex, {
    int topK = 5,
    double? threshold,
  }) async {
    if (_items.isEmpty) return [];
    RangeError.checkValidIndex(itemIndex, _items);
    final q = _vectors[itemIndex];
    final scored =
        Similarity.topK(q, _vectors, k: topK + 1, threshold: threshold);
    return [
      for (final s in scored)
        if (s.index != itemIndex)
          SuggestionResult(item: _items[s.index], score: s.score, index: s.index),
    ].take(topK).toList();
  }

  /// Suggests items similar to the given [anchor] text.
  Future<List<SuggestionResult<T>>> suggestFor(
    String anchor, {
    int topK = 5,
    double? threshold,
  }) async {
    if (_items.isEmpty) return [];
    final q = await _embedder.embed(anchor);
    final scored = Similarity.topK(q, _vectors, k: topK, threshold: threshold);
    return [
      for (final s in scored)
        SuggestionResult(item: _items[s.index], score: s.score, index: s.index),
    ];
  }

  /// Suggests items similar to multiple [anchors] (e.g. user history).
  /// Averages anchor embeddings into a centroid and ranks by similarity to it.
  Future<List<SuggestionResult<T>>> suggestLike(
    List<String> anchors, {
    int topK = 5,
    double? threshold,
  }) async {
    if (_items.isEmpty || anchors.isEmpty) return [];
    final anchorVecs = await _embedder.embedBatch(anchors);
    final centroid = _averageAndNormalize(anchorVecs);
    if (centroid == null) return [];
    final scored =
        Similarity.topK(centroid, _vectors, k: topK, threshold: threshold);
    return [
      for (final s in scored)
        SuggestionResult(item: _items[s.index], score: s.score, index: s.index),
    ];
  }

  /// Diversity-aware suggestions (MMR) — avoids returning near-duplicate items.
  /// [lambda] trades relevance (1.0) against diversity (0.0).
  Future<List<SuggestionResult<T>>> suggestDiverse(
    String anchor, {
    int topK = 5,
    double lambda = 0.5,
  }) async {
    if (_items.isEmpty) return [];
    final q = await _embedder.embed(anchor);
    final scored = Similarity.mmr(q, _vectors, k: topK, lambda: lambda);
    return [
      for (final s in scored)
        SuggestionResult(item: _items[s.index], score: s.score, index: s.index),
    ];
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  static const int _formatVersion = 1;

  /// Saves the index (items + vectors) to [path] as JSON so it can be reloaded
  /// without re-embedding.
  Future<void> save(
    String path, {
    required Map<String, dynamic> Function(T item) encode,
  }) async {
    final json = {
      'version': _formatVersion,
      'dimension': dimension,
      'records': [
        for (var i = 0; i < _items.length; i++)
          {'item': encode(_items[i]), 'v': _encodeVector(_vectors[i])},
      ],
    };
    await File(path).writeAsString(jsonEncode(json));
  }

  /// Restores an index previously written with [save].
  ///
  /// Throws [StateError] if the saved embedding dimension doesn't match the
  /// embedder's (i.e. the model changed).
  static Future<SuggestionIndex<T>> restore<T>({
    required SuggestionEmbedder embedder,
    required String path,
    required T Function(Map<String, dynamic> json) decode,
  }) async {
    final raw = jsonDecode(await File(path).readAsString());
    final json = raw as Map<String, dynamic>;
    final savedDim = json['dimension'] as int? ?? 0;

    if (embedder.isInitialized &&
        savedDim != 0 &&
        embedder.dimension != savedDim) {
      throw StateError(
        'Saved index dimension ($savedDim) does not match the current model '
        '(${embedder.dimension}). Re-create the index after a model change.',
      );
    }

    final items = <T>[];
    final vectors = <Float32List>[];
    for (final r in (json['records'] as List)) {
      final m = r as Map<String, dynamic>;
      items.add(decode((m['item'] as Map).cast<String, dynamic>()));
      vectors.add(_decodeVector(m['v'] as String));
    }
    return SuggestionIndex._(embedder, items, vectors);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Float32List? _averageAndNormalize(List<Float32List> vecs) {
    if (vecs.isEmpty) return null;
    final dim = vecs.first.length;
    final avg = Float32List(dim);
    for (final v in vecs) {
      for (var i = 0; i < dim; i++) {
        avg[i] += v[i];
      }
    }
    final n = vecs.length.toDouble();
    for (var i = 0; i < dim; i++) {
      avg[i] /= n;
    }
    var norm = 0.0;
    for (var i = 0; i < dim; i++) {
      norm += avg[i] * avg[i];
    }
    norm = sqrt(norm);
    if (norm == 0.0) return null;
    for (var i = 0; i < dim; i++) {
      avg[i] /= norm;
    }
    return avg;
  }

  static String _encodeVector(Float32List v) =>
      base64Encode(v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes));

  static Float32List _decodeVector(String s) {
    final bytes = base64Decode(s);
    final out = Float32List(bytes.length ~/ 4);
    out.buffer.asUint8List(out.offsetInBytes, out.lengthInBytes).setAll(0, bytes);
    return out;
  }
}
