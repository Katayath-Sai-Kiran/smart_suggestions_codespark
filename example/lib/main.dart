import 'package:flutter/material.dart';
import 'package:smart_suggestions_codespark/smart_suggestions_codespark.dart';

// ── Data Models ──────────────────────────────────────────────────────────────

class Article {
  final String title;
  final String summary;
  final String category;
  final IconData icon;

  const Article({
    required this.title,
    required this.summary,
    required this.category,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'category': category,
        'icon': icon.codePoint,
      };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        title: json['title'] as String,
        summary: json['summary'] as String,
        category: json['category'] as String,
        icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      );
}

// ── Sample Data ──────────────────────────────────────────────────────────────

const _articles = <Article>[
  Article(
    title: 'How to Train for a Marathon',
    summary: 'A complete training plan for first-time marathon runners',
    category: 'Fitness',
    icon: Icons.directions_run,
  ),
  Article(
    title: 'Best Running Shoes for Beginners',
    summary: 'Top picks for comfortable and supportive running footwear',
    category: 'Gear',
    icon: Icons.shopping_bag,
  ),
  Article(
    title: 'Healthy Post-Workout Smoothie Recipes',
    summary: 'Delicious protein-packed smoothies to fuel recovery',
    category: 'Nutrition',
    icon: Icons.local_drink,
  ),
  Article(
    title: 'Guide to Cycling in the City',
    summary: 'Stay safe and efficient while cycling through urban areas',
    category: 'Cycling',
    icon: Icons.pedal_bike,
  ),
  Article(
    title: 'Yoga Stretches for Runners',
    summary: 'Improve flexibility and prevent injuries with these poses',
    category: 'Wellness',
    icon: Icons.self_improvement,
  ),
  Article(
    title: 'Strength Training for Endurance Athletes',
    summary: 'Build power without bulking up for long-distance performance',
    category: 'Fitness',
    icon: Icons.fitness_center,
  ),
  Article(
    title: 'Nutrition Tips for Long-Distance Running',
    summary: 'What to eat before, during, and after long runs',
    category: 'Nutrition',
    icon: Icons.restaurant,
  ),
  Article(
    title: 'How to Prevent Running Injuries',
    summary: 'Common mistakes and how to avoid them on the track',
    category: 'Health',
    icon: Icons.healing,
  ),
  Article(
    title: 'Swimming Versus Running for Fitness',
    summary: 'Comparing calorie burn, impact, and overall health benefits',
    category: 'Fitness',
    icon: Icons.pool,
  ),
  Article(
    title: 'Trail Running Gear Guide',
    summary: 'Essential equipment for off-road running adventures',
    category: 'Gear',
    icon: Icons.terrain,
  ),
  Article(
    title: 'Meditation for Athletic Performance',
    summary: 'Mental training techniques used by elite athletes',
    category: 'Wellness',
    icon: Icons.spa,
  ),
  Article(
    title: 'The Science of Hydration',
    summary: 'How much water you really need during exercise',
    category: 'Health',
    icon: Icons.water_drop,
  ),
  Article(
    title: 'Beginner\'s Guide to Rock Climbing',
    summary: 'Getting started with bouldering and rope climbing',
    category: 'Adventure',
    icon: Icons.landscape,
  ),
  Article(
    title: 'Home Gym Setup on a Budget',
    summary: 'Build an effective workout space without breaking the bank',
    category: 'Gear',
    icon: Icons.home,
  ),
  Article(
    title: 'Recovery Techniques After Intense Workouts',
    summary: 'Ice baths, foam rolling, and sleep for faster recovery',
    category: 'Health',
    icon: Icons.bed,
  ),
];

// ── App Entry ────────────────────────────────────────────────────────────────

void main() => runApp(const SmartSuggestionsPlayground());

class SmartSuggestionsPlayground extends StatelessWidget {
  const SmartSuggestionsPlayground({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Suggestions Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const _PlaygroundHome(),
    );
  }
}

// ── Home Screen ──────────────────────────────────────────────────────────────

