import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';

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
    phoneController = TextEditingController(text: widget.userPhone);
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

      return pad > 0 ? value.toString().padLeft(pad, '0') : value.toString();
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
    final currentUser = user;
    if (currentUser == null) return;

    setState(() {
      saving = true;
    });

    try {
      String? photoUrl = currentUser.photoURL;

      // upload avatar
      final imageFile = pickedImage;

      if (imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("avatars")
            .child("${currentUser.uid}.jpg");

        await ref.putFile(imageFile);

        photoUrl = await ref.getDownloadURL();
      }

      final dob =
          "${yearController.text}-${monthController.text}-${dayController.text}";

      // update auth
      final cleanName = nameController.text.trim();

      if (cleanName.isNotEmpty) {
        await currentUser.updateDisplayName(cleanName);
      }

      if (photoUrl != null) {
        await currentUser.updatePhotoURL(photoUrl);
      }

      // update realtime db
      await FirebaseDatabase.instance
          .ref("accounts/${currentUser.uid}/profile")
          .update({
            "name": nameController.text.trim(),
            "gender": gender,
            "dob": dob,
            "phone": phoneController.text.trim(),
            "photoUrl": photoUrl ?? "",
          });

      if (!mounted) return;

      final strings = AppStrings.of(context);
      showTopToast(
        context,
        strings.t("Đã lưu thông tin"),
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final strings = AppStrings.of(context);
      showTopToast(
        context,
        strings.t("Lỗi lưu profile"),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
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
    final strings = AppStrings.of(context);
    final imageFile = pickedImage;
    final avatarUrl = imageFile != null ? null : user?.photoURL;
    final ImageProvider? avatarImage = imageFile != null
        ? FileImage(imageFile)
        : (avatarUrl != null && avatarUrl.isNotEmpty)
        ? NetworkImage(avatarUrl)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t("Thông tin cá nhân"))),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,

                  backgroundImage: avatarImage,

                  child: avatarImage == null
                      ? const Icon(Icons.person, size: 42, color: Colors.grey)
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
                        border: Border.all(color: Colors.white, width: 2),
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

              decoration: InputDecoration(labelText: strings.t("Tên")),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.t("Giới tính"),

                style: const TextStyle(
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

              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: "Nam",
                      title: Text(strings.t("Nam")),
                    ),
                  ),

                  Expanded(
                    child: RadioListTile<String>(
                      value: "Nữ",
                      title: Text(strings.t("Nữ")),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: strings.t("Số điện thoại"),
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.t("Ngày sinh"),

                style: const TextStyle(
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
                    label: strings.t("Ngày"),
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
                    label: strings.t("Tháng"),
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
                    label: strings.t("Năm"),
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
                    : Text(
                        strings.t("Lưu thay đổi"),
                        style: const TextStyle(
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
