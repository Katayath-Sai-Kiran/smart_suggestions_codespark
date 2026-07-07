import 'dart:typed_data';

import 'package:ai_core_codespark/ai_core_codespark.dart';

/// The minimal embedding contract [SmartSuggestions] depends on.
///
/// Kept as an interface so the suggestion logic can be unit-tested with a fake
/// backend (no 23 MB model download in CI) and so advanced users can plug in a
/// different embedding source later.
abstract class SuggestionEmbedder {
  Future<void> initialize({ProgressCallback? onProgress});
  bool get isInitialized;
  int get dimension;

  Future<Float32List> embed(String text);
  Future<List<Float32List>> embedBatch(List<String> texts);

  Future<void> dispose();
}

/// Default backend: adapts [CodesparkEngine] (ai_core_codespark) to
/// [SuggestionEmbedder]. This is what runs in real apps.
/// Default backend: adapts [CodesparkEngine] (ai_core_codespark) to
/// [SuggestionEmbedder]. This is what runs in real apps.
class CodesparkBackend implements SuggestionEmbedder {
  /// Wraps the given [engine].
  CodesparkBackend(this.engine);

  /// Convenience factory using the default MiniLM-L6 v2 model.
  factory CodesparkBackend.miniLm() =>
      CodesparkBackend(CodesparkEngine(model: ModelCatalog.miniLmL6V2));

  /// The underlying [CodesparkEngine] instance.
  final CodesparkEngine engine;

  @override
  Future<void> initialize({ProgressCallback? onProgress}) =>
      engine.initialize(onProgress: onProgress);

  @override
  bool get isInitialized => engine.isInitialized;

  /// Embedding dimensionality of the loaded model.
  @override
  int get dimension => engine.dimension;

  /// Embeds a single [text] and returns its vector representation.
  @override
  Future<Float32List> embed(String text) => engine.embed(text);

  /// Embeds a batch of [texts] and returns their vector representations.
  @override
  Future<List<Float32List>> embedBatch(List<String> texts) =>
      engine.embedBatch(texts);

  /// Releases model resources.
  @override
  Future<void> dispose() => engine.dispose();
}
