
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/payment_gateway_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/app_config/presentation/bloc/app_config_bloc.dart';
import '../../data/models/addon_service_model.dart';
import '../../data/models/item_category_model.dart';
import '../../data/models/service_type_model.dart';
import '../bloc/house_shifting_cubit.dart';
import '../bloc/house_shifting_state.dart';
import '../widgets/hs_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class passed from home screen into the booking flow
// ─────────────────────────────────────────────────────────────────────────────
class HsBookingArgs {
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final int pickupFloor;
  final bool pickupLift;
  final String dropAddress;
  final double dropLat;
  final double dropLng;
  final int dropFloor;
  final bool dropLift;
  final ItemCategoryModel? initialCategory;

  const HsBookingArgs({
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupFloor,
    required this.pickupLift,
    required this.dropAddress,
    required this.dropLat,
    required this.dropLng,
    required this.dropFloor,
    required this.dropLift,
    this.initialCategory,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Step indices
// ─────────────────────────────────────────────────────────────────────────────
const int _kStepItems = 0;
const int _kStepVehicle = 1;
const int _kStepAddons = 2;
const int _kStepReview = 3;

// ─────────────────────────────────────────────────────────────────────────────
// Main booking flow screen
// ─────────────────────────────────────────────────────────────────────────────
class HsBookingFlowScreen extends StatefulWidget {
  final HsBookingArgs args;

  const HsBookingFlowScreen({super.key, required this.args});

  @override
  State<HsBookingFlowScreen> createState() => _HsBookingFlowScreenState();
}

class _HsBookingFlowScreenState extends State<HsBookingFlowScreen> {
  final HouseShiftingCubit _cubit = GetIt.I<HouseShiftingCubit>();
  final PageController _pageCtrl = PageController();

  int _currentStep = _kStepItems;

  // Booking state
  final Map<int, int> _selectedItems = {};
  ServiceTypeModel? _selectedVehicle;
  final Set<int> _selectedAddonIds = {};

  // Estimate result
  Map<String, dynamic>? _estimateResult;
  bool _loadingEstimate = false;
  String? _estimateError;

  // Payment
  List<PaymentMethodInfo> _paymentMethods = [];
  PaymentMethodInfo? _selectedPaymentMethod;
  bool _loadingPaymentMethods = false;

  // Order placement
  bool _placingOrder = false;
  String? _orderError;

  @override
  void initState() {
    super.initState();
    // Ensure data is loaded
    if (_cubit.state is! HouseShiftingLoaded) {
      _cubit.loadData();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentStep < _kStepReview) {
      _goToStep(_currentStep + 1);
      if (_currentStep == _kStepReview) _fetchEstimate();
    }
  }

  void _back() {
    if (_currentStep > _kStepItems) {
      _goToStep(_currentStep - 1);
    } else {
      context.pop();
    }
  }

  Future<void> _fetchEstimate() async {
    if (_selectedVehicle == null) return;
    setState(() {
      _loadingEstimate = true;
      _estimateError = null;
    });
    // Load estimate + payment methods in parallel
    await Future.wait([
      _doFetchEstimate(),
      _loadPaymentMethods(),
    ]);
  }

  Future<void> _doFetchEstimate() async {
    try {
      final items = _selectedItems.entries
          .map((e) => {'item_id': e.key, 'quantity': e.value})
          .toList();
      final result = await _cubit.getEstimate(
        pickupLat: widget.args.pickupLat,
        pickupLng: widget.args.pickupLng,
        dropoffLat: widget.args.dropLat,
        dropoffLng: widget.args.dropLng,
        pickupFloor: widget.args.pickupFloor,
        pickupLiftAvailable: widget.args.pickupLift,
        dropoffFloor: widget.args.dropFloor,
        dropoffLiftAvailable: widget.args.dropLift,
        addonIds: _selectedAddonIds.toList(),
        serviceTypeId: _selectedVehicle!.id,
        items: items,
      );
      if (mounted) {
        setState(() {
          _estimateResult = result;
          _loadingEstimate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estimateError = e.toString();
          _loadingEstimate = false;
        });
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    if (_paymentMethods.isNotEmpty) return;
    setState(() => _loadingPaymentMethods = true);
    try {
      final svc = GetIt.I<PaymentGatewayService>();
      final methods = await svc.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods.where((m) => m.isEnabled).toList();
          // Auto-select first method
          if (_selectedPaymentMethod == null && _paymentMethods.isNotEmpty) {
            _selectedPaymentMethod = _paymentMethods.first;
          }
          _loadingPaymentMethods = false;
        });
      }
    } catch (_) {
      // Payment methods failed — fall back to cash only
      if (mounted) {
        setState(() {
          _paymentMethods = [
            PaymentMethodInfo(id: 'cash', name: 'Cash on Delivery', type: 'cash'),
          ];
          _selectedPaymentMethod = _paymentMethods.first;
          _loadingPaymentMethods = false;
        });
      }
    }
  }

  /// Maps the main app's payment method type names to the values accepted
  /// by the house shifting backend: cash, wallet, card, upi.
  String _normalizePaymentMethod(String type) {
    switch (type.toLowerCase()) {
      case 'cod':
      case 'cash_on_delivery':
      case 'cash':
        return 'cash';
      case 'wallet':
        return 'wallet';
      case 'upi':
        return 'upi';
      case 'card':
      case 'stripe':
      case 'razorpay':
      case 'paystack':
      case 'flutterwave':
      case 'paytm':
      case 'phonepe':
        return 'card';
      default:
        return 'cash';
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedVehicle == null) return;
    if (_selectedPaymentMethod == null) {
      setState(() => _orderError = 'Please select a payment method');
      return;
    }
    setState(() {
      _placingOrder = true;
      _orderError = null;
    });

    try {
      final items = _selectedItems.entries
          .map((e) => {'item_id': e.key, 'quantity': e.value})
          .toList();

      final normalizedMethod = _normalizePaymentMethod(_selectedPaymentMethod!.type);

      // Step 1: Create the order
      final result = await _cubit.createOrder(
        serviceTypeId: _selectedVehicle!.id,
        pickupAddress: widget.args.pickupAddress,
        pickupLat: widget.args.pickupLat,
        pickupLng: widget.args.pickupLng,
        pickupFloor: widget.args.pickupFloor,
        pickupLiftAvailable: widget.args.pickupLift,
        dropoffAddress: widget.args.dropAddress,
        dropoffLat: widget.args.dropLat,
        dropoffLng: widget.args.dropLng,
        dropoffFloor: widget.args.dropFloor,
        dropoffLiftAvailable: widget.args.dropLift,
        items: items,
        addonIds: _selectedAddonIds.toList(),
        paymentMethod: normalizedMethod,
      );

      final order = result['order'] as Map<String, dynamic>? ?? result;
      final orderId = order['id'] as int?;

      // Step 2: COD / cash — no gateway needed
      final isCod = normalizedMethod == 'cash' || normalizedMethod == 'wallet';

      if (isCod || orderId == null) {
        if (mounted) {
          context.pushReplacement('/house-shifting/order-success', extra: result);
        }
        return;
      }

      // Step 3: Initialize payment with backend
      final svc = GetIt.I<PaymentGatewayService>();
      final estimates = _estimateResult?['estimates'] as List? ?? [];
      final totalAmount = estimates.isNotEmpty
          ? (estimates.first as Map<String, dynamic>)['total_amount'] as num? ?? 0
          : 0;

      final initData = await svc.initializePayment(
        orderId: orderId,
        amount: totalAmount.toDouble(),
        paymentMethod: _selectedPaymentMethod!.type,
        currency: _estimateResult?['estimates'] != null
            ? (((_estimateResult!['estimates'] as List).first
                    as Map<String, dynamic>)['currency_symbol'] ??
                'USD')
            : 'USD',
      );

      // Step 4: Open gateway
      PaymentSuccessData? paymentResult;
      final type = _selectedPaymentMethod!.type.toLowerCase();

      if (type == 'razorpay') {
        final completer = Completer<PaymentSuccessData?>();
        await svc.processRazorpayPayment(
          initData: initData,
          name: '',
          email: '',
          phone: '',
          onSuccess: (d) => completer.complete(d),
          onError: (e) => completer.completeError(e.message),
        );
        paymentResult = await completer.future;
      } else if (type == 'stripe') {
        paymentResult = await svc.processStripePayment(
          initData: initData,
          email: '',
        );
      } else if (type == 'paystack') {
        if (!mounted) return;
        paymentResult = await svc.processPaystackPayment(
          initData: initData,
          context: context,
        );
      } else if (type == 'flutterwave') {
        if (!mounted) return;
        paymentResult = await svc.processFlutterwavePayment(
          initData: initData,
          context: context,
        );
      } else if (type == 'phonepe') {
        if (!mounted) return;
        paymentResult = await svc.processPhonePePayment(
          initData: initData,
          context: context,
        );
      } else if (type == 'paytm') {
        if (!mounted) return;
        paymentResult = await svc.processPaytmPayment(
          initData: initData,
          context: context,
        );
      }

      if (paymentResult == null) {
        throw Exception('Payment was not completed');
      }

      // Step 5: Verify with backend
      final verified = await svc.verifyPayment(
        orderId: orderId,
        paymentId: paymentResult.paymentId,
        paymentMethod: _selectedPaymentMethod!.type,
        additionalData: paymentResult.signature != null
            ? {'signature': paymentResult.signature}
            : null,
      );

      if (!verified) throw Exception('Payment verification failed');

      if (mounted) {
        context.pushReplacement('/house-shifting/order-success', extra: result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orderError = e.toString();
          _placingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _StepperHeader(currentStep: _currentStep, onStepTap: _goToStep),
            Expanded(
              child: BlocBuilder<HouseShiftingCubit, HouseShiftingState>(
                builder: (context, state) {
                  if (state is HouseShiftingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is HouseShiftingError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _cubit.loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is HouseShiftingLoaded) {
                    return PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StepItems(
                          categories: state.itemCategories,
                          selectedItems: _selectedItems,
                          initialCategory: widget.args.initialCategory,
                          onChanged: (items) => setState(() {
                            _selectedItems
                              ..clear()
                              ..addAll(items);
                          }),
                        ),
                        _StepVehicle(
                          vehicles: state.serviceTypes,
                          selected: _selectedVehicle,
                          onSelected: (v) => setState(() => _selectedVehicle = v),
                        ),
                        _StepAddons(
                          addons: state.addons,
                          selectedIds: _selectedAddonIds,
                          onToggle: (id) => setState(() {
                            if (_selectedAddonIds.contains(id)) {
                              _selectedAddonIds.remove(id);
                            } else {
                              _selectedAddonIds.add(id);
                            }
                          }),
                        ),
                        _StepReview(
                          args: widget.args,
                          selectedItems: _selectedItems,
                          selectedVehicle: _selectedVehicle,
                          selectedAddonIds: _selectedAddonIds,
                          categories: state.itemCategories,
                          addons: state.addons,
                          estimateResult: _estimateResult,
                          loadingEstimate: _loadingEstimate,
                          estimateError: _estimateError,
                          onRefreshEstimate: _fetchEstimate,
                          paymentMethods: _paymentMethods,
                          selectedPaymentMethod: _selectedPaymentMethod,
                          loadingPaymentMethods: _loadingPaymentMethods,
                          onPaymentMethodSelected: (m) =>
                              setState(() => _selectedPaymentMethod = m),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            _BottomBar(
              currentStep: _currentStep,
              canProceed: _canProceed(),
              loading: _placingOrder,
              orderError: _orderError,
              onBack: _back,
              onNext: () {
                if (_currentStep == _kStepReview) {
                  _placeOrder();
                } else {
                  _next();
                  if (_currentStep == _kStepReview) _fetchEstimate();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case _kStepItems:
        return _selectedItems.isNotEmpty;
      case _kStepVehicle:
        return _selectedVehicle != null;
      case _kStepAddons:
        return true;
      case _kStepReview:
        return _estimateResult != null &&
            !_loadingEstimate &&
            _selectedPaymentMethod != null;
      default:
        return false;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final titles = ['Select Items', 'Choose Vehicle', 'Add-ons', 'Review & Book'];
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: _back,
      ),
      title: Text(
        titles[_currentStep],
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stepper header  ○──●──○──○
// ─────────────────────────────────────────────────────────────────────────────
class _StepperHeader extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTap;

  const _StepperHeader({required this.currentStep, required this.onStepTap});

  static const _labels = ['Items', 'Vehicle', 'Add-ons', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final filled = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: filled ? AppColors.primary : AppColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < currentStep;
          final active = stepIndex == currentStep;
          return GestureDetector(
            onTap: done ? () => onStepTap(stepIndex) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || active ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: done || active ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : AppColors.textTertiary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.primary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentStep;
  final bool canProceed;
  final bool loading;
  final String? orderError;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomBar({
    required this.currentStep,
    required this.canProceed,
    required this.loading,
    required this.orderError,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == _kStepReview;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (orderError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  orderError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                // Back button
                SizedBox(
                  width: 56,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                // Next / Place Order button
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: canProceed && !loading
                          ? const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: canProceed && !loading ? null : AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: canProceed && !loading
                          ? [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canProceed && !loading ? onNext : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isLast ? 'Place Order' : 'Continue',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: canProceed ? Colors.white : AppColors.textTertiary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Select Items
// ─────────────────────────────────────────────────────────────────────────────
class _StepItems extends StatefulWidget {
  final List<ItemCategoryModel> categories;
  final Map<int, int> selectedItems;
  final ItemCategoryModel? initialCategory;
  final ValueChanged<Map<int, int>> onChanged;

  const _StepItems({
    required this.categories,
    required this.selectedItems,
    required this.initialCategory,
    required this.onChanged,
  });

  @override
  State<_StepItems> createState() => _StepItemsState();
}

class _StepItemsState extends State<_StepItems> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late Map<int, int> _items;

  @override
  void initState() {
    super.initState();
    _items = Map.from(widget.selectedItems);
    final initialIndex = widget.initialCategory != null
        ? widget.categories.indexWhere((c) => c.id == widget.initialCategory!.id)
        : 0;
    _tabCtrl = TabController(
      length: widget.categories.length,
      vsync: this,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _setQty(int itemId, int qty) {
    setState(() {
      if (qty <= 0) {
        _items.remove(itemId);
      } else {
        _items[itemId] = qty;
      }
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(child: Text('No item categories available'));
    }
    // Use a LayoutBuilder so the Column gets a finite height from PageView
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Column(
            children: [
              // Tab bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: widget.categories.map((c) => Tab(text: c.name)).toList(),
                ),
              ),
              // Item list per tab
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: widget.categories.map((cat) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cat.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = cat.items[i];
                        final qty = _items[item.id] ?? 0;
                        return _ItemRow(
                          item: item,
                          qty: qty,
                          onDecrement: () => _setQty(item.id, qty - 1),
                          onIncrement: () => _setQty(item.id, qty + 1),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              // Selected summary chip
              if (_items.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: Text(
                    '${_items.values.fold(0, (a, b) => a + b)} item(s) selected across ${_items.length} type(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ItemModel item;
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _ItemRow({
    required this.item,
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qty > 0 ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          width: qty > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: qty > 0 ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: qty > 0 ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: qty > 0 ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (item.isFragile)
                  const Text(
                    'Fragile',
                    style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          // Qty stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (qty > 0) ...[
                _StepBtn(icon: Icons.remove, onTap: onDecrement),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              _StepBtn(icon: Icons.add, onTap: onIncrement, filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _StepBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: filled ? Colors.white : AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Choose Vehicle
// ─────────────────────────────────────────────────────────────────────────────
class _StepVehicle extends StatelessWidget {
  final List<ServiceTypeModel> vehicles;
  final ServiceTypeModel? selected;
  final ValueChanged<ServiceTypeModel> onSelected;

  const _StepVehicle({
    required this.vehicles,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencyConfig = configState is AppConfigLoaded
            ? configState.config.currencyConfig
            : null;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final v = vehicles[i];
            final isSelected = selected?.id == v.id;
            final baseFee = CurrencyFormatter.formatAmount(v.baseFee, currencyConfig);
            final perKm = '+${CurrencyFormatter.formatAmount(v.perKmRate, currencyConfig)}/km';

            return GestureDetector(
              onTap: () => onSelected(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isSelected ? 12 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(HsIcons.placeholder),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            v.capacityDisplay,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (v.description.isNotEmpty)
                            Text(
                              v.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          baseFee,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            perKm,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — Add-ons (3 per row square cards)
// ─────────────────────────────────────────────────────────────────────────────
class _StepAddons extends StatelessWidget {
  final List<AddonServiceModel> addons;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  const _StepAddons({
    required this.addons,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencyConfig = configState is AppConfigLoaded
            ? configState.config.currencyConfig
            : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enhance your move',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'All add-ons are optional',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: addons.length,
                itemBuilder: (_, i) {
                  final addon = addons[i];
                  final isOn = selectedIds.contains(addon.id);
                  final price = CurrencyFormatter.formatAmount(addon.price, currencyConfig);
                  return GestureDetector(
                    onTap: () => onToggle(addon.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isOn ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOn ? AppColors.primary : AppColors.border,
                          width: isOn ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isOn
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isOn
                                        ? AppColors.primary.withValues(alpha: 0.12)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: SvgPicture.asset(HsIcons.placeholder),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  addon.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isOn ? FontWeight.w700 : FontWeight.w600,
                                    color: isOn ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  price,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isOn ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isOn)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 4 — Review & Estimate
// ─────────────────────────────────────────────────────────────────────────────
class _StepReview extends StatelessWidget {
  final HsBookingArgs args;
  final Map<int, int> selectedItems;
  final ServiceTypeModel? selectedVehicle;
  final Set<int> selectedAddonIds;
  final List<ItemCategoryModel> categories;
  final List<AddonServiceModel> addons;
  final Map<String, dynamic>? estimateResult;
  final bool loadingEstimate;
  final String? estimateError;
  final VoidCallback onRefreshEstimate;
  final List<PaymentMethodInfo> paymentMethods;
  final PaymentMethodInfo? selectedPaymentMethod;
  final bool loadingPaymentMethods;
  final ValueChanged<PaymentMethodInfo> onPaymentMethodSelected;

  const _StepReview({
    required this.args,
    required this.selectedItems,
    required this.selectedVehicle,
    required this.selectedAddonIds,
    required this.categories,
    required this.addons,
    required this.estimateResult,
    required this.loadingEstimate,
    required this.estimateError,
    required this.onRefreshEstimate,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.loadingPaymentMethods,
    required this.onPaymentMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Locations
          _ReviewCard(
            title: 'Locations',
            child: Column(
              children: [
                _ReviewRow(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.secondary,
                  label: 'Pickup',
                  value: args.pickupAddress,
                  sub: 'Floor ${args.pickupFloor == 0 ? "Ground" : args.pickupFloor}  •  Lift: ${args.pickupLift ? "Yes" : "No"}',
                ),
                const SizedBox(height: 10),
                _ReviewRow(
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.error,
                  label: 'Drop',
                  value: args.dropAddress,
                  sub: 'Floor ${args.dropFloor == 0 ? "Ground" : args.dropFloor}  •  Lift: ${args.dropLift ? "Yes" : "No"}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Items
          if (selectedItems.isNotEmpty)
            _ReviewCard(
              title: 'Items',
              child: Column(
                children: selectedItems.entries.map((e) {
                  final item = _findItem(e.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item?.name ?? 'Item #${e.key}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        Text('x${e.value}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),

          // Vehicle
          if (selectedVehicle != null)
            _ReviewCard(
              title: 'Vehicle',
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(HsIcons.placeholder),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedVehicle!.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(selectedVehicle!.capacityDisplay,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Add-ons
          if (selectedAddonIds.isNotEmpty)
            _ReviewCard(
              title: 'Add-ons',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedAddonIds.map((id) {
                  final addon = addons.firstWhere((a) => a.id == id,
                      orElse: () => AddonServiceModel(
                          id: id, name: 'Addon', slug: '', price: 0, type: 'other'));
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      addon.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Estimate section
          if (loadingEstimate)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Calculating estimate...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else if (estimateError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(estimateError!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onRefreshEstimate,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (estimateResult != null)
            _EstimateBreakdown(estimateResult: estimateResult!)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tap "Continue" to calculate your estimate',
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                  TextButton(
                    onPressed: onRefreshEstimate,
                    child: const Text('Get Estimate'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Payment method section
          _ReviewCard(
            title: 'PAYMENT METHOD',
            child: loadingPaymentMethods
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : paymentMethods.isEmpty
                    ? const Text(
                        'No payment methods available',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      )
                    : Column(
                        children: paymentMethods.map((method) {
                          final isSelected = selectedPaymentMethod?.id == method.id;
                          return GestureDetector(
                            onTap: () => onPaymentMethodSelected(method),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.06)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _paymentIcon(method.type),
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      method.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 20),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  ItemModel? _findItem(int itemId) {
    for (final cat in categories) {
      for (final item in cat.items) {
        if (item.id == itemId) return item;
      }
    }
    return null;
  }

  IconData _paymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cod':
      case 'cash':
        return Icons.payments_outlined;
      case 'razorpay':
      case 'stripe':
      case 'card':
        return Icons.credit_card_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'upi':
      case 'phonepe':
      case 'paytm':
        return Icons.phone_android_rounded;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      default:
        return Icons.payment_rounded;
    }
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReviewCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? sub;

  const _ReviewRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.8)),
              Text(value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (sub != null)
                Text(sub!,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EstimateBreakdown extends StatelessWidget {
  final Map<String, dynamic> estimateResult;

  const _EstimateBreakdown({required this.estimateResult});

  @override
  Widget build(BuildContext context) {
    final estimates = estimateResult['estimates'] as List? ?? [];
    if (estimates.isEmpty) {
      return const Text('No estimate data available');
    }
    final est = estimates.first as Map<String, dynamic>;
    final symbol = est['currency_symbol']?.toString() ?? '';
    final distanceKm = (est['estimated_distance_km'] as num?)?.toStringAsFixed(2) ?? '-';
    final isSurge = est['is_surge_active'] == true;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Estimate',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      est['total_formatted']?.toString() ?? '$symbol${est['total_amount']}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isSurge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('SURGE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 4),
                    Text('$distanceKm km',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          // Breakdown
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _ERow(label: 'Base fee', value: '$symbol${est['base_fee']}'),
                _ERow(label: 'Distance fee', value: '$symbol${est['distance_fee']}'),
                if ((est['item_surcharge'] as num? ?? 0) > 0)
                  _ERow(label: 'Item surcharge', value: '$symbol${est['item_surcharge']}'),
                if ((est['floor_surcharge'] as num? ?? 0) > 0)
                  _ERow(label: 'Floor surcharge', value: '$symbol${est['floor_surcharge']}'),
                if ((est['helper_fee'] as num? ?? 0) > 0)
                  _ERow(label: 'Helper fee', value: '$symbol${est['helper_fee']}'),
                if ((est['addon_total'] as num? ?? 0) > 0)
                  _ERow(label: 'Add-ons', value: '$symbol${est['addon_total']}'),
                if (isSurge)
                  _ERow(label: 'Surge (x${est['surge_multiplier']})', value: '+$symbol${est['surge_amount']}'),
                const Divider(color: Colors.white30, height: 16),
                _ERow(label: 'Subtotal', value: '$symbol${est['subtotal']}'),
                _ERow(label: 'Tax', value: '$symbol${est['tax_amount']}'),
                const SizedBox(height: 4),
                _ERow(
                  label: 'Total',
                  value: est['total_formatted']?.toString() ?? '$symbol${est['total_amount']}',
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ERow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ERow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 13 : 12,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: Colors.white.withValues(alpha: bold ? 1 : 0.8))),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 14 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
