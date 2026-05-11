import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:taptag/model/user.model.dart';
import 'package:taptag/model/tag.model.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final tagProvider = Provider.of<TagProvider>(context);
    final user = userProvider.user;
    final theme = Theme.of(context);

    if (user == null) {
      return const Center(child: Text("Đang tải dữ liệu..."));
    }

    // Find tag associated with this user
    final boundTag = tagProvider.tags.where((t) => t.associated == user.id).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          FadeInDown(
            child: Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, size: 60, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                      ),
                      child: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              user.name ?? "N/A",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.type == 'admin' ? "Quản trị viên" : "Học sinh/Sinh viên",
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(context, Icons.phone_android_rounded, "Số điện thoại", user.mobileNo),
                    const Divider(height: 32),
                    _buildInfoRow(context, Icons.email_rounded, "Email", user.email ?? "Chưa cập nhật"),
                    const Divider(height: 32),
                    _buildInfoRow(context, Icons.verified_user_rounded, "Trạng thái", user.verified ? "Đã xác thực" : "Chưa xác thực"),
                    const Divider(height: 32),
                    _buildInfoRow(context, Icons.credit_card_rounded, "Mã thẻ RFID", boundTag?.tag ?? "Chưa gán thẻ"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


