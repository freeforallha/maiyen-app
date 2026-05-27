class FirebasePaths {
  // ================= ACCOUNTS =================

  static String account(String uid) =>
      "accounts/$uid";

  static String profile(String uid) =>
      "accounts/$uid/profile";

  static String homes(String uid) =>
      "accounts/$uid/homes";

  static String home(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/homes/$homeId";

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

  // ================= SHARED =================

  static String sharedHomes(String uid) =>
      "accounts/$uid/sharedHomes";

  static String sharedHome(
      String uid,
      String homeId,
      ) =>
      "accounts/$uid/sharedHomes/$homeId";

  static String sharedByHome(String homeId) =>
      "sharedByHome/$homeId";

  // ================= CHAT =================

  static String homeChat(String homeId) =>
      "homeChats/$homeId";

  static String homeMessages(String homeId) =>
      "homeChats/$homeId/messages";

  static String homeLastRead(
      String homeId,
      String uid,
      ) =>
      "homeChats/$homeId/lastRead/$uid";
}