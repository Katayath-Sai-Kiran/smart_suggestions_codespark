# smart_suggestions_codespark

[![pub package](https://img.shields.io/pub/v/smart_suggestions_codespark.svg)](https://pub.dev/packages/smart_suggestions_codespark)
[![pub points](https://img.shields.io/pub/points/smart_suggestions_codespark)](https://pub.dev/packages/smart_suggestions_codespark/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Add "related items" / "you might also like" to your Flutter app in three
lines — fully on-device, no backend, no API keys, no per-query cost.**

It finds items that *mean* the same thing, so when a user reads **"How to train
for a marathon"** it suggests **"Best running shoes for beginners"** even though
they share almost no words — something keyword matching can't do.

## Three lines

```dart
import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

final suggestions = SmartSuggestions();
await suggestions.initialize(); // downloads a ~23 MB model once, then cached

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
| ✓ | ✓ | ✓ | ✓ | ✓ | experimental |

## How it works

Text → a local MiniLM embedding (via
[ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) → a vector →
cosine similarity ranking, all on a background isolate.

## Roadmap

- **v0.1** — on-device suggestions with `similarTo`, `suggestLike`, MMR, persistence, widget.
- **Next** — category-aware filtering, hybrid scoring (semantic + metadata),
  then a multilingual model.

## More from ksaikiran.dev

| Package | What it does |
|---|---|
| [ai_core_codespark](https://pub.dev/packages/ai_core_codespark) | The on-device embedding engine both packages are built on. |
| [semantic_search_codespark](https://pub.dev/packages/semantic_search_codespark) | Offline semantic search — search by meaning. |
| [text_comparison_score_codespark](https://pub.dev/packages/text_comparison_score_codespark) | Fuzzy string similarity — Levenshtein, Jaro-Winkler. |
| [animated_dropdown_search_codespark](https://pub.dev/packages/animated_dropdown_search_codespark) | Searchable, animated dropdown widget. |
| [text_highlight_codespark](https://pub.dev/packages/text_highlight_codespark) | Highlight query matches in text. |

Browse all on [pub.dev/publishers/ksaikiran.dev](https://pub.dev/publishers/ksaikiran.dev/packages).

## License

MIT © Sai Kiran Katayath — part of the **codespark** on-device AI ecosystem · [ksaikiran.dev](https://ksaikiran.dev)

If this saved you a backend, a ⭐ on [GitHub](https://github.com/Katayath-Sai-Kiran/smart_suggestions_codespark) and a 👍 on [pub.dev](https://pub.dev/packages/smart_suggestions_codespark) help other developers find it.
