import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';
import 'favorites/favorites_screen.dart';
import '../auth/user_provider.dart';

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          HomeScreen(cameras: widget.cameras),
          const FavoritesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: userProvider.isLoggedIn &&
                    (userProvider.user?.favoriteRecipes.length ?? 0) > 0,
                label: Text(
                  (userProvider.user?.favoriteRecipes.length ?? 0).toString(),
                ),
                child: const Icon(Icons.favorite_outline),
              ),
              activeIcon: Badge(
                isLabelVisible: userProvider.isLoggedIn &&
                    (userProvider.user?.favoriteRecipes.length ?? 0) > 0,
                label: Text(
                  (userProvider.user?.favoriteRecipes.length ?? 0).toString(),
                ),
                child: const Icon(Icons.favorite),
              ),
              label: 'Избранное',
            ),
            BottomNavigationBarItem(
              icon: userProvider.isLoggedIn && userProvider.user?.photoUrl != null
                  ? CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(userProvider.user!.photoUrl!),
              )
                  : const Icon(Icons.person_outline),
              activeIcon: userProvider.isLoggedIn && userProvider.user?.photoUrl != null
                  ? CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(userProvider.user!.photoUrl!),
              )
                  : const Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}
