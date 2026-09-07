import '../../../../core/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../address/domain/entities/address.dart';
import '../../../address/presentation/bloc/address_bloc.dart' as address_bloc;
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../checkout/presentation/bloc/checkout_bloc.dart';
import '../../../checkout/domain/entities/checkout_data.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_event.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../../../../core/services/payment_gateway_service.dart';
import '../../../../core/widgets/inallcart_loader.dart';
import '../../../popups/domain/services/popup_manager.dart';
import '../../../popups/presentation/widgets/popup_overlay_dialog.dart';
import '../bloc/cart_bloc.dart';
import '../../domain/entities/cart.dart';
import 'coupons_page.dart';
import '../widgets/cart_recommended_section.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState is Authenticated;

    return MultiBlocProvider(
      providers: [
        if (isAuthenticated) ...[
          BlocProvider(
            create: (_) => getIt<address_bloc.AddressBloc>()..add(address_bloc.LoadAddresses()),
          ),
          BlocProvider(
            // Don't fire LoadPaymentMethods here — _CartPageContentState.initState handles it
            // so it loads eagerly on first visit without waiting for cart/checkout interaction.
            create: (_) => getIt<CheckoutBloc>(),
          ),
          BlocProvider(
            create: (_) => getIt<WalletBloc>()..add(const LoadWallet()),
          ),
        ] else ...[
          BlocProvider(
            create: (_) => getIt<address_bloc.AddressBloc>(),
          ),
          BlocProvider(
            create: (_) => getIt<CheckoutBloc>(),
          ),
          BlocProvider(
            create: (_) => getIt<WalletBloc>(),
          ),
        ],
      ],
      child: const _CartPageContent(),
    );
  }
}

class _CartPageContent extends StatefulWidget {
  const _CartPageContent();

  @override
  State<_CartPageContent> createState() => _CartPageContentState();
}

class _CartPageContentState extends State<_CartPageContent> {
  PaymentMethod? _selectedPaymentMethod;
  int? _selectedAddressId;
  String? _prescriptionImagePath;
  String _orderType = 'delivery';
  double _driverTip = 0.0;
  final StorageService _storage = getIt<StorageService>();

