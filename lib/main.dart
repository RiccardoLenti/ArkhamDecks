import 'package:arkham_decks/cards_screen.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/decks_screen.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/services.dart';
import 'icon_manager.dart';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.initDb();

  final iconManager = IconManager();
  await iconManager.loadIcons('assets/icons/app.json');
  await iconManager.loadIcons('assets/icons/investigator_cards.json');
  await iconManager.loadIcons('assets/icons/expansions.json');

  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'title',
      home: MainScreen(),
      theme: AppTheme.theme(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPageIndex = 0;
  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final SearchFilters _searchFilters = SearchFilters();

  @override
  void dispose() {
    _searchFilters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) async {
        if (didPop) return;

        final currentNavigator =
            _navigatorKeys[_selectedPageIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedPageIndex,
          children: [
            Navigator(
              key: _navigatorKeys[0],
              onGenerateRoute:
                  (_) => MaterialPageRoute(
                    builder: (_) => CardsScreen(searchFilters: _searchFilters),
                  ),
            ),
            Navigator(
              key: _navigatorKeys[1],
              onGenerateRoute:
                  (_) => MaterialPageRoute(builder: (_) => const DecksScreen()),
            ),
          ],
        ),

        // notes on the colors: the icon and text not selected are onSurfaceVariant
        // the selected text is onSurface, the icon is onSecondaryContainer
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedPageIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedPageIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_books),
              label: 'Cards',
            ),
            NavigationDestination(icon: Icon(Icons.book), label: 'Decks'),
          ],

          height: 60.0,
        ),
      ),
    );
  }
}
