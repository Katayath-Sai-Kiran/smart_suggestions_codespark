import 'package:ai_core_codespark/ai_core_codespark.dart';

import 'suggestion_embedder.dart';
import 'suggestion_index.dart';
import 'suggestion_result.dart';

/// On-device "related items" — find similar content by meaning.
///
/// ```dart
/// final suggestions = await SmartSuggestions.create();
/// final hits = await suggestions.suggest(
///   anchor: 'running shoes',
///   candidates: ['sneakers', 'formal boots', 'sandals'],
/// );
/// // hits.first.item == 'sneakers'
/// ```
///
/// For a dataset you query repeatedly, build a [SuggestionIndex] with
/// [createIndex] so items are embedded once rather than on every call.
class SmartSuggestions {
  final SuggestionEmbedder _embedder;

  /// Uses the default on-device model (MiniLM-L6, ~23 MB, downloaded on first
  /// [initialize]).
  SmartSuggestions({ModelConfig? model})
      : _embedder = CodesparkBackend(
          CodesparkEngine(model: model ?? ModelCatalog.miniLmL6V2),
        );

  /// Inject any [SuggestionEmbedder] — used for tests and custom backends.
  SmartSuggestions.withEmbedder(this._embedder);

  /// Creates and initializes in one step.
  ///
  /// ```dart
  /// final suggestions = await SmartSuggestions.create();
  /// ```
  ///
  /// Equivalent to `final s = SmartSuggestions(); await s.initialize();`.
  static Future<SmartSuggestions> create({
    ModelConfig? model,
    ProgressCallback? onProgress,
  }) async {
    final s = SmartSuggestions(model: model);
    await s.initialize(onProgress: onProgress);
    return s;
  }

  /// Creates and initializes with a custom [SuggestionEmbedder] in one step.
  ///
  /// Useful for tests (inject a fake embedder) or custom backends.
  static Future<SmartSuggestions> createWithEmbedder(
    SuggestionEmbedder embedder, {
    ProgressCallback? onProgress,
  }) async {
    final s = SmartSuggestions.withEmbedder(embedder);
    await s.initialize(onProgress: onProgress);
    return s;
  }

  bool get isInitialized => _embedder.isInitialized;

  /// Downloads + loads the model if needed. Idempotent.
  Future<void> initialize({ProgressCallback? onProgress}) =>
      _embedder.initialize(onProgress: onProgress);

  /// One-shot: rank [candidates] by similarity to [anchor].
  Future<List<SuggestionResult<String>>> suggest({
    required String anchor,
    required List<String> candidates,
    int topK = 5,
    double? threshold,
  }) =>
      suggestFor<String>(
        anchor: anchor,
        candidates: candidates,
        textOf: (s) => s,
        topK: topK,
        threshold: threshold,
      );

  /// One-shot: rank typed [candidates] by similarity to [anchor].
  ///
  /// ```dart
  /// final hits = await suggestions.suggestFor<Article>(
  ///   anchor: currentArticle.title,
  ///   candidates: allArticles,
  ///   textOf: (a) => '${a.title} ${a.summary}',
  /// );
  /// ```
  Future<List<SuggestionResult<T>>> suggestFor<T>({
    required String anchor,
    required List<T> candidates,
    required String Function(T) textOf,
    int topK = 5,
    double? threshold,
  }) async {
    _ensureReady();
    final index = await SuggestionIndex.build(
      embedder: _embedder,
      items: candidates,
      textOf: textOf,
    );
    return index.suggestFor(anchor, topK: topK, threshold: threshold);
  }

  /// One-shot: rank [candidates] by similarity to multiple [anchors] (e.g.
  /// user history). Embeddings are averaged into a centroid.
  Future<List<SuggestionResult<T>>> suggestLike<T>({
    required List<String> anchors,
    required List<T> candidates,
    required String Function(T) textOf,
    int topK = 5,
    double? threshold,
  }) async {
    _ensureReady();
    final index = await SuggestionIndex.build(
      embedder: _embedder,
      items: candidates,
      textOf: textOf,
    );
    return index.suggestLike(anchors, topK: topK, threshold: threshold);
  }

  /// Builds a reusable [SuggestionIndex] (embeds items once).
  Future<SuggestionIndex<T>> createIndex<T>({
    required List<T> items,
    required String Function(T) textOf,
  }) {
    _ensureReady();
    return SuggestionIndex.build(
      embedder: _embedder,
      items: items,
      textOf: textOf,
    );
  }

  /// Loads an index previously written with [SuggestionIndex.save].
  Future<SuggestionIndex<T>> loadIndex<T>({
    required String path,
    required T Function(Map<String, dynamic> json) decode,
  }) {
    _ensureReady();
    return SuggestionIndex.restore<T>(
      embedder: _embedder,
      path: path,
      decode: decode,
    );
  }

  void _ensureReady() {
    if (!isInitialized) {
      throw const EngineNotInitializedException(
        'SmartSuggestions.initialize() must be awaited before suggesting.',
      );
    }
  }

  Future<void> dispose() => _embedder.dispose();
}
