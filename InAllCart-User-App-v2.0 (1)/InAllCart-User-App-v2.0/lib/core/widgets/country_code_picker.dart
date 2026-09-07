import 'dart:convert';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class Country {
  final String name;
  final String flag;
  final String code; // e.g. "+91"
  final String iso;  // e.g. "IN"

  const Country(this.name, this.flag, this.code, this.iso);
}

const List<Country> kCountries = [
  Country('India', '🇮🇳', '+91', 'IN'),
  Country('United States', '🇺🇸', '+1', 'US'),
  Country('United Kingdom', '🇬🇧', '+44', 'GB'),
  Country('United Arab Emirates', '🇦🇪', '+971', 'AE'),
  Country('Saudi Arabia', '🇸🇦', '+966', 'SA'),
  Country('Canada', '🇨🇦', '+1', 'CA'),
  Country('Australia', '🇦🇺', '+61', 'AU'),
  Country('Germany', '🇩🇪', '+49', 'DE'),
  Country('France', '🇫🇷', '+33', 'FR'),
  Country('Singapore', '🇸🇬', '+65', 'SG'),
  Country('Malaysia', '🇲🇾', '+60', 'MY'),
  Country('Bangladesh', '🇧🇩', '+880', 'BD'),
  Country('Pakistan', '🇵🇰', '+92', 'PK'),
  Country('Nepal', '🇳🇵', '+977', 'NP'),
  Country('Sri Lanka', '🇱🇰', '+94', 'LK'),
  Country('Indonesia', '🇮🇩', '+62', 'ID'),
  Country('Philippines', '🇵🇭', '+63', 'PH'),
  Country('Thailand', '🇹🇭', '+66', 'TH'),
  Country('Vietnam', '🇻🇳', '+84', 'VN'),
  Country('South Africa', '🇿🇦', '+27', 'ZA'),
  Country('Nigeria', '🇳🇬', '+234', 'NG'),
  Country('Kenya', '🇰🇪', '+254', 'KE'),
  Country('Brazil', '🇧🇷', '+55', 'BR'),
  Country('Mexico', '🇲🇽', '+52', 'MX'),
  Country('Japan', '🇯🇵', '+81', 'JP'),
  Country('China', '🇨🇳', '+86', 'CN'),
  Country('South Korea', '🇰🇷', '+82', 'KR'),
  Country('Russia', '🇷🇺', '+7', 'RU'),
  Country('Turkey', '🇹🇷', '+90', 'TR'),
  Country('Egypt', '🇪🇬', '+20', 'EG'),
  Country('Qatar', '🇶🇦', '+974', 'QA'),
  Country('Kuwait', '🇰🇼', '+965', 'KW'),
  Country('Bahrain', '🇧🇭', '+973', 'BH'),
  Country('Oman', '🇴🇲', '+968', 'OM'),
  Country('Jordan', '🇯🇴', '+962', 'JO'),
  Country('Lebanon', '🇱🇧', '+961', 'LB'),
  Country('New Zealand', '🇳🇿', '+64', 'NZ'),
  Country('Netherlands', '🇳🇱', '+31', 'NL'),
  Country('Sweden', '🇸🇪', '+46', 'SE'),
  Country('Norway', '🇳🇴', '+47', 'NO'),
  Country('Denmark', '🇩🇰', '+45', 'DK'),
  Country('Switzerland', '🇨🇭', '+41', 'CH'),
  Country('Italy', '🇮🇹', '+39', 'IT'),
  Country('Spain', '🇪🇸', '+34', 'ES'),
  Country('Portugal', '🇵🇹', '+351', 'PT'),
  Country('Poland', '🇵🇱', '+48', 'PL'),
  Country('Ukraine', '🇺🇦', '+380', 'UA'),
  Country('Argentina', '🇦🇷', '+54', 'AR'),
  Country('Colombia', '🇨🇴', '+57', 'CO'),
  Country('Chile', '🇨🇱', '+56', 'CL'),
];

/// Auto-detects user country based on device locale settings
Country detectUserCountry() {
  try {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = deviceLocale.countryCode?.toUpperCase();
    if (countryCode != null && countryCode.isNotEmpty) {
      for (final country in kCountries) {
        if (country.iso == countryCode) {
          return country;
        }
      }
    }
  } catch (_) {}

  // Default fallback: India (+91)
  return kCountries.first;
}

void showCountryPickerModal(
  BuildContext context, {
  required ValueChanged<Country> onSelect,
  Country? selectedCountry,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CountryPickerSheet(
      onSelect: onSelect,
      selectedCountry: selectedCountry ?? kCountries.first,
    ),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final ValueChanged<Country> onSelect;
  final Country selectedCountry;

  const _CountryPickerSheet({
    required this.onSelect,
    required this.selectedCountry,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<Country> _filtered = List.from(kCountries);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(kCountries);
      } else {
        _filtered = kCountries.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.code.contains(query) ||
              c.iso.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F0F1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search country or code...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF4F4F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
              itemBuilder: (ctx, idx) {
                final country = _filtered[idx];
                final isSelected = country.iso == widget.selectedCountry.iso;

                return ListTile(
                  leading: Text(country.flag, style: const TextStyle(fontSize: 26)),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : const Color(0xFF0F0F1A),
                    ),
                  ),
                  trailing: Text(
                    country.code,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    widget.onSelect(country);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
