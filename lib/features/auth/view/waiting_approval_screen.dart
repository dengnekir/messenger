import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../model/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../core/colors.dart';
import 'dart:async';

class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({Key? key}) : super(key: key);

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  bool _isCheckingStatus = false;
  bool _checkingForRejection = false;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    // İlk açılışta direkt red kontrolü yap
    _checkRejectionStatus();
    // Periyodik kontrol başlat (3 saniyede bir)
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkRejectionStatus() async {
    if (!mounted) return;

    setState(() {
      _checkingForRejection = true;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Direkt red durumunu kontrol et
      final isRejected = await authViewModel.isUserRejected();

      if (isRejected && mounted) {
        // Kullanıcı durumunu güncelle ve red sebebini al
        await authViewModel.checkUserStatus();

        // Red diyaloğunu göster
        if (mounted && authViewModel.state.status == AuthStatus.rejected) {
          _showRejectionDialog(context,
              authViewModel.state.rejectionReason ?? 'Başvurunuz reddedildi.');
        }
      }
    } catch (e) {
      print('Red durumu kontrolünde hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingForRejection = false;
        });
      }
    }
  }

  void _startPeriodicCheck() {
    // Her 3 saniyede bir kontrol et
    _periodicTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        final authViewModel =
            Provider.of<AuthViewModel>(context, listen: false);
        authViewModel.checkUserStatus();
        _checkRejectionStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Onay Bekleniyor',
          style: TextStyle(color: AppColors.textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.square_arrow_right,
              color: AppColors.accentColor,
            ),
            onPressed: () {
              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              authViewModel.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          // Kullanıcı onaylandıysa ana ekrana yönlendir
          if (authViewModel.state.status == AuthStatus.authenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            });
          }

          // Kullanıcı reddedildiyse diyalog göster
          if (authViewModel.state.status == AuthStatus.rejected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRejectionDialog(
                  context,
                  authViewModel.state.rejectionReason ??
                      'Başvurunuz reddedildi.');
            });
          }

          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.hourglass,
                        size: 60,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Onay Bekleniyor',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hesabınız şu anda inceleniyor. Admin onayladığında uygulamaya erişim sağlayabileceksiniz.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Text(
                        authViewModel.state.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _checkingForRejection || _isCheckingStatus
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accentColor),
                          )
                        : const CupertinoActivityIndicator(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isCheckingStatus || _checkingForRejection)
                            ? null
                            : () async {
                                setState(() {
                                  _isCheckingStatus = true;
                                });

                                try {
                                  final authViewModel =
                                      Provider.of<AuthViewModel>(context,
                                          listen: false);

                                  // Önce red durumunu kontrol et
                                  bool isRejected =
                                      await authViewModel.isUserRejected();

                                  if (mounted) {
                                    // Durum kontrolü
                                    await authViewModel.checkUserStatus();

                                    // Reddedilmemiş ve beklemede ise kullanıcıya bildir
                                    if (!isRejected &&
                                        authViewModel.state.status ==
                                            AuthStatus.pendingApproval &&
                                        mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Hesabınız hala inceleniyor. Lütfen bekleyin.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  }

                                  // Biraz bekletelim
                                  await Future.delayed(
                                      const Duration(milliseconds: 500));
                                } catch (e) {
                                  print("Durum kontrol hatası: $e");
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isCheckingStatus = false;
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: (_isCheckingStatus || _checkingForRejection)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Durumu Kontrol Et',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Red mesajını göster ve çıkış yap
  void _showRejectionDialog(BuildContext context, String rejectionMessage) {
    // Diyaloğun tekrar tekrar gösterilmemesi için kontrol et
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: const Text(
            'Başvurunuz Reddedildi',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.xmark_circle,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                rejectionMessage,
                style: TextStyle(color: AppColors.textColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Kullanıcı çıkış yap
                    final authViewModel =
                        Provider.of<AuthViewModel>(context, listen: false);
                    authViewModel.signOut();

                    // Ana ekrana dön
                    Navigator.of(context).pop();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tamam'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
