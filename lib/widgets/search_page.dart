import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/pin.dart';
import '../parsers/pinterest_parser.dart';
import '../services/client_handler.dart';
import '../services/preferences_handler.dart';
import 'pin_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with ClientHandler, PreferencesHandler {
  final List<PinItem> _searchResults = <PinItem>[];
  final Set<String> _seenUrls = <String>{};
  bool _loading = false;
  bool _hasSearched = false;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = <String>[];

  @override
  void initState() {
    super.initState();
    initializeClient().then((_) => setState(() {}));
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    _searchHistory.clear();
    _searchHistory.addAll(await loadStringList('search_history'));
    setState(() {});
  }

  Future<void> _saveSearchHistory() async {
    await saveStringList('search_history', _searchHistory);
  }

  void _addToSearchHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty && !_searchHistory.contains(trimmedQuery)) {
      _searchHistory.insert(0, trimmedQuery);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
      _saveSearchHistory();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty || _loading) return;
    
    _addToSearchHistory(query);
    
    setState(() {
      _loading = true;
      _searchResults.clear();
      _seenUrls.clear();
      _hasSearched = true;
    });

    try {
      final html = await client.fetchSearchHtml(query);
      final newPins = PinterestParser.parseHomeHtml(html);
      
      for (final p in newPins) {
        final key = p.canonicalUrl;
        if (_seenUrls.add(key)) {
          _searchResults.add(p);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _clearSearchHistory() async {
    _searchHistory.clear();
    setState(() {});
    await removeKey('search_history');
  }

  void _removeFromHistory(String query) {
    _searchHistory.remove(query);
    setState(() {});
    _saveSearchHistory();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchResults.clear();
    _seenUrls.clear();
    _hasSearched = false;
    setState(() {});
  }

  void _selectHistoryItem(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Pinterest...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onSubmitted: _performSearch,
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_searchHistory.isNotEmpty && !_hasSearched)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearSearchHistory,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear History'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        if (_searchHistory.isNotEmpty && !_hasSearched)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeFromHistory(query),
                    color: Colors.grey[600],
                  ),
                  onTap: () => _selectHistoryItem(query),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                );
              },
            ),
          ),
        if (_hasSearched)
          Expanded(
            child: _buildSearchContent(),
          ),
      ],
    );
  }

  Widget _buildSearchContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pin = _searchResults[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PinTile(pin: pin),
        );
      },
    );
  }
}
