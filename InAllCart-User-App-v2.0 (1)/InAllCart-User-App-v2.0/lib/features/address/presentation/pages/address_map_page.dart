import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/location_service.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';

/// Result returned when user confirms a location on the map.
class AddressMapResult {
  final double lat;
  final double lng;
  final String streetAddress; // street + subLocality
  final String city;
  final String state;
  final String postalCode;
  final String country;

  const AddressMapResult({
    required this.lat,
    required this.lng,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });
}

class AddressMapPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const AddressMapPage({super.key, this.initialLat, this.initialLng});

  @override
  State<AddressMapPage> createState() => _AddressMapPageState();
}

class _AddressMapPageState extends State<AddressMapPage> {
  double _lat = 28.6139;
  double _lng = 77.2090;

  // Parsed placemark fields
  String _streetAddress = '';
  String _city          = '';
  String _state         = '';
  String _postalCode    = '';
  String _country       = 'India';

  bool _isLoading        = true;
  bool _isLoadingAddress = false;
  late MapProvider _mapProvider; // resolved in _init

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Location> _searchResults = [];
  bool _isSearching = false;

  gmaps.GoogleMapController? _googleCtrl;
  final MapController _osmCtrl = MapController();
  bool _osmReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Resolve map provider from bloc
    final configBloc = getIt<AppConfigBloc>();
    
    // Try currentConfig first (most common path — config loads at app start)
    if (configBloc.currentConfig != null) {
      _mapProvider = configBloc.currentConfig!.mapProvider;
    } else if (configBloc.state is AppConfigLoaded) {
      // Fallback: check current bloc state directly
      _mapProvider = (configBloc.state as AppConfigLoaded).config.mapProvider;
    } else {
      // Config not loaded yet — wait for it (up to 5s)
      _mapProvider = MapProvider.osm; // safe default while waiting
      await for (final state in configBloc.stream.timeout(
        const Duration(seconds: 5),
        onTimeout: (sink) => sink.close(),
      )) {
        if (state is AppConfigLoaded) {
          _mapProvider = state.config.mapProvider;
          break;
        }
      }
    }
    if (mounted) setState(() {});