  Future<void> _pickPrescriptionImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _prescriptionImagePath = pickedFile.path;
      });
    }
  }

  // Track the last known user ID so we can reset selections when the user
  // switches accounts (Bug 6 fix).
  int? _lastUserId;

  @override
  void initState() {
    super.initState();

    // Always refresh the cart when the screen is opened (Bug 1 fix).
    // This ensures the cart is up-to-date regardless of when the global
    // startup LoadCart fired.
    context.read<CartBloc>().add(LoadCart());

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _lastUserId = authState.user.id;
      // Load payment methods and addresses eagerly so they're ready before the user taps Pay.
      context.read<CheckoutBloc>().add(LoadPaymentMethods());
      context.read<address_bloc.AddressBloc>().add(address_bloc.LoadAddresses());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCartPopups();
    });
  }

  void _checkCartPopups() async {
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded) return;
    final cart = cartState.cart;

    final popupManager = getIt<PopupManager>();
    final authState = context.read<AuthBloc>().state;
    final isAuthed = authState is Authenticated;
    final userData = _storage.getUser();
    final isVipUser = userData?['is_vip'] == true || userData?['vip_status'] == 'active';
    final lang = _storage.getLanguage() ?? 'en';

    final productIds = cart.items.map((e) => e.productId).toList();

    final popup = await popupManager.evaluateEligiblePopup(
      contextTrigger: PopupContextTrigger.onBeforeCheckout,
      isUserLoggedIn: isAuthed,
      isVipUser: isVipUser,
      currentLanguage: lang,
      cartSubtotal: cart.subtotal,
      cartProductIds: productIds,
    );

    if (popup != null && mounted) {
      await popupManager.recordPopupPresented(popup);
      if (mounted) {
        PopupOverlayDialog.show(context, popup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalAppBar(
        title: 'Cart',
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppColors.textPrimary),
            onPressed: () => context.push(Routes.wishlist),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          // Auth state listener — reload cart and reset per-user selections
          // when the user logs in, logs out, or switches accounts (Bug 5 & 6).
          BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              final newUserId = authState is Authenticated ? authState.user.id : null;

              if (newUserId != _lastUserId) {
                // User changed — reset address and payment selections so we
                // don't accidentally use the previous user's data.
                setState(() {
                  _selectedAddressId = null;
                  _selectedPaymentMethod = null;
                  _lastUserId = newUserId;
                });

                // Reload the cart for the new auth state.
                context.read<CartBloc>().add(LoadCart());

                if (authState is Authenticated) {
                  context.read<CheckoutBloc>().add(LoadPaymentMethods());
                }
              }
            },
          ),
          BlocListener<CartBloc, CartState>(
            listener: (context, cartState) {
              // Keep checkout in sync whenever the cart changes.
              if (cartState.cart.isNotEmpty) {
                context.read<CheckoutBloc>().add(InitializeCheckout(cartState.cart));
              }

              // Surface stock/price issues found during pre-checkout validation.
              if (cartState is CartValidated && cartState.issues.isNotEmpty) {
                _showCartIssuesSheet(context, cartState.issues);
              }

              // After validation passes (no issues), proceed to place the order.
              if (cartState is CartValidated && cartState.issues.isEmpty) {
                _placeOrder(context);
              }
            },
          ),
          BlocListener<CheckoutBloc, CheckoutState>(
            listenWhen: (previous, current) => current is CheckoutSuccess && previous is! CheckoutSuccess,
            listener: (context, checkoutState) {
              if (checkoutState is CheckoutSuccess) {
                // Clear cart and navigate to order success
                context.read<CartBloc>().add(ClearCartEvent());
                context.go(
                  '/order-success/${checkoutState.order.id}',
                  extra: checkoutState.order,
                );
              }
            },
          ),
          BlocListener<CheckoutBloc, CheckoutState>(
            listener: (context, checkoutState) {
              // Auto-restore last used payment method when methods are loaded
              // This handles both cases:
              // 1. Methods arrive after checkout is initialized
              // 2. Checkout is initialized after methods are already loaded
              if (checkoutState is CheckoutReady && checkoutState.paymentMethods.isNotEmpty && _selectedPaymentMethod == null) {
                final lastId = _storage.getLastPaymentMethodId();
                if (lastId != null) {
                  try {
                    final match = checkoutState.paymentMethods.firstWhere(
                      (m) => m.id.toString() == lastId && m.isEnabled,
                    );
                    setState(() {
                      _selectedPaymentMethod = PaymentMethod(
                        id: match.id,
                        name: match.name,
                        type: match.type,
                        icon: match.icon,
                        isEnabled: match.isEnabled,
                        config: match.config,
                      );
                    });
                  } catch (_) {
                    // Last method no longer available, ignore
                  }
                }
              }
            },
          ),
          BlocListener<address_bloc.AddressBloc, address_bloc.AddressState>(
            listener: (context, addressState) {
              if (addressState.addresses.isNotEmpty) {
                if (addressState.selectedAddress != null) {
                  setState(() {
                    _selectedAddressId = addressState.selectedAddress!.id;
                  });
                } else if (_selectedAddressId == null || !addressState.addresses.any((a) => a.id == _selectedAddressId)) {
                  final defaultAddr = addressState.addresses.firstWhere(
                    (a) => a.isDefault,
                    orElse: () => addressState.addresses.last,
                  );
                  setState(() {
                    _selectedAddressId = defaultAddr.id;
                  });
                }
              }
            },
          ),
          BlocListener<CheckoutBloc, CheckoutState>(
            listenWhen: (previous, current) => current is CheckoutError,
            listener: (context, checkoutState) {
              if (checkoutState is CheckoutError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(checkoutState.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            if (cartState is CartLoading && cartState.cart.isEmpty) {
              return const Center(child: InAllCartLoader(size: 60, useOverlay: false));
            }

            if (cartState.cart.isEmpty) {
              return _buildEmptyCart(context);
            }

            // Both guests and authenticated users see the full cart.
            // Guests get a "Login to checkout" sticky bar instead of the
            // payment bar — they can browse and manage their cart freely.
            return _buildCartContent(context, cartState);
          },
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartState cartState) {
    final cart = cartState.cart;
    
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Savings Banner
            if (cart.summary.discount > 0)
              SliverToBoxAdapter(
                child: _buildSavingsBanner(cart.summary.discount),
              ),

            // Coupon Section
            SliverToBoxAdapter(
              child: _buildCouponSection(context, cartState),
            ),

            // Wallet Section
            SliverToBoxAdapter(
              child: _buildWalletSection(context, cart.summary.totalWithDelivery),
            ),

            // Fulfillment Mode Selector Section (Home Delivery vs Store Pickup)
            SliverToBoxAdapter(
              child: _buildFulfillmentSelector(context, cart),
            ),

            // Delivery Address Section
            SliverToBoxAdapter(
              child: _buildDeliveryAddressSection(context),
            ),

            // Delivery Info & Cart Items - Single Container
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    // Delivery Info Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivering in ${cart.store?.preparationTime ?? '10-15'} mins',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${cart.items.length} item${cart.items.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Divider
                    Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                    
                    // Cart Items
                    ...cart.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          _buildCartItem(context, item, cartState is CartUpdating),
                          if (index < cart.items.length - 1)
                            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                        ],
                      );
                    }),
                    
                    // Divider before "Add More Items"
                    Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                    
                    // Add More Items
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: TextButton(
                        onPressed: () {
                          context.go(Routes.home);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Forgot something? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Add More Items',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recommended Items
            SliverToBoxAdapter(
              child: CartRecommendedSection(
                categoryIds: cart.items
                    .map((i) => i.categoryId)
                    .whereType<int>()
                    .toSet()
                    .toList(),
              ),
            ),

            // Rider Tip Section
            SliverToBoxAdapter(
              child: _buildRiderTipSection(),
            ),

            // Bill Summary
            SliverToBoxAdapter(
              child: _buildBillSummary(cart.summary, cart.couponDiscount),
            ),

            // Prescription Upload Section (Required if Rx items present)
            SliverToBoxAdapter(
              child: _buildPrescriptionUploadSection(cart),
            ),

            // Bottom Spacing for sticky bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 140),
            ),
          ],
        ),

        // Sticky Payment Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildStickyPaymentBar(context, cart.summary),
        ),
      ],
    );
  }

  Widget _buildRiderTipSection() {
    final tipOptions = [0.0, 10.0, 20.0, 30.0, 50.0];
    const emeraldColor = Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_outlined, size: 18, color: emeraldColor),
              const SizedBox(width: 8),
              const Text(
                'Say Thanks with a Rider Tip',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Text(
                '100% goes to rider',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: emeraldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: tipOptions.map((tip) {
              final isSelected = _driverTip == tip;
              final isZero = tip == 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _driverTip = tip;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? emeraldColor.withValues(alpha: 0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? emeraldColor : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isZero ? 'No Tip' : '₹${tip.toInt()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? emeraldColor : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentSelector(BuildContext context, Cart cart) {
    final store = cart.store;
    final deliveryEnabled = store?.deliveryEnabled ?? true;
    final pickupEnabled = store?.pickupEnabled ?? true;

    if (!deliveryEnabled && _orderType == 'delivery') {
      _orderType = 'pickup';
    } else if (!pickupEnabled && _orderType == 'pickup') {
      _orderType = 'delivery';
    }

    if (!deliveryEnabled && !pickupEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fulfillment Mode',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (deliveryEnabled)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _orderType = 'delivery';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _orderType == 'delivery' ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _orderType == 'delivery' ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 16,
                            color: _orderType == 'delivery' ? AppColors.primary : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Home Delivery',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _orderType == 'delivery' ? AppColors.primary : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (deliveryEnabled && pickupEnabled) const SizedBox(width: 10),
              if (pickupEnabled)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _orderType = 'pickup';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _orderType == 'pickup' ? Colors.purple.withValues(alpha: 0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _orderType == 'pickup' ? Colors.purple : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: _orderType == 'pickup' ? Colors.purple : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Store Pickup',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _orderType == 'pickup' ? Colors.purple : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_orderType == 'pickup' && store?.address != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.purple),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pickup Address: ${store?.name} — ${store?.address}',
                      style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsBanner(double savings) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            'Yay! You ',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          BlocBuilder<AppConfigBloc, AppConfigState>(
            builder: (context, state) {
              final config = state is AppConfigLoaded ? state.config : null;
              return Text(
                'saved ${CurrencyFormatter.formatAmount(savings, config?.currencyConfig)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              );
            },
          ),
          const Text(
            ' on this order',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context, CartState cartState) {
    final hasCoupon = cartState.cart.couponCode != null;
    final couponCode = cartState.cart.couponCode;
    final couponDiscount = cartState.cart.couponDiscount;

    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final config = configState is AppConfigLoaded ? configState.config.currencyConfig : null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasCoupon ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          child: hasCoupon
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer_rounded, color: AppColors.success, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              couponCode!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (couponDiscount != null && couponDiscount > 0)
                              Text(
                                'You save ${CurrencyFormatter.formatAmount(couponDiscount, config)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.read<CartBloc>().add(RemoveCouponEvent()),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              : InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => BlocProvider.value(
                      value: context.read<CartBloc>(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.85,
                        child: const CouponsPage(),
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Apply coupon code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCartItem(BuildContext context, dynamic item, bool isUpdating) {
    final imageUrl = AppConstants.getFullMediaUrl(item.productImage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedImage(
              imageUrl: imageUrl,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 68,
                height: 68,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Info — fills remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variantName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.variantName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                BlocBuilder<AppConfigBloc, AppConfigState>(
                  builder: (context, state) {
                    final config = state is AppConfigLoaded ? state.config : null;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (item.hasDiscount) ...[
                          Text(
                            CurrencyFormatter.formatAmount(item.comparePrice! * item.quantity, config?.currencyConfig),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          CurrencyFormatter.formatAmount(item.price * item.quantity, config?.currencyConfig),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Quantity Controls — always enabled (optimistic UI).
          // The repository applies the change locally first so the user
          // never waits for a server round-trip before seeing feedback.
          item.inStock
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (item.quantity > 1) {
                            context.read<CartBloc>().add(
                              UpdateCartItemEvent(itemId: item.id, quantity: item.quantity - 1),
                            );
                          } else {
                            HapticFeedback.lightImpact();
                            context.read<CartBloc>().add(RemoveFromCartEvent(item.id));
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.remove, size: 15, color: AppColors.primary),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.read<CartBloc>().add(
                            UpdateCartItemEvent(itemId: item.id, quantity: item.quantity + 1),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.add, size: 15, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                )
              : _NotifyButton(productName: item.productName),
        ],
      ),
    );
  }

  void _showLoginRequiredSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Login to Place Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your cart is saved. Login to complete your order.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Continue Shopping"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummary(dynamic summary, double? couponDiscount) {
    final totalSavings = (summary.discount) + (couponDiscount ?? 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: BlocBuilder<AppConfigBloc, AppConfigState>(
        builder: (context, state) {
          final config = state is AppConfigLoaded ? state.config : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'Cart Summary',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),

              // Rows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildBillRow('Item Total', summary.subtotal, config?.currencyConfig),
                    const SizedBox(height: 10),
                    _buildBillRow(
                      'Delivery Fee',
                      summary.deliveryCharge,
                      config?.currencyConfig,
                      freeText: summary.deliveryCharge == 0,
                    ),
                    if (_driverTip > 0) ...[
                      const SizedBox(height: 10),
                      _buildBillRow('Driver Tip (100% to Rider)', _driverTip, config?.currencyConfig),
                    ],
                    if (summary.tax > 0) ...[
                      const SizedBox(height: 10),
                      _buildBillRow('Taxes & Charges', summary.tax, config?.currencyConfig),
                    ],
                    if (summary.discount > 0) ...[
                      const SizedBox(height: 10),
                      _buildBillRow('Product Discount', -summary.discount, config?.currencyConfig, isDiscount: true),
                    ],
                    if (couponDiscount != null && couponDiscount > 0) ...[
                      const SizedBox(height: 10),
                      _buildBillRow('Coupon Discount', -couponDiscount, config?.currencyConfig, isDiscount: true),
                    ],
                  ],
                ),
              ),

              // Total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'To Pay',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (totalSavings > 0) ...[
                          Text(
                            CurrencyFormatter.formatAmount(summary.totalWithDelivery + _driverTip + totalSavings, config?.currencyConfig),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          CurrencyFormatter.formatAmount(summary.totalWithDelivery + _driverTip, config?.currencyConfig),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Savings pill
              if (totalSavings > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'You\'re saving ',
                        style: const TextStyle(fontSize: 13, color: AppColors.success),
                      ),
                      Text(
                        CurrencyFormatter.formatAmount(totalSavings, config?.currencyConfig),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                      const Text(
                        ' on this order',
                        style: TextStyle(fontSize: 13, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveryAddressSection(BuildContext context) {
    return BlocBuilder<address_bloc.AddressBloc, address_bloc.AddressState>(
      builder: (context, state) {
        dynamic selectedAddr;
        if (state.addresses.isNotEmpty) {
          if (_selectedAddressId != null) {
            try {
              selectedAddr = state.addresses.firstWhere((a) => a.id == _selectedAddressId);
            } catch (_) {
              selectedAddr = state.addresses.firstWhere((a) => a.isDefault, orElse: () => state.addresses.first);
            }
          } else {
            selectedAddr = state.addresses.firstWhere((a) => a.isDefault, orElse: () => state.addresses.first);
          }
        }

        if (_selectedAddressId == null && selectedAddr != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedAddressId == null) {
              setState(() {
                _selectedAddressId = selectedAddr.id;
              });
            }
          });
        }

        void onAddressTap() {
          if (state.addresses.isNotEmpty) {
            _showAddressSelector(context, state.addresses);
          } else {
            final addressBloc = context.read<address_bloc.AddressBloc>();
            context.push('/addresses/add').then((_) {
              addressBloc.add(address_bloc.LoadAddresses());
            });
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedAddr != null ? AppColors.primary.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: onAddressTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              selectedAddr != null ? 'DELIVER TO (${selectedAddr.type.toString().toUpperCase()})' : 'DELIVERY ADDRESS',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (selectedAddr != null && (selectedAddr.isDefault ?? false)) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selectedAddr != null
                              ? '${selectedAddr.addressLine1}, ${selectedAddr.city ?? ''}'
                              : 'Tap to select or add delivery address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selectedAddr != null ? AppColors.textPrimary : AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onAddressTap,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: Text(
                      selectedAddr != null ? 'Change' : 'Add',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillRow(String label, double amount, dynamic config, {bool freeText = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          freeText
              ? 'FREE'
              : isDiscount
                  ? '- ${CurrencyFormatter.formatAmount(amount.abs(), config)}'
                  : CurrencyFormatter.formatAmount(amount, config),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: freeText || isDiscount ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSection(BuildContext context, double cartTotal) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        if (walletState is! WalletLoaded) {
          return const SizedBox.shrink();
        }

        final wallet = walletState.wallet;
        final walletBalance = wallet.balance;

        // Don't show if wallet balance is zero
        if (walletBalance <= 0) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<CheckoutBloc, CheckoutState>(
          builder: (context, checkoutState) {
            final useWallet = checkoutState.checkoutData?.useWallet ?? false;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: useWallet ? AppColors.success : AppColors.border,
                  width: useWallet ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: useWallet ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: useWallet ? AppColors.success : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pay with Wallet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            BlocBuilder<AppConfigBloc, AppConfigState>(
                              builder: (context, state) {
                                final config = state is AppConfigLoaded ? state.config : null;
                                return Text(
                                  'Balance: ${CurrencyFormatter.formatAmount(walletBalance, config?.currencyConfig)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: useWallet ? AppColors.success : AppColors.textSecondary,
                                    fontWeight: useWallet ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: useWallet,
                        onChanged: (value) {
                          // Validate payment method
                          final paymentMethod = checkoutState.checkoutData?.selectedPaymentMethod;
                          if (value && paymentMethod != null && paymentMethod.isCOD) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallet cannot be used with Cash on Delivery'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          context.read<CheckoutBloc>().add(ToggleWallet(value));
                        },
                        activeThumbColor: AppColors.success,
                      ),
                    ],
                  ),
                  if (useWallet) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: BlocBuilder<AppConfigBloc, AppConfigState>(
                        builder: (context, state) {
                          final config = state is AppConfigLoaded ? state.config : null;
                          final walletPayment = walletBalance >= cartTotal ? cartTotal : walletBalance;
                          final remainingAmount = cartTotal - walletPayment;

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Wallet Payment',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatAmount(walletPayment, config?.currencyConfig),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              if (remainingAmount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Remaining Amount',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatAmount(remainingAmount, config?.currencyConfig),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrescriptionUploadSection(Cart cart) {
    final hasRxItem = cart.items.any((item) => item.isPrescriptionRequired);
    if (!hasRxItem) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _prescriptionImagePath != null ? AppColors.success : const Color(0xFFFCA5A5),
          width: _prescriptionImagePath != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctor\'s Prescription Required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _prescriptionImagePath != null
                          ? '✓ Prescription attached successfully'
                          : 'Your cart contains items that require a doctor\'s prescription',
                      style: TextStyle(
                        fontSize: 12,
                        color: _prescriptionImagePath != null ? AppColors.success : const Color(0xFFB91C1C),
                        fontWeight: _prescriptionImagePath != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickPrescriptionImage(),
              icon: Icon(
                _prescriptionImagePath != null ? Icons.check_circle : Icons.camera_alt_outlined,
                color: _prescriptionImagePath != null ? AppColors.success : const Color(0xFFDC2626),
              ),
              label: Text(
                _prescriptionImagePath != null ? 'Change Uploaded Prescription' : 'Upload Doctor\'s Prescription (Camera / Gallery)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _prescriptionImagePath != null ? AppColors.success : const Color(0xFFDC2626),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _prescriptionImagePath != null ? AppColors.success : const Color(0xFFDC2626),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky bar shown to guest users — their cart items are fully visible and
  /// editable, but checkout requires authentication.
  Widget _buildGuestCheckoutBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your cart is saved. Login to place your order.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Login / Register buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push(Routes.register),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.push(Routes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Login to Checkout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyPaymentBar(BuildContext context, dynamic summary) {
    // Guest users see a "Login to checkout" bar instead of the full payment
    // bar.  They can still browse and manage their cart — only checkout is
    // gated behind authentication.
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return _buildGuestCheckoutBar(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Address Section
            BlocBuilder<address_bloc.AddressBloc, address_bloc.AddressState>(
              builder: (context, state) {
                if (state.addresses.isNotEmpty) {
                  Address? selectedAddress;
                  
                  // Auto-select default address if available and no address is selected yet
                  if (_selectedAddressId == null) {
                    // Try to find default address, otherwise use first
                    try {
                      selectedAddress = state.addresses.firstWhere(
                        (a) => a.isDefault,
                      );
                    } catch (e) {
                      selectedAddress = state.addresses.first;
                    }
                    _selectedAddressId = selectedAddress.id;
                  } else {
                    // Find the selected address
                    try {
                      selectedAddress = state.addresses.firstWhere(
                        (a) => a.id == _selectedAddressId,
                      );
                    } catch (e) {
                      // If selected address not found, use first address
                      selectedAddress = state.addresses.first;
                      _selectedAddressId = selectedAddress.id;
                    }
                  }

                  return InkWell(
                    onTap: () => _showAddressSelector(context, state.addresses),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        border: Border(
                          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.textPrimary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selectedAddress.type} - ${selectedAddress.addressLine1}, ${selectedAddress.city}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                }

                return InkWell(
                  onTap: () {
                    // Navigate to add address form directly
                    final addressBloc = context.read<address_bloc.AddressBloc>();
                    context.push('/addresses/add').then((_) {
                      // Reload addresses after adding
                      addressBloc.add(address_bloc.LoadAddresses());
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      border: Border(
                        bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_location_alt, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add Delivery Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Payment Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<WalletBloc, WalletState>(
                builder: (context, walletState) {
                  return BlocBuilder<CheckoutBloc, CheckoutState>(
                    builder: (context, checkoutState) {
                      final useWallet = checkoutState.checkoutData?.useWallet ?? false;
                      final walletBalance = walletState is WalletLoaded ? walletState.wallet.balance : 0.0;
                      final walletCoversFullAmount = useWallet && walletBalance >= summary.totalWithDelivery;
                      
                      return Row(
                        children: [
                          // Payment Method Selector
                          Expanded(
                            child: InkWell(
                              onTap: walletCoversFullAmount ? null : () => _showPaymentMethodSelector(context),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: walletCoversFullAmount 
                                          ? AppColors.success 
                                          : const Color(0xFFFF6B6B),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      walletCoversFullAmount
                                          ? Icons.account_balance_wallet
                                          : (_selectedPaymentMethod != null 
                                              ? _getPaymentIcon(_selectedPaymentMethod!.type)
                                              : Icons.payment),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'PAYING VIA',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            if (!walletCoversFullAmount) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          walletCoversFullAmount
                                              ? 'Wallet'
                                              : (_selectedPaymentMethod?.name ?? 'Select Payment'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Pay Button
                          Expanded(
                            child: BlocBuilder<CheckoutBloc, CheckoutState>(
                              builder: (context, checkoutState) {
                                final isProcessing = checkoutState is CheckoutProcessing || 
                                                   checkoutState is CheckoutPaymentProcessing;
                                
                                return BlocBuilder<WalletBloc, WalletState>(
                                  builder: (context, walletState) {
                                    final useWallet = checkoutState.checkoutData?.useWallet ?? false;
                                    final walletBalance = walletState is WalletLoaded ? walletState.wallet.balance : 0.0;
                                    
                                    // Calculate amount to pay
                                    double amountToPay = summary.totalWithDelivery;
                                    if (useWallet && walletBalance > 0) {
                                      final walletPayment = walletBalance >= summary.totalWithDelivery ? summary.totalWithDelivery : walletBalance;
                                      amountToPay = summary.totalWithDelivery - walletPayment;
                                    }
                                    
                                    return BlocBuilder<AppConfigBloc, AppConfigState>(
                                      builder: (context, state) {
                                        final config = state is AppConfigLoaded ? state.config : null;
                                        
                                        String buttonText;
                                        if (amountToPay == 0) {
                                          buttonText = 'Place Order';
                                        } else {
                                          buttonText = 'Pay ${CurrencyFormatter.formatAmount(amountToPay, config?.currencyConfig)}';
                                        }
                                        
                                        return ElevatedButton(
                                          onPressed: isProcessing
                                              ? null
                                              : () => _handlePayButtonTap(context, useWallet, walletBalance, summary.totalWithDelivery),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE91E63),
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: AppColors.border,
                                            disabledForegroundColor: AppColors.textTertiary,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: isProcessing
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: InAllCartLoader(
                                                    size: 24, 
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  buttonText,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayButtonTap(BuildContext context, bool useWallet, double walletBalance, double cartTotal) {
    // 1. Auth check
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      _showLoginRequiredSheet(context);
      return;
    }

    // 2. Address check
    final addressState = context.read<address_bloc.AddressBloc>().state;
    if (_selectedAddressId == null && addressState.addresses.isNotEmpty) {
      final defaultAddr = addressState.addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressState.addresses.first,
      );
      setState(() {
        _selectedAddressId = defaultAddr.id;
      });
    }
    if (_selectedAddressId == null) {
      if (addressState.addresses.isNotEmpty) {
        _showAddressSelector(context, addressState.addresses);
      } else {
        final addressBloc = context.read<address_bloc.AddressBloc>();
        context.push('/addresses/add').then((_) {
          addressBloc.add(address_bloc.LoadAddresses());
        });
      }
      return;
    }

    // 3. Payment method check (skip if wallet covers full amount)
    final walletCoversFullAmount = useWallet && walletBalance >= cartTotal;
    if (!walletCoversFullAmount && _selectedPaymentMethod == null) {
      _showPaymentMethodSelector(context);
      return;
    }

    // 4. Pre-checkout validation — stock & price drift check.
    //    The CartBloc listener handles the result:
    //    - issues found  → _showCartIssuesSheet
    //    - no issues     → _placeOrder
    context.read<CartBloc>().add(ValidateCartEvent());
  }

  /// Shows a bottom sheet listing stock/price issues found during pre-checkout
  /// validation. The user can either fix the issues or dismiss and continue.
  void _showCartIssuesSheet(BuildContext context, List<Map<String, dynamic>> issues) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Cart Issues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Some items in your cart have issues. Please review before placing your order.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...issues.map((issue) {
              final type = issue['type'] as String? ?? '';
              final name = issue['name'] as String? ?? '';
              final message = issue['message'] as String? ?? '';
              final icon = type == 'out_of_stock'
                  ? Icons.inventory_2_outlined
                  : type == 'price_changed'
                      ? Icons.price_change_outlined
                      : Icons.error_outline;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Review Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Atomic order placement — resolves all required data synchronously and
  /// dispatches a single [PlaceOrderDirectEvent], eliminating the race
  /// condition that existed when firing multiple sequential BLoC events.
  void _placeOrder(BuildContext context) {
    final cartState = context.read<CartBloc>().state;
    final addressState = context.read<address_bloc.AddressBloc>().state;
    final checkoutState = context.read<CheckoutBloc>().state;
    final walletState = context.read<WalletBloc>().state;

    // Resolve selected address.
    if (addressState.addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final hasRxItem = cartState.cart.items.any((item) => item.isPrescriptionRequired);
    if (hasRxItem && _prescriptionImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload Doctor\'s Prescription for prescribed items in your cart.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    late Address selectedAddress;
    try {
      selectedAddress = addressState.addresses.firstWhere(
        (a) => a.id == _selectedAddressId,
      );
    } catch (_) {
      selectedAddress = addressState.addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addressState.addresses.first,
      );
      _selectedAddressId = selectedAddress.id;
    }

    final useWallet = checkoutState.checkoutData?.useWallet ?? false;
    final walletBalance = walletState is WalletLoaded ? walletState.wallet.balance : 0.0;
    final cartTotal = cartState.cart.summary.totalWithDelivery + _driverTip;
    final walletCoversFullAmount = useWallet && walletBalance >= cartTotal;

    // Dispatch a single atomic event — no sequential chaining, no race.
    context.read<CheckoutBloc>().add(PlaceOrderDirectEvent(
      cart: cartState.cart,
      address: selectedAddress,
      paymentMethod: walletCoversFullAmount ? null : _selectedPaymentMethod,
      useWallet: useWallet,
      orderType: _orderType,
      driverTip: _driverTip,
      prescriptionImagePath: _prescriptionImagePath,
      context: context, // needed only for online payment gateway SDK overlays
    ));
  }

  void _showPaymentMethodSelector(BuildContext context) {
    // Auth check — same pattern as pay/address buttons
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      _showLoginRequiredSheet(context);
      return;
    }

    // Get the checkout state before opening the bottom sheet
    final checkoutBloc = context.read<CheckoutBloc>();
    final checkoutState = checkoutBloc.state;
    final walletState = context.read<WalletBloc>().state;
    final useWallet = checkoutState.checkoutData?.useWallet ?? false;
    final walletBalance = walletState is WalletLoaded ? walletState.wallet.balance : 0.0;
    final cartState = context.read<CartBloc>().state;
    final cartTotal = cartState.cart.summary.totalWithDelivery + _driverTip;
    
    // Check if wallet covers full amount
    final walletCoversFullAmount = useWallet && walletBalance >= cartTotal;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        if (checkoutState is CheckoutLoading) {
          return Container(
            padding: const EdgeInsets.all(24),
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // If wallet covers full amount, show wallet payment info
        if (walletCoversFullAmount) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paying with Wallet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your wallet balance covers the full order amount',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          );
        }

        final paymentMethods = checkoutState.paymentMethods.where((m) => m.isEnabled).toList();
        
        // Filter out COD if wallet is being used (partial payment)
        final availableMethods = useWallet 
            ? paymentMethods.where((m) => m.type.toLowerCase() != 'cod').toList()
            : paymentMethods;

        if (availableMethods.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No Payment Methods Available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  useWallet 
                      ? 'Wallet cannot be combined with COD. Please disable wallet or add funds to cover the full amount.'
                      : 'Please contact support to enable payment methods.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (useWallet && walletBalance > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Partial Payment',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (useWallet && walletBalance > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'COD is not available when using wallet for partial payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ...availableMethods.map((method) => _buildPaymentOption(
                method.name,
                _getPaymentIcon(method.type),
                method,
                sheetContext,
              )),
            ],
          ),
        );
      },
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cod':
        return Icons.money;
      case 'razorpay':
        return Icons.payment;
      case 'stripe':
        return Icons.credit_card;
      case 'paystack':
        return Icons.account_balance_wallet;
      case 'flutterwave':
        return Icons.waves;
      case 'phonepe':
        return Icons.phone_android;
      case 'paytm':
        return Icons.wallet;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentOption(String name, IconData icon, PaymentMethodInfo methodInfo, BuildContext sheetContext) {
    final isSelected = _selectedPaymentMethod?.id == methodInfo.id;
    final isCOD = methodInfo.type.toLowerCase() == 'cod';
    
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(name),
      subtitle: isCOD 
          ? const Text('Pay when you receive', style: TextStyle(fontSize: 12))
          : const Text('Pay securely online', style: TextStyle(fontSize: 12)),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: AppColors.success)
          : null,
      onTap: () {
        setState(() {
          // Convert PaymentMethodInfo to PaymentMethod
          _selectedPaymentMethod = PaymentMethod(
            id: methodInfo.id,
            name: methodInfo.name,
            type: methodInfo.type,
            icon: methodInfo.icon,
            isEnabled: methodInfo.isEnabled,
            config: methodInfo.config,
          );
        });
        // Persist last used payment method
        _storage.setLastPaymentMethodId(methodInfo.id.toString());
        Navigator.pop(sheetContext);
      },
    );
  }

  void _showAddressSelector(BuildContext context, List<dynamic> addresses) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      final addressBloc = context.read<address_bloc.AddressBloc>();
                      context.push('/addresses').then((_) {
                        // Reload addresses after managing
                        addressBloc.add(address_bloc.LoadAddresses());
                      });
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Manage'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...addresses.map((address) => ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: Text(address.type),
                subtitle: Text('${address.addressLine1}, ${address.city}'),
                trailing: _selectedAddressId == address.id
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedAddressId = address.id;
                  });
                  Navigator.pop(sheetContext);
                },
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    final addressBloc = context.read<address_bloc.AddressBloc>();
                    context.push('/addresses/add').then((_) {
                      // Reload addresses after adding
                      addressBloc.add(address_bloc.LoadAddresses());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Address'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Good food is always cooking! Go ahead, order some yummy items from the menu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go(Routes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Browse Products',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Animated "Notify Me" button for out-of-stock cart items
class _NotifyButton extends StatefulWidget {
  final String productName;
  const _NotifyButton({required this.productName});

  @override
  State<_NotifyButton> createState() => _NotifyButtonState();
}

class _NotifyButtonState extends State<_NotifyButton>
    with SingleTickerProviderStateMixin {
  bool _notified = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (_notified) return;
    HapticFeedback.lightImpact();
    await _controller.forward();
    await _controller.reverse();
    setState(() => _notified = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You'll be notified when ${widget.productName} is back in stock",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _notified
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _notified ? AppColors.success : AppColors.error.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _notified
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_rounded,
                size: 14,
                color: _notified ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                _notified ? 'Notified' : 'Notify',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _notified ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

