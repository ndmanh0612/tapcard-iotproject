import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
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
    final theme = Theme.of(context);
    final translatedReason = _reasonMap[attendance.reason] ?? "Khác";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết điểm danh'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.groups_rounded, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      translatedReason,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attendance.date,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildSectionTitle(context, "Thông tin phiên"),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        Icons.swap_vert_rounded,
                        "Loại hình",
                        attendance.isOut ? "Giờ ra (Exit)" : "Giờ vào (Entry)",
                        attendance.isOut ? Colors.orange : Colors.green,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.access_time_rounded,
                        attendance.isOut ? "Thời gian ra" : "Thời gian vào",
                        _formatTimestamp(attendance.isOut ? attendance.timeOut : attendance.timeIn),
                        theme.colorScheme.primary,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.qr_code_scanner_rounded,
                        "Máy quét",
                        attendance.reader.name,
                        theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildSectionTitle(context, "Danh sách học sinh (${attendance.students.length})"),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendance.students.length,
                itemBuilder: (context, index) {
                  final student = attendance.students[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Text(student.name ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("SĐT: ${student.mobileNo}"),
                      trailing: student.suspended
                          ? const Icon(Icons.cancel_rounded, color: Colors.red, size: 20)
                          : const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }
}