class _PlaygroundHome extends StatefulWidget {
  const _PlaygroundHome();

  @override
  State<_PlaygroundHome> createState() => _PlaygroundHomeState();
}

class _PlaygroundHomeState extends State<_PlaygroundHome> {
  final _suggestions = SmartSuggestions();
  SuggestionIndex<Article>? _index;

  String _status = 'Initializing model...';
  double _progress = 0;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      // For simpler apps: final s = await SmartSuggestions.create();
      // The example below shows fine-grained progress reporting.
      await _suggestions.initialize(onProgress: (received, total) {
        if (total > 0) {
          setState(() {
            _progress = received / total;
            _status = 'Downloading model: ${(_progress * 100).toInt()}%';
          });
        }
      });
      setState(() => _status = 'Building index...');
      final index = await _suggestions.createIndex(
        items: _articles,
        textOf: (a) => '${a.title} ${a.summary}',
      );
      setState(() {
        _index = index;
        _ready = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _suggestions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Smart Suggestions')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to initialize',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _progress = 0;
                      _status = 'Initializing model...';
                    });
                    _boot();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Smart Suggestions')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 64, color: Colors.teal),
                const SizedBox(height: 24),
                Text(_status,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              ],
            ),
          ),
        ),
      );
    }

    return _DemoNavigator(
      suggestions: _suggestions,
      index: _index!,
    );
  }
}

// ── Demo Navigator (tabs for each feature) ───────────────────────────────────

class _DemoNavigator extends StatefulWidget {
  const _DemoNavigator({required this.suggestions, required this.index});
  final SmartSuggestions suggestions;
  final SuggestionIndex<Article> index;

  @override
  State<_DemoNavigator> createState() => _DemoNavigatorState();
}

class _DemoNavigatorState extends State<_DemoNavigator> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _SimilarToDemo(index: widget.index),
      _FreeTextDemo(index: widget.index),
      _MultiAnchorDemo(index: widget.index),
      _DiverseDemo(index: widget.index),
      _WidgetDemo(index: widget.index),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Suggestions Playground'),
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Similar To',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Free Text',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Multi-Anchor',
          ),
          NavigationDestination(
            icon: Icon(Icons.shuffle),
            label: 'Diverse',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets),
            label: 'Widget',
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Similar To (item-to-item) ─────────────────────────────────────────

class _SimilarToDemo extends StatefulWidget {
  const _SimilarToDemo({required this.index});
  final SuggestionIndex<Article> index;

  @override
  State<_SimilarToDemo> createState() => _SimilarToDemoState();
}

