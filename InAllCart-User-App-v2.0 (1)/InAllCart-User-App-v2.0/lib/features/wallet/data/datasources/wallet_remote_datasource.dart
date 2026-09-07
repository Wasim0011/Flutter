import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet();
  Future<TransactionsResponse> getTransactions({
    int page = 1,
    int perPage = 20,
    String? type,
    String? startDate,
    String? endDate,
  });
  Future<Map<String, dynamic>> initiateTopUp({
    required double amount,
    required String gateway,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient apiClient;

  WalletRemoteDataSourceImpl(this.apiClient);

  @override
  Future<WalletModel> getWallet() async {
    final response = await apiClient.get(ApiEndpoints.wallet);
    return WalletModel.fromJson(response['data']);
  }

  @override
  Future<TransactionsResponse> getTransactions({
    int page = 1,
    int perPage = 20,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (type != null) queryParams['type'] = type;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final response = await apiClient.get(
      ApiEndpoints.walletTransactions,
      queryParameters: queryParams,
    );

    final data = response['data'] as List? ?? [];
    final transactions = data.map((e) => WalletTransactionModel.fromJson(e)).toList();

    final meta = response['meta'] as Map<String, dynamic>? ?? {};

    return TransactionsResponse(
      transactions: transactions,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? 0,
    );
  }

  @override
  Future<Map<String, dynamic>> initiateTopUp({
    required double amount,
    required String gateway,
  }) async {
    final response = await apiClient.post(ApiEndpoints.walletTopUp, data: {
      'amount': amount,
      'gateway': gateway,
    });
    return response['data'] as Map<String, dynamic>;
  }
}

/// Response wrapper for transactions
class TransactionsResponse {
  final List<WalletTransactionModel> transactions;
  final int currentPage;
  final int lastPage;
  final int total;

  TransactionsResponse({
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
