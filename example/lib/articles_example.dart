/// CLI example: find articles related to a given one.
///
/// Run with: dart run example/lib/articles_example.dart
library;

import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

Future<void> main() async {
  final suggestions = SmartSuggestions();
  await suggestions.initialize();

  final articles = [
    'How to train for a marathon',
    'Best running shoes for beginners',
    'Healthy smoothie recipes',
    'Guide to cycling in the city',
    'Yoga stretches for runners',
  ];

  final index = await suggestions.createIndex(items: articles, textOf: (a) => a);

  // User is reading about marathon training — find related articles.
  final hits = await index.similarTo(0, topK: 3);

  print('Reading: "${articles[0]}"');
  print('');
  print('Related articles:');
  for (final h in hits) {
    print('  ${h.score.toStringAsFixed(2)}  ${h.item}');
  }

  // Expected output (approximately):
  // Reading: "How to train for a marathon"
  //
  // Related articles:
  //   0.89  Best running shoes for beginners
  //   0.76  Yoga stretches for runners
  //   0.54  Guide to cycling in the city

  await suggestions.dispose();
}
