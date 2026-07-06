/// A single suggestion result carrying the matched item, its similarity score,
/// and its position in the original list.
class SuggestionResult<T> {
  /// The matched item from the candidate list.
  final T item;

  /// Cosine similarity to the anchor (~0–1, higher = more similar).
  final double score;

  /// Position of this item in the original input list.
  final int index;

  const SuggestionResult({
    required this.item,
    required this.score,
    required this.index,
  });

  @override
  String toString() =>
      'SuggestionResult(index: $index, score: ${score.toStringAsFixed(4)}, item: $item)';
}
