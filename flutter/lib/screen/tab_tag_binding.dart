import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taptag/model/tag.model.dart';
import 'package:taptag/model/user.model.dart';
import 'package:taptag/model/rfid.model.dart';
import 'package:taptag/model/reader.model.dart';
import 'package:taptag/core/constants.dart';

class TagBindingTab extends StatefulWidget {
  const TagBindingTab({super.key});

  @override
  State<TagBindingTab> createState() => _TagBindingTabState();
}

class _TagBindingTabState extends State<TagBindingTab> {
  String searchQuery = "";
  bool showUnboundOnly = false;
  bool isLoading = false;
  List<UserModel> allStudents = [];

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final url = Uri.parse("${AppConstants.baseUrl}/user?type=student");
      final response = await http.get(url, headers: {'Authorization': userProvider.token!});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allStudents = (data['result'] as List).map((u) => UserModel.fromJson(u)).toList();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách học sinh: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchStudents();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.token != null) {
        Provider.of<TagProvider>(context, listen: false).fetchAllTags(userProvider.token!);
      }
    });
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thêm học sinh mới"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Họ và tên")),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại", counterText: ""),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();

              if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")));
                return;
              }

              if (phone.length != 10) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Số điện thoại phải có đúng 10 số")));
                return;
              }

              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email không đúng định dạng")));
                return;
              }

              final userProvider = Provider.of<UserProvider>(context, listen: false);
              try {
                final newUser = UserModel(
                  name: name,
                  mobileNo: phone,
                  email: email,
                  type: 'student',
                );
                await userProvider.adminCreateUser(newUser, userProvider.token!);
                if (mounted) {
                  Navigator.pop(context);
                  fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm học sinh thành công!")));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            child: const Text("Thêm"),
          ),
        ],
      ),
    );
  }

  void _showDeleteStudentConfirm(UserModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa học sinh?"),
        content: Text("Bạn có chắc chắn muốn xóa hoàn toàn học sinh ${student.name} khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              try {
                final url = Uri.parse("${AppConstants.baseUrl}/user?id=${student.id}");
                final response = await http.delete(url, headers: {'Authorization': userProvider.token!});
                
                if (response.statusCode == 200) {
                  if (mounted) {
                    Navigator.pop(context);
                    fetchStudents();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa học sinh thành công!")));
                  }
                } else {
                  throw Exception("Lỗi server: ${response.body}");
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showBindingDialog(UserModel student) async {
    final rfidProvider = Provider.of<RFIDProvider>(context, listen: false);
    final readerProvider = Provider.of<ReaderProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (readerProvider.allReaders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy máy quét. Hãy đăng ký máy quét trước.")));
      return;
    }

    String selectedReaderId = readerProvider.allReaders.first.id!;

    try {
      await readerProvider.toggleBindingMode(selectedReaderId, true, userProvider.token!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Không thể bật chế độ gán thẻ: $e")));
      return;
    }

    rfidProvider.lastDetectedTag = null;
    rfidProvider.connectToWebSocket();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<RFIDProvider>(
          builder: (context, rfid, child) {
            return AlertDialog(
              title: const Text("Gán thẻ RFID"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Đang gán thẻ cho: ${student.name}"),
                  const SizedBox(height: 10),
                  const Text("Chế độ gán thẻ đang MỞ trên server.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 20),
                  if (rfid.lastDetectedTag == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    const Text("Đang chờ quẹt thẻ..."),
                    const Text("(Quẹt thẻ chưa đăng ký lên máy quét)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ] else ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 10),
                    Text("Đã nhận diện UID: ${rfid.lastDetectedTag}"),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await readerProvider.toggleBindingMode(selectedReaderId, false, userProvider.token!);
                    rfid.lastDetectedTag = null;
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Hủy"),
                ),
                if (rfid.lastDetectedTag != null)
                  ElevatedButton(
                    onPressed: () async {
                      final tagProvider = Provider.of<TagProvider>(context, listen: false);
                      try {
                        await tagProvider.bindTag(
                          token: userProvider.token!,
                          tag: rfid.lastDetectedTag!,
                          userId: student.id!,
                        );
                        await readerProvider.toggleBindingMode(selectedReaderId, false, userProvider.token!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gán thẻ thành công!")));
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                      }
                    },
                    child: const Text("Xác nhận gán"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = Provider.of<TagProvider>(context);
    
    final filteredStudents = allStudents.where((s) {
      final matchesSearch = (s.name ?? "").toLowerCase().contains(searchQuery.toLowerCase()) || s.mobileNo.contains(searchQuery);
      if (showUnboundOnly) {
        final hasTag = tagProvider.tags.any((t) => t.associated == s.id);
        return matchesSearch && !hasTag;
      }
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: "Tìm kiếm học sinh...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.person_add, color: Colors.blue),
                onPressed: _showAddUserDialog,
                tooltip: "Thêm học sinh mới",
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("Chưa gán thẻ", style: TextStyle(fontSize: 12)),
              Switch(
                value: showUnboundOnly,
                onChanged: (v) => setState(() => showUnboundOnly = v),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: fetchStudents,
                  child: ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final boundTag = tagProvider.tags.cast<TagModel?>().firstWhere((t) => t?.associated == student.id, orElse: () => null);

                      return ListTile(
                        leading: CircleAvatar(child: Text(student.name?[0] ?? "U")),
                        title: Text(student.name ?? "Không tên"),
                        subtitle: Text(student.mobileNo),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (boundTag != null)
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.orange),
                                tooltip: "Hủy gán thẻ",
                                onPressed: () => _showDeleteTagConfirm(student, boundTag.tag),
                              )
                            else
                              ElevatedButton(
                                onPressed: () => showBindingDialog(student),
                                child: const Text("Gán thẻ"),
                              ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                              tooltip: "Xóa học sinh",
                              onPressed: () => _showDeleteStudentConfirm(student),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showDeleteTagConfirm(UserModel student, String tagUid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hủy gán thẻ?"),
        content: Text("Bạn có chắc chắn muốn xóa mã thẻ của ${student.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              final tagProvider = Provider.of<TagProvider>(context, listen: false);
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              try {
                await tagProvider.deleteTag(userProvider.token!, tagUid);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy gán thẻ!")));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
