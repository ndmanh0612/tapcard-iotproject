import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:taptag/core/widgets/modern_button.dart';
import 'package:taptag/model/attendance.model.dart';
import 'package:taptag/model/reader.model.dart';
import 'package:taptag/model/rfid.model.dart';
import 'package:taptag/model/user.model.dart';

class AttendanceStepperPage extends StatefulWidget {
  const AttendanceStepperPage({super.key});

  @override
  State<AttendanceStepperPage> createState() => _AttendanceStepperPageState();
}

class _AttendanceStepperPageState extends State<AttendanceStepperPage> {
  int _currentStep = 0;
  String _selectedReason = "general";
  bool _isExit = false;
  ReaderModel? _selectedReader;
  bool _isSessionStarted = false;

  final Map<String, String> _reasonMap = {
    "lecture": "Tiết học lý thuyết",
    "lab": "Thực hành / Thí nghiệm",
    "exam": "Kiểm tra / Thi",
    "seminar": "Hội thảo",
    "workshop": "Workshop",
    "extracurricular": "Hoạt động ngoại khóa",
    "general": "Khác",
  };

  @override
  Widget build(BuildContext context) {
    final readerProvider = Provider.of<ReaderProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final rfidProvider = Provider.of<RFIDProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: theme.colorScheme.primary),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          elevation: 0,
          onStepContinue: () async {
            if (_currentStep == 0 && _selectedReader != null) {
              setState(() => _currentStep++);
            } else if (_currentStep == 1) {
              try {
                await attendanceProvider.startSession(
                  token: userProvider.token!,
                  reader: _selectedReader!.id!,
                  isOut: _isExit,
                  reason: _selectedReason,
                );
                rfidProvider.scannedStudents.clear();
                rfidProvider.connectToWebSocket();
                setState(() {
                  _isSessionStarted = true;
                  _currentStep++;
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi: $e"), behavior: SnackBarBehavior.floating),
                );
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0 && !_isSessionStarted) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              title: const Text("Chọn máy quét", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hãy chọn máy quét đang hoạt động tại phòng:"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ReaderModel>(
                        isExpanded: true,
                        hint: const Text("Chọn máy quét"),
                        value: _selectedReader,
                        onChanged: (v) => setState(() => _selectedReader = v),
                        items: readerProvider.allReaders.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r.name));
                        }).toList(),
                      ),
                    ),
                  ),
                  if (readerProvider.allReaders.isEmpty)
                    TextButton.icon(
                      onPressed: () => readerProvider.fetchAllReaders(userProvider.token!),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Tải lại danh sách máy"),
                    ),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text("Thiết lập phiên", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Lý do điểm danh:", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedReason,
                        onChanged: (v) => setState(() => _selectedReason = v!),
                        items: _reasonMap.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: const Text("Hình thức: Ra về", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_isExit ? "Ghi nhận giờ ra" : "Ghi nhận giờ vào"),
                      value: _isExit,
                      onChanged: (v) => setState(() => _isExit = v),
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text("Đang điểm danh", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        SpinKitRipple(color: theme.colorScheme.primary, size: 60),
                        const SizedBox(height: 16),
                        const Text(
                          "Hệ thống đang chờ quẹt thẻ...",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Đã quẹt: ${rfidProvider.scannedStudents.length} học sinh",
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: rfidProvider.scannedStudents.isEmpty
                        ? Center(
                            child: Text(
                              "Chưa có học sinh nào quẹt thẻ",
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: rfidProvider.scannedStudents.length,
                            itemBuilder: (context, index) {
                              final student = rfidProvider.scannedStudents[index];
                              return FadeInRight(
                                delay: const Duration(milliseconds: 200),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                      child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 20),
                                    ),
                                    title: Text(student.name ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("SĐT: ${student.mobileNo}"),
                                    trailing: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  ModernButton(
                    color: Colors.redAccent,
                    onPressed: () async {
                      try {
                        await attendanceProvider.endSession(
                          token: userProvider.token!,
                          sessionId: attendanceProvider.currentSessionId!,
                        );
                        setState(() {
                          _isSessionStarted = false;
                          _currentStep = 0;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã kết thúc phiên điểm danh!"), behavior: SnackBarBehavior.floating),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi: $e"), behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    text: "Kết thúc điểm danh",
                    icon: Icons.stop_rounded,
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
          controlsBuilder: (context, details) {
            if (_isSessionStarted) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      onPressed: details.onStepContinue!,
                      text: _currentStep == 1 ? "Bắt đầu điểm danh" : "Tiếp tục",
                      icon: _currentStep == 1 ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text("Quay lại"),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

