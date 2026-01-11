import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/api_service.dart';
import '../config/constants.dart';
import '../utils/session.dart';
import '../utils/device_id.dart';
import '../admin/admin_home.dart';
import '../satpam/satpam_home.dart';
import '../warga/list_tamu_page.dart';
import '../config/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final deviceId = await DeviceId.getDeviceId();

    final response = await ApiService.post(AppConstants.loginEndpoint, {
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'device_id': deviceId,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['status'] == 200) {
      await Session.saveSession(
        response['data']['token'],
        response['data']['user'],
      );

      final role = response['data']['user']['role'];
      Widget page;

      if (role == 'admin') {
        page = const AdminHome();
      } else if (role == 'satpam') {
        page = const SatpamHome();
      } else {
        page = const ListTamuPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 16.0 : 24.0;
    
    return Scaffold(
      body: Container(
        decoration: AppDecorations.primaryGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo-baru.png',
                              height: isSmallScreen ? 56 : 66,
                              width: isSmallScreen ? 56 : 66,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 14 : 18),
                        Text(
                          'Selamat Datang',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MyKomplek',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masuk untuk mengelola ronda\n& tamu wajib lapor di komplek Anda',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            height: 1.4,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    Container(
                      decoration: AppDecorations.cardDecoration.copyWith(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 16 : 20,
                        isSmallScreen ? 16 : 20,
                        isSmallScreen ? 16 : 20,
                        16,
                      ),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _usernameController,
                            label: 'Username',
                            hint: 'Masukkan username',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Masukkan password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(
                                      () => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'Login',
                            onPressed: _login,
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
