## 0.1.0

Initial release — on-device "related items" suggestions for Flutter.

- **`SmartSuggestions`**: one-call API to rank candidates by similarity to an
  anchor, fully on-device (no API keys, no cloud).
- **`suggest()` / `suggestFor<T>()`**: one-shot suggestions with `topK` and
  optional cosine `threshold`.
- **`suggestLike()`**: multi-anchor blending — average multiple reference
  embeddings (e.g. user history) to suggest related items.
- **`createIndex()` → `SuggestionIndex`**: embed a corpus once and suggest
  repeatedly; supports `similarTo()` (within-index, self-excluded),
  `suggestDiverse()` (MMR), and incremental `add()`.
- **Persistence**: `SuggestionIndex.save()` / `SmartSuggestions.loadIndex()` —
  embed once, restore instantly on next launch.
- **`SuggestionsList<T>`**: drop-in widget that shows suggestions for a given
  anchor text or index position.
- **Pluggable `SuggestionEmbedder`** (default: `CodesparkBackend` over
  `ai_core_codespark`) — swap in a fake for model-free testing.
