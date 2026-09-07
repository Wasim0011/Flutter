import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/plugins/plugin_registry.dart';
import '../../../../core/plugins/flutter_plugin.dart';
import '../../../home_header/presentation/bloc/home_header_bloc.dart';
import '../../../home_header/presentation/widgets/header_background.dart';
import '../../../home_header/presentation/widgets/header_tabs.dart';
import '../../../home_header/presentation/widgets/quick_access_cards.dart';
import '../../../home_header/domain/entities/home_header_config.dart';
import '../../../app_content/presentation/bloc/app_content_bloc.dart';
import '../../../app_content/presentation/widgets/app_content_section.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../app_content/domain/usecases/get_app_content.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../../core/utils/bottom_nav_scroll_controller.dart';
import '../../../common/presentation/widgets/no_service_widget.dart';
import '../../../address/presentation/bloc/address_bloc.dart';
import '../../../address/domain/entities/address.dart';
import '../widgets/home_slivers.dart';
import '../widgets/module_buttons_row.dart';
import '../../../../core/widgets/global_search_bar.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../onboarding/presentation/widgets/onboarding_modal_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../popups/domain/services/popup_manager.dart';
import '../../../popups/presentation/widgets/popup_overlay_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  String _address = 'Select Location';
  bool _isLoadingLocation = false;
  int? _selectedTabId;
  DateTime? _lastBackPressTime;

  late final HomeHeaderBloc _homeHeaderBloc;
  late final AppContentBloc _appContentBloc;
  StreamSubscription? _headerStreamSubscription;

  Timer? _backgroundRefreshTimer;
  static const _refreshInterval = Duration(seconds: 30);
  bool _prefetchScheduled = false;

  // Scroll controller for bottom nav hide/show
  late ScrollController _scrollController;

  // Stable background widget — built once so PremiumHeaderDelegate.shouldRebuild
  // can rely on instance identity for the widget while using backgroundUrl/Type
  // for semantic change detection.
  late final Widget _stableHeaderBackground;

  /// Signals to HeaderBackground whether the header is fully collapsed (pinned).
  /// When true, the video decoder is paused to free HW resources for content
  /// videos that appear further down the scroll list.
  late final ValueNotifier<bool> _headerCollapseNotifier;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _homeHeaderBloc = getIt<HomeHeaderBloc>()..add(const LoadHomeHeader());
    _appContentBloc = getIt<AppContentBloc>();

    // Collapse notifier: starts as not-collapsed (header fully expanded).
    _headerCollapseNotifier = ValueNotifier<bool>(false);

    // Build the background BlocBuilder once as a stable widget instance.
    // HeaderBackground internally uses VideoCacheService and handles URL
    // changes via didUpdateWidget — no need to recreate it per state.
    _stableHeaderBackground = _buildHeaderBackground();

    _loadCurrentLocation();
    _startBackgroundRefresh();

    // Setup scroll controller for bottom nav hide/show
    _scrollController = ScrollController();
    BottomNavScrollController().attachToScrollController(_scrollController);

    // Scroll to top when home tab is re-tapped
    BottomNavScrollController().addListener(_onNavControllerChanged);

    // Check & show Onboarding popup over Home Page if first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
      _checkAndShowPopup();
    });

    // Listen to header bloc to sync selected tab and load content
    _headerStreamSubscription = _homeHeaderBloc.stream.listen((state) {
      if (state is HomeHeaderLoaded && mounted) {
        final headerSelectedTabId = state.selectedTab.id;
        // Always sync with header's selected tab
        if (_selectedTabId != headerSelectedTabId) {
          setState(() => _selectedTabId = headerSelectedTabId);
          _appContentBloc.add(LoadAppContent(tabId: headerSelectedTabId));

          // Fix: Reset scroll position to top when switching category tabs
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        }
        _scheduleTabPrefetch(state.config, activeTabId: headerSelectedTabId);
      }
    });

    // Also check current state in case it's already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = _homeHeaderBloc.state;
      if (currentState is HomeHeaderLoaded) {
        final headerSelectedTabId = currentState.selectedTab.id;
        if (_selectedTabId != headerSelectedTabId) {
          setState(() => _selectedTabId = headerSelectedTabId);
          _appContentBloc.add(LoadAppContent(tabId: headerSelectedTabId));

          // Ensure top position on initial load
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        }
        _scheduleTabPrefetch(
          currentState.config,
          activeTabId: headerSelectedTabId,
        );
      }
    });
  }

  bool _hasShownOnboarding = false;

  void _checkAndShowOnboarding() {
    if (!mounted || _hasShownOnboarding) return;
    final storage = getIt<StorageService>();
    final configState = context.read<AppConfigBloc>().state;
    bool enabled = true;
    if (configState is AppConfigLoaded) {
      enabled = configState.config.onboardingEnabled;
    }
    final isCompleted = storage.isOnboardingCompleted();
    debugPrint('[ONBOARDING_POPUP] enabled=$enabled, isCompleted=$isCompleted');

    if (enabled && !isCompleted) {
      _hasShownOnboarding = true;
      OnboardingModalDialog.show(context);
    }
  }

  void _checkAndShowPopup() async {
    if (!mounted) return;
    final storage = getIt<StorageService>();

    // Onboarding is first priority for first-time users.
    // If onboarding is active and not yet completed, skip showing popup.
    final configState = context.read<AppConfigBloc>().state;
    bool onboardingEnabled = true;
    if (configState is AppConfigLoaded) {
      onboardingEnabled = configState.config.onboardingEnabled;
    }
    if (onboardingEnabled && !storage.isOnboardingCompleted()) {
      debugPrint('[POPUP_MANAGER] Onboarding is active for first-time user. Skipping popup.');
      return;
    }

    await storage.incrementAppOpenCount();
    if (!mounted) return;
    final popupManager = getIt<PopupManager>();

    final authState = context.read<AuthBloc>().state;
    final isAuthed = authState is Authenticated;
    final user = isAuthed ? authState.user : null;
    final userData = storage.getUser();
    final isVipUser = userData?['is_vip'] == true || userData?['vip_status'] == 'active';
    final isNewUser = isAuthed && user != null && DateTime.now().difference(user.createdAt).inDays <= 7;
    final lang = storage.getLanguage() ?? 'en';

    final eligiblePopup = await popupManager.evaluateEligiblePopup(
      contextTrigger: PopupContextTrigger.onAppOpen,
      isUserLoggedIn: isAuthed,
      isVipUser: isVipUser,
      isNewUser: isNewUser,
      currentLanguage: lang,
    );

    if (eligiblePopup != null && mounted) {
      await popupManager.recordPopupPresented(eligiblePopup);
      if (mounted) {
        PopupOverlayDialog.show(context, eligiblePopup);
      }
    }
  }

  void _scheduleTabPrefetch(
    HomeHeaderConfig config, {
    required int activeTabId,
  }) {
    if (_prefetchScheduled) return;
    _prefetchScheduled = true;

    final toPrefetch = config.tabs
        .where((t) => t.id != 0 && t.id != activeTabId)
        .take(2)
        .map((t) => t.id)
        .toList();

    if (toPrefetch.isEmpty) return;

    unawaited(() async {
      for (final tabId in toPrefetch) {
        await Future.delayed(const Duration(milliseconds: 250));
        await getIt<GetAppContent>()(tabId: tabId, forceRefresh: false);
      }
    }());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundRefreshTimer?.cancel();
    _headerStreamSubscription?.cancel();
    _headerCollapseNotifier.dispose();
    BottomNavScrollController().removeListener(_onNavControllerChanged);
    _scrollController.dispose();
    _homeHeaderBloc.close();
    _appContentBloc.close();
    super.dispose();
  }

  int _lastScrollToTopCount = 0;

  void _onNavControllerChanged() {
    final count = BottomNavScrollController().scrollToTopCount;
    if (count != _lastScrollToTopCount) {
      _lastScrollToTopCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _prefetchScheduled = false;
      _triggerBackgroundRefresh();
      _startBackgroundRefresh();
    } else if (state == AppLifecycleState.paused) {
      _backgroundRefreshTimer?.cancel();
    }
  }

  void _startBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      _triggerBackgroundRefresh();
    });
  }

  void _triggerBackgroundRefresh() {
    _homeHeaderBloc.add(const LoadHomeHeader(forceRefresh: false));
    if (_selectedTabId != null) {
      _appContentBloc.add(
        LoadAppContent(tabId: _selectedTabId, forceRefresh: false),
      );
    }
    // Refresh app config so admin changes (map provider, currency, etc.) take effect
    getIt<AppConfigBloc>().add(RefreshAppConfig());
  }

  /// Called when the user explicitly changes location.
  /// Force-refreshes everything that is zone-sensitive: app config (currency)
  /// and app content (zone-specific products/prices).
  void _onLocationChanged() {
    // Clear DataSyncService throttle so AppContent fetches fresh ignoring ETag
    getIt<DataSyncService>().clearAll();
    _prefetchScheduled = false;

    // Force-refresh app config — new location means potentially new zone currency
    getIt<AppConfigBloc>().add(RefreshAppConfig());

    // Force-refresh home header and content (zone may show different stores/products)
    _homeHeaderBloc.add(const LoadHomeHeader(forceRefresh: true));
    if (_selectedTabId != null) {
      _appContentBloc.add(
        LoadAppContent(tabId: _selectedTabId, forceRefresh: true),
      );
    }
  }

  Future<void> _loadCurrentLocation() async {
    final storage = getIt<StorageService>();

    if (isLoggedIn) {
      // Show persisted label instantly (even if stale)
      final persisted = storage.getDefaultAddressLabel();
      if (persisted != null && persisted.isNotEmpty) {
        if (mounted) setState(() => _address = persisted);
      } else {
        // No saved address yet — fall back to cached GPS label from guest session
        final cachedGps = storage.getCachedAddressLabel();
        if (cachedGps != null && cachedGps.isNotEmpty) {
          if (mounted) setState(() => _address = cachedGps);
        }
      }
      // Always refresh from API in background — no spinner, no waiting
      _refreshDefaultAddressInBackground(storage);
      return;
    }

    // Guest — use cached GPS label or live GPS
    final cachedLabel = storage.getCachedAddressLabel();
    if (cachedLabel != null && cachedLabel.isNotEmpty) {
      if (mounted) setState(() => _address = cachedLabel);
      _refreshLocationInBackground(storage);
      return;
    }

    // First time guest — GPS with 12s hard cap
    if (mounted) setState(() => _isLoadingLocation = true);
    await Future.any([
      _refreshLocationInBackground(storage),
      Future.delayed(const Duration(seconds: 12)),
    ]);
    if (mounted) setState(() => _isLoadingLocation = false);
  }

  String _addressLabel(Address addr) =>
      [addr.addressLine1, addr.city].where((e) => e.isNotEmpty).join(', ');

  /// Silently re-fetches the default address from API and updates cache if changed.
  void _refreshDefaultAddressInBackground(StorageService storage) {
    _fetchDefaultAddressFromApi().then((addr) async {
      if (!mounted) return;

      if (addr == null) {
        // No saved addresses — refresh GPS location silently so header shows
        // something useful for new users instead of "Select Location"
        final cachedGps = storage.getCachedAddressLabel();
        if (cachedGps == null || cachedGps.isEmpty) {
          _refreshLocationInBackground(storage);
        }
        return;
      }

      final label = _addressLabel(addr);
      final current = storage.getDefaultAddressLabel();
      if (label != current) {
        await storage.setDefaultAddressLabel(label);
        if (addr.latitude != null && addr.longitude != null) {
          await storage.setLocation(
            addr.latitude!,
            addr.longitude!,
            label: label,
          );
        }
        if (mounted) setState(() => _address = label);
        // Location changed — refresh zone-sensitive data (currency, content)
        _onLocationChanged();
      }
    });
  }

  Future<Address?> _fetchDefaultAddressFromApi() async {
    final bloc = getIt<AddressBloc>();
    bloc.add(LoadAddresses());
    try {
      final loaded = await bloc.stream
          .firstWhere((s) => s is AddressLoaded || s is AddressError)
          .timeout(const Duration(seconds: 8));
      if (loaded is AddressLoaded) return _pickDefault(loaded.addresses);
    } finally {
      bloc.close();
    }
    return null;
  }

  Address? _pickDefault(List<Address> addresses) {
    if (addresses.isEmpty) return null;
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.first;
    }
  }

  bool get isLoggedIn => getIt<StorageService>().isLoggedIn;

  Future<void> _refreshLocationInBackground(StorageService storage) async {
    try {
      final locationService = getIt<LocationService>();
      final position = await locationService.getCurrentLocation(
        timeout: const Duration(seconds: 10),
      );

      if (position == null) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
        ].where((e) => e != null && e.isNotEmpty).toList();
        final label = parts.take(2).join(', ');
        final resolvedLabel = label.isNotEmpty ? label : 'Current Location';

        await storage.setLocation(
          position.latitude,
          position.longitude,
          label: resolvedLabel,
        );
        if (mounted) {
          setState(() {
            _address = resolvedLabel;
            _isLoadingLocation = false;
          });
        }
        // Location just resolved — refresh zone-sensitive data (currency, content)
        _onLocationChanged();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleRefresh() async {
    _homeHeaderBloc.add(const LoadHomeHeader(forceRefresh: true));
    if (_selectedTabId != null) {
      _appContentBloc.add(
        LoadAppContent(tabId: _selectedTabId, forceRefresh: true),
      );
    }

    await Future.wait([
      _homeHeaderBloc.stream.firstWhere((state) => state is! HomeHeaderLoading),
      if (_selectedTabId != null)
        _appContentBloc.stream.firstWhere(
          (state) => state is! AppContentLoading,
        ),
    ]);

    await _loadCurrentLocation();
  }

  Future<void> _openLocationPicker() async {
    final storage = getIt<StorageService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final bottomPadding = MediaQuery.of(modalContext).padding.bottom;
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const Text(
                    'Select Delivery Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

              // Option 1: Use Current Location
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                ),
                title: const Text(
                  'Use Current Location',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Using GPS real-time location',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  _refreshLocationInBackground(storage);
                },
              ),

              const Divider(height: 1),

              // Option 2: Set Location from Map
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_outlined, color: Colors.orange, size: 20),
                ),
                title: const Text(
                  'Set Location from Map',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Pick custom coordinates on interactive map',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final savedLoc = storage.getLocation();
                  final uri = savedLoc != null
                      ? Uri(
                          path: Routes.selectLocation,
                          queryParameters: {
                            'lat': savedLoc['lat'].toString(),
                            'lng': savedLoc['lng'].toString(),
                          },
                        ).toString()
                      : Routes.selectLocation;
                  final result = await context.push<Map<String, dynamic>>(uri);
                  if (result != null && mounted) {
                    final label = result['address'] as String? ?? 'Selected Location';
                    setState(() => _address = label);
                    final lat = result['lat'] as double?;
                    final lng = result['lng'] as double?;
                    if (lat != null && lng != null) {
                      await storage.setLocation(lat, lng, label: label);
                      _onLocationChanged();
                    }
                  }
                },
              ),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // Saved Addresses Section (if logged in)
              if (isLoggedIn) ...[
                const Text(
                  'Saved Addresses',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Address>>(
                  future: _loadSavedAddresses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }
                    final addresses = snapshot.data ?? [];
                    if (addresses.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No saved addresses yet.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: addresses.take(4).map((addr) {
                        final label = _addressLabel(addr);
                        final typeName = addr.type.isNotEmpty ? addr.type.toUpperCase() : 'ADDRESS';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            addr.type.toLowerCase() == 'home'
                                ? Icons.home_rounded
                                : (addr.type.toLowerCase() == 'work' ? Icons.work_rounded : Icons.location_on_rounded),
                            color: AppColors.primary,
                            size: 22,
                          ),
                          title: Text(
                            typeName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          subtitle: Text(
                            label,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            Navigator.pop(modalContext);
                            await storage.setDefaultAddressLabel(label);
                            if (addr.latitude != null && addr.longitude != null) {
                              await storage.setLocation(
                                addr.latitude!,
                                addr.longitude!,
                                label: label,
                              );
                            }
                            if (mounted) setState(() => _address = label);
                            _onLocationChanged();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      context.push('/saved-addresses');
                    },
                    icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                    label: const Text('Manage All Saved Addresses'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Future<List<Address>> _loadSavedAddresses() async {
    try {
      final bloc = getIt<AddressBloc>();
      bloc.add(LoadAddresses());
      final state = await bloc.stream
          .firstWhere((s) => s is AddressLoaded || s is AddressError)
          .timeout(const Duration(seconds: 5));
      if (state is AddressLoaded) {
        return state.addresses;
      }
    } catch (_) {}
    return [];
  }

  void _onTabSelected(int? tabId) {
    // This is called when user taps a tab
    // The header bloc will also emit a new state, which the stream listener will pick up
    // So we don't need to do anything here - the stream listener handles it
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _homeHeaderBloc),
          BlocProvider.value(value: _appContentBloc),
        ],
        child: Scaffold(
        body: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            BlocBuilder<HomeHeaderBloc, HomeHeaderState>(
              bloc: _homeHeaderBloc,
              builder: (context, state) {
                // Check for No Service state
                if (state is HomeHeaderLoaded &&
                    state.config.serviceUnavailable) {
                  return SliverFillRemaining(
                    child: NoServiceWidget(
                      onRetry: _handleRefresh,
                      onChangeLocation: _openLocationPicker,
                    ),
                  );
                }

                return BlocBuilder<AppConfigBloc, AppConfigState>(
                  bloc: getIt<AppConfigBloc>(),
                  builder: (context, configState) {
                    bool hasActivePlugins = false;
                    if (configState is AppConfigLoaded) {
                      final activeSlugs = configState.config.pluginsConfig.activeSlugs;
                      hasActivePlugins = PluginRegistry.instance
                          .getActiveModuleButtons(activeSlugs)
                          .isNotEmpty;
                    }

                    final double safeTop = MediaQuery.of(context).padding.top;
                    final double searchHeight = 64.0;

                    bool showTabs = false;
                    if (state is HomeHeaderLoaded) {
                      showTabs =
                          state.config.tabsActive &&
                          state.config.tabs
                              .where((t) => t.hasCategory)
                              .isNotEmpty;
                    }

                    bool isTabsHorizontalStyle = false;

                    if (state is HomeHeaderLoaded) {
                      if (state.config.moduleIconStyle == 'image_and_name') {
                        isTabsHorizontalStyle = false;
                      } else {
                        isTabsHorizontalStyle = state.config.tabsHorizontalStyle;
                      }
                    }

                    bool isImageOnly = false;
                    if (state is HomeHeaderLoaded) {
                      isImageOnly = state.config.moduleIconStyle == 'image_only';
                    }

                    final double tabsHeight = showTabs
                        ? (isTabsHorizontalStyle ? 60.0 : (isImageOnly ? 60.0 : 80.0))
                        : 0.0;
                    final double stickyTabsHeight = tabsHeight;

                    // Module buttons row was previously here (moved to tabs at the end of the list).
                    // We set this to 0.0 so that the spacer above the search bar disappears.
                    final double moduleRowHeight = 0.0;

                    // Minimum pinned header height when collapsed (Search Bar + Sticky Tabs)
                    final minHeight =
                        safeTop +
                        searchHeight +
                        stickyTabsHeight -
                        (isTabsHorizontalStyle ? 8.0 : 0.0);
                    final headerHeight = _calculateHeaderHeight(
                      context,
                      state,
                      hasActivePlugins,
                    );

                    // height of the locationWidget slot (top bar + optional module row)
                    final double locationWidgetHeight = 60.0 + moduleRowHeight;

                    // Ensure max is never less than min to prevent layout errors (CRASH FIX)
                    final effectiveMaxHeight = headerHeight < minHeight
                        ? minHeight
                        : headerHeight;

                    // Extract background identity for semantic shouldRebuild
                    String? bgUrl;
                    String? bgType;
                    String? topBgType;
                    String? topBgColor1;
                    String? topBgColor2;
                    String? topBgStyle;
                    String? topBgImageUrl;
                    if (state is HomeHeaderLoaded) {
                      final bg = state.selectedTab.background;
                      if (state.config.backgroundActive &&
                          bg?.hasMedia == true) {
                        bgUrl = bg?.url;
                        bgType = bg?.type.name;
                      }

                      final topBg = state.selectedTab.topHeaderBackground;
                      if (topBg != null) {
                        topBgType = topBg.type.name;
                        topBgColor1 = topBg.color1;
                        topBgColor2 = topBg.color2;
                        topBgStyle = topBg.style.name;
                        topBgImageUrl = topBg.imageUrl;
                      }
                    }

                    return SliverPersistentHeader(
                      pinned: true,
                      delegate: PremiumHeaderDelegate(
                        minHeight: minHeight,
                        maxHeight: effectiveMaxHeight,
                        locationHeight: locationWidgetHeight,
                        topHeaderBackgroundWidget: _buildTopHeaderBackground(state),
                        backgroundWidget: _stableHeaderBackground,
                        topBgType: topBgType,
                        topBgColor1: topBgColor1,
                        topBgColor2: topBgColor2,
                        topBgStyle: topBgStyle,
                        topBgImageUrl: topBgImageUrl,
                        backgroundUrl: bgUrl,
                        backgroundType: bgType,
                        headerCollapseNotifier: _headerCollapseNotifier,
                        selectedTabId: state is HomeHeaderLoaded
                            ? state.selectedTab.id
                            : null,
                        locationWidget: SizedBox(
                          height: locationWidgetHeight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 60,
                                child: _buildTopBar(context, true),
                              ),
                            ],
                          ),
                        ),
                        searchBarWidget: const SizedBox(
                          height: 60,
                          child: GlobalSearchBar(
                            hasBackground: true,
                            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
                          ),
                        ),
                        tabsBuilder: (isCompact) => _buildHeaderTabs(
                          context,
                          state,
                          isCompact,
                          hasActivePlugins,
                        ),
                        cardsWidget: _buildHeaderCards(context, state),
                        tabsAboveSearch: isTabsHorizontalStyle,
                        tabsHeight: tabsHeight,
                        isCardsHorizontal: state is HomeHeaderLoaded
                            ? state.selectedTab.cardsHorizontal
                            : false,
                        stickyHeaderColor: state is HomeHeaderLoaded
                            ? (_parseColor(
                                    state.selectedTab.stickyHeaderColor,
                                  ) ??
                                  const Color(0xFFE5E7EB))
                            : const Color(0xFFE5E7EB),
                      ),
                    );
                  },
                );
              },
            ),

            // Dynamic App Content (replaces static categories/products)
            // Top spacer so the first content widget isn't hidden behind the bleeding background video
            const SliverToBoxAdapter(child: SizedBox(height: 58)),
            AppContentSection(tabId: _selectedTabId, onLinkTap: _handleLinkTap),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    ),
    );
  }

  void _handleCardTap(HomeHeaderCard card) {
    switch (card.linkType) {
      case CardLinkType.category:
        if (card.linkId != null) {
          context.push(Routes.category(card.linkId.toString()));
        }
        break;
      case CardLinkType.product:
        if (card.linkId != null) {
          context.push(Routes.product(card.linkId.toString()));
        }
        break;
      case CardLinkType.store:
        if (card.linkId != null) {
          context.push(Routes.store(card.linkId.toString()));
        }
        break;
      case CardLinkType.url:
        if (card.linkUrl != null && card.linkUrl!.isNotEmpty) {
          final uri = Uri.tryParse(card.linkUrl!);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
    }
  }

  void _handleLinkTap(
    ContentLinkType type,
    int? id,
    String? url, {
    dynamic extra,
  }) {
    switch (type) {
      case ContentLinkType.product:
        if (id != null) {
          context.push(Routes.product(id.toString()), extra: extra);
        }
        break;
      case ContentLinkType.category:
        if (id != null) {
          context.push(Routes.category(id.toString()));
        }
        break;
      case ContentLinkType.brand:
        if (id != null) {
          // Navigate to products filtered by brand
          context.push('/products?brand=$id');
        }
        break;
      case ContentLinkType.store:
        if (id != null) {
          context.push(Routes.store(id.toString()), extra: extra);
        }
        break;
      case ContentLinkType.url:
        if (url != null && url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
      case ContentLinkType.none:
        break;
    }
  }

  Widget _buildTopBar(BuildContext context, bool hasBackground) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          // Location selector
          Expanded(
            child: GestureDetector(
              onTap: _openLocationPicker,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasBackground
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: hasBackground ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deliver to',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasBackground
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: _isLoadingLocation
                                  ? Text(
                                      'Getting location...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: hasBackground
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    )
                                  : Text(
                                      _address,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: hasBackground
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: hasBackground
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification bell
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: hasBackground ? Colors.white : AppColors.textPrimary,
                ),
                if (getIt<StorageService>().getUnreadNotificationCount() > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE91E63),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push(Routes.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    // This widget is created ONCE in initState and stored in _stableHeaderBackground.
    // HeaderBackground's didUpdateWidget handles URL changes internally;
    // no need to recreate the widget on every BLoC state change.
    return BlocBuilder<HomeHeaderBloc, HomeHeaderState>(
      bloc: _homeHeaderBloc,
      buildWhen: (prev, curr) {
        // Only rebuild when the background URL or type actually changes
        if (prev is HomeHeaderLoaded && curr is HomeHeaderLoaded) {
          return prev.selectedTab.background?.url !=
                  curr.selectedTab.background?.url ||
              prev.selectedTab.background?.type !=
                  curr.selectedTab.background?.type ||
              prev.config.backgroundActive != curr.config.backgroundActive;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        if (state is HomeHeaderLoaded) {
          final config = state.config;
          final selectedTab = state.selectedTab;
          final hasBackground =
              config.backgroundActive &&
              selectedTab.background?.hasMedia == true;

          if (hasBackground) {
            return HeaderBackground(
              background: selectedTab.background!,
              extendBelowCards: true,
              isCollapsed: _headerCollapseNotifier,
            );
          }
        }

        // Default gradient
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeaderBackground(HomeHeaderState state) {
    TopHeaderBackground? topBg;
    if (state is HomeHeaderLoaded) {
      topBg = state.selectedTab.topHeaderBackground;
      if (topBg == null || (topBg.color1 == null && topBg.imageUrl == null)) {
        for (final tab in state.config.tabs) {
          if (tab.topHeaderBackground != null && (tab.topHeaderBackground!.color1 != null || tab.topHeaderBackground!.imageUrl != null)) {
            topBg = tab.topHeaderBackground;
            break;
          }
        }
      }
    }

    final c1 = (topBg != null && topBg.color1 != null && topBg.color1!.isNotEmpty)
        ? (_parseHexColor(topBg.color1) ?? AppColors.primary)
        : AppColors.primary;

    final c2 = (topBg != null && topBg.color2 != null && topBg.color2!.isNotEmpty)
        ? (_parseHexColor(topBg.color2) ?? AppColors.primaryDark)
        : AppColors.primaryDark;

    if (topBg != null &&
        topBg.type == TopHeaderBgType.image &&
        topBg.imageUrl != null &&
        topBg.imageUrl!.isNotEmpty) {
      return CachedImage(
        imageUrl: topBg.imageUrl!,
        fit: BoxFit.cover,
      );
    }

    if (topBg != null && topBg.type == TopHeaderBgType.solid) {
      return Container(color: c1);
    }

    // 2-Color Linear Gradient with 8 Directional Styles
    Alignment begin = Alignment.topCenter;
    Alignment end = Alignment.bottomCenter;

    if (topBg != null) {
      switch (topBg.style) {
        case GradientStyle.bottomToTop:
          begin = Alignment.bottomCenter;
          end = Alignment.topCenter;
          break;
        case GradientStyle.leftToRight:
          begin = Alignment.centerLeft;
          end = Alignment.centerRight;
          break;
        case GradientStyle.rightToLeft:
          begin = Alignment.centerRight;
          end = Alignment.centerLeft;
          break;
        case GradientStyle.topLeftToBottomRight:
        case GradientStyle.diagonal:
          begin = Alignment.topLeft;
          end = Alignment.bottomRight;
          break;
        case GradientStyle.bottomRightToTopLeft:
          begin = Alignment.bottomRight;
          end = Alignment.topLeft;
          break;
        case GradientStyle.topRightToBottomLeft:
          begin = Alignment.topRight;
          end = Alignment.bottomLeft;
          break;
        case GradientStyle.bottomLeftToTopRight:
          begin = Alignment.bottomLeft;
          end = Alignment.topRight;
          break;
        case GradientStyle.topToBottom:
          begin = Alignment.topCenter;
          end = Alignment.bottomCenter;
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [c1, c2],
        ),
      ),
    );
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      String clean = hex.replaceFirst('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return null;
    }
  }

  double _getCardsHeight(BuildContext context, HomeHeaderState state) {
    if (state is! HomeHeaderLoaded) return 0.0;

    final config = state.config;
    final selectedTab = state.selectedTab;

    if (!config.cardsActive || !selectedTab.hasCards) return 0.0;

    if (selectedTab.cardsHorizontal) {
      return 115.0 + 16.0; // card height (115) + bottom spacing
    } else {
      // Grid Calculation
      final cardsCount = selectedTab.gridDisplayCards.length;
      if (cardsCount > 0) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth =
            (screenWidth - 32 - 2 * 10) / 3; // (Screen - Padding - Spacing) / 3

        if (cardsCount <= 3) {
          return cardWidth + 16.0; // 1 row + bottom spacing
        } else {
          return (cardWidth * 2) + 10.0 + 16.0; // 2 rows + mainAxisSpacing + bottom spacing
        }
      }
    }
    return 0.0;
  }

  double _calculateHeaderHeight(
    BuildContext context,
    HomeHeaderState state,
    bool hasActivePlugins,
  ) {
    double height =
        60.0 +
        64.0 +
        MediaQuery.of(context).padding.top; // Location + Search + SafeTop

    // Add module buttons row height when any plugin module is active
    if (hasActivePlugins) {
      height += kModuleButtonsRowHeight;
    }

    if (state is! HomeHeaderLoaded) return height;

    final config = state.config;

    // Add Tabs height
    if (config.tabsActive &&
        config.tabs.where((t) => t.hasCategory).isNotEmpty) {
      height += config.tabsHorizontalStyle ? 60.0 : 74.0;
    }

    // Add Cards height
    height += _getCardsHeight(context, state);

    // Add extra padding at bottom (sits below the cards, above the content)
    // Extra offset matches cardsBottom shift in PremiumHeaderDelegate:
    // grid: -24 (20px below original +4), horizontal: -44 (40px below original +4)
    final bool isHorizontalCards = config.cardsActive &&
        state.selectedTab.hasCards &&
        state.selectedTab.cardsHorizontal;
    height += 32.0 + (isHorizontalCards ? 40.0 : 20.0);

    // Adjust height matching the shifts applied in PremiumHeaderDelegate
    if (config.tabsActive && config.tabsHorizontalStyle) {
      height -= 8.0; // Search shift (tabs-above-search mode)
    }
    // No further subtractions — cards are bottom-anchored, no internal offsets

    return height;
  }

  /// Returns true when at least one plugin module button should be shown.
  /// Reads directly from the current AppConfigBloc state — no rebuild triggered here.

  Widget _buildHeaderTabs(
    BuildContext context,
    HomeHeaderState state,
    bool isCompact,
    bool hasActivePlugins,
  ) {
    if (state is! HomeHeaderLoaded || !state.config.tabsActive) {
      return const SizedBox.shrink();
    }

    // Get active plugin header tabs from the registry
    final configState = getIt<AppConfigBloc>().state;
    List<PluginHeaderTab> pluginTabs = [];
    if (configState is AppConfigLoaded) {
      final activeSlugs = configState.config.pluginsConfig.activeSlugs;
      final moduleIcons = configState.config.pluginsConfig.moduleIcons;
      pluginTabs = PluginRegistry.instance.getActiveHeaderTabs(activeSlugs, moduleIcons);
    }

    return HeaderTabs(
      tabs: state.config.tabs,
      selectedTabId: state.selectedTab.id,
      isCompact: isCompact,
      isHorizontalStyle: state.config.tabsHorizontalStyle,
      moduleIconStyle: state.config.moduleIconStyle,
      onTabSelected: (tabId) {
        _homeHeaderBloc.add(SelectTab(tabId));
        _onTabSelected(tabId);
      },
      pluginTabs: pluginTabs,
    );
  }

  Widget _buildHeaderCards(BuildContext context, HomeHeaderState state) {
    if (state is! HomeHeaderLoaded ||
        !state.config.cardsActive ||
        !state.selectedTab.hasCards) {
      return const SizedBox.shrink();
    }

    return QuickAccessCards(
      cards: state.selectedTab.cardsHorizontal
          ? state.selectedTab.displayCards
          : state.selectedTab.gridDisplayCards,
      isHorizontal: state.selectedTab.cardsHorizontal,
      onCardTap: _handleCardTap,
    );
  }

  Color? _parseColor(String? hexCode) {
    if (hexCode == null || hexCode.isEmpty) return null;
    try {
      return Color(int.parse(hexCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }
}
