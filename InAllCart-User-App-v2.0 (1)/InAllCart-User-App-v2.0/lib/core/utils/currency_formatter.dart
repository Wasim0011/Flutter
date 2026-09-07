import '../../features/app_config/domain/entities/app_config.dart';

class CurrencyFormatter {
  final CurrencyConfig config;

  CurrencyFormatter(this.config);

  /// Format amount with currency symbol (static helper)
  static String formatAmount(double amount, CurrencyConfig? config) {
    if (config == null) {
      return '\$${amount.toStringAsFixed(0)}';
    }
    return CurrencyFormatter(config).format(amount);
  }

  /// Format amount with currency symbol
  String format(double amount) {
    return config.formatAmount(amount);
  }

  /// Format amount without currency symbol
  String formatWithoutSymbol(double amount) {
    final decimalSeparator = config.thousandSeparator == ',' ? '.' : ',';

    String formatted = amount.toStringAsFixed(config.decimalPlaces);

    List<String> parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    String result = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = config.thousandSeparator + result;
      }
      result = integerPart[i] + result;
      count++;
    }

    if (config.decimalPlaces > 0 && decimalPart.isNotEmpty) {
      result += decimalSeparator + decimalPart;
    }

    return result;
  }

  /// Get currency symbol
  String get symbol => config.symbol;

  /// Get currency code
  String get currencyCode => config.defaultCurrency;

  /// Format for input fields (no thousand separator)
  String formatForInput(double amount) {
    return amount.toStringAsFixed(config.decimalPlaces);
  }

  /// Parse string to double
  double? parse(String value) {
    try {
      String cleaned = value.replaceAll(config.symbol, '').trim();
      cleaned = cleaned.replaceAll(config.thousandSeparator, '');
      final decimalSeparator = config.thousandSeparator == ',' ? '.' : ',';
      cleaned = cleaned.replaceAll(decimalSeparator, '.');
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Format compact (e.g., 1.2K, 1.5M)
  String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${config.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${config.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}

/// Extension on double for easy currency formatting
extension CurrencyExtension on double {
  String toCurrency(CurrencyConfig config) {
    return CurrencyFormatter(config).format(this);
  }

  String toCurrencyCompact(CurrencyConfig config) {
    return CurrencyFormatter(config).formatCompact(this);
  }
}

/// Extension on String for parsing currency
extension CurrencyStringExtension on String {
  double? parseCurrency(CurrencyConfig config) {
    return CurrencyFormatter(config).parse(this);
  }
}
