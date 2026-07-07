import 'package:flutter/material.dart';

import 'suggestion_index.dart';
import 'suggestion_result.dart';

/// A drop-in widget that displays suggestions from a [SuggestionIndex] for a
/// given anchor (text or index position).
///
/// ```dart
/// SuggestionsList<Article>(
///   index: articleIndex,
///   anchor: currentArticle.title,
///   itemBuilder: (context, r) => ListTile(
///     title: Text(r.item.title),
///     subtitle: Text('Score: ${r.score.toStringAsFixed(2)}'),
///   ),
/// )
/// ```
class SuggestionsList<T> extends StatefulWidget {
  const SuggestionsList({
    super.key,
    required this.index,
    required this.itemBuilder,
    this.anchor,
    this.anchorIndex,
    this.onItemTap,
    this.topK = 5,
    this.threshold,
    this.diverse = false,
    this.lambda = 0.5,
    this.padding = const EdgeInsets.all(12),
    this.shrinkWrap = false,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  }) : assert(
          anchor != null || anchorIndex != null,
          'Provide either anchor (text) or anchorIndex (position in index).',
        );

  /// The pre-built, ready-to-query index.
  final SuggestionIndex<T> index;

  /// Builds the widget for one suggestion result.
  final Widget Function(BuildContext context, SuggestionResult<T> result)
      itemBuilder;

  /// Text anchor — find items similar to this text.
  final String? anchor;

  /// Index-position anchor — find items similar to the item at this position.
  final int? anchorIndex;

  /// Called when a suggestion is tapped.
  final void Function(SuggestionResult<T> result)? onItemTap;

  /// Max suggestions to show.
  final int topK;

  /// Optional minimum cosine score (0–1).
  final double? threshold;

  /// Use MMR diversification instead of pure cosine ranking.
  final bool diverse;

  /// MMR lambda (only used when [diverse] is true).
  final double lambda;

  /// Padding around the list.
  final EdgeInsetsGeometry padding;

  /// When true, the list shrink-wraps (use inline inside a scroll view).
  /// When false, the list fills available space.
  final bool shrinkWrap;

  /// Shown while computing suggestions.
  final WidgetBuilder? loadingBuilder;

  /// Shown when no suggestions are found.
  final WidgetBuilder? emptyBuilder;

  /// Shown when an error occurs.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<SuggestionsList<T>> createState() => _SuggestionsListState<T>();
}

class _SuggestionsListState<T> extends State<SuggestionsList<T>> {
  List<SuggestionResult<T>>? _results;
  Object? _error;
  bool _loading = true;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(covariant SuggestionsList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.anchor != oldWidget.anchor ||
        widget.anchorIndex != oldWidget.anchorIndex ||
        widget.topK != oldWidget.topK ||
        widget.threshold != oldWidget.threshold ||
        widget.diverse != oldWidget.diverse) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<SuggestionResult<T>> results;
      if (widget.anchorIndex != null) {
        results = await widget.index.similarTo(
          widget.anchorIndex!,
          topK: widget.topK,
          threshold: widget.threshold,
        );
      } else if (widget.diverse) {
        results = await widget.index.suggestDiverse(
          widget.anchor!,
          topK: widget.topK,
          lambda: widget.lambda,
        );
      } else {
        results = await widget.index.suggestFor(
          widget.anchor!,
          topK: widget.topK,
          threshold: widget.threshold,
        );
      }

      if (!mounted || seq != _seq) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          Center(child: Text('Error: $_error'));
    }
    final results = _results;
    if (results == null || results.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(
            child: Padding(
                padding: EdgeInsets.all(24), child: Text('No suggestions.')),
          );
    }
    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: widget.padding,
      itemCount: results.length,
      itemBuilder: (context, i) {
        final r = results[i];
        final child = widget.itemBuilder(context, r);
        if (widget.onItemTap == null) return child;
        return InkWell(onTap: () => widget.onItemTap!(r), child: child);
      },
    );
  }
}
