import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/brand_config.dart';
import '../../localization/app_strings.dart';
import '../../navigation/safehome_navigation.dart';
import '../../safehome_theme.dart';
import 'home_auto_away_models.dart';

Future<HomeAutoAwayLocation?> showHomeAutoAwayMapPicker({
  required BuildContext context,
  required AppStrings strings,
  required double? initialLatitude,
  required double? initialLongitude,
  required int radiusMeters,
  required Future<HomeAutoAwayLocation?> Function() onGetCurrentLocation,
}) {
  return SafeHomeNavigation.pushChildPage<HomeAutoAwayLocation>(
    context: context,
    routeName: 'home_auto_away_map',
    builder: (_) => HomeAutoAwayMapPage(
      strings: strings,
      initialLatitude: initialLatitude,
      initialLongitude: initialLongitude,
      radiusMeters: radiusMeters,
      onGetCurrentLocation: onGetCurrentLocation,
    ),
  );
}

class HomeAutoAwayMapPage extends StatefulWidget {
  const HomeAutoAwayMapPage({
    super.key,
    required this.strings,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.radiusMeters,
    required this.onGetCurrentLocation,
  });

  final AppStrings strings;
  final double? initialLatitude;
  final double? initialLongitude;
  final int radiusMeters;
  final Future<HomeAutoAwayLocation?> Function() onGetCurrentLocation;

  @override
  State<HomeAutoAwayMapPage> createState() => _HomeAutoAwayMapPageState();
}

