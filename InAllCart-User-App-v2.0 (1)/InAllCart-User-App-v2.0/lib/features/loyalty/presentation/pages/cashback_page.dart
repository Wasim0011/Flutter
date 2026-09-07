
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../bloc/points_bloc.dart';
import '../bloc/points_event.dart';
import '../bloc/points_state.dart';
import '../../data/models/points_model.dart';
import 'package:intl/intl.dart';

class CashbackPage extends StatefulWidget {
  const CashbackPage({super.key});

  @override
  State<CashbackPage> createState() => _CashbackPageState();
}

class _CashbackPageState extends State<CashbackPage> {
  @override
  void initState() {
    super.initState();
    context.read<PointsBloc>().add(const LoadPoints());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const GlobalAppBar(
        title: 'Cashback',
      ),
      body: BlocConsumer<PointsBloc, PointsState>(
        listener: (context, state) {
          if (state is PointsRedemptionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully redeemed ${state.pointsRedeemed} points!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is PointsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PointsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PointsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<PointsBloc>().add(const LoadPoints());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Balance Card
                      _buildBalanceCard(context, state.points),
                      
                      const SizedBox(height: 24),
                      
                      // Redeem Button
                      if (state.points.availablePoints > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showRedeemDialog(context, state.points),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Redeem to Wallet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // History Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (state.transactions.isEmpty)
                        _buildEmptyHistory()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.transactions.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final transaction = state.transactions[index];
                            final isCredit = transaction.type == 'earned' || transaction.type == 'admin_credit';
                            
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit ? Icons.add : Icons.remove,
                                  color: isCredit ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                transaction.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(transaction.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                '${isCredit ? '+' : ''}${transaction.points}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCredit ? Colors.green : Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, PointsModel points) {
     return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final currencyConfig = configState is AppConfigLoaded
            ? configState.config.currencyConfig
            : null;
        
        final formattedValue = currencyConfig != null
            ? currencyConfig.formatAmount(points.currencyValue)
            : points.currencyValue.toStringAsFixed(0);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Cashback Points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${points.availablePoints} Points',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Value: $formattedValue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, PointsModel pointsModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available: ${pointsModel.availablePoints} Points',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter points to redeem',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final points = int.tryParse(controller.text);
              if (points != null && points > 0) {
                 if (points > pointsModel.availablePoints) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient points')),
                    );
                    return;
                }
                context.read<PointsBloc>().add(RedeemPoints(points));
                Navigator.pop(context); // Close dialog
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Redeem', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
