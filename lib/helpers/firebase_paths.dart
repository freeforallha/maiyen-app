class FirebasePaths {
  // ================= ACCOUNTS =================

  static String account(String uid) =>
      "accounts/$uid";

  static String accountEmail(String uid) =>
      "accounts/$uid/email";

  static String profile(String uid) =>
      "accounts/$uid/profile";

  static String fcmToken(String uid) =>
      "accounts/$uid/fcmToken";

  // ================= HOMES =================

  static String homes(String uid) =>
      "accounts/$uid/homes";

  static String home(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/homes/$homeId";
  static String schedules(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/homes/$homeId/schedules";

  static String devices(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/homes/$homeId/devices";

  static String device(
      String uid,
      String homeId,
      String deviceId,
      ) =>
      "accounts/$uid/homes/$homeId/devices/$deviceId";

  static String homeOrder(String uid) =>
      "accounts/$uid/homeOrder";

  // ================= SHARED =================

  static String sharedHomes(String uid) =>
      "accounts/$uid/sharedHomes";

  static String sharedHome(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/sharedHomes/$homeId";

  static String shareRequests(String uid) =>
      "accounts/$uid/shareRequests";

  static String shareRequest(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/shareRequests/$homeId";

  static String shareList(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/shareList/$homeId";

  static String sharedByHome(String homeId) =>
      "sharedByHome/$homeId";

  static String sharedMember(
      String homeId,
      String uid,
      ) =>
      "sharedByHome/$homeId/$uid";

  // ================= CHAT =================

  static String homeChats() =>
      "homeChats";

  static String homeChat(String homeId) =>
      "homeChats/$homeId";

  static String homeMessages(String homeId) =>
      "homeChats/$homeId/messages";

  static String homeLastRead(
      String homeId,
      String uid,
      ) =>
      "homeChats/$homeId/lastRead/$uid";

  // ================= PAIR =================

  static String pairRequests() =>
      "pair_requests";

  static String pairRequest(String requestId) =>
      "pair_requests/$requestId";

}
