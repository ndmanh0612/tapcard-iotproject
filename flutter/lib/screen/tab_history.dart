import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
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
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              await attendanceProvider.fetchAllAttendance(userProvider.token!);
            },
            child: attendanceProvider.attendanceResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          "Chưa có lịch sử điểm danh",
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: attendanceProvider.attendanceResults.length,
                    itemBuilder: (context, index) {
                      final attendance = attendanceProvider.attendanceResults[index];
                      final translatedReason = _reasonMap[attendance.reason] ?? "Khác";
                      final timeStr = _formatTime(attendance.isOut ? attendance.timeOut : attendance.timeIn);
                      final isOut = attendance.isOut;

                      return FadeInUp(
                        delay: Duration(milliseconds: index * 100),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AttendanceDetailPage(attendance: attendance)),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (isOut ? Colors.orange : Colors.green).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        isOut ? Icons.logout_rounded : Icons.login_rounded,
                                        color: isOut ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            translatedReason,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                              const SizedBox(width: 4),
                                              Text(
                                                attendance.date,
                                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(Icons.access_time_rounded, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                              const SizedBox(width: 4),
                                              Text(
                                                timeStr,
                                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  "${attendance.students.length} Học sinh",
                                                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "Máy: ${attendance.reader.name}",
                                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 10),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

