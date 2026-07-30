part of '../all_home_page.dart';

extension _AllHomeGroupingPart on _AllHomeState {
  Map<String, List<String>> groupedHomes() {
    final Map<String, List<String>> grouped = {};
    final seen = <String>{};
    for (final homeId in widget.homeOrder) {
      if (seen.contains(homeId)) continue;
      seen.add(homeId);
      if (!homes.containsKey(homeId)) continue;
      final data = safeMap(homes[homeId]);
      final name = (data["name"] ?? homeId).toString().toLowerCase();

      if (search.isNotEmpty && !name.contains(search)) {
        continue;
      }

      final isShared = data["_shared"] == true;

      final groupKey = isShared
          ? (data["_ownerUid"] ?? "unknown_uid")
          : "your_homes";

      grouped.putIfAbsent(groupKey, () => []).add(homeId);
    }

    return grouped;
  }

  Future<void> renameGroup(String key) async {
    final oldName = customNames[key] ?? "";
    String inputName = oldName.trim();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_strings.t("Đổi tên nhóm")),
        content: TextFormField(
          initialValue: oldName,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: _strings.t("VD: Mr Chung")),
          onChanged: (value) {
            inputName = value.trim();
          },
          onFieldSubmitted: (_) {
            Navigator.pop(dialogContext, inputName);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, inputName);
            },
            child: Text(_strings.t("Lưu")),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      for (final id in selectedHomes) {
        homes.remove(id);
      }

      selectedHomes.clear();
    });

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;
    final newName = result.trim();

    final ref = FirebaseDatabase.instance.ref("accounts/$uid/groupNames/$key");

    if (newName.isEmpty) {
      await ref.remove();
    } else {
      await ref.set(newName);
    }
  }
}