class _HomeAutoAwayMapPageState extends State<HomeAutoAwayMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late LatLng _selectedPoint;
  late double _initialZoom;
  bool _locating = false;
  bool _searching = false;
  int _searchRequestSerial = 0;
  String? _searchMessage;
  List<_AutoAwayMapSearchResult> _searchResults = const [];

  @override
  void initState() {
    super.initState();

    final latitude = widget.initialLatitude;
    final longitude = widget.initialLongitude;
    final hasInitialPoint = latitude != null && longitude != null;

    _selectedPoint = hasInitialPoint
        ? LatLng(latitude, longitude)
        : const LatLng(16.047079, 108.206230);
    _initialZoom = hasInitialPoint ? 17 : 5.2;
    _searchController.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _searchRequestSerial++;
    _searchController
      ..removeListener(_handleSearchTextChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchTextChanged() {
    if (!mounted) {
      return;
    }

    if (_searchController.text.trim().isEmpty &&
        (_searchResults.isNotEmpty || _searchMessage != null)) {
      setState(() {
        _searchResults = const [];
        _searchMessage = null;
      });
      return;
    }

    setState(() {});
  }

  Future<void> _moveToCurrentLocation() async {
    if (_locating) {
      return;
    }

    setState(() {
      _locating = true;
    });

    try {
      final location = await widget.onGetCurrentLocation();

      if (!mounted || location == null) {
        return;
      }

      final nextPoint = LatLng(location.latitude, location.longitude);

      _searchRequestSerial++;
      _searchFocusNode.unfocus();

      setState(() {
        _selectedPoint = nextPoint;
        _searchResults = const [];
        _searchMessage = null;
        _searching = false;
      });

      _mapController.move(nextPoint, 17);
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  Future<dynamic> _readSearchJson({
    required HttpClient client,
    required Uri uri,
    required String languageCode,
  }) async {
    final request = await client.getUrl(uri).timeout(
      const Duration(seconds: 12),
    );
    request.headers.set(
      HttpHeaders.userAgentHeader,
      BrandConfig.mapUserAgent,
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptLanguageHeader, languageCode);

    final response = await request.close().timeout(
      const Duration(seconds: 12),
    );

    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'Location search failed: ${response.statusCode}',
        uri: uri,
      );
    }

    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 12));

    return jsonDecode(body);
  }

  Future<List<_AutoAwayMapSearchResult>> _searchNominatim({
    required HttpClient client,
    required String query,
    required String languageCode,
  }) async {
    const viewboxOffset = 3.0;
    final left = (_selectedPoint.longitude - viewboxOffset).clamp(-180, 180);
    final right = (_selectedPoint.longitude + viewboxOffset).clamp(-180, 180);
    final top = (_selectedPoint.latitude + viewboxOffset).clamp(-90, 90);
    final bottom = (_selectedPoint.latitude - viewboxOffset).clamp(-90, 90);
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      <String, String>{
        'format': 'jsonv2',
        'limit': '10',
        'q': query,
        'accept-language': languageCode,
        'addressdetails': '1',
        'namedetails': '1',
        'dedupe': '1',
        // bounded=0 chỉ ưu tiên vùng đang xem, không loại kết quả ở nơi khác.
        'viewbox': '$left,$top,$right,$bottom',
        'bounded': '0',
      },
    );
    final decoded = await _readSearchJson(
      client: client,
      uri: uri,
      languageCode: languageCode,
    );
    final results = <_AutoAwayMapSearchResult>[];

    if (decoded is! List) {
      return results;
    }

    for (final rawResult in decoded) {
      if (rawResult is! Map) {
        continue;
      }

      final latitude = double.tryParse(rawResult['lat']?.toString() ?? '');
      final longitude = double.tryParse(rawResult['lon']?.toString() ?? '');
      final displayName = rawResult['display_name']?.toString().trim() ?? '';

      if (latitude == null || longitude == null || displayName.isEmpty) {
        continue;
      }

      results.add(
        _AutoAwayMapSearchResult(
          displayName: displayName,
          point: LatLng(latitude, longitude),
        ),
      );
    }

    return results;
  }

  String _buildPhotonDisplayName(Map<dynamic, dynamic> properties) {
    String read(String key) => properties[key]?.toString().trim() ?? '';

    final name = read('name');
    final houseNumber = read('housenumber');
    final street = read('street');
    final streetLine = [
      houseNumber,
      street,
    ].where((part) => part.isNotEmpty).join(' ');
    final parts = <String>[
      name,
      if (streetLine.isNotEmpty &&
          streetLine.toLowerCase() != name.toLowerCase())
        streetLine,
      read('district'),
      read('city'),
      read('county'),
      read('state'),
      read('postcode'),
      read('country'),
    ];
    final normalizedParts = <String>[];
    final seen = <String>{};

    for (final rawPart in parts) {
      final part = rawPart.trim();
      final key = part.toLowerCase();

      if (part.isEmpty || !seen.add(key)) {
        continue;
      }

      normalizedParts.add(part);
    }

    return normalizedParts.join(', ');
  }

  Future<List<_AutoAwayMapSearchResult>> _searchPhoton({
    required HttpClient client,
    required String query,
    required String languageCode,
  }) async {
    final uri = Uri.https(
      'photon.komoot.io',
      '/api',
      <String, String>{
        'q': query,
        'limit': '10',
        'lang': languageCode,
        'lat': _selectedPoint.latitude.toString(),
        'lon': _selectedPoint.longitude.toString(),
        'zoom': '12',
        'location_bias_scale': '0.25',
        'dedupe': '1',
      },
    );
    final decoded = await _readSearchJson(
      client: client,
      uri: uri,
      languageCode: languageCode,
    );
    final results = <_AutoAwayMapSearchResult>[];

    if (decoded is! Map || decoded['features'] is! List) {
      return results;
    }

    for (final rawFeature in decoded['features'] as List) {
      if (rawFeature is! Map) {
        continue;
      }

      final geometry = rawFeature['geometry'];
      final properties = rawFeature['properties'];

      if (geometry is! Map || properties is! Map) {
        continue;
      }

      final coordinates = geometry['coordinates'];

      if (coordinates is! List || coordinates.length < 2) {
        continue;
      }

      final longitude = coordinates[0] is num
          ? (coordinates[0] as num).toDouble()
          : double.tryParse(coordinates[0]?.toString() ?? '');
      final latitude = coordinates[1] is num
          ? (coordinates[1] as num).toDouble()
          : double.tryParse(coordinates[1]?.toString() ?? '');
      final displayName = _buildPhotonDisplayName(properties);

      if (latitude == null || longitude == null || displayName.isEmpty) {
        continue;
      }

      results.add(
        _AutoAwayMapSearchResult(
          displayName: displayName,
          point: LatLng(latitude, longitude),
        ),
      );
    }

    return results;
  }

  List<_AutoAwayMapSearchResult> _mergeSearchResults(
    List<_AutoAwayMapSearchResult> nominatimResults,
    List<_AutoAwayMapSearchResult> photonResults,
  ) {
    final merged = <_AutoAwayMapSearchResult>[];
    final seenPoints = <String>{};
    final maxLength = nominatimResults.length > photonResults.length
        ? nominatimResults.length
        : photonResults.length;

    void addResult(_AutoAwayMapSearchResult result) {
      final pointKey =
          '${result.point.latitude.toStringAsFixed(5)}:'
          '${result.point.longitude.toStringAsFixed(5)}';

      if (seenPoints.add(pointKey)) {
        merged.add(result);
      }
    }

    // Xen kẽ hai nguồn để vừa giữ độ chính xác địa chỉ của Nominatim,
    // vừa có thêm địa danh/POI và khả năng chịu lỗi chính tả từ Photon.
    for (var index = 0; index < maxLength && merged.length < 12; index++) {
      if (index < nominatimResults.length) {
        addResult(nominatimResults[index]);
      }
      if (index < photonResults.length && merged.length < 12) {
        addResult(photonResults[index]);
      }
    }

    return merged;
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();

    if (query.length < 2) {
      return;
    }

    FocusScope.of(context).unfocus();

    final requestSerial = ++_searchRequestSerial;
    setState(() {
      _searching = true;
      _searchMessage = null;
      _searchResults = const [];
    });

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      Object? nominatimError;
      Object? photonError;

      Future<List<_AutoAwayMapSearchResult>> guardedSearch(
        Future<List<_AutoAwayMapSearchResult>> search,
        void Function(Object error) onError,
      ) async {
        try {
          return await search;
        } catch (error) {
          onError(error);
          return const <_AutoAwayMapSearchResult>[];
        }
      }

      final providerResults = await Future.wait([
        guardedSearch(
          _searchNominatim(
            client: client,
            query: query,
            languageCode: languageCode,
          ),
          (error) => nominatimError = error,
        ),
        guardedSearch(
          _searchPhoton(
            client: client,
            query: query,
            languageCode: languageCode,
          ),
          (error) => photonError = error,
        ),
      ]);
      final results = _mergeSearchResults(
        providerResults[0],
        providerResults[1],
      );

      if (!mounted || requestSerial != _searchRequestSerial) {
        return;
      }

      setState(() {
        _searchResults = results;
        _searchMessage = results.isNotEmpty
            ? null
            : nominatimError != null && photonError != null
            ? widget.strings.autoAwaySearchFailed
            : widget.strings.autoAwayNoSearchResults;
      });
    } catch (_) {
      if (!mounted || requestSerial != _searchRequestSerial) {
        return;
      }

      setState(() {
        _searchResults = const [];
        _searchMessage = widget.strings.autoAwaySearchFailed;
      });
    } finally {
      client.close(force: true);

      if (mounted && requestSerial == _searchRequestSerial) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  void _selectSearchResult(_AutoAwayMapSearchResult result) {
    _searchRequestSerial++;
    _searchController.text = result.displayName;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _searchFocusNode.unfocus();

    setState(() {
      _selectedPoint = result.point;
      _searchResults = const [];
      _searchMessage = null;
      _searching = false;
    });

    _mapController.move(result.point, 17);
  }

  void _clearSearch() {
    _searchRequestSerial++;
    _searchController.clear();
    _searchFocusNode.requestFocus();

    setState(() {
      _searchResults = const [];
      _searchMessage = null;
      _searching = false;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      HomeAutoAwayLocation(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: SafeHomeColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: SafeHomeColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.strings.autoAwayMapTitle,
                      style: const TextStyle(
                        color: SafeHomeColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.strings.autoAwayMapHint,
                      style: const TextStyle(
                        color: SafeHomeColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPoint,
                  initialZoom: _initialZoom,
                  minZoom: 2,
                  maxZoom: 19,
                  onTap: (_, point) {
                    _searchRequestSerial++;
                    _searchFocusNode.unfocus();
                    setState(() {
                      _selectedPoint = point;
                      _searchResults = const [];
                      _searchMessage = null;
                      _searching = false;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.myfamily.safehome',
                    maxNativeZoom: 19,
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _selectedPoint,
                        radius: widget.radiusMeters.toDouble(),
                        useRadiusInMeter: true,
                        color: SafeHomeColors.primary.withValues(alpha: 0.14),
                        borderColor: SafeHomeColors.primary,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPoint,
                        width: 54,
                        height: 54,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 48,
                          color: SafeHomeColors.danger,
                          shadows: [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: SafeHomeColors.surface,
                      elevation: 3,
                      shadowColor: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchLocation(),
                        decoration: InputDecoration(
                          hintText: widget.strings.autoAwaySearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        onPressed: _clearSearch,
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    IconButton(
                                      onPressed: _searchLocation,
                                      icon: const Icon(Icons.search_rounded),
                                    ),
                                  ],
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    if (_searchResults.isNotEmpty || _searchMessage != null)
                      const SizedBox(height: 8),
                    if (_searchResults.isNotEmpty)
                      Material(
                        color: SafeHomeColors.surface,
                        elevation: 3,
                        shadowColor: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              indent: 48,
                              color: SafeHomeColors.border,
                            ),
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];

                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: SafeHomeColors.primary,
                                ),
                                title: Text(
                                  result.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SafeHomeColors.textPrimary,
                                    fontSize: 12.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onTap: () => _selectSearchResult(result),
                              );
                            },
                          ),
                        ),
                      ),
                    if (_searchMessage != null)
                      Material(
                        color: SafeHomeColors.surface,
                        elevation: 3,
                        shadowColor: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_off_outlined,
                                color: SafeHomeColors.warning,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _searchMessage!,
                                  style: const TextStyle(
                                    color: SafeHomeColors.textSecondary,
                                    fontSize: 12.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                top: 82,
                child: Material(
                  color: SafeHomeColors.surface,
                  elevation: 3,
                  shadowColor: const Color(0x22000000),
                  borderRadius: BorderRadius.circular(16),
                  child: IconButton(
                    tooltip: widget.strings.t('Đặt vị trí nhà tại đây'),
                    onPressed: _locating ? null : _moveToCurrentLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: SafeHomeColors.primary,
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 106,
                child: Material(
                  color: SafeHomeColors.surface.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      child: Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(
                          color: SafeHomeColors.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SafeHomeColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selectedPoint.latitude.toStringAsFixed(6)}, '
                        '${_selectedPoint.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: SafeHomeColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(widget.strings.autoAwayConfirmMapLocation),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AutoAwayMapSearchResult {
  const _AutoAwayMapSearchResult({
    required this.displayName,
    required this.point,
  });

  final String displayName;
  final LatLng point;
}
