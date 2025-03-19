import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../auth/user_provider.dart';
import '../auth/login_screen.dart';
import '../auth/edit_profile_screen.dart';
import '../favorites/favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Если пользователь не вошел в систему
    if (!userProvider.isLoggedIn) {
      return Scaffold(
        body: _buildNotLoggedInView(),
      );
    }

    // Если пользователь вошел в систему
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Аппбар с аватаром и именем
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                user?.displayName ?? 'Профиль',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade800,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileImage(user?.photoUrl),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Информация о пользователе
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Профиль пользователя',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Email', user?.email ?? ''),
                        if (user?.bio != null && user!.bio!.isNotEmpty)
                          _buildInfoRow('О себе', user.bio!),
                        _buildInfoRow(
                          'Аккаунт создан',
                          DateFormat('dd MMM yyyy').format(user?.createdAt ?? DateTime.now()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Статистика
                  _buildInfoCard(
                    icon: Icons.bar_chart,
                    title: 'Статистика',
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          user?.favoriteRecipes.length ?? 0,
                          'Сохранено рецептов',
                        ),
                        // Можно добавить другие статистические данные
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Избранные рецепты
                  _buildInfoCard(
                    icon: Icons.favorite,
                    title: 'Избранные рецепты',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'У вас ${user?.favoriteRecipes.length ?? 0} сохраненных рецептов',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            );
                          },
                          child: const Text('Смотреть все рецепты'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Кнопка выхода
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await userProvider.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Выйти'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Войдите в аккаунт',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Войдите, чтобы сохранять рецепты, персонализировать свой опыт и многое другое',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Войти в аккаунт'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? photoUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl) as ImageProvider
            : const AssetImage('assets/images/default_avatar.png'),
        child: photoUrl == null
            ? const Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        )
            : null,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget _buildInfoCard({
  required IconData icon,
  required String title,
  required Widget content,
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          content,
        ],
      ),
    ),
  );
}


Widget _buildAnalyticsRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    ),
  );
}

