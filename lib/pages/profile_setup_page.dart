import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
  String gender = "male";
  DateTime? dob;

  Future<void> submit() async {
    if (nameController.text.trim().isEmpty || dob == null) return;

    await FirebaseDatabase.instance.ref("accounts/${widget.uid}").set({
      "email": widget.email,
      "name": nameController.text.trim(),
      "gender": gender,
      "dob": dob!.toIso8601String(),

      "homes": {
        "home1": {
          "name": "Home 1",
          "devices": {},
          "alarm": {
            "enabled": false,
            "start": "23:00",
            "end": "06:00",
          },
        }
      },

      "alarm": {
        "enabled": false,
        "start": "23:00",
        "end": "06:00",
      },
    });

    Navigator.pop(context); // quay lại app sau khi lưu
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (picked != null) {
      setState(() => dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Profile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Tên"),
            ),

            SizedBox(height: 12),

            DropdownButton<String>(
              value: gender,
              items: [
                DropdownMenuItem(value: "male", child: Text("Nam")),
                DropdownMenuItem(value: "female", child: Text("Nữ")),
              ],
              onChanged: (v) {
                setState(() => gender = v!);
              },
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Text(dob == null
                    ? "Chưa chọn ngày sinh"
                    : dob!.toLocal().toString().split(" ")[0]),
                Spacer(),
                ElevatedButton(
                  onPressed: pickDate,
                  child: Text("Chọn ngày"),
                ),
              ],
            ),

            Spacer(),

            ElevatedButton(
              onPressed: submit,
              child: Text("Hoàn tất"),
            ),
          ],
        ),
      ),
    );
  }
}