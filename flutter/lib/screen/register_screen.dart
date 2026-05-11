import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:taptag/core/widgets/modern_button.dart';
import 'package:taptag/core/widgets/modern_textfield.dart';
import 'package:taptag/model/user.model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Đăng ký tài khoản"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
            child: Column(
              children: [
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 60,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: ModernTextField(
                    controller: _nameController,
                    label: "Họ và tên",
                    hint: "Nhập họ và tên của bạn",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: ModernTextField(
                    controller: _phoneController,
                    label: "Số điện thoại",
                    hint: "Nhập số điện thoại",
                    prefixIcon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: ModernTextField(
                    controller: _emailController,
                    label: "Email",
                    hint: "Nhập địa chỉ email",
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
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
                    text: "Đăng ký ngay",
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        final newUser = UserModel(
                          name: _nameController.text,
                          mobileNo: _phoneController.text,
                          email: _emailController.text,
                          password: _passwordController.text,
                          type: 'student',
                        );
                        await userProvider.registerUser(newUser);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Đăng ký thành công! Hãy đăng nhập."),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Lỗi đăng ký: $e"),
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );

  }
}