class _SimilarToDemoState extends State<_SimilarToDemo> {
  int _selectedIndex = 0;
  int _topK = 5;
  List<SuggestionResult<Article>>? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _query();
  }

  Future<void> _query() async {
    setState(() => _loading = true);
    final results = await widget.index.similarTo(
      _selectedIndex,
      topK: _topK,
    );
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anchor = _articles[_selectedIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Find articles similar to an existing one',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 12),

        // Anchor selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select anchor article:', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: _selectedIndex,
                  isExpanded: true,
                  items: [
                    for (var i = 0; i < _articles.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            Icon(_articles[i].icon, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_articles[i].title, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedIndex = v);
                      _query();
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Top K: $_topK', style: theme.textTheme.labelMedium),
                    Expanded(
                      child: Slider(
                        value: _topK.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_topK',
                        onChanged: (v) {
                          setState(() => _topK = v.round());
                          _query();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Anchor display
        Card(
          color: theme.colorScheme.primaryContainer,
          child: ListTile(
            leading: Icon(anchor.icon, color: theme.colorScheme.onPrimaryContainer),
            title: Text(anchor.title, style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
            subtitle: Text(anchor.summary, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
            trailing: Chip(label: Text(anchor.category, style: const TextStyle(fontSize: 11))),
          ),
        ),

        const SizedBox(height: 16),
        Text('Similar articles:', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),

        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_results != null)
          ..._results!.map((r) => _ResultCard(result: r)),
      ],
    );
  }
}

// ── Tab 2: Free-Text Search ──────────────────────────────────────────────────

class _FreeTextDemo extends StatefulWidget {
  const _FreeTextDemo({required this.index});
  final SuggestionIndex<Article> index;

  @override
  State<_FreeTextDemo> createState() => _FreeTextDemoState();
}

class _FreeTextDemoState extends State<_FreeTextDemo> {
  final _controller = TextEditingController(text: 'running shoes');
  List<SuggestionResult<Article>>? _results;
  bool _loading = false;
  int _topK = 5;

  @override
  void initState() {
    super.initState();
    _query();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    final results = await widget.index.suggestFor(text, topK: _topK);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Type anything and find related articles by meaning',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Search by meaning',
                    hintText: 'e.g. "healthy eating", "prevent pain", "outdoor adventure"',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _query,
                    ),
                  ),
                  onSubmitted: (_) => _query(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _QuickChip('running shoes', _controller, _query),
                    _QuickChip('healthy eating', _controller, _query),
                    _QuickChip('outdoor adventure', _controller, _query),
                    _QuickChip('muscle recovery', _controller, _query),
                    _QuickChip('mental health', _controller, _query),
                    _QuickChip('cardio workout', _controller, _query),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Top K: $_topK', style: theme.textTheme.labelMedium),
                    Expanded(
                      child: Slider(
                        value: _topK.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_topK',
                        onChanged: (v) {
                          setState(() => _topK = v.round());
                          _query();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_results != null) ...[
          Text('Results:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._results!.map((r) => _ResultCard(result: r)),
        ],
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip(this.label, this.controller, this.onTap);
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        controller.text = label;
        onTap();
      },
    );
  }
}

// ── Tab 3: Multi-Anchor (user history) ───────────────────────────────────────

class _MultiAnchorDemo extends StatefulWidget {
  const _MultiAnchorDemo({required this.index});
  final SuggestionIndex<Article> index;

  @override
  State<_MultiAnchorDemo> createState() => _MultiAnchorDemoState();
}

class _MultiAnchorDemoState extends State<_MultiAnchorDemo> {
  final _anchors = <String>['marathon training', 'yoga stretches'];
  final _anchorController = TextEditingController();
  List<SuggestionResult<Article>>? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _query();
  }

  @override
  void dispose() {
    _anchorController.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    if (_anchors.isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    final results = await widget.index.suggestLike(_anchors, topK: 5);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _addAnchor() {
    final text = _anchorController.text.trim();
    if (text.isEmpty) return;
    setState(() => _anchors.add(text));
    _anchorController.clear();
    _query();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Simulate user history — blend multiple interests',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User interests (anchors):', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < _anchors.length; i++)
                      Chip(
                        label: Text(_anchors[i]),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _anchors.removeAt(i));
                          _query();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _anchorController,
                        decoration: const InputDecoration(
                          labelText: 'Add interest',
                          hintText: 'e.g. "swimming"',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addAnchor(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addAnchor,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _SuggestionChip('cycling', _anchorController, (t) {
                      setState(() => _anchors.add(t));
                      _query();
                    }),
                    _SuggestionChip('nutrition', _anchorController, (t) {
                      setState(() => _anchors.add(t));
                      _query();
                    }),
                    _SuggestionChip('climbing', _anchorController, (t) {
                      setState(() => _anchors.add(t));
                      _query();
                    }),
                    _SuggestionChip('meditation', _anchorController, (t) {
                      setState(() => _anchors.add(t));
                      _query();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_results != null) ...[
          Text('Recommended for you:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._results!.map((r) => _ResultCard(result: r)),
        ],
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip(this.label, this.controller, this.onAdd);
  final String label;
  final TextEditingController controller;
  final void Function(String) onAdd;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => onAdd(label),
    );
  }
}

// ── Tab 4: Diverse (MMR) ─────────────────────────────────────────────────────

class _DiverseDemo extends StatefulWidget {
  const _DiverseDemo({required this.index});
  final SuggestionIndex<Article> index;

  @override
  State<_DiverseDemo> createState() => _DiverseDemoState();
}

class _DiverseDemoState extends State<_DiverseDemo> {
  double _lambda = 0.5;
  String _anchor = 'fitness training';
  List<SuggestionResult<Article>>? _standardResults;
  List<SuggestionResult<Article>>? _diverseResults;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _query();
  }

  Future<void> _query() async {
    setState(() => _loading = true);
    final standard = await widget.index.suggestFor(_anchor, topK: 5);
    final diverse = await widget.index.suggestDiverse(
      _anchor,
      topK: 5,
      lambda: _lambda,
    );
    if (!mounted) return;
    setState(() {
      _standardResults = standard;
      _diverseResults = diverse;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Compare standard vs diverse (MMR) ranking',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anchor query:', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final q in ['fitness training', 'running gear', 'healthy living', 'outdoor sports'])
                      ChoiceChip(
                        label: Text(q),
                        selected: _anchor == q,
                        onSelected: (_) {
                          setState(() => _anchor = q);
                          _query();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Relevance'),
                    Expanded(
                      child: Slider(
                        value: _lambda,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        label: 'lambda: ${_lambda.toStringAsFixed(1)}',
                        onChanged: (v) {
                          setState(() => _lambda = v);
                          _query();
                        },
                      ),
                    ),
                    const Text('Diversity'),
                  ],
                ),
                Center(
                  child: Text(
                    'lambda = ${_lambda.toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_standardResults != null && _diverseResults != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Standard', style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      )),
                    ),
                    const SizedBox(height: 8),
                    ..._standardResults!.map((r) => _CompactResultCard(result: r)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Diverse (MMR)', style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      )),
                    ),
                    const SizedBox(height: 8),
                    ..._diverseResults!.map((r) => _CompactResultCard(result: r)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Tab 5: SuggestionsList Widget Demo ───────────────────────────────────────

class _WidgetDemo extends StatefulWidget {
  const _WidgetDemo({required this.index});
  final SuggestionIndex<Article> index;

  @override
  State<_WidgetDemo> createState() => _WidgetDemoState();
}

class _WidgetDemoState extends State<_WidgetDemo> {
  int _anchorIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anchor = _articles[_anchorIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Drop-in SuggestionsList widget',
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(anchor.icon, color: theme.colorScheme.onPrimaryContainer),
              title: Text(anchor.title, style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              )),
              subtitle: Text(anchor.summary, style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
              )),
              trailing: PopupMenuButton<int>(
                icon: Icon(Icons.swap_vert, color: theme.colorScheme.onPrimaryContainer),
                tooltip: 'Change anchor',
                onSelected: (i) => setState(() => _anchorIndex = i),
                itemBuilder: (context) => [
                  for (var i = 0; i < _articles.length; i++)
                    PopupMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          Icon(_articles[i].icon, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_articles[i].title, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Related articles (via SuggestionsList widget):',
              style: theme.textTheme.titleSmall),
        ),
        Expanded(
          child: SuggestionsList<Article>(
            index: widget.index,
            anchorIndex: _anchorIndex,
            topK: 5,
            itemBuilder: (context, r) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(r.item.icon, size: 20,
                      color: theme.colorScheme.onSecondaryContainer),
                ),
                title: Text(r.item.title),
                subtitle: Text(r.item.summary, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: _ScoreBadge(score: r.score),
              ),
            ),
            onItemTap: (r) {
              setState(() => _anchorIndex = r.index);
            },
          ),
        ),
      ],
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final SuggestionResult<Article> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(result.item.icon, size: 20,
              color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(result.item.title),
        subtitle: Text(result.item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: _ScoreBadge(score: result.score),
      ),
    );
  }
}

class _CompactResultCard extends StatelessWidget {
  const _CompactResultCard({required this.result});
  final SuggestionResult<Article> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(result.item.icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.item.title,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _ScoreBadge(score: result.score, compact: true),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, this.compact = false});
  final double score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = score > 0.7
        ? Colors.green
        : score > 0.4
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        score.toStringAsFixed(2),
        style: (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
