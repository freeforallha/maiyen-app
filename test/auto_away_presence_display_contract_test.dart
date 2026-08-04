import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/helpers/home_helper.dart';

Map<String, dynamic> buildHome({
  required Map<String, dynamic> participantUids,
  required Map<String, dynamic> memberPresenceStatus,
  Map<String, dynamic> presenceSummary = const <String, dynamic>{},
}) {
  return <String, dynamic>{
    "securityMode": "normal",
    "devices": <String, dynamic>{
      "repeater-1": <String, dynamic>{
        "name": "Repeater",
        "type": "repeater",
        "last_seen": DateTime.now().toIso8601String(),
      },
    },
    "autoAway": <String, dynamic>{
      "enabled": true,
      "latitude": 20.0,
      "longitude": 106.0,
      "participantUids": participantUids,
    },
    "presenceSummary": presenceSummary,
    "memberPresenceStatus": memberPresenceStatus,
  };
}

void main() {
  group("Auto Away presence display", () {
    test("counts only selected members in StatusPanel and home summary", () {
      final home = buildHome(
        participantUids: <String, dynamic>{"member-1": true, "member-2": true},
        presenceSummary: <String, dynamic>{
          "insideCount": 2,
          "outsideCount": 1,
          "unknownCount": 1,
          "totalMemberCount": 4,
          "participantCount": 2,
        },
        memberPresenceStatus: <String, dynamic>{
          "member-1": <String, dynamic>{
            "state": "inside",
            "autoAwayParticipant": true,
          },
          "member-2": <String, dynamic>{
            "state": "inside",
            "autoAwayParticipant": true,
          },
          "member-3": <String, dynamic>{
            "state": "outside",
            "autoAwayParticipant": false,
          },
          "member-4": <String, dynamic>{
            "state": "unknown",
            "autoAwayParticipant": false,
          },
        },
      );

      final counts = resolveAutoAwayPresenceDisplayCounts(home);

      expect(counts["insideCount"], 2);
      expect(counts["outsideCount"], 0);
      expect(counts["unknownCount"], 0);
      expect(counts["participantCount"], 2);
      expect(counts["totalMemberCount"], 4);

      final overall = getHomeOverallStatus(home);
      final lines = List<String>.from(
        overall["presencePanelLines"] ?? const <String>[],
      );

      expect(lines, contains("Thành viên đang ở trong nhà: 2/2"));
      expect(
        lines,
        contains("Số thành viên dùng để xác định mở Tự động bảo vệ: 2/4"),
      );
      expect(
        lines.any((line) => line.startsWith("Thành viên đang ở ngoài:")),
        isFalse,
      );
      expect(
        lines.any(
          (line) => line.startsWith("Thành viên chưa xác định vị trí:"),
        ),
        isFalse,
      );
    });

    test("ignores unselected outside and unknown members", () {
      final home = buildHome(
        participantUids: <String, dynamic>{"member-1": true, "member-2": true},
        presenceSummary: <String, dynamic>{
          "insideCount": 2,
          "outsideCount": 1,
          "unknownCount": 1,
          "totalMemberCount": 4,
          "participantCount": 2,
        },
        memberPresenceStatus: <String, dynamic>{
          "member-1": <String, dynamic>{
            "state": "inside",
            "autoAwayParticipant": true,
          },
          "member-2": <String, dynamic>{
            "state": "unknown",
            "autoAwayParticipant": true,
          },
          "member-3": <String, dynamic>{
            "state": "outside",
            "autoAwayParticipant": false,
          },
          "member-4": <String, dynamic>{
            "state": "inside",
            "autoAwayParticipant": false,
          },
        },
      );

      final overall = getHomeOverallStatus(home);
      final lines = List<String>.from(
        overall["presencePanelLines"] ?? const <String>[],
      );
      final warnings = List<String>.from(
        overall["presenceWarnings"] ?? const <String>[],
      );

      expect(lines, contains("Thành viên đang ở trong nhà: 1/2"));
      expect(lines, contains("Thành viên chưa xác định vị trí: 1/2"));
      expect(warnings, contains("Thành viên chưa xác định vị trí: 1/2"));
      expect(
        lines.any((line) => line.startsWith("Thành viên đang ở ngoài:")),
        isFalse,
      );
    });

    test(
      "legacy homes without participant selection still use all members",
      () {
        final home = buildHome(
          participantUids: const <String, dynamic>{},
          presenceSummary: <String, dynamic>{
            "insideCount": 2,
            "outsideCount": 1,
            "unknownCount": 1,
            "totalMemberCount": 4,
          },
          memberPresenceStatus: <String, dynamic>{
            "member-1": <String, dynamic>{"state": "inside"},
            "member-2": <String, dynamic>{"state": "inside"},
            "member-3": <String, dynamic>{"state": "outside"},
            "member-4": <String, dynamic>{"state": "unknown"},
          },
        );

        final counts = resolveAutoAwayPresenceDisplayCounts(home);

        expect(counts["insideCount"], 2);
        expect(counts["outsideCount"], 1);
        expect(counts["unknownCount"], 1);
        expect(counts["participantCount"], 4);
        expect(counts["totalMemberCount"], 4);
      },
    );

    test("missing selected presence is shown as unknown, not borrowed", () {
      final home = buildHome(
        participantUids: <String, dynamic>{"member-1": true, "member-2": true},
        presenceSummary: <String, dynamic>{
          "insideCount": 2,
          "outsideCount": 1,
          "unknownCount": 1,
          "totalMemberCount": 4,
          "participantCount": 2,
        },
        memberPresenceStatus: <String, dynamic>{
          "member-1": <String, dynamic>{
            "state": "inside",
            "autoAwayParticipant": true,
          },
          "member-3": <String, dynamic>{
            "state": "inside",
            "autoAwayParticipant": false,
          },
          "member-4": <String, dynamic>{
            "state": "outside",
            "autoAwayParticipant": false,
          },
        },
      );

      final counts = resolveAutoAwayPresenceDisplayCounts(home);

      expect(counts["insideCount"], 1);
      expect(counts["outsideCount"], 0);
      expect(counts["unknownCount"], 1);
      expect(counts["participantCount"], 2);
    });
  });
}
