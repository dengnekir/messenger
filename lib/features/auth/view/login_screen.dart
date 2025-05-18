import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../model/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'register_screen.dart';
import 'waiting_approval_screen.dart';
import '../../core/colors.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        width: double.infinity,
        height: double.infinity,
        child: Consumer<AuthViewModel>(
          builder: (context, authViewModel, _) {
            // Durum değişikliklerini dinle
            if (authViewModel.state.status == AuthStatus.loggingIn) {
              _isLoading = true;
            } else {
              _isLoading = false;
            }

            if (authViewModel.state.status == AuthStatus.authenticated) {
              // Ana sayfaya yönlendir
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (Route<dynamic> route) => false,
                );
              });
            } else if (authViewModel.state.status ==
                AuthStatus.pendingApproval) {
              // Onay sayfasına yönlendir
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaitingApprovalScreen(),
                  ),
                );
              });
            }

            return SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  );
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 80),

                          // Animasyonlu logo ve slogan
                          _buildAnimatedLogo()
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOutQuart,
                                duration: 600.ms,
                              ),
                          const SizedBox(height: 60),

                          // Email alanı
                          _buildEmailField()
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms)
                              .moveY(
                                  begin: 20,
                                  end: 0,
                                  delay: 200.ms,
                                  duration: 500.ms,
                                  curve: Curves.easeOutQuad),
                          const SizedBox(height: 16),

                          // Şifre alanı
                          _buildPasswordField()
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 500.ms)
                              .moveY(
                                  begin: 20,
                                  end: 0,
                                  delay: 300.ms,
                                  duration: 500.ms,
                                  curve: Curves.easeOutQuad),
                          const SizedBox(height: 12),

                          // Beni hatırla ve şifremi unuttum
                          _buildRememberMeAndForgotPassword()
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 500.ms),

                          // Hata mesajı
                          if (authViewModel.state.errorMessage != null)
                            _buildErrorMessage(
                                    authViewModel.state.errorMessage!)
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .shimmer(
                                    duration: 1200.ms,
                                    color: Colors.red.withOpacity(0.4)),

                          // Giriş butonu
                          const SizedBox(height: 24),
                          _buildLoginButton()
                              .animate()
                              .fadeIn(delay: 500.ms, duration: 500.ms)
                              .moveY(
                                  begin: 20,
                                  end: 0,
                                  delay: 500.ms,
                                  duration: 500.ms,
                                  curve: Curves.easeOutQuad),

                          // Kayıt ol linki
                          const SizedBox(height: 32),
                          _buildRegisterLink()
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 500.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.white70,
            highlightColor: Colors.white,
            period: const Duration(seconds: 3),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  const TextSpan(
                      text: 'Messenger', style: TextStyle(color: Colors.white)),
                  TextSpan(
                    text: 'App',
                    style: TextStyle(
                      color: AppColors.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Haydiii',
                textStyle: TextStyle(
                  fontSize: 18.0,
                  color: AppColors.accentColor,
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
            totalRepeatCount: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: AppColors.inputColor,
        border: Border.all(
          color: AppColors.inputBorderColor.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'E-posta',
          hintStyle: TextStyle(color: AppColors.inputHintColor),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.email, color: AppColors.accentColor),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'E-posta adresinizi giriniz';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Geçerli bir e-posta adresi giriniz';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: AppColors.inputColor,
        border: Border.all(
          color: AppColors.inputBorderColor.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Şifre',
          hintStyle: TextStyle(color: AppColors.inputHintColor),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.lock, color: AppColors.accentColor),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: AppColors.textColor.withOpacity(0.7),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Şifrenizi giriniz';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Beni hatırla
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.accentColor;
                      }
                      return Colors.transparent;
                    },
                  ),
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: AppColors.accentColor.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Beni Hatırla',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),

        // Şifremi unuttum
        GestureDetector(
          onTap: () {
            _showForgotPasswordDialog();
          },
          child: Text(
            'Şifremi Unuttum',
            style: TextStyle(
              color: AppColors.accentColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentColor.withOpacity(0.4),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: AppColors.buttonGradient,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Hesabın yok mu?',
          style: TextStyle(color: Colors.white70),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const RegisterScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text('Kayıt ol'),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Şifre Sıfırlama',
            style: TextStyle(color: AppColors.textColor),
            textAlign: TextAlign.center,
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lütfen e-posta adresinizi girin. Size şifre sıfırlama bağlantısı göndereceğiz.',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputColor,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppColors.inputBorderColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'E-posta',
                      hintStyle: TextStyle(
                        color: AppColors.inputHintColor,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: AppColors.accentColor,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta adresinizi giriniz';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Geçerli bir e-posta adresi giriniz';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondaryTextColor,
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final authViewModel =
                            Provider.of<AuthViewModel>(context, listen: false);
                        authViewModel.sendPasswordResetEmail(
                            emailController.text.trim());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            content: const Text(
                              'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Gönder'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
