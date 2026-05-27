import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userGender;
  final String userDob;
  final String userPhone;

  const EditProfilePage({
    super.key,
    required this.userName,
    required this.userGender,
    required this.userDob,
    required this.userPhone,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController nameController;
  late final TextEditingController dayController;
  late final TextEditingController monthController;
  late final TextEditingController yearController;
  late final TextEditingController phoneController;

  String gender = "";
  bool saving = false;

  File? pickedImage;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.userName);

    gender = widget.userGender;

    final dob = widget.userDob.split('T')[0];
    final parts = dob.split('-');

    yearController = TextEditingController(
      text: parts.length == 3 ? parts[0] : "",
    );

    monthController = TextEditingController(
      text: parts.length == 3 ? parts[1] : "",
    );

    dayController = TextEditingController(
      text: parts.length == 3 ? parts[2] : "",
    );
    phoneController = TextEditingController(
      text: widget.userPhone,
    );
  }

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

      return pad > 0
          ? value.toString().padLeft(pad, '0')
          : value.toString();
    }).where((v) => v.startsWith(input.trim())).toList();
  }

  Widget _autoBox({
    required String label,
    required TextEditingController controller,
    required List<String> Function(String input) suggestions,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        return suggestions(value.text);
      },

      onSelected: (value) {
        controller.text = value;
      },

      fieldViewBuilder: (
          context,
          autoController,
          focusNode,
          onSubmit,
          ) {
        autoController.text = controller.text;

        autoController.selection = TextSelection.fromPosition(
          TextPosition(offset: autoController.text.length),
        );

        return TextField(
          controller: autoController,
          focusNode: focusNode,
          keyboardType: TextInputType.number,

          decoration: InputDecoration(
            labelText: label,
          ),

          onChanged: (value) {
            controller.text = value;
          },
        );
      },
    );
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (file == null) return;

    setState(() {
      pickedImage = File(file.path);
    });
  }

  Future<void> saveProfile() async {
    if (saving) return;
    if (user == null) return;

    setState(() {
      saving = true;
    });

    try {
      String? photoUrl = user!.photoURL;

      // upload avatar
      if (pickedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("avatars")
            .child("${user!.uid}.jpg");

        await ref.putFile(pickedImage!);

        photoUrl = await ref.getDownloadURL();
      }

      final dob =
          "${yearController.text}-${monthController.text}-${dayController.text}";

      // update auth
      final cleanName = nameController.text.trim();

      if (cleanName.isNotEmpty) {
        await user!.updateDisplayName(cleanName);
      }

      if (photoUrl != null) {
        await user!.updatePhotoURL(photoUrl);
      }

      // update realtime db
      await FirebaseDatabase.instance
          .ref("accounts/${user!.uid}/profile")
          .update({
        "name": nameController.text.trim(),
        "gender": gender,
        "dob": dob,
        "phone": phoneController.text.trim(),
        "photoUrl": photoUrl ?? "",
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã lưu thông tin"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi lưu profile: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() {
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = pickedImage != null
        ? null
        : user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin cá nhân"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,

                  backgroundImage: pickedImage != null
                      ? FileImage(pickedImage!)
                      : (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,

                  child: avatarUrl == null && pickedImage == null
                      ? const Icon(
                    Icons.person,
                    size: 42,
                    color: Colors.grey,
                  )
                      : null,
                ),

                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: pickAvatar,

                    child: Container(
                      width: 32,
                      height: 32,

                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),

                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            TextField(
              controller: nameController,

              decoration: const InputDecoration(
                labelText: "Tên",
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Giới tính",

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            RadioGroup<String>(
              groupValue: gender,

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  gender = value;
                });
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

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Số điện thoại",
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ngày sinh",

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: ElevatedButton(
                onPressed: saving ? null : saveProfile,

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
                  "Lưu thay đổi",
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