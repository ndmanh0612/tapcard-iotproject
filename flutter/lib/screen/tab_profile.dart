import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taptag/model/user.model.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Center(child: Text("Đang tải dữ liệu..."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 20),
          Text(
            user.name ?? "Không tên",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user.type == 'admin' ? "Quản trị viên" : "Học sinh",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          _buildInfoTile(Icons.phone, "Số điện thoại", user.mobileNo),
          _buildInfoTile(Icons.email, "Email", user.email ?? "Chưa cập nhật"),
          _buildInfoTile(Icons.verified, "Trạng thái", user.verified ? "Đã xác thực" : "Chưa xác thực"),
          const SizedBox(height: 40),
          
        
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
