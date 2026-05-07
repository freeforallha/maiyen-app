import 'package:flutter/material.dart';

class AllHomePage extends StatelessWidget {
  final Map<String, dynamic> homes;

  AllHomePage({required this.homes});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Homes")),
      body: Padding(
        padding: EdgeInsets.all(6),
        child: GridView.builder(
          itemCount: homes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final e = homes.entries.elementAt(index);
            final homeId = e.key;
            final data = safeMap(e.value);
            final devices = safeMap(data["devices"]);
            final unsafe = isUnsafe(devices);

            return InkWell(
              onTap: () {
                Navigator.pop(context, homeId);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: unsafe ? Colors.red.shade300 : Colors.green.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data["name"] ?? homeId,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
