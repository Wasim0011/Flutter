import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../../core/services/payment_gateway_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class TopUpPage extends StatefulWidget {
  final double? prefilledAmount;

  const TopUpPage({
    super.key,
    this.prefilledAmount,
  });

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedGateway;
  List<PaymentMethodInfo> _paymentMethods = [];
  bool _isLoadingMethods = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!.toStringAsFixed(0);
    }
    // Load payment methods after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentMethods();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    if (!mounted) return;
    
    try {
      
      // Use GetIt instead of context.read to avoid provider issues
      final paymentService = getIt<PaymentGatewayService>();
      
      final methods = await paymentService.getPaymentMethods();
      for (var _ in methods) {
      }
      
      // Filter out COD and Bank Transfer for wallet top-up
      final filteredMethods = methods.where((method) {
        final shouldInclude = method.type != 'cod' && 
               method.type != 'bank_transfer' && 
               method.isEnabled;
        return shouldInclude;
      }).toList();

      if (!mounted) return;
      
      setState(() {
        _paymentMethods = filteredMethods;
        _isLoadingMethods = false;
        
        // Auto-select first available gateway
        if (filteredMethods.isNotEmpty) {
          _selectedGateway = filteredMethods.first.id;
        } else {
        }
      });
    } catch (e) {
      
      if (!mounted) return;
      
      setState(() {
        _isLoadingMethods = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment methods: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const GlobalAppBar(
        title: 'Add Money',
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is TopUpInitiated) {
            // Handle payment gateway navigation
            _handlePaymentGateway(context, state);
          }
          
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final wallet = state is WalletLoaded ? state.wallet : null;
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Balance Card
                    if (wallet != null) _buildBalanceCard(wallet.balance),
                    
                    const SizedBox(height: 24),
                    
                    // Amount Input Section
                    _buildAmountSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Gateway Selection
                    _buildPaymentGatewaySection(),
                    
                    const SizedBox(height: 32),
                    
                    // Proceed Button
                    _buildProceedButton(state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencyConfig = configState is AppConfigLoaded 
            ? configState.config.currencyConfig 
            : null;
        
        final formattedBalance = currencyConfig != null
            ? currencyConfig.formatAmount(balance)
            : balance.toStringAsFixed(0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedBalance,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Amount Input
          BlocBuilder<AppConfigBloc, AppConfigState>(
            builder: (context, configState) {
              final currencySymbol = configState is AppConfigLoaded 
                  ? configState.config.currencyConfig.symbol 
                  : '₹';

              return TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: '$currencySymbol ',
                  prefixStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  
                  // Min/max validation - using default values
                  // These can be fetched from backend settings in future enhancement
                  if (amount < 100) {
                    return 'Minimum amount is ${currencySymbol}100';
                  }
                  
                  if (amount > 100000) {
                    return 'Maximum amount is ${currencySymbol}1,00,000';
                  }
                  
                  return null;
                },
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Quick Amount Buttons
          Row(
            children: [
              Expanded(child: _buildQuickAmountChip(500)),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickAmountChip(1000)),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickAmountChip(2000)),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickAmountChip(5000)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int amount) {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencySymbol = configState is AppConfigLoaded 
            ? configState.config.currencyConfig.symbol 
            : '₹';

        return InkWell(
          onTap: () {
            setState(() {
              _amountController.text = amount.toString();
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '$currencySymbol$amount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentGatewaySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingMethods)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_paymentMethods.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No payment methods available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            RadioGroup<String>(
              groupValue: _selectedGateway,
              onChanged: (value) {
                setState(() {
                  _selectedGateway = value;
                });
              },
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paymentMethods.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return RadioListTile<String>(
                    value: method.id,
                    title: Text(
                      method.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProceedButton(WalletState state) {
    final isLoading = state is WalletLoading;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading || _selectedGateway == null
            ? null
            : _handleProceed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _handleProceed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedGateway == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final amount = double.parse(_amountController.text);
    
    // Initiate top-up
    context.read<WalletBloc>().add(
      InitiateTopUp(
        amount: amount,
        paymentGateway: _selectedGateway!,
      ),
    );
  }

  Future<void> _handlePaymentGateway(BuildContext context, TopUpInitiated state) async {
    try {
      // Get payment gateway service from GetIt
      final paymentService = getIt<PaymentGatewayService>();
      
      // Get user info from AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      final user = authState.user;
      
      // Show loading message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing payment...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Process payment based on gateway type
      PaymentSuccessData? successData;
      
      if (_selectedGateway == 'razorpay') {
        // Handle Razorpay payment using gateway_data from backend
        if (state.gatewayData == null) {
          throw Exception('Gateway data not available');
        }
        
        final completer = Completer<PaymentSuccessData?>();
        
        // Create PaymentInitData from the backend response
        final initData = PaymentInitData(
          orderId: 0, // Wallet top-up doesn't have order ID
          paymentId: state.transactionId,
          amount: (state.gatewayData!['amount'] as num).toDouble() / 100, // Convert from paise
          currency: state.gatewayData!['currency'] as String,
          gatewayData: state.gatewayData!,
          success: true,
        );
        
        await paymentService.processRazorpayPayment(
          initData: initData,
          name: user.name,
          email: user.email,
          phone: user.phone ?? '',
          onSuccess: (data) {
            completer.complete(data);
          },
          onError: (error) {
            completer.completeError(error);
          },
        );
        
        successData = await completer.future;
      } else {
        // For other gateways that use WebView, check if we have a payment_url
        if (state.paymentUrl.isEmpty) {
          throw Exception('No payment URL provided by gateway');
        }
        
        // Handle WebView-based payments
        throw Exception('WebView payment gateways not yet implemented for wallet top-up');
      }

      if (successData == null) {
        throw Exception('Payment was cancelled or failed');
      }

      if (!mounted) return;

      // Now we need to complete the top-up on the backend
      // Call the wallet top-up callback endpoint
      
      try {
        final amount = double.parse(_amountController.text);
        
        // Call the backend to complete the top-up
        final response = await getIt<ApiClient>().post(
          '/wallet/top-up/callback',
          data: {
            'transaction_id': successData.paymentId,
            'amount': amount,
            'gateway': _selectedGateway,
            'status': 'success',
            'user_id': user.id,
            // Add Razorpay-specific data
            if (successData.signature != null) 'signature': successData.signature,
            'razorpay_payment_id': successData.paymentId,
            'razorpay_order_id': successData.orderId,
          },
        );
        
        if (response['success'] != true) {
          throw Exception('Failed to complete top-up on backend');
        }
      } catch (e) {
        throw Exception('Payment successful but failed to update wallet. Please contact support.');
      }

      if (!context.mounted) return;

      // Show success and refresh wallet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Wallet updated.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh wallet and go back
      context.read<WalletBloc>().add(const RefreshWallet());
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      if (!context.mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
