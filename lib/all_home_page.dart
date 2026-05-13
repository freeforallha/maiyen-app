import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AllHomePage extends StatefulWidget {
  final List<String> homeOrder;

  const AllHomePage({super.key, required this.homeOrder});

  @override
  State<AllHomePage> createState() => _AllHomePageState();
}

class _AllHomePageState extends State<AllHomePage> {
  Map<String, dynamic> homes = {};

  Set<String> selectedHomes = {};

  Map<String, String> customNames = {};

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};

    return Map<String, dynamic>.from(data as Map);
  }

  bool isUnsafe(Map dev) {
    return dev.values.any((d) {
      final status = d["status"]?.toString();

      final tamper = d["tamper"] == true;

      return status != "closed" || tamper;
    });
  }

  late DatabaseReference ref;

  @override
  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseDatabase.instance.ref("accounts/$uid").onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = Map<String, dynamic>.from(data as Map);
      customNames = Map<String, String>.from(map["groupNames"] ?? {});

      final ownHomes = Map<String, dynamic>.from(map["homes"] ?? {});
      final sharedHomes = Map<String, dynamic>.from(map["sharedHomes"] ?? {});

      final Map<String, dynamic> merged = {...ownHomes};

      setState(() {
        homes = merged;
      });

      // 🔥 shared homes listener FIX (KHÔNG tạo lại liên tục)
      sharedHomes.forEach((homeId, value) {
        final v = Map<String, dynamic>.from(value);
        final ownerUid = v["ownerUid"];

        if (ownerUid == null) return;

        FirebaseDatabase.instance.ref("accounts/$ownerUid/email").get().then((
          emailSnap,
        ) {
          final ownerEmail = emailSnap.value?.toString() ?? "Unknown";

          FirebaseDatabase.instance
              .ref("accounts/$ownerUid/homes/$homeId")
              .onValue
              .listen((e) {
                final d = e.snapshot.value;

                if (d == null) return;

                setState(() {
                  homes[homeId] = {
                    ...Map<String, dynamic>.from(d as Map),
                    "_shared": true,
                    "_ownerEmail": ownerEmail,
                  };
                });
              });
        });
      });
    });
  }

  Map<String, List<String>> groupedHomes() {
    final Map<String, List<String>> grouped = {};

    for (final homeId in widget.homeOrder) {
      final data = safeMap(homes[homeId]);

      final isShared = data["_shared"] == true;

      final groupKey = isShared
          ? (data["_ownerUid"] ?? "unknown_uid")
          : "your_homes";

      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(homeId);
    }

    return grouped;
  }

  Future<void> renameGroup(String key) async {
    final controller = TextEditingController(text: customNames[key] ?? "");

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Rename Group"),

        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "VD: Mr Chung"),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),

            child: Text("OK"),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() {
      customNames[key] = result;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseDatabase.instance
        .ref("accounts/$uid/groupNames/$key")
        .set(result);
  }

  Widget buildSectionTitle(String groupKey, List<String> ids) {
    final isYourHomes = groupKey == "your_homes";

    String ownerText = "";
    if (!isYourHomes) {
      final firstHome = safeMap(homes[ids.first]);

      ownerText = firstHome["_ownerEmail"] ?? "Unknown";
    }

    String subtitle = "";

    if (!isYourHomes) {
      final firstHome = safeMap(homes[ids.first]);

      subtitle = firstHome["_ownerEmail"] ?? "Unknown";
    }

    final displayName =
        customNames[groupKey] ?? (isYourHomes ? "Your Homes" : ownerText);

    return Container(
      margin: EdgeInsets.only(top: 6, bottom: 8),

      padding: EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,

                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  Icons.other_houses_rounded,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      displayName,

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (!isYourHomes)
                      Text(
                        ownerText,

                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  renameGroup(groupKey);
                },

                icon: Icon(Icons.edit_rounded, color: Colors.blueAccent),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    final allSelected = ids.every(
                      (id) => selectedHomes.contains(id),
                    );

                    if (allSelected) {
                      selectedHomes.removeAll(ids);
                    } else {
                      selectedHomes.addAll(ids);
                    }
                  });
                },

                icon: Icon(Icons.done_all_rounded, color: Colors.green),
              ),
            ],
          ),

          SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,

            physics: NeverScrollableScrollPhysics(),

            itemCount: ids.length,

            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1,
            ),

            itemBuilder: (context, index) {
              final homeId = ids[index];

              final data = safeMap(homes[homeId]);

              return buildHomeCard(context, homeId, data);
            },
          ),
        ],
      ),
    );
  }

  Widget buildHomeCard(
    BuildContext context,
    String homeId,
    Map<String, dynamic> data,
  ) {
    final devices = safeMap(data["devices"]);

    final unsafe = isUnsafe(devices);

    final selected = selectedHomes.contains(homeId);

    return InkWell(
      onTap: () {
        if (selectedHomes.isNotEmpty) {
          setState(() {
            if (selected) {
              selectedHomes.remove(homeId);
            } else {
              selectedHomes.add(homeId);
            }
          });

          return;
        }

        Navigator.pop(context, homeId);
      },

      onLongPress: () {
        setState(() {
          selectedHomes.add(homeId);
        });
      },

      borderRadius: BorderRadius.circular(14),

      child: Container(
        decoration: BoxDecoration(
          color: unsafe ? Colors.red.shade300 : Colors.green.shade300,

          borderRadius: BorderRadius.circular(14),

          border: selected
              ? Border.all(color: Colors.blueAccent, width: 4)
              : null,
        ),

        child: Padding(
          padding: EdgeInsets.all(6),

          child: SizedBox.expand(
            child: Center(
              child: Text(
                (data["name"] ?? homeId).toString(),

                textAlign: TextAlign.center,

                softWrap: true,

                maxLines: 4,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> confirmDeleteSelected() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete selected homes?"),

        content: Text("Bạn sắp thao tác với nhiều home."),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),

            child: Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),

            child: Text("Continue"),
          ),
        ],
      ),
    );

    if (first != true) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xác nhận lần cuối"),

        content: Text("Hành động này không thể hoàn tác."),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),

            child: Text("No"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

            onPressed: () => Navigator.pop(context, true),

            child: Text("DELETE"),
          ),
        ],
      ),
    );

    if (second != true) return;

    setState(() {
      selectedHomes.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Delete logic chưa được thêm")));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedHomes();

    return Scaffold(
      appBar: AppBar(
        title: Text("All Homes"),

        actions: [
          if (selectedHomes.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close),

              onPressed: () {
                setState(() {
                  selectedHomes.clear();
                });
              },
            ),
        ],
      ),

      bottomNavigationBar: selectedHomes.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),

                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,

                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),

                  icon: Icon(Icons.delete),

                  label: Text("Delete ${selectedHomes.length} Selected Homes"),

                  onPressed: confirmDeleteSelected,
                ),
              ),
            ),

      body: ListView(
        padding: EdgeInsets.all(10),

        children: grouped.entries.map((entry) {
          final groupKey = entry.key;

          final ids = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [buildSectionTitle(groupKey, ids), SizedBox(height: 6)],
          );
        }).toList(),
      ),
    );
  }
}
