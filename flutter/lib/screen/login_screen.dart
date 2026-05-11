import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:taptag/core/widgets/modern_button.dart';
import 'package:taptag/core/widgets/modern_textfield.dart';
import 'package:taptag/model/user.model.dart';
import 'package:taptag/screen/home_screen.dart';
import 'package:taptag/screen/register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.surface,
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      size: 60,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    "Tapcard",
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    "Hệ thống điểm danh thông minh",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: ModernTextField(
                    controller: _phoneController,
                    label: "Số điện thoại",
                    hint: "Nhập số điện thoại của bạn",
                    prefixIcon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: ModernTextField(
                    controller: _passwordController,
                    label: "Mật khẩu",
                    hint: "Nhập mật khẩu",
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 1000),
                  child: ModernButton(
                    isLoading: _isLoading,
                    text: "Đăng nhập",
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        await userProvider.login(_phoneController.text, _passwordController.text);
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Lỗi đăng nhập: $e"),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 1200),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: "Chưa có tài khoản? "),
                          TextSpan(
                            text: "Đăng ký ngay",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );

  }
}

