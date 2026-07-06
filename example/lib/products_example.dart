/// CLI example: product recommendations using typed objects.
///
/// Run with: dart run example/lib/products_example.dart
library;

import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

class Product {
  final int id;
  final String name;
  final String description;
  Product(this.id, this.name, this.description);
}

Future<void> main() async {
  final suggestions = SmartSuggestions();
  await suggestions.initialize();

  final products = [
    Product(1, 'Trail Runner Pro', 'Lightweight trail running shoes with grip'),
    Product(2, 'City Cruiser', 'Urban bicycle for daily commuting'),
    Product(3, 'Yoga Mat Deluxe', 'Non-slip mat for yoga and stretching'),
    Product(4, 'Marathon Socks', 'Compression socks for long-distance running'),
    Product(5, 'Swim Goggles', 'Anti-fog goggles for pool and open water'),
  ];

  // User is viewing "Trail Runner Pro" — suggest alternatives.
  final hits = await suggestions.suggestFor<Product>(
    anchor: 'Trail Runner Pro lightweight trail running shoes with grip',
    candidates: products,
    textOf: (p) => '${p.name} ${p.description}',
    topK: 3,
  );

  print('Viewing: ${products[0].name}');
  print('');
  print('You might also like:');
  for (final h in hits) {
    print('  ${h.score.toStringAsFixed(2)}  ${h.item.name}');
  }

  // Expected output (approximately):
  // Viewing: Trail Runner Pro
  //
  // You might also like:
  //   0.95  Trail Runner Pro    (self — usually filter this in real apps)
  //   0.82  Marathon Socks
  //   0.61  Yoga Mat Deluxe

  // Multi-anchor: user has viewed running AND cycling items.
  print('');
  print('Based on your history (running + cycling):');
  final history = await suggestions.suggestLike<Product>(
    anchors: ['trail running shoes', 'urban bicycle commuting'],
    candidates: products,
    textOf: (p) => '${p.name} ${p.description}',
    topK: 3,
  );
  for (final h in history) {
    print('  ${h.score.toStringAsFixed(2)}  ${h.item.name}');
  }

  await suggestions.dispose();
}
