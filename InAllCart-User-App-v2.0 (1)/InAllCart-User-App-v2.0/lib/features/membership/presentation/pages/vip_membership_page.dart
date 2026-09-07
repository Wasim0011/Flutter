import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';

class VipMembershipPage extends StatefulWidget {
  const VipMembershipPage({super.key});

  @override
  State<VipMembershipPage> createState() => _VipMembershipPageState();
}

class _VipMembershipPageState extends State<VipMembershipPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _plans = [];
  Map<String, dynamic>? _myStatus;
  bool _isSubscribing = false;

  // Dynamic Theme & Copy Fields from Admin Backend
  String _themeStyle = 'zomato_gold'; // 'zomato_gold' or 'swiggy_one'
  String _badgeText = 'VIP MEMBERSHIP';
  String _subHeaderMotto = 'More Perks. More Moments.';
  String _heroTitle = 'Upgrade your everyday experience with a premium membership built for people who expect more. Save more, earn more and get treated like a VIP every time.';
  Color _primaryColor = const Color(0xFFF97316);
  Color _secondaryColor = const Color(0xFFEA580C);
  String _subHeading = 'Premium benefits. Effortless savings. One membership.';
  String _vipAdvantageTitle = 'Your VIP advantage';
  String _vipAdvantageSubtitle = 'Everything you love, with more value. Four powerful benefits designed to make every order, purchase and support moment feel better.';
  List<dynamic> _perks = [
    {'icon': '🚚', 'title': 'Unlimited Free Delivery', 'desc': 'Skip delivery fees and enjoy your favorites whenever you want, without counting every order.'},
    {'icon': '🏷️', 'title': 'Extra Member Discount', 'desc': 'Unlock exclusive member-only pricing and stack more value into the purchases you already make.'},
    {'icon': '💰', 'title': 'Wallet Cashback', 'desc': 'Get rewarded as you spend. Cashback goes straight to your wallet for your next experience.'},
    {'icon': '⚡', 'title': 'Priority Support', 'desc': 'Need help? VIP members move to the front of the line for faster, more attentive support.'},
  ];
  String _whyVipTitle = 'Why Go VIP?';
  String _whyVipSubtitle = "Because ordinary is overrated. VIP turns everyday spending into a smarter, more rewarding experience. Whether you're ordering in, shopping your favorites or looking for support, your membership keeps giving back.";
  List<dynamic> _highlights = [
    'Designed for frequent users who want maximum value.',
    'Benefits work together to amplify your savings.',
    'One premium membership. A better everyday experience.',
    '✦ Member-only value',
    '✓ More savings',
  ];
  String _upgradeTitle = 'Your upgrade starts here';
  String _upgradeSubtitle = 'Ready to live a little more VIP? Unlock premium benefits and make every experience count.';
  String _footerTagline = 'VIP Membership · Premium experiences, everyday value.';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int _parsePlanId(dynamic val) {
    if (val == null) return 1;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 1;
    return 1;
  }

  double _parsePrice(dynamic val) {
    if (val == null) return 299.0;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 299.0;
    return 299.0;
  }

  Color _parseColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = getIt<ApiClient>();

      // 1. Fetch All Dynamic Page Fields & Copy Texts from Admin Backend
      try {
        final pageResponse = await apiClient.get<Map<String, dynamic>>(
          ApiEndpoints.membershipPage,
          parser: (data) => data['data'] as Map<String, dynamic>,
        );
        _themeStyle = pageResponse['theme_style'] ?? 'zomato_gold';
        _badgeText = pageResponse['badge_text'] ?? _badgeText;
        _subHeaderMotto = pageResponse['sub_header_motto'] ?? _subHeaderMotto;
        _heroTitle = pageResponse['hero_title'] ?? _heroTitle;
        _subHeading = pageResponse['sub_heading'] ?? _subHeading;
        _vipAdvantageTitle = pageResponse['vip_advantage_title'] ?? _vipAdvantageTitle;
        _vipAdvantageSubtitle = pageResponse['vip_advantage_subtitle'] ?? _vipAdvantageSubtitle;
        _whyVipTitle = pageResponse['why_vip_title'] ?? _whyVipTitle;
        _whyVipSubtitle = pageResponse['why_vip_subtitle'] ?? _whyVipSubtitle;
        _upgradeTitle = pageResponse['upgrade_title'] ?? _upgradeTitle;
        _upgradeSubtitle = pageResponse['upgrade_subtitle'] ?? _upgradeSubtitle;
        _footerTagline = pageResponse['footer_tagline'] ?? _footerTagline;

        if (pageResponse['primary_color'] != null) {
          _primaryColor = _parseColor(pageResponse['primary_color'], const Color(0xFFF97316));
        }
        if (pageResponse['secondary_color'] != null) {
          _secondaryColor = _parseColor(pageResponse['secondary_color'], const Color(0xFFEA580C));
        }
        if (pageResponse['perks'] is List && (pageResponse['perks'] as List).isNotEmpty) {
          _perks = pageResponse['perks'];
        }
        if (pageResponse['highlights'] is List && (pageResponse['highlights'] as List).isNotEmpty) {
          _highlights = pageResponse['highlights'];
        }
        if (pageResponse['plans'] is List && (pageResponse['plans'] as List).isNotEmpty) {
          _plans = pageResponse['plans'];
        }
      } catch (_) {}

      // 2. Fetch Plans from plans API endpoint if list is empty
      if (_plans.isEmpty) {
        try {
          final plansResponse = await apiClient.get<Map<String, dynamic>>(
            ApiEndpoints.membershipPlans,
            parser: (data) => data as Map<String, dynamic>,
          );
          _plans = plansResponse['data'] ?? [];
        } catch (_) {
          try {
            final fallbackResponse = await apiClient.get<Map<String, dynamic>>(
              '/api/v1/membership/plans',
              parser: (data) => data as Map<String, dynamic>,
            );
            _plans = fallbackResponse['data'] ?? [];
          } catch (_) {}
        }
      }

      // 3. Guarantee fallback plan if server returns empty list
      if (_plans.isEmpty) {
        _plans = [
          {
            'id': 1,
            'name': 'VIP Membership Plan',
            'price': 299.0,
            'duration_days': 30,
            'badge_icon': '👑',
            'cashback_percentage': 5.0,
            'free_delivery': true,
            'extra_discount_percentage': 5.0,
          }
        ];
      }

      // 4. Fetch User's Active VIP Status (if logged in)
      try {
        final statusResponse = await apiClient.get<Map<String, dynamic>>(
          ApiEndpoints.membershipStatus,
          parser: (data) => data as Map<String, dynamic>,
        );
        _myStatus = statusResponse;
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (e) {
      _plans = [
        {
          'id': 1,
          'name': 'VIP Membership Plan',
          'price': 299.0,
          'duration_days': 30,
          'badge_icon': '👑',
          'cashback_percentage': 5.0,
          'free_delivery': true,
          'extra_discount_percentage': 5.0,
        }
      ];
      setState(() {
        _isLoading = false;
        _error = null;
      });
    }
  }

  Future<void> _subscribeToPlan(int planId, String paymentMethod, {String? transactionReference}) async {
    setState(() => _isSubscribing = true);

    try {
      final apiClient = getIt<ApiClient>();
      final payload = <String, dynamic>{
        'membership_plan_id': planId,
        'payment_method': paymentMethod,
      };
      if (transactionReference != null && transactionReference.isNotEmpty) {
        payload['transaction_reference'] = transactionReference;
      }

      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.membershipSubscribe,
        data: payload,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (mounted) {
        final message = response['message'] ?? 'VIP Membership activated successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('Insufficient')) {
          errorMsg = 'Insufficient wallet balance. Please top up your wallet first.';
        } else if (errorMsg.contains('401') || errorMsg.contains('Unauthenticated')) {
          errorMsg = 'Please log in to your account to subscribe to VIP Membership.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  void _showPaymentSheet(int planId, String planName, double price) {
    final isDark = _themeStyle == 'swiggy_one';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text(
                'Subscribe to $planName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 6),
              Text('₹${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF10B981) : _primaryColor)),
              const SizedBox(height: 4),
              Text('Choose payment method', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600)),
              const SizedBox(height: 24),

              _PaymentOptionTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Pay from Wallet',
                subtitle: 'Deduct ₹${price.toStringAsFixed(2)} from wallet balance',
                color: isDark ? const Color(0xFF10B981) : Colors.orange,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _subscribeToPlan(planId, 'wallet');
                },
              ),
              const SizedBox(height: 12),
              _PaymentOptionTile(
                icon: Icons.credit_card_rounded,
                title: 'Online Payment Gateway',
                subtitle: 'Pay via UPI, Cards, Razorpay, Stripe or Net Banking',
                color: isDark ? Colors.cyan : Colors.blue,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _showGatewaySelectionSheet(planId, planName, price);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showGatewaySelectionSheet(int planId, String planName, double price) {
    final isDark = _themeStyle == 'swiggy_one';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Select Payment Gateway',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Total Amount to Pay: ₹${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF10B981) : _primaryColor)),
              const SizedBox(height: 20),

              _GatewayTile(
                icon: Icons.flash_on_rounded,
                title: 'Razorpay Payment Gateway',
                subtitle: 'UPI, Google Pay, PhonePe, Cards, NetBanking',
                color: Colors.blue.shade700,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPaymentGatewayPage(planId, planName, price, 'razorpay', 'Razorpay Gateway');
                },
              ),
              const SizedBox(height: 10),
              _GatewayTile(
                icon: Icons.credit_card_rounded,
                title: 'Stripe Payment Gateway',
                subtitle: 'International & Domestic Credit / Debit Cards',
                color: Colors.purple.shade600,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPaymentGatewayPage(planId, planName, price, 'stripe', 'Stripe Gateway');
                },
              ),
              const SizedBox(height: 10),
              _GatewayTile(
                icon: Icons.account_balance_rounded,
                title: 'Paytm / PhonePe Direct',
                subtitle: 'Direct Wallet & Fast UPI Checkout',
                color: Colors.cyan.shade700,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPaymentGatewayPage(planId, planName, price, 'phonepe', 'PhonePe / Paytm Gateway');
                },
              ),
              const SizedBox(height: 10),
              _GatewayTile(
                icon: Icons.language_rounded,
                title: 'Standard Online Gateway',
                subtitle: 'Secure Web Gateway Page',
                color: Colors.orange.shade700,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPaymentGatewayPage(planId, planName, price, 'online', 'Online Gateway');
                },
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPaymentGatewayPage(int planId, String planName, double price, String gatewayId, String gatewayTitle) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => VipPaymentGatewayCheckoutPage(
          planId: planId,
          planName: planName,
          price: price,
          gatewayId: gatewayId,
          gatewayTitle: gatewayTitle,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      final txRef = result['transaction_reference'] as String? ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      _subscribeToPlan(planId, gatewayId, transactionReference: txRef);
    }
  }

  void _triggerPrimarySubscription() {
    if (_plans.isNotEmpty) {
      final primaryPlan = _plans.first;
      final planId = _parsePlanId(primaryPlan['id']);
      final planName = primaryPlan['name']?.toString() ?? 'VIP Membership Plan';
      final price = _parsePrice(primaryPlan['price']);
      _showPaymentSheet(planId, planName, price);
    } else {
      _showPaymentSheet(1, 'VIP Membership Plan', 299.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeStyle == 'swiggy_one';
    final isVip = _myStatus != null && _myStatus!['is_vip'] == true;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8F9FA),
      appBar: const GlobalAppBar(
        title: 'VIP Membership',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF10B981) : AppColors.primary))
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
      bottomNavigationBar: (!isVip && !_isLoading) ? _buildStickyBottomActionBar() : null,
    );
  }

  Widget _buildStickyBottomActionBar() {
    final isDark = _themeStyle == 'swiggy_one';
    final primaryPlan = _plans.isNotEmpty ? _plans.first : null;
    final price = _parsePrice(primaryPlan?['price']);
    final planName = primaryPlan?['name']?.toString() ?? 'VIP Membership';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(planName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.grey.shade900)),
                  Text('₹${price.toStringAsFixed(2)} / 30 Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF10B981) : _primaryColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _triggerPrimarySubscription,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF10B981) : _primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF10B981) : _primaryColor).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Buy Now - Upgrade',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    final isDark = _themeStyle == 'swiggy_one';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Failed to load VIP Membership', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _loadData,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(12)),
                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isVip = _myStatus != null && _myStatus!['is_vip'] == true;
    final isDark = _themeStyle == 'swiggy_one';

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          color: isDark ? const Color(0xFF10B981) : _primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                // Render Hero Banner
                if (isDark) _buildSwiggyOneHeroBanner() else _buildZomatoGoldHeroBanner(),

                // Sub Heading Pill Banner
                _buildSubHeadingPill(),

                // Active Membership Status Banner (if active)
                if (isVip) _buildActiveStatusBanner(),

                // VIP Advantage & Perks Section
                _buildVipAdvantageSection(),

                // Why Go VIP Section
                _buildWhyGoVipSection(),

                // Plan Cards with Buy Now Action Buttons
                _buildPlanCards(),

                // Upgrade Footer CTA
                _buildUpgradeFooterSection(),
              ],
            ),
          ),
        ),

        // Loading overlay during subscription
        if (_isSubscribing)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('Activating VIP Membership...', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubHeadingPill() {
    final isDark = _themeStyle == 'swiggy_one';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFFED7AA)),
      ),
      child: Text(
        _subHeading,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF34D399) : const Color(0xFFC2410C),
        ),
      ),
    );
  }

  // Theme 1: Zomato Gold / Crown Premium Hero Banner
  Widget _buildZomatoGoldHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _secondaryColor],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _badgeText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _subHeaderMotto,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.amber.shade200),
          ),
          const SizedBox(height: 12),
          Text(
            _heroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _triggerPrimarySubscription,
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on_rounded, size: 18, color: _primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Buy Now - Upgrade to VIP',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Theme 2: Swiggy One / Modern Sleek Dark Hero Banner
  Widget _buildSwiggyOneHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Text(
              _badgeText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF34D399), letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _subHeaderMotto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF34D399)),
          ),
          const SizedBox(height: 12),
          Text(
            _heroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _triggerPrimarySubscription,
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF0B0F19)),
                    SizedBox(width: 6),
                    Text(
                      'Buy Now - Upgrade to VIP',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0B0F19)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatusBanner() {
    final membership = _myStatus!['membership'] as Map<String, dynamic>?;
    final planName = membership?['plan_name'] ?? 'VIP Member';
    final badge = membership?['badge_icon'] ?? '👑';
    final remainingDays = membership?['remaining_days'] ?? 0;
    final freeDelivRemaining = membership?['free_deliveries_remaining'] ?? 0;
    final cashbackEarned = (membership?['cashback_earned'] ?? 0).toDouble();
    final totalSaved = (membership?['total_discount_saved'] ?? 0).toDouble();
    final isDark = _themeStyle == 'swiggy_one';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF10B981) : Colors.green.shade200),
        boxShadow: [BoxShadow(color: (isDark ? const Color(0xFF10B981) : Colors.green).withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(badge, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(planName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.green.shade200)),
                child: Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.green.shade700, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(icon: Icons.schedule, label: '$remainingDays\nDays Left', color: Colors.orange, isDark: isDark),
              const SizedBox(width: 8),
              _MiniStat(icon: Icons.local_shipping, label: '$freeDelivRemaining\nFree Deliveries', color: Colors.blue, isDark: isDark),
              const SizedBox(width: 8),
              _MiniStat(icon: Icons.monetization_on, label: '₹${cashbackEarned.toStringAsFixed(0)}\nCashback', color: Colors.green, isDark: isDark),
              const SizedBox(width: 8),
              _MiniStat(icon: Icons.savings, label: '₹${totalSaved.toStringAsFixed(0)}\nSaved', color: Colors.purple, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVipAdvantageSection() {
    final isDark = _themeStyle == 'swiggy_one';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_vipAdvantageTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.grey.shade900)),
          const SizedBox(height: 4),
          Text(_vipAdvantageSubtitle, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: _perks.length,
            itemBuilder: (ctx, index) {
              final perk = _perks[index];
              return _PerkCard(
                icon: perk['icon'] ?? '✨',
                title: perk['title'] ?? 'VIP Perk',
                desc: perk['desc'] ?? '',
                isDark: isDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWhyGoVipSection() {
    final isDark = _themeStyle == 'swiggy_one';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_whyVipTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF34D399) : const Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(_whyVipSubtitle, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 14),

          ..._highlights.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: isDark ? const Color(0xFF10B981) : Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(item.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade800))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPlanCards() {
    final isDark = _themeStyle == 'swiggy_one';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Your VIP Membership Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.grey.shade900)),
          const SizedBox(height: 12),
          ..._plans.map<Widget>((plan) {
            final planId = _parsePlanId(plan['id']);
            final name = plan['name']?.toString() ?? 'VIP Membership Plan';
            final price = _parsePrice(plan['price']);
            final durationDays = _parsePlanId(plan['duration_days']);
            final cashback = _parsePrice(plan['cashback_percentage']);
            final freeDelivery = plan['free_delivery'] == true || plan['free_delivery'] == 1 || plan['free_delivery']?.toString() == '1' || plan['free_delivery']?.toString() == 'true';
            final discount = _parsePrice(plan['extra_discount_percentage']);
            final badge = plan['badge_icon']?.toString() ?? '👑';
            final isActive = _myStatus?['is_vip'] == true && _myStatus?['membership']?['plan_id'] == planId;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? Colors.green.shade300 : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(badge, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87))),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                          child: Text('CURRENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: '₹${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF10B981) : _primaryColor)),
                      TextSpan(text: ' / $durationDays Days', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  if (freeDelivery) _PerkRow(icon: Icons.local_shipping, text: 'Unlimited Free Delivery', isDark: isDark),
                  if (cashback > 0) _PerkRow(icon: Icons.monetization_on, text: '${cashback.toStringAsFixed(cashback.truncateToDouble() == cashback ? 0 : 1)}% Wallet Cashback on Every Order', isDark: isDark),
                  if (discount > 0) _PerkRow(icon: Icons.local_offer, text: '${discount.toStringAsFixed(discount.truncateToDouble() == discount ? 0 : 1)}% Extra Member Discount', isDark: isDark),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isActive ? null : () => _showPaymentSheet(planId, name, price),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isActive ? (isDark ? const Color(0xFF1E293B) : Colors.grey.shade300) : (isDark ? const Color(0xFF10B981) : _primaryColor),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isActive ? null : [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF10B981) : _primaryColor).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          isActive ? 'Currently Active Plan' : 'Buy Now - Subscribe VIP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isActive ? Colors.grey.shade500 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUpgradeFooterSection() {
    final isDark = _themeStyle == 'swiggy_one';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFFED7AA)),
      ),
      child: Column(
        children: [
          Text(_upgradeTitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF34D399) : const Color(0xFFC2410C))),
          const SizedBox(height: 6),
          Text(_upgradeSubtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _triggerPrimarySubscription,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10B981) : _primaryColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF10B981) : _primaryColor).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Buy Now - Upgrade to VIP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(_footerTagline, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500)),
        ],
      ),
    );
  }
}

