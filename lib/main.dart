import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/admin/viewmodel/admin_viewmodel.dart';
import 'features/admin/view/admin_panel_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/message/viewmodel/message_viewmodel.dart';
import 'features/message/view/chat_list_screen.dart';
import 'features/core/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Firebase App Check'i başlat
  await FirebaseAppCheck.instance.activate(
    // Debug modda test için AndroidProvider.debug kullan
    androidProvider: AndroidProvider.debug,
    // iOS için
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => MessageViewModel()),
      ],
      child: MaterialApp(
        title: 'Messenger',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(homeScreen: HomeScreen()),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminPanelScreen(),
        },
      ),
    );
  }
}

// Ana ekran (mesajlaşma ekranını içerir)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminViewModel =
          Provider.of<AdminViewModel>(context, listen: false);
      adminViewModel.checkAdminStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.accentColor,
          unselectedItemColor: AppColors.secondaryTextColor,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Sohbetler',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// Profil ekranı (geçici)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profilim',
          style: TextStyle(color: AppColors.textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Admin paneli butonu (sadece admin kullanıcılar için göster)
          Consumer<AdminViewModel>(
            builder: (context, adminViewModel, child) {
              if (adminViewModel.state.isAdmin) {
                return IconButton(
                  icon: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                  tooltip: 'Admin Paneli',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () {
              authViewModel.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profil fotoğrafı
            CircleAvatar(
              backgroundColor: AppColors.accentColor.withOpacity(0.2),
              radius: 70,
              child: Icon(
                Icons.person,
                size: 70,
                color: AppColors.accentColor,
              ),
            ),
            const SizedBox(height: 24),

            // Kullanıcı bilgileri
            FutureBuilder(
              future: Firebase.initializeApp(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    return Column(
                      children: [
                        Text(
                          user.displayName ?? 'Kullanıcı',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'E-posta: ${user.email}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<AdminViewModel>(
                          builder: (context, adminViewModel, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: adminViewModel.state.isAdmin
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Rol: ${adminViewModel.state.isAdmin ? 'Admin' : 'Kullanıcı'}',
                                style: TextStyle(
                                  color: adminViewModel.state.isAdmin
                                      ? Colors.red
                                      : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                }
                return const CircularProgressIndicator();
              },
            ),

            const SizedBox(height: 40),

            // Çıkış butonu
            ElevatedButton(
              onPressed: () {
                authViewModel.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
