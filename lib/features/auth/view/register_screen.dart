import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../model/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'waiting_approval_screen.dart';
import '../../core/colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentStep = 0; // 0 = Kişisel bilgiler, 1 = Şifre oluştur
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validatePersonalInfo() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text)) {
      return false;
    }
    return true;
  }

  bool _validatePassword() {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _passwordController.text != _confirmPasswordController.text ||
        _passwordController.text.length < 6) {
      return false;
    }
    return true;
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _validatePersonalInfo()) {
      setState(() {
        _currentStep = 1;
      });
      _animationController.reset();
      _animationController.forward();
    } else if (_currentStep == 1 && _validatePassword()) {
      _register();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep = 0;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      Navigator.pop(context);
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
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),

              // İlerleme çubuğu
              _buildProgressIndicator(),

              // Form içeriği
              _buildFormContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Center(
        child: Text(
          _currentStep == 0 ? 'Kişisel Bilgiler' : 'Şifre Oluştur',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 20, 36, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Step 1 indicator
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _currentStep >= 0
                          ? AppColors.accentColor
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Kişisel Bilgiler',
                      style: TextStyle(
                        color: _currentStep == 0
                            ? AppColors.accentColor
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: _currentStep == 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              // Line between steps
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: _currentStep >= 1
                        ? AppColors.buttonGradient
                        : LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.5)
                            ],
                          ),
                  ),
                ),
              ),

              // Step 2 indicator
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _currentStep >= 1
                          ? AppColors.accentColor
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Şifre Oluştur',
                      style: TextStyle(
                        color: _currentStep == 1
                            ? AppColors.accentColor
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: _currentStep == 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Expanded(
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          // Durum değişikliklerini dinle
          if (authViewModel.state.status == AuthStatus.registering) {
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
          } else if (authViewModel.state.status == AuthStatus.pendingApproval) {
            // Onay sayfasına yönlendir
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const WaitingApprovalScreen(),
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
            });
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    (1.0 - _slideAnimation.value) *
                        (_currentStep == 0
                            ? -MediaQuery.of(context).size.width
                            : MediaQuery.of(context).size.width),
                    0,
                  ),
                  child: child,
                );
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Form içeriği
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 10),
                        child: _currentStep == 0
                            ? _buildPersonalInfoStep()
                                .animate()
                                .fadeIn(duration: 300.ms)
                            : _buildPasswordStep(authViewModel)
                                .animate()
                                .fadeIn(duration: 300.ms),
                      ),
                    ),

                    // Butonlar
                    _buildButtons(authViewModel),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // Ad alanı
        _buildInputField(
          label: 'Ad',
          hint: 'Adınızı girin',
          icon: Icons.person_outline,
          controller: _firstNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Adınızı giriniz';
            }
            return null;
          },
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 300.ms)
            .moveY(begin: 20, end: 0, delay: 100.ms, duration: 300.ms),

        const SizedBox(height: 16),

        // Soyad alanı
        _buildInputField(
          label: 'Soyad',
          hint: 'Soyadınızı girin',
          icon: Icons.person_outline,
          controller: _lastNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Soyadınızı giriniz';
            }
            return null;
          },
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 300.ms)
            .moveY(begin: 20, end: 0, delay: 200.ms, duration: 300.ms),

        const SizedBox(height: 16),

        // E-posta alanı
        _buildInputField(
          label: 'E-posta',
          hint: 'E-posta adresinizi girin',
          icon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'E-posta adresinizi giriniz';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir e-posta adresi giriniz';
            }
            return null;
          },
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 300.ms)
            .moveY(begin: 20, end: 0, delay: 300.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildPasswordStep(AuthViewModel authViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // Şifre alanı
        _buildPasswordField(
          label: 'Şifre',
          hint: 'Şifrenizi girin',
          isObscure: _obscurePassword,
          controller: _passwordController,
          toggleObscure: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şifrenizi giriniz';
            }
            if (value.length < 6) {
              return 'Şifre en az 6 karakter olmalıdır';
            }
            return null;
          },
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 300.ms)
            .moveY(begin: 20, end: 0, delay: 100.ms, duration: 300.ms),

        const SizedBox(height: 16),

        // Şifre tekrar alanı
        _buildPasswordField(
          label: 'Şifre Tekrar',
          hint: 'Şifrenizi tekrar girin',
          isObscure: _obscureConfirmPassword,
          controller: _confirmPasswordController,
          toggleObscure: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şifrenizi tekrar giriniz';
            }
            if (value != _passwordController.text) {
              return 'Şifreler eşleşmiyor';
            }
            return null;
          },
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 300.ms)
            .moveY(begin: 20, end: 0, delay: 200.ms, duration: 300.ms),

        // Hata mesajı
        if (authViewModel.state.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authViewModel.state.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).shimmer(
              duration: 1200.ms,
              delay: 300.ms,
              color: Colors.red.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: AppColors.inputColor,
            border: Border.all(
              color: AppColors.inputBorderColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.inputHintColor),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: AppColors.accentColor),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: AppColors.inputColor,
            border: Border.all(
              color: AppColors.inputBorderColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.inputHintColor),
              border: InputBorder.none,
              prefixIcon:
                  Icon(Icons.lock_outline, color: AppColors.accentColor),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: toggleObscure,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(AuthViewModel authViewModel) {
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: Column(
        children: [
          // İleri / Kayıt Ol butonları
          Row(
            children: [
              // Geri butonu
              if (_currentStep == 1)
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 55,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: TextButton(
                      onPressed: _isLoading ? null : _prevStep,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Geri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              // İleri / Kayıt Ol butonu
              Expanded(
                flex: 2,
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentStep == 0 ? 'İleri' : 'Kayıt Ol',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          // Hesabınız var mı?
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hesabınız var mı?',
                  style: TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text('Giriş yap'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }
}
