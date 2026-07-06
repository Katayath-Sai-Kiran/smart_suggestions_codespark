import 'package:flutter/material.dart';
import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

const _articles = [
  'How to train for a marathon',
  'Best running shoes for beginners',
  'Healthy post-workout smoothie recipes',
  'Guide to cycling in the city',
  'Yoga stretches for runners',
  'Strength training for endurance athletes',
  'Nutrition tips for long-distance running',
  'How to prevent running injuries',
  'Swimming versus running for fitness',
  'Trail running gear guide',
];

void main() => runApp(const SuggestionsDemo());

class SuggestionsDemo extends StatelessWidget {
  const SuggestionsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Suggestions Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final _suggestions = SmartSuggestions();
  SuggestionIndex<String>? _index;
  String? _status;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _status = 'Initializing model…');
    await _suggestions.initialize(onProgress: (received, total) {
      setState(() => _status = 'Downloading model: ${received * 100 ~/ total}%');
    });
    setState(() => _status = 'Building index…');
    final index = await _suggestions.createIndex(
      items: _articles,
      textOf: (a) => a,
    );
    setState(() {
      _index = index;
      _status = null;
    });
  }

  @override
  void dispose() {
    _suggestions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Suggestions')),
      body: _status != null
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_status!),
              ],
            ))
          : _selectedIndex != null
              ? _buildDetail()
              : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _articles.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(_articles[i]),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                onPressed: () => setState(() => _selectedIndex = null),
              ),
              const SizedBox(height: 8),
              Text(
                _articles[_selectedIndex!],
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Related articles:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: SuggestionsList<String>(
            index: _index!,
            anchorIndex: _selectedIndex!,
            topK: 5,
            itemBuilder: (context, r) => ListTile(
              title: Text(r.item),
              subtitle: Text('Score: ${r.score.toStringAsFixed(2)}'),
            ),
          ),
        ),
      ],
    );
  }
}
