import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../domain/repositories/address_repository.dart';
import '../bloc/address_bloc.dart';
import 'address_map_page.dart';

class AddressFormPage extends StatefulWidget {
  final int? addressId;
  final AddressMapResult? mapResult;

  const AddressFormPage({super.key, this.addressId, this.mapResult});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _line1Ctrl  = TextEditingController(); // House / Flat
  final _line2Ctrl  = TextEditingController(); // Street / Area

  String _type      = 'home';
  bool   _isDefault = false;
  bool   _saving    = false;
  bool   _prefilled = false;

  // Geo fields — always from map result, never user-editable
  AddressMapResult? _mapResult;

  @override
  void initState() {
    super.initState();
    if (widget.addressId != null) {
      _loadAddressForEdit();
    } else {
      _mapResult = widget.mapResult;
      if (_mapResult == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openMap(replace: true));
      }
    }
  }

  Future<void> _loadAddressForEdit() async {
    // Fetch directly by ID — no dependency on bloc state timing
    final repo = getIt<AddressRepository>();
    final result = await repo.getAddressById(widget.addressId!);
    result.fold(
      (failure) {
        // Fallback: try from bloc state if already loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final addresses = context.read<AddressBloc>().state.addresses;
          if (addresses.isNotEmpty) {
            _prefillFromExisting(addresses);
          } else {
            context.read<AddressBloc>().add(LoadAddresses());
          }
        });
      },
      (addr) {
        if (!mounted) return;
        setState(() {
          _prefilled     = true;
          _nameCtrl.text  = addr.name;
          _phoneCtrl.text = addr.phone;
          _line1Ctrl.text = addr.addressLine1;
          _line2Ctrl.text = addr.addressLine2 ?? '';
          _type      = addr.type;
          _isDefault = addr.isDefault;
          _mapResult = AddressMapResult(
            lat: addr.latitude ?? 0,
            lng: addr.longitude ?? 0,
            streetAddress: addr.addressLine2 ?? '',
            city: addr.city,
            state: addr.state,
            postalCode: addr.postalCode,
            country: addr.country,
          );
        });
      },
    );
  }

  void _prefillFromExisting(List<dynamic> addresses) {
    if (_prefilled) return;
    final addr = addresses.firstWhere(
      (a) => a.id == widget.addressId,
      orElse: () => null,
    );
    if (addr == null) return;
    setState(() {
      _prefilled     = true;
      _nameCtrl.text  = addr.name;
      _phoneCtrl.text = addr.phone;
      _line1Ctrl.text = addr.addressLine1;
      _line2Ctrl.text = addr.addressLine2 ?? '';
      _type      = addr.type;
      _isDefault = addr.isDefault;
      _mapResult = AddressMapResult(
        lat: (addr.latitude as num?)?.toDouble() ?? 0,
        lng: (addr.longitude as num?)?.toDouble() ?? 0,
        streetAddress: addr.addressLine2 ?? '',
        city: addr.city,
        state: addr.state,
        postalCode: addr.postalCode,
        country: addr.country,
      );
    });
  }

  Future<void> _openMap({bool replace = false}) async {
    final result = await Navigator.of(context).push<AddressMapResult>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AppConfigBloc>(),
          child: AddressMapPage(
            initialLat: _mapResult?.lat,
            initialLng: _mapResult?.lng,
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _mapResult = result);
      // Sync line2 with map street for backend submission
      _line2Ctrl.text = result.streetAddress;
    } else if (replace && mounted && result == null) {
      // User cancelled map on add flow — go back
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_mapResult == null) {
      _openMap();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    String? nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();
    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address_line_1': _line1Ctrl.text.trim(),
      'address_line_2': nullIfEmpty(_line2Ctrl.text),
      'city': nullIfEmpty(_mapResult!.city),
      'state': nullIfEmpty(_mapResult!.state),
      'postal_code': nullIfEmpty(_mapResult!.postalCode),
      'country': _mapResult!.country.isNotEmpty ? _mapResult!.country : 'India',
      'type': _type,
      'is_default': _isDefault,
      'latitude': _mapResult!.lat,
      'longitude': _mapResult!.lng,
    };
    if (widget.addressId != null) {
      context.read<AddressBloc>().add(UpdateAddressEvent(widget.addressId!, data));
    } else {
      context.read<AddressBloc>().add(AddAddressEvent(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.addressId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocListener<AddressBloc, AddressState>(
        listener: (context, state) {
          // Prefill for edit once addresses arrive from API
          if (widget.addressId != null && !_prefilled && state.addresses.isNotEmpty) {
            _prefillFromExisting(state.addresses);
          }
          if (state is AddressOperationSuccess) {
            HapticFeedback.mediumImpact();
            if (mounted) setState(() => _saving = false);
            context.pop();
          } else if (state is AddressError) {
            if (mounted) setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
          // Do NOT react to AddressLoading here — _saving is set in _save() directly
        },
        child: Form(
          key: _formKey,
          child: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Color(0xFF1A1A1A)),
                  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.addresses),
                ),
                title: Text(
                  isEdit ? 'Edit Address' : 'Add Address',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.4,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: const Color(0xFFEEEEEE)),
                ),
              ),
            ],
            body: _mapResult == null
                ? const Center(child: CircularProgressIndicator())
                : _buildForm(isEdit),
          ),
        ),
      ),
      bottomNavigationBar: _mapResult == null
          ? null
          : Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 54,
                  decoration: BoxDecoration(
                    color: _saving
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          isEdit ? 'Update Address' : 'Save Address',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildForm(bool isEdit) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        // ── Mini Map ──────────────────────────────────────────────
        _MiniMap(
          mapResult: _mapResult!,
          onChangeTap: () => _openMap(),
        ),

        // ── Address Type ──────────────────────────────────────────
        _sectionLabel('ADDRESS TYPE'),
        _TypeSelector(
          selected: _type,
          onChanged: (v) => setState(() => _type = v),
        ),

        // ── Delivery Details ──────────────────────────────────────
        _sectionLabel('DELIVERY DETAILS'),
        _FormGroup(children: [
          _Field(
            controller: _line1Ctrl,
            label: 'House / Flat / Floor No.',
            icon: Icons.home_outlined,
            required: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          _divider(),
          _LockedField(
            value: _mapResult!.streetAddress.isNotEmpty
                ? _mapResult!.streetAddress
                : _line2Ctrl.text,
            label: 'Street / Area',
            icon: Icons.apartment_outlined,
          ),
        ]),

        // ── Default toggle ────────────────────────────────────────
        _sectionLabel('PREFERENCES'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: () => setState(() => _isDefault = !_isDefault),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bookmark_outline_rounded,
                        size: 20, color: Color(0xFF555555)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set as default address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            )),
                        SizedBox(height: 2),
                        Text('Used automatically at checkout',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            )),
                      ],
                    ),
                  ),
                  _Toggle(value: _isDefault),
                ],
              ),
            ),
          ),
        ),

        // ── Contact ───────────────────────────────────────────────
        _sectionLabel('CONTACT DETAILS'),
        _FormGroup(children: [
          _Field(
            controller: _nameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            required: true,
            textCapitalization: TextCapitalization.words,
          ),
          _divider(),
          _Field(
            controller: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            required: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ]),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF999999),
          letterSpacing: 1.2,
        )),
  );

  Widget _divider() => const _DividerSpacer();
}

// ─── Mini Map ─────────────────────────────────────────────────────────────────

class _MiniMap extends StatefulWidget {
  final AddressMapResult mapResult;
  final VoidCallback onChangeTap;

  const _MiniMap({required this.mapResult, required this.onChangeTap});

  @override
  State<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<_MiniMap> {
  final MapController _osmCtrl = MapController();

  MapProvider get _mapProvider {
    final bloc = getIt<AppConfigBloc>();
    // Prefer currentConfig (set once config loads at app start)
    if (bloc.currentConfig != null) return bloc.currentConfig!.mapProvider;
    // Fallback: check bloc state
    final state = bloc.state;
    if (state is AppConfigLoaded) return state.config.mapProvider;
    // Last resort: trigger a refresh and default to osm
    bloc.add(RefreshAppConfig());
    return MapProvider.osm;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      bloc: getIt<AppConfigBloc>(),
      buildWhen: (prev, curr) => curr is AppConfigLoaded,
      builder: (context, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map
            Positioned.fill(
              child: IgnorePointer(
                child: _mapProvider == MapProvider.google
                    ? _buildGoogleMap()
                    : _buildOSMMap(),
              ),
            ),

            // Center pin
            const Center(
              child: Icon(Icons.location_pin, size: 32, color: Color(0xFFE91E63)),
            ),

            // Change button — top right
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: widget.onChangeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_location_alt_outlined,
                          size: 14, color: Color(0xFF1A1A1A)),
                      SizedBox(width: 4),
                      Text('Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // Address label — bottom
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  [
                    widget.mapResult.streetAddress,
                    widget.mapResult.city,
                  ].where((e) => e.isNotEmpty).join(', '),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
          target: gmaps.LatLng(widget.mapResult.lat, widget.mapResult.lng),
          zoom: 16),
      onMapCreated: (c) {},
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }

  Widget _buildOSMMap() {
    return FlutterMap(
      mapController: _osmCtrl,
      options: MapOptions(
        initialCenter: LatLng(widget.mapResult.lat, widget.mapResult.lng),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
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

// ─── Locked Field (single read-only row inside a FormGroup) ──────────────────

class _LockedField extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _LockedField({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFCCCCCC)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFAAAAAA),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }
}

// ─── Type Selector ────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const types = [
      ('home',  'Home',  Icons.home_rounded),
      ('work',  'Work',  Icons.work_rounded),
      ('other', 'Other', Icons.location_on_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: types.map((t) {
          final isSelected = selected == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(t.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(t.$3,
                        size: 20,
                        color: isSelected ? Colors.white : const Color(0xFF888888)),
                    const SizedBox(height: 4),
                    Text(t.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF888888),
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Form Group ───────────────────────────────────────────────────────────────

// No longer a grouped container — fields are individually outlined.
// Kept as a thin wrapper so call sites don't need changing.
class _FormGroup extends StatelessWidget {
  final List<Widget> children;
  const _FormGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    // Filter out divider widgets (Container height:1) between fields
    final fields = children.where((w) => w is! _DividerSpacer).toList();
    return Column(
      children: fields
          .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: f,
              ))
          .toList(),
    );
  }
}

// Sentinel so _FormGroup can skip old _divider() calls
class _DividerSpacer extends StatelessWidget {
  const _DividerSpacer();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─── Field ────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, size: 18, color: const Color(0xFFAAAAAA)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(fontSize: 11, color: AppColors.error),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

// ─── Toggle ───────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final bool value;
  const _Toggle({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: value ? AppColors.primary : const Color(0xFFDDDDDD),
        borderRadius: BorderRadius.circular(13),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3),
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
