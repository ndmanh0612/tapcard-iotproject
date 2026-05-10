import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Stepper(
      type: StepperType.vertical,
      currentStep: _currentStep,
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
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
          title: const Text("Chọn máy quét"),
          content: Column(
            children: [
              const Text("Hãy chọn máy quét đang hoạt động:"),
              DropdownButton<ReaderModel>(
                hint: const Text("Chọn máy quét"),
                value: _selectedReader,
                onChanged: (v) => setState(() => _selectedReader = v),
                items: readerProvider.allReaders.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.name));
                }).toList(),
              ),
              if (readerProvider.allReaders.isEmpty)
                TextButton(
                  onPressed: () => readerProvider.fetchAllReaders(userProvider.token!),
                  child: const Text("Tải lại danh sách"),
                ),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text("Thiết lập phiên"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Lý do điểm danh:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                value: _selectedReason,
                onChanged: (v) => setState(() => _selectedReason = v!),
                items: _reasonMap.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("Hình thức: Ra về"),
                subtitle: Text(_isExit ? "Ghi nhận giờ ra" : "Ghi nhận giờ vào"),
                value: _isExit,
                onChanged: (v) => setState(() => _isExit = v),
              ),
            ],
          ),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text("Đang điểm danh"),
          content: Column(
            children: [
              const Text("Hệ thống đang chờ quẹt thẻ...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const Divider(),
              Text("Đã quẹt: ${rfidProvider.scannedStudents.length} học sinh"),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: rfidProvider.scannedStudents.length,
                  itemBuilder: (context, index) {
                    final student = rfidProvider.scannedStudents[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(student.name ?? "Không tên"),
                      subtitle: Text("SĐT: ${student.mobileNo}"),
                    );
                  },
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã kết thúc phiên điểm danh!")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                  }
                },
                child: const Text("Kết thúc điểm danh", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          isActive: _currentStep >= 2,
        ),
      ],
      controlsBuilder: (context, details) {
        if (_isSessionStarted) return const SizedBox.shrink();
        return Row(
          children: [
            ElevatedButton(onPressed: details.onStepContinue, child: const Text("Tiếp tục")),
            if (_currentStep > 0)
              TextButton(onPressed: details.onStepCancel, child: const Text("Quay lại")),
          ],
        );
      },
    );
  }
}
