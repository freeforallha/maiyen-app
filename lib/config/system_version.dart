enum ProtocolCompatibility { unknown, compatible, incompatible }

class SystemVersionConfig {
  SystemVersionConfig._();

  /// Must stay synchronized with `version:` in pubspec.yaml.
  static const String appVersionName = '1.1.0';
  static const int appBuildNumber = 2;

  /// Current App ↔ Hub protocol implemented by this application.
  static const String protocolVersion = '1.0.0';
  static const int supportedProtocolMajor = 1;

  static const String appVersionDisplay = '$appVersionName+$appBuildNumber';

  static int? versionMajor(String? rawVersion) {
    final clean = rawVersion?.trim() ?? '';

    if (clean.isEmpty) {
      return null;
    }

    final normalized = clean.startsWith('v') || clean.startsWith('V')
        ? clean.substring(1)
        : clean;
    final match = RegExp(r'^(\d+)(?:\.|$)').firstMatch(normalized);

    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  static ProtocolCompatibility protocolCompatibility(
    String? hubProtocolVersion,
  ) {
    final hubMajor = versionMajor(hubProtocolVersion);

    if (hubMajor == null) {
      return ProtocolCompatibility.unknown;
    }

    return hubMajor == supportedProtocolMajor
        ? ProtocolCompatibility.compatible
        : ProtocolCompatibility.incompatible;
  }
}

class HubSystemVersionInfo {
  const HubSystemVersionInfo({
    required this.backendVersion,
    required this.hubFirmwareVersion,
    required this.protocolVersion,
    required this.versionSchemaVersion,
  });

  final String backendVersion;
  final String hubFirmwareVersion;
  final String protocolVersion;
  final int? versionSchemaVersion;

  factory HubSystemVersionInfo.fromHubStatus(Map<String, dynamic> hubStatus) {
    String readText(String key) => hubStatus[key]?.toString().trim() ?? '';

    final rawSchemaVersion = hubStatus['versionSchemaVersion'];

    return HubSystemVersionInfo(
      backendVersion: readText('backendVersion'),
      hubFirmwareVersion: readText('hubFirmwareVersion'),
      protocolVersion: readText('protocolVersion'),
      versionSchemaVersion: rawSchemaVersion is num
          ? rawSchemaVersion.toInt()
          : int.tryParse(rawSchemaVersion?.toString() ?? ''),
    );
  }

  ProtocolCompatibility get compatibility =>
      SystemVersionConfig.protocolCompatibility(protocolVersion);
}
