# smart_suggestions_codespark

[![pub package](https://img.shields.io/pub/v/smart_suggestions_codespark.svg)](https://pub.dev/packages/smart_suggestions_codespark)
[![pub points](https://img.shields.io/pub/points/smart_suggestions_codespark)](https://pub.dev/packages/smart_suggestions_codespark/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/Katayath-Sai-Kiran/smart_suggestions_codespark/actions/workflows/ci.yml/badge.svg)](https://github.com/Katayath-Sai-Kiran/smart_suggestions_codespark/actions/workflows/ci.yml)

**Add "related items" / "you might also like" to your Flutter app in three
lines — fully on-device, no backend, no API keys, no per-query cost.**

It finds items that *mean* the same thing, so when a user reads **"How to train
for a marathon"** it suggests **"Best running shoes for beginners"** even though
they share almost no words — something keyword matching can't do.

## Three lines

```dart
import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

final suggestions = await SmartSuggestions.create(); // downloads ~23 MB once, cached
final hits = await suggestions.suggest(
  anchor: 'running shoes',
  candidates: ['sneakers', 'formal boots', 'hiking sandals', 'flip flops'],
);
// hits.first.item == 'sneakers' — closest in meaning
```

## Why developers use it

- **No backend, no API keys, no cost.** No Algolia, Firebase, or OpenAI bill.
- **100% offline & private.** Text never leaves the device. Great for privacy,
  compliance (health/finance), and low-connectivity markets.
- **Understands meaning, not just words.** "running shoes" → "sneakers" with
  zero shared keywords.
- **Doesn't block your UI.** Inference runs on a background isolate.
- **Typed results.** Suggest from your own objects, get them back fully typed.
- **One package, every platform** — Android, iOS, macOS, Windows, Linux.

## Suggest from your own objects

The real use case — rank a list of *your* models by similarity and get them back
typed:

```dart
final hits = await suggestions.suggestFor<Article>(
  anchor: currentArticle.title,
  candidates: allArticles,
  textOf: (a) => '${a.title} ${a.summary}',
  topK: 5,
);

for (final hit in hits) {
  print('${hit.item.title}  ·  ${hit.score.toStringAsFixed(2)}');
}
```

## Index once, suggest many

For a stable corpus (a catalog, an article list, a FAQ), embed it once and reuse
the index — only the anchor is embedded per request:

```dart
final index = await suggestions.createIndex<Article>(
  items: articles,
  textOf: (a) => '${a.title} ${a.summary}',
);

final a = await index.suggestFor('marathon training', topK: 3);
final b = await index.suggestFor('healthy eating', topK: 3);
```

## Find similar within the index

The killer feature for recommendations — suggest items similar to another item
in the same index, *without embedding anything*:

```dart
// User is viewing article at index 0 — find related articles.
final related = await index.similarTo(0, topK: 5);
// The viewed article itself is automatically excluded.
```

## Multi-anchor: "items like these"

Blend multiple references (e.g. user history) into a single recommendation:

```dart
final hits = await index.suggestLike(
  ['marathon training tips', 'best running shoes'],
  topK: 5,
);
// Suggests items related to BOTH anchors (averaged embedding).
```

## Diverse suggestions (MMR)

Avoid near-duplicate results with Maximal Marginal Relevance:

```dart
final diverse = await index.suggestDiverse(
  'running gear',
  topK: 5,
  lambda: 0.5, // 1.0 = pure relevance, 0.0 = pure diversity
);
```

## Persist the index

Embed once, save to disk, reload instantly on next launch:

```dart
// Save
await index.save('path/to/suggestions.json', encode: (a) => a.toJson());

// Restore (no re-embedding!)
final restored = await suggestions.loadIndex<Article>(
  path: 'path/to/suggestions.json',
  decode: (json) => Article.fromJson(json),
);
```

## Drop-in widget

Show suggestions in your UI with zero boilerplate:

```dart
SuggestionsList<Article>(
  index: articleIndex,
  anchor: currentArticle.title,   // or: anchorIndex: 0
  topK: 5,
  itemBuilder: (context, r) => ListTile(
    title: Text(r.item.title),
    subtitle: Text('Score: ${r.score.toStringAsFixed(2)}'),
  ),
  onItemTap: (r) => openArticle(r.item),
)
```

## Install

```yaml
dependencies:
  smart_suggestions_codespark: ^0.1.0
```

Then `flutter pub get`.

## When to reach for it

| Scenario | Tool |
|----------|------|
| "Items similar to this one" | **smart_suggestions_codespark** |
| "Search by meaning" (user-typed query) | [semantic_search_codespark](https://pub.dev/packages/semantic_search_codespark) |
| Personalized ML recs (collaborative filtering) | Cloud service (Firebase, AWS Personalize) |
| Exact keyword / filter matching | Algolia, Meilisearch, or SQLite FTS |

## Limitations & tips

- **Model size**: ~23 MB downloaded once, cached thereafter. Not suitable for
  very small apps where APK size is critical.
- **Latency**: First call takes ~200–500 ms (model load). Subsequent calls are
  fast (~5–50 ms depending on corpus size).
- **English-centric**: The default MiniLM model works best on English text.
  Multilingual model planned for a future release.
- **Not collaborative filtering**: This is content-based similarity, not
  user-behavior-based recommendations.

## Platform support

| Android | iOS | macOS | Windows | Linux | Web |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✓ | ✓ | ✓ | ✓ | ✓ | ⚠️ library |

> ⚠️ **Web**: The library compiles on web. Embedding inference requires
> [`ai_core_codespark`](https://pub.dev/packages/ai_core_codespark) with a WASM
> ONNX runtime, which is pending upstream. Index persistence (`save`/`load`)
> throws on web — provide your own storage layer or use a native platform.

## How it works

Text → a local MiniLM embedding (via
[ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) → a vector →
cosine similarity ranking, all on a background isolate.

## Similarity utilities

The `Similarity` and `Pooling` classes from the embedding engine are re-exported
for advanced use — compute custom scores between arbitrary vectors:

```dart
import 'dart:typed_data';
import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

final a = Float32List.fromList([1, 0, 0, 0]);
final b = Float32List.fromList([0.8, 0.6, 0, 0]);

Pooling.l2Normalize(a);
Pooling.l2Normalize(b);

final score = Similarity.dot(a, b); // ~0.80

// Top-k from your own corpus
final hits = Similarity.topK(a, [b, ...], k: 5, threshold: 0.3);

// Diversity-aware re-ranking
final diverse = Similarity.mmr(a, corpus, k: 5, lambda: 0.5);
```

## Exceptions

Domain-specific exceptions for precise error handling:

| Exception | When thrown |
|---|---|
| `IndexOutOfRangeException` | `similarTo()` index exceeds corpus bounds |
| `IndexDimensionMismatchException` | `loadIndex()` saved dimension ≠ current model |
| `EngineNotInitializedException` | Any method before `initialize()` |

All suggestion exceptions extend `SuggestionException` which extends
`CodesparkException`, so `catch (CodesparkException e)` covers all of them.

## Roadmap

- **v0.1** — on-device suggestions with `similarTo`, `suggestLike`, MMR, persistence, widget.
- **v0.2** — `SmartSuggestions.create()` factory, `Similarity`/`Pooling` exports, typed exceptions,
  web-compatible persistence layer, CI + benchmarks.
- **Next** — category-aware filtering, hybrid scoring (semantic + metadata),
  then a multilingual model.

## More from the codespark ecosystem

All packages by **Sai Kiran Katayath** ([ksaikiran.dev](https://ksaikiran.dev)) —
on-device AI, Flutter utilities, and developer tooling.

| Package | What it does | Depends on |
|---|---|---|
| **smart_suggestions_codespark** ⬅ | On-device "related items" — similar by meaning | `ai_core_codespark` |
| [ai_core_codespark](https://pub.dev/packages/ai_core_codespark) | **Engine**: on-device text embeddings & vector search (MiniLM) | — |
| [semantic_search_codespark](https://pub.dev/packages/semantic_search_codespark) | On-device semantic & vector search — search by meaning | `ai_core_codespark` |
| [text_comparison_score_codespark](https://pub.dev/packages/text_comparison_score_codespark) | Fuzzy string matching — Levenshtein, Damerau-Levenshtein, Jaro-Winkler | — |
| [text_highlight_codespark](https://pub.dev/packages/text_highlight_codespark) | Rich-text highlighting — single/multi-query, regex, tappable spans | — |
| [animated_dropdown_search_codespark](https://pub.dev/packages/animated_dropdown_search_codespark) | Searchable, animated multi-select dropdown | — |
| [date_formatter_codespark](https://pub.dev/packages/date_formatter_codespark) | DateTime formatting, relative time, time-ago, human-readable dates | — |
| [context_extensions_codespark](https://pub.dev/packages/context_extensions_codespark) | BuildContext extensions — MediaQuery, theme, snackbar, responsive | — |
| [icon_to_text_extension_codespark](https://pub.dev/packages/icon_to_text_extension_codespark) | Convert any IconData to inline Text or TextSpan | — |
| [advanced_text_input_formatters_codespark](https://pub.dev/packages/advanced_text_input_formatters_codespark) | Custom TextInputFormatters — simulate typing, block clipboard, enforce rules | — |
| [dual_tone_text_codespark](https://pub.dev/packages/dual_tone_text_codespark) | Dual-tone gradient text — vertical, horizontal, or radial splits | — |

Browse all 14 packages on [pub.dev/publishers/ksaikiran.dev](https://pub.dev/publishers/ksaikiran.dev/packages).

## License

MIT © [Sai Kiran Katayath](https://ksaikiran.dev) — part of the **codespark** on-device AI ecosystem.

If this saved you a backend, a ⭐ on [GitHub](https://github.com/Katayath-Sai-Kiran/smart_suggestions_codespark) and a 👍 on [pub.dev](https://pub.dev/packages/smart_suggestions_codespark) help other developers find it.
