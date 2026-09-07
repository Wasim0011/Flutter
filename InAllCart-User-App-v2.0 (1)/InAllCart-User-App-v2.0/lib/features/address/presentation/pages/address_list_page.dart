import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/inallcart_loader.dart';
import '../../domain/entities/address.dart';
import '../bloc/address_bloc.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(LoadAddresses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state is AddressOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          } else if (state is AddressError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Color(0xFF1A1A1A)),
                  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.profile),
                ),
                title: const Text(
                  'Saved Addresses',
                  style: TextStyle(
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
            body: Builder(builder: (context) {
              if (state is AddressLoading && state.addresses.isEmpty) {
                return const Center(child: InAllCartLoader(size: 40, useOverlay: false));
              }
              if (state.addresses.isEmpty) {
                return _EmptyState();
              }
              return _AddressList(state: state);
            }),
          );
        },
      ),
    );
  }
}

// ─── Address List ────────────────────────────────────────────────────────────

class _AddressList extends StatelessWidget {
  final AddressState state;
  const _AddressList({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Section header
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            'YOUR LOCATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF999999),
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Address cards grouped in white container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (int i = 0; i < state.addresses.length; i++) ...[
                _AddressTile(address: state.addresses[i]),
                if (i < state.addresses.length - 1)
                  const Divider(height: 1, indent: 68, color: Color(0xFFF0F0F0)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Add new address
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final bloc = context.read<AddressBloc>();
            context.push('/addresses/add').then((_) => bloc.add(LoadAddresses()));
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Add new address',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCCCCCC), size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Address Tile ─────────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  final Address address;
  const _AddressTile({required this.address});

  IconData get _icon {
    switch (address.type.toLowerCase()) {
      case 'home': return Icons.home_rounded;
      case 'work': return Icons.work_rounded;
      default: return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        final bloc = context.read<AddressBloc>();
        context.push('/addresses/edit/${address.id}').then((_) => bloc.add(LoadAddresses()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 20, color: const Color(0xFF555555)),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.type[0].toUpperCase() + address.type.substring(1),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF777777),
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Action chips
                  Row(
                    children: [
                      _Chip(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final bloc = context.read<AddressBloc>();
                          context.push('/addresses/edit/${address.id}').then((_) => bloc.add(LoadAddresses()));
                        },
                      ),
                      const SizedBox(width: 8),
                      if (!address.isDefault)
                        _Chip(
                          label: 'Set default',
                          icon: Icons.check_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.read<AddressBloc>().add(
                                SetDefaultAddressEvent(address.id));
                          },
                        ),
                      if (!address.isDefault) const SizedBox(width: 8),
                      _Chip(
                        label: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        danger: true,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showDeleteSheet(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Icon
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 26, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              const Text(
                'Remove this address?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                address.addressLine1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF888888), height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.read<AddressBloc>().add(
                            DeleteAddressEvent(address.id));
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : const Color(0xFF555555);
    final bg = danger
        ? AppColors.error.withValues(alpha: 0.07)
        : const Color(0xFFF2F2F2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined,
                        size: 44, color: Color(0xFFAAAAAA)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No saved addresses',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a delivery address to get\nyour orders delivered faster',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final bloc = context.read<AddressBloc>();
              context.push('/addresses/add').then((_) => bloc.add(LoadAddresses()));
            },
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Add Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
