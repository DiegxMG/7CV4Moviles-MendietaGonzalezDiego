import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/public_api_service.dart';
import 'services/google_auth_service.dart';
import 'services/recommendations_service.dart';
import 'database/db_helper.dart';

void main() => runApp(const Practica5App());

class Practica5App extends StatelessWidget {
  const Practica5App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Práctica 5 - Multiplataforma',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _loginLocal() async {
    setState(() => _isLoading = true);
    bool success = await ApiService.login(_userCtrl.text, _passCtrl.text);
    setState(() => _isLoading = false);
    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(userId: _userCtrl.text)));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de acceso, revisa red y credenciales')));
    }
  }

  void _loginGoogle() async {
    setState(() => _isLoading = true);
    final account = await GoogleAuthService.signInWithGoogle();
    setState(() => _isLoading = false);
    if (account != null) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(userId: account.email)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Usuario')),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 20),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _loginLocal, child: const Text('Entrar (API REST)')),
            const SizedBox(height: 10),
            _isLoading ? const SizedBox.shrink() : OutlinedButton(onPressed: _loginGoogle, child: const Text('Ingresar con Google')),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _SearchTab(userId: widget.userId),
      _FavoritesTab(userId: widget.userId),
      _RecommendationsTab(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Práctica 5'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: () {}), // Espacio para método de sync
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await GoogleAuthService.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
          )
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Búsqueda'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Sugeridos'),
        ],
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  final String userId;
  const _SearchTab({required this.userId});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  void _search() async {
    if (_searchCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    await DBHelper.insertHistory(widget.userId, _searchCtrl.text);
    final res = await PublicApiService.searchShows(_searchCtrl.text);
    setState(() {
      _results = res ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _searchCtrl, decoration: const InputDecoration(hintText: 'Buscar series (API pública)...'))),
              IconButton(icon: const Icon(Icons.search), onPressed: _search)
            ],
          ),
        ),
        if (_isLoading) const CircularProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final show = _results[index]['show'];
              return ListTile(
                title: Text(show['name']),
                subtitle: Text(show['language'] ?? 'Sin idioma'),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () => DBHelper.toggleFavorite(widget.userId, show['id'].toString(), show['name'], 'datos'),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  final String userId;
  const _FavoritesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DBHelper.getFavorites(userId),
      builder: (context, AsyncSnapshot<List>> snapshot) {
    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
    if (snapshot.data!.isEmpty) return const Center(child: Text('Sin favoritos'));

    return ListView.builder(
    itemCount: snapshot.data!.length,
    itemBuilder: (context, index) => ListTile(
    title: Text(snapshot.data![index]['title']),
    trailing: const Icon(Icons.favorite, color: Colors.red),
    ),
    );
    },
    );
  }
}

class _RecommendationsTab extends StatelessWidget {
  final String userId;
  const _RecommendationsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: RecommendationsService.getRecommendations(userId),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text('Sin recomendaciones aún'));

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final show = snapshot.data![index]['show'];
            return ListTile(
              title: Text(show['name']),
              leading: const Icon(Icons.star, color: Colors.amber),
            );
          },
        );
      },
    );
  }
}