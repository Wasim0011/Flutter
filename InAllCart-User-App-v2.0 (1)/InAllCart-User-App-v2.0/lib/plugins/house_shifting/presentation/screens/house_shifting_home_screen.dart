
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/item_category_model.dart';
import '../bloc/house_shifting_cubit.dart';
import '../bloc/house_shifting_state.dart';
import '../widgets/hs_icons.dart';
import '../widgets/location_card.dart';
import '../widgets/shifting_banner.dart';
import '../widgets/shimmer_loading.dart';
import 'hs_booking_flow_screen.dart';

class HouseShiftingHomeScreen extends StatefulWidget {
  const HouseShiftingHomeScreen({super.key});

  @override
  State<HouseShiftingHomeScreen> createState() => _HouseShiftingHomeScreenState();
}

class _HouseShiftingHomeScreenState extends State<HouseShiftingHomeScreen> {
  final HouseShiftingCubit _cubit = GetIt.I<HouseShiftingCubit>();

  String? _pickupAddress;
  double? _pickupLat;
  double? _pickupLng;
  int _pickupFloor = 0;
  bool _pickupLift = false;

  String? _dropAddress;
  double? _dropLat;
  double? _dropLng;
  int _dropFloor = 0;
  bool _dropLift = false;

  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    _cubit.loadData();
  }

  @override
  void dispose() {
    // Don't close the cubit — it's a singleton managed by GetIt and shared
    // across the shell tabs.
    super.dispose();
  }

  Future<void> _showFloorLiftDialog({
    required String title,
    required int initialFloor,
    required bool initialLift,
    required Function(int floor, bool lift) onSave,
  }) async {
    int floor = initialFloor;
    bool lift = initialLift;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Floor Number'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setDialogState(() {
                          if (floor > 0) floor--;
                        }),
                      ),
                      Text(floor == 0 ? 'Ground' : floor.toString()),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setDialogState(() => floor++),
                      ),
                    ],
                  ),
                ],
              ),
              if (floor > 0)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Service Lift Available?'),
                  value: lift,
                  onChanged: (val) => setDialogState(() => lift = val),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    onSave(floor, lift);
  }

  void _startBooking(List<ItemCategoryModel> categories, {ItemCategoryModel? category}) {
    if (_pickupLat == null || _dropLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and drop locations first')),
      );
      return;
    }
    context.push(
      '/house-shifting/book',
      extra: HsBookingArgs(
        pickupAddress: _pickupAddress!,
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        pickupFloor: _pickupFloor,
        pickupLift: _pickupLift,
        dropAddress: _dropAddress!,
        dropLat: _dropLat!,
        dropLng: _dropLng!,
        dropFloor: _dropFloor,
        dropLift: _dropLift,
        initialCategory: category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: _buildAppBar(),
        body: BlocBuilder<HouseShiftingCubit, HouseShiftingState>(
          builder: (context, state) {
            if (state is HouseShiftingLoading) return const ShiftingShimmer();
            if (state is HouseShiftingError) return _buildError(state.message);
            if (state is HouseShiftingLoaded) return _buildBody(state);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'House Shifting',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text('Something went wrong',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cubit.loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(HouseShiftingLoaded state) {
    // Max 4 rows × 3 cols = 12 categories before "View All"
    const int maxVisible = 12;
    final cats = state.itemCategories;
    final visibleCats = _showAllCategories ? cats : cats.take(maxVisible).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          const ShiftingBanner(),
          const SizedBox(height: 16),

          // Location card
          LocationCard(
            pickupAddress: _pickupAddress,
            dropAddress: _dropAddress,
            pickupFloor: _pickupFloor,
            pickupLift: _pickupLift,
            dropFloor: _dropFloor,
            dropLift: _dropLift,
            onPickupTap: () async {
              final result = await context.push<Map<String, dynamic>>(Routes.selectLocation);
              if (result != null && result.containsKey('address')) {
                setState(() {
                  _pickupAddress = result['address'] as String?;
                  _pickupLat = result['lat'] as double?;
                  _pickupLng = result['lng'] as double?;
                });
                if (mounted) {
                  await _showFloorLiftDialog(
                    title: 'Pickup Details',
                    initialFloor: _pickupFloor,
                    initialLift: _pickupLift,
                    onSave: (floor, lift) => setState(() {
                      _pickupFloor = floor;
                      _pickupLift = lift;
                    }),
                  );
                }
              }
            },
            onDropTap: () async {
              final result = await context.push<Map<String, dynamic>>(Routes.selectLocation);
              if (result != null && result.containsKey('address')) {
                setState(() {
                  _dropAddress = result['address'] as String?;
                  _dropLat = result['lat'] as double?;
                  _dropLng = result['lng'] as double?;
                });
                if (mounted) {
                  await _showFloorLiftDialog(
                    title: 'Drop Details',
                    initialFloor: _dropFloor,
                    initialLift: _dropLift,
                    onSave: (floor, lift) => setState(() {
                      _dropFloor = floor;
                      _dropLift = lift;
                    }),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 28),

          // Category section header
          if (cats.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'What are you shifting?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (cats.length > maxVisible)
                    GestureDetector(
                      onTap: () => setState(() => _showAllCategories = !_showAllCategories),
                      child: Text(
                        _showAllCategories ? 'Show Less' : 'View All',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3-column grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: visibleCats.length,
                itemBuilder: (_, i) => _CategoryCard(
                  category: visibleCats[i],
                  onTap: () => _startBooking(cats, category: visibleCats[i]),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card — no background card, just icon/image + name
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final ItemCategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Returns true if the icon value is an uploaded image URL (not a feather name).
  bool get _isImageUrl {
    final icon = widget.category.icon;
    if (icon == null || icon.isEmpty) return false;
    return icon.startsWith('http') || icon.startsWith('/storage');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ListenableBuilder(
        listenable: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image fills most of the cell width, no white card behind it
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isImageUrl
                      ? Image.network(
                          widget.category.icon!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _fallbackIcon(),
                        )
                      : _fallbackIcon(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SvgPicture.asset(
        HsIcons.placeholder,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

