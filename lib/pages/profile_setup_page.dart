import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
class ProfileSetupPage extends StatefulWidget {
  final String uid;
  final String email;

  const ProfileSetupPage({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final nameController = TextEditingController();
  final dayController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();
  final phoneController = TextEditingController();

  String gender = "Nam";
  bool saving = false;
  String error = "";

  @override
  void dispose() {
    nameController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  List<String> _suggestNumbers({
    required String input,
    required int start,
    required int end,
    int pad = 0,
  }) {
    if (input.trim().isEmpty) return [];

    return List.generate(end - start + 1, (i) {
      final value = start + i;
      return pad > 0 ? value.toString().padLeft(pad, '0') : value.toString();
    }).where((v) => v.startsWith(input.trim())).toList();
  }

  Widget _autoBox({
    required String label,
    required TextEditingController controller,
    required List<String> Function(String input) suggestions,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (value) => suggestions(value.text),
      onSelected: (value) {
        controller.text = value;
      },
      fieldViewBuilder: (context, autoController, focusNode, onSubmit) {
        autoController.text = controller.text;
        autoController.selection = TextSelection.fromPosition(
          TextPosition(offset: autoController.text.length),
        );

        return TextField(
          controller: autoController,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          onChanged: (value) {
            controller.text = value;
          },
        );
      },
    );
  }

  Future<void> submit() async {
    if (saving) return;

    setState(() {
      saving = true;
      error = "";
    });

    try {
      final name = nameController.text.trim();

      final day = dayController.text
          .trim()
          .padLeft(2, '0');

      final month = monthController.text
          .trim()
          .padLeft(2, '0');

      final year = yearController.text.trim();

      final phone = phoneController.text.trim();

      if (name.isEmpty ||
          phone.isEmpty ||
          gender.isEmpty ||
          day.isEmpty ||
          month.isEmpty ||
          year.isEmpty) {
        setState(() {
          error = "Vui lòng nhập đủ thông tin";
          saving = false;
        });

        return;
      }

      final homeId =
          "home_${DateTime.now().millisecondsSinceEpoch}";

      final dob = "$year-$month-$day";

      final accountRef =
      FirebaseDatabase.instance.ref("accounts/${widget.uid}");

      final accountSnap = await accountRef.get();

      final oldData = accountSnap.value is Map
          ? Map<String, dynamic>.from(accountSnap.value as Map)
          : <String, dynamic>{};

      final oldHomes = oldData["homes"];
      final oldHomeOrder = oldData["homeOrder"];

      final hasHomes = oldHomes is Map && oldHomes.isNotEmpty;
      await accountRef.update({
        "email": widget.email,
        "profile": {
          "name": name,
          "gender": gender,
          "dob": dob,
          "phone": phone,
          "photoUrl": oldData["profile"] is Map
              ? (Map<String, dynamic>.from(oldData["profile"] as Map)["photoUrl"] ?? "")
              : "",
        },
        "shareRequests": oldData["shareRequests"] ?? {},
        "shareList": oldData["shareList"] ?? {},
        "sharedHomes": oldData["sharedHomes"] ?? {},
      });

      if (!hasHomes) {
        await accountRef.child("homes/$homeId").set({
          "name": "Nhà của tôi",
          "_ownerUid": widget.uid,
          "_shared": false,
          "devices": {},
        });

        await accountRef.child("homeOrder").set([homeId]);
      } else if (oldHomeOrder == null) {
        await accountRef.child("homeOrder").set((oldHomes as Map).keys.toList());
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomePage(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = "Không thể lưu thông tin";
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thiết lập tài khoản"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();

            if (!context.mounted) return;

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Tên"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Số điện thoại",
                helperText: "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp",
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),

            const SizedBox(height: 20),

            RadioGroup<String>(
              groupValue: gender,
              onChanged: (value) {
                if (value == null) return;
                setState(() => gender = value);
              },
              child: const Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: "Nam",
                      title: Text("Nam"),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: "Nữ",
                      title: Text("Nữ"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ngày sinh",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _autoBox(
                    label: "Ngày",
                    controller: dayController,
                    suggestions: (input) => _suggestNumbers(
                      input: input,
                      start: 1,
                      end: 31,
                      pad: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _autoBox(
                    label: "Tháng",
                    controller: monthController,
                    suggestions: (input) => _suggestNumbers(
                      input: input,
                      start: 1,
                      end: 12,
                      pad: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _autoBox(
                    label: "Năm",
                    controller: yearController,
                    suggestions: (input) => _suggestNumbers(
                      input: input,
                      start: 1950,
                      end: DateTime.now().year,
                    ),
                  ),
                ),
              ],
            ),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : submit,
                child: saving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Hoàn tất",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}