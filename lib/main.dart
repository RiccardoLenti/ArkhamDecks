import 'dart:async';

import 'package:arkham_decks/card_pager_screen.dart';
import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/filter_screen.dart';

import 'icon_manager.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final iconManager = IconManager();
  await iconManager.loadIcons('assets/icons/app.json');
  await iconManager.loadIcons('assets/icons/investigator_cards.json');

  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'title', home: CardList());
  }
}

class CardList extends StatefulWidget {
  const CardList({super.key});

  @override
  _CardListState createState() => _CardListState();
}

class _CardListState extends State<CardList> {
  List<ArkhamCard> _cards = [];
  final TextEditingController _searchController = TextEditingController();
  final SearchFilters _searchFilters = SearchFilters();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFilters.addListener(_onFiltersChanged);
    _updateCards();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFilters.removeListener(_onFiltersChanged);
    _searchFilters.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateCards();
    });
  }

  Future<void> _updateCards() async {
    final cards = await _searchFilters.queryDb();

    setState(() {
      _cards = cards;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Investigator Cards'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FilterScreen(filters: _searchFilters),
                ),
              );
            },
            icon: Icon(Icons.filter_alt, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchFilters.updateSearchText('');
                  },
                  icon: Icon(Icons.clear),
                ),
              ),
              onChanged:
                  (searchText) => _searchFilters.updateSearchText(searchText),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return ListTile(
                  leading: CostLevelCircle(card: card),
                  title: Text(card.name),
                  subtitle: Text(card.code.toString()),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CardPagerScreen(
                              cards: _cards,
                              initialIndex: index,
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      //floatingActionButton: ExpandableFab(searchFilters: _searchFilters),
    );
  }
}

/*class ExpandableFab extends StatefulWidget {
  final SearchFilters searchFilters;
  const ExpandableFab({super.key, required this.searchFilters});

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ...Faction.valuesWithoutMulti().reversed.map((faction) {
          // index is reversed because they appear top to bottom
          final index = Faction.values.length - 2 - faction.index;
          final isSelected = widget.searchFilters.isFactionSelected(faction);

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            right: 16 + 16 / 2,
            bottom: _isOpen ? (25.0 + 60.0 * (index + 1)) : 16,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: FloatingActionButton(
                heroTag: 'tagFab$faction.name',
                mini: true,
                backgroundColor: isSelected ? faction.color : Colors.grey,
                onPressed: () {
                  setState(() => widget.searchFilters.toggleFaction(faction));
                },
                child: IconManager().getIcon(faction.name),
              ),
            ),
          );
        }),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _toggle,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _controller,
            ),
          ),
        ),
      ],
    );
  }
}
*/
