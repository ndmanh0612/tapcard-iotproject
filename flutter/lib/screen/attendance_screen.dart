import 'package:flutter/material.dart';
import 'package:taptag/model/attendance.model.dart';

class AttendanceDetailPage extends StatelessWidget {
  final AttendanceResult attendance;

  const AttendanceDetailPage({super.key, required this.attendance});

  static const Map<String, String> _reasonMap = {
    "lecture": "Tiết học lý thuyết",
    "lab": "Thực hành / Thí nghiệm",
    "exam": "Kiểm tra / Thi",
    "seminar": "Hội thảo",
    "workshop": "Workshop",
    "extracurricular": "Hoạt động ngoại khóa",
    "general": "Khác",
  };

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ngày ${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final translatedReason = _reasonMap[attendance.reason] ?? "Khác";

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết điểm danh')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Icon(Icons.groups_outlined, size: 84, color: Theme.of(context).colorScheme.primary),
          Text(
            "Phiên điểm danh",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            "Lý do",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          Text(translatedReason, style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 10),
          Text(
            "Ngày",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          Text(attendance.date, style: Theme.of(context).textTheme.bodyLarge),

          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          Text(
            "Loại hình",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          Text(attendance.isOut ? "Giờ ra (Exit)" : "Giờ vào (Entry)"),

          const SizedBox(height: 10),
          Text(
            attendance.isOut ? "Thời gian ra" : "Thời gian vào",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          Text(_formatTimestamp(attendance.isOut ? attendance.timeOut : attendance.timeIn)),

          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          Text(
            "Máy quét",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(attendance.reader.name),
            subtitle: Text("ID: ${attendance.reader.ssid}"),
            trailing: attendance.reader.isActive
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.cancel, color: Colors.red),
          ),

          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          Text(
            "Danh sách học sinh (${attendance.students.length})",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          ...attendance.students.map(
            (student) => ListTile(
              leading: const Icon(Icons.person_outlined),
              dense: true,
              title: Text("${student.name} (${student.mobileNo})"),
              trailing: student.suspended
                  ? const Icon(Icons.cancel, color: Colors.red)
                  : const Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