/// Dedicated Payment Gateway Checkout Page (Simulation & Payment Gateway Redirect)
class VipPaymentGatewayCheckoutPage extends StatefulWidget {
  final int planId;
  final String planName;
  final double price;
  final String gatewayId;
  final String gatewayTitle;

  const VipPaymentGatewayCheckoutPage({
    super.key,
    required this.planId,
    required this.planName,
    required this.price,
    required this.gatewayId,
    required this.gatewayTitle,
  });

  @override
  State<VipPaymentGatewayCheckoutPage> createState() => _VipPaymentGatewayCheckoutPageState();
}

class _VipPaymentGatewayCheckoutPageState extends State<VipPaymentGatewayCheckoutPage> {
  bool _isProcessing = false;
  String _selectedMethod = 'upi';

  void _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final txRef = 'TXN-${widget.gatewayId.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
      Navigator.pop(context, {
        'success': true,
        'transaction_reference': txRef,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: GlobalAppBar(
        title: '${widget.gatewayTitle} Checkout',
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                  const SizedBox(height: 20),
                  Text('Connecting to ${widget.gatewayTitle}...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Please do not close or press back', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encrypted Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '256-Bit SSL Encrypted Secure Gateway',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ORDER SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.planName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                                  Text('30 Days VIP Access & Unlimited Perks', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount Payable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('₹${widget.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text('Select Mode on ${widget.gatewayTitle}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),

                  _CheckoutOption(
                    title: 'Google Pay / PhonePe / Paytm / BHIM UPI',
                    subtitle: 'Instant payment via UPI App',
                    icon: Icons.qr_code_scanner_rounded,
                    isSelected: _selectedMethod == 'upi',
                    onTap: () => setState(() => _selectedMethod = 'upi'),
                  ),
                  const SizedBox(height: 10),
                  _CheckoutOption(
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, MasterCard, RuPay, Maestro',
                    icon: Icons.credit_card_rounded,
                    isSelected: _selectedMethod == 'card',
                    onTap: () => setState(() => _selectedMethod = 'card'),
                  ),
                  const SizedBox(height: 10),
                  _CheckoutOption(
                    title: 'Net Banking',
                    subtitle: 'SBI, HDFC, ICICI, Axis & 50+ Banks',
                    icon: Icons.account_balance_rounded,
                    isSelected: _selectedMethod == 'netbanking',
                    onTap: () => setState(() => _selectedMethod = 'netbanking'),
                  ),

                  const SizedBox(height: 32),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _processPayment,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Pay ₹${widget.price.toStringAsFixed(2)} & Activate VIP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CheckoutOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CheckoutOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade700, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GatewayTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _GatewayTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.grey.shade900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _MiniStat({required this.icon, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.9), height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _PerkCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final bool isDark;
  const _PerkCard({required this.icon, required this.title, required this.desc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, height: 1.2)),
        ],
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _PerkRow({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? const Color(0xFF34D399) : Colors.orange.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800))),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey.shade900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