    if (widget.initialLat != null && widget.initialLng != null) {
      _lat = widget.initialLat!;
      _lng = widget.initialLng!;
    } else {
      await _fetchCurrentLocation();
    }
    await _reverseGeocode();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final svc = getIt<LocationService>();
      final result = await svc.getCurrentLocationWithStatus();
      if (result.status == LocationStatus.granted && result.position != null) {
        _lat = result.position!.latitude;
        _lng = result.position!.longitude;
      } else if (mounted) {
        _showPermissionDialog(result.status);
      }
    } catch (e) {
      // Non-critical: location service error. UI shows default state.
    }
  }

  Future<void> _reverseGeocode() async {
    if (mounted) setState(() => _isLoadingAddress = true);
    try {
      final marks = await placemarkFromCoordinates(_lat, _lng);
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        setState(() {
          _streetAddress = [p.street, p.subLocality]
              .where((e) => e != null && e.isNotEmpty)
              .join(', ');
          _city       = p.locality ?? p.subAdministrativeArea ?? '';
          _state      = p.administrativeArea ?? '';
          _postalCode = p.postalCode ?? '';
          _country    = p.country ?? 'India';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _streetAddress = 'Location selected');
    }
    if (mounted) setState(() => _isLoadingAddress = false);
  }

  void _animateTo(double lat, double lng) {
    _googleCtrl?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), 17),
    );
    if (_osmReady) _osmCtrl.move(LatLng(lat, lng), 17);
  }

  Future<void> _onMyLocation() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoadingAddress = true);
    await _fetchCurrentLocation();
    // setState first so map widgets rebuild at new initial position
    if (mounted) setState(() {});
    // Small delay to let map controller settle after rebuild
    await Future.delayed(const Duration(milliseconds: 300));
    _animateTo(_lat, _lng);
    await _reverseGeocode();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final locs = await locationFromAddress(query);
      if (mounted) setState(() { _searchResults = locs; _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() { _searchResults = []; _isSearching = false; });
    }
  }

  Future<void> _selectResult(Location loc) async {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() { _lat = loc.latitude; _lng = loc.longitude; _searchResults = []; });
    await _reverseGeocode();
    _animateTo(_lat, _lng);
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(AddressMapResult(
      lat: _lat, lng: _lng,
      streetAddress: _streetAddress,
      city: _city, state: _state,
      postalCode: _postalCode, country: _country,
    ));
  }

  void _showPermissionDialog(LocationStatus status) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Required'),
        content: const Text('Please enable location to auto-detect your address.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (status == LocationStatus.deniedForever) {
                await openAppSettings();
              } else {
                await Permission.location.request();
                _onMyLocation();
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _googleCtrl?.dispose();
    _osmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ── Map fills screen ──────────────────────────────────
                Positioned.fill(
                  bottom: 160,
                  child: _buildMap(),
                ),

                // ── Center pin — sits at exact visual center of map area ──
                Positioned.fill(
                  bottom: 160,
                  child: IgnorePointer(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Pin tip should be at center of map area.
                        // Column height: tooltip + triangle + gap + pin(44) + shadow(8)
                        // We want the pin tip (bottom of icon) at center → shift up by half pin height
                        const pinHeight = 44.0;
                        const tooltipH = 58.0; // approx bubble + triangle
                        const shadowH  = 8.0;
                        // Center of map = constraints.maxHeight / 2
                        // Pin tip is at: top + tooltipH + 2 + pinHeight
                        // We want pin tip at center → top = center - tooltipH - 2 - pinHeight
                        final top = (constraints.maxHeight / 2) - tooltipH - 2 - pinHeight + (pinHeight / 2);

                        return Stack(
                          children: [
                            Positioned(
                              left: 0, right: 0,
                              top: top,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Tooltip bubble
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Column(
                                      children: [
                                        Text('Order will be delivered here',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                        SizedBox(height: 2),
                                        Text('Place the pin accurately',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  // Triangle pointer
                                  CustomPaint(
                                    size: const Size(14, 7),
                                    painter: _TrianglePainter(
                                        const Color(0xFF1A1A1A)),
                                  ),
                                  const SizedBox(height: 2),
                                  // Pin icon — tip is at bottom of this icon
                                  const Icon(Icons.location_pin,
                                      size: pinHeight,
                                      color: Color(0xFFE91E63)),
                                  // Shadow dot
                                  Container(
                                    width: shadowH,
                                    height: shadowH,
                                    decoration: const BoxDecoration(
                                      color: Colors.black26,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ── App bar ───────────────────────────────────────────
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: Color(0xFF1A1A1A)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Text('Select Your Location',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.4,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Search bar ────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 52,
                  left: 16, right: 16,
                  child: _buildSearchBar(),
                ),

                // ── My location FAB ───────────────────────────────────
                Positioned(
                  right: 16,
                  bottom: 160 + 16,
                  child: GestureDetector(
                    onTap: _onMyLocation,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          size: 20, color: Color(0xFF555555)),
                    ),
                  ),
                ),

                // ── Bottom panel ──────────────────────────────────────
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _buildBottomPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: 'Search for apartment, street name...',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFFAAAAAA)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFAAAAAA)),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchResults = []);
                      })
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (v) {
              setState(() {});
              _search(v);
            },
          ),
        ),
        if (_isSearching || _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 48, color: Color(0xFFF0F0F0)),
                    itemBuilder: (context, i) {
                      final loc = _searchResults[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined,
                            size: 18, color: Color(0xFF888888)),
                        title: FutureBuilder<List<Placemark>>(
                          future: placemarkFromCoordinates(loc.latitude, loc.longitude),
                          builder: (_, snap) {
                            if (snap.hasData && snap.data!.isNotEmpty) {
                              final p = snap.data!.first;
                              return Text(
                                [p.street, p.locality, p.administrativeArea]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(', '),
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            return Text('${loc.latitude.toStringAsFixed(3)}, ${loc.longitude.toStringAsFixed(3)}',
                                style: const TextStyle(fontSize: 13));
                          },
                        ),
                        onTap: () => _selectResult(loc),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final streetLine = _streetAddress.isNotEmpty ? _streetAddress : 'Locating...';
    final subLine = [_city, _state].where((e) => e.isNotEmpty).join(', ');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _isLoadingAddress
                    ? const Text('Finding address...',
                        style: TextStyle(fontSize: 15, color: Color(0xFF888888)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(streetLine,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (subLine.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(subLine,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF888888)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isLoadingAddress ? null : _confirm,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 54,
              decoration: BoxDecoration(
                color: _isLoadingAddress
                    ? const Color(0xFFE91E63).withValues(alpha: 0.5)
                    : const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: _isLoadingAddress
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() =>
      _mapProvider == MapProvider.google ? _buildGoogleMap() : _buildOSMMap();

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(_lat, _lng), zoom: 17),
      onMapCreated: (c) => _googleCtrl = c,
      onCameraMove: (pos) {
        _lat = pos.target.latitude;
        _lng = pos.target.longitude;
      },
      onCameraIdle: _reverseGeocode,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      mapType: gmaps.MapType.normal,
    );
  }

  Widget _buildOSMMap() {
    return FlutterMap(
      mapController: _osmCtrl,
      options: MapOptions(
        initialCenter: LatLng(_lat, _lng),
        initialZoom: 17,
        onMapReady: () => _osmReady = true,
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            _lat = event.camera.center.latitude;
            _lng = event.camera.center.longitude;
            _reverseGeocode();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmTileUrl,
          userAgentPackageName: AppConstants.packageName,
          maxZoom: 20,
          maxNativeZoom: 20,
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
