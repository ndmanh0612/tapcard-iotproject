import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taptag/model/theme.model.dart';
import 'package:taptag/screen/tab_attendance_form.dart';
import 'package:taptag/screen/login_screen.dart';
import 'package:taptag/model/user.model.dart';
import 'package:taptag/screen/tab_history.dart';
import 'package:taptag/screen/tab_profile.dart';
import 'package:taptag/screen/tab_tag_binding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> _getTabs(bool isAdmin) {
    return [
      const ProfileTab(),
      const HistoryTab(),
      const AttendanceStepperPage(),
      if (isAdmin) const TagBindingTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tapcard"),
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
          onPressed: () async {
            await Provider.of<UserProvider>(context, listen: false).logout();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
            );
          },
        ),
        actions: [IconButton(icon: const Icon(Icons.brightness_6), onPressed: () => themeProvider.toggleTheme())],
      ),
      body: _getTabs(userProvider.user?.type == 'admin')[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (newIndex) => setState(() => _currentIndex = newIndex),
        type: BottomNavigationBarType.fixed, // Quan trọng khi có > 3 item
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Cá nhân"),
          const BottomNavigationBarItem(icon: Icon(Icons.view_list), label: "Lịch sử"),
          const BottomNavigationBarItem(icon: Icon(Icons.add), label: "Điểm danh"),
          if (userProvider.user?.type == 'admin')
            const BottomNavigationBarItem(icon: Icon(Icons.badge), label: "Gán thẻ"),
        ],
      ),
    );
  }
}
