import 'package:ai_core_codespark/ai_core_codespark.dart';

/// Base exception for all suggestion-related errors.
class SuggestionException extends CodesparkException {
  const SuggestionException(super.message);
}

/// Thrown when a saved index has a different embedding dimension than the
/// current model (e.g. after a model upgrade).
class IndexDimensionMismatchException extends SuggestionException {
  const IndexDimensionMismatchException({
    required int saved,
    required int current,
  }) : super(
          'Saved index dimension ($saved) does not match the current model '
          '($current). Re-create the index after a model change.',
        );
}

/// Thrown when an operation targets an invalid position in the index.
class IndexOutOfRangeException extends SuggestionException {
  const IndexOutOfRangeException(int index, int length)
      : super('Index $index is out of range for index of length $length.');
}
