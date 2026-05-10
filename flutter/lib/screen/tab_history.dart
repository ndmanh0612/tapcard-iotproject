import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taptag/model/attendance.model.dart';
import 'package:taptag/model/user.model.dart';
import 'package:taptag/screen/attendance_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final Map<String, String> _reasonMap = {
    "lecture": "Tiết học lý thuyết",
    "lab": "Thực hành / Thí nghiệm",
    "exam": "Kiểm tra / Thi",
    "seminar": "Hội thảo",
    "workshop": "Workshop",
    "extracurricular": "Hoạt động ngoại khóa",
    "general": "Khác",
  };

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      Provider.of<AttendanceProvider>(context, listen: false).fetchAllAttendance(userProvider.token!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Lịch sử điểm danh",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              await attendanceProvider.fetchAllAttendance(userProvider.token!);
            },
            child: ListView.builder(
              itemCount: attendanceProvider.attendanceResults.length,
              itemBuilder: (context, index) {
                final attendance = attendanceProvider.attendanceResults[index];
                final translatedReason = _reasonMap[attendance.reason] ?? "Khác";
                final timeStr = _formatTime(attendance.isOut ? attendance.timeOut : attendance.timeIn);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: attendance.isOut ? Colors.orange : Colors.green,
                    child: Icon(
                      attendance.isOut ? Icons.logout : Icons.login,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(translatedReason),
                  subtitle: Text("Ngày: ${attendance.date} • Lúc: $timeStr\nMáy: ${attendance.reader.name} • ${attendance.students.length} HS"),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AttendanceDetailPage(attendance: attendance)),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
