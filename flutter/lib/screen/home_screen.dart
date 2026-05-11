import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "Tapcard",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 20),
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
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
            ),
          )
        ],
      ),
      body: FadeIn(
        key: ValueKey(_currentIndex),
        duration: const Duration(milliseconds: 400),
        child: _getTabs(userProvider.user?.type == 'admin')[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (newIndex) => setState(() => _currentIndex = newIndex),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Cá nhân",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: "Lịch sử",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded),
              label: "Điểm danh",
            ),
            if (userProvider.user?.type == 'admin')
              const BottomNavigationBarItem(
                icon: Icon(Icons.badge_outlined),
                activeIcon: Icon(Icons.badge_rounded),
                label: "Gán thẻ",
              ),
          ],
        ),
      ),
    );
  }
}

