import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/services/user_service.dart';
import 'view/login_screen.dart';
import 'view/waiting_approval_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget homeScreen;

  const AuthWrapper({
    Key? key,
    required this.homeScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Yükleniyor durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı giriş yapmamış
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Kullanıcı giriş yapmış, onay durumunu kontrol et
        return FutureBuilder<bool>(
          future: UserService().isUserApproved(snapshot.data!.uid),
          builder: (context, approvalSnapshot) {
            if (approvalSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Kullanıcı onaylı ise ana ekrana yönlendir
            if (approvalSnapshot.data == true) {
              return homeScreen;
            }

            // Kullanıcı onaylı değilse onay bekleme ekranına yönlendir
            return const WaitingApprovalScreen();
          },
        );
      },
    );
  }
}
