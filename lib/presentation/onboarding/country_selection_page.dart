import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/geolocation_service.dart';

/// Stage 1: Country selection with IP detection
class CountrySelectionPage extends StatefulWidget {
  final AppTheme appTheme;
  final CountryInfo? suggestedCountry;
  final Function(CountryInfo) onCountrySelected;

  const CountrySelectionPage({
    super.key,
    required this.appTheme,
    required this.suggestedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<CountrySelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  final GeoLocationService _geoService = GeoLocationService();
  List<CountryInfo> _filteredCountries = [];
  CountryInfo? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _filteredCountries = GeoLocationService.popularCountries;
    _selectedCountry = widget.suggestedCountry;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = _geoService.searchCountries(query);
    });
  }

  void _selectCountry(CountryInfo country) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCountry = country;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = widget.appTheme;

    return Column(
      children: [
        const SizedBox(height: 20),
        // Title
        Text(
          'Where are you from?',
          style: TextStyle(
            color: appTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll customize your experience',
          style: TextStyle(
            color: appTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),

        // Suggested country card (if detected)
        if (widget.suggestedCountry != null) ...[
          _buildSuggestedCountryCard(appTheme),
          const SizedBox(height: 16),
          Text(
            'Or choose from the list',
            style: TextStyle(
              color: appTheme.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Search bar
        _buildSearchBar(appTheme),
        const SizedBox(height: 16),

        // Country list
        Expanded(
          child: _buildCountryList(appTheme),
        ),

        // Continue button
        _buildContinueButton(appTheme),
      ],
    );
  }

  Widget _buildSuggestedCountryCard(AppTheme appTheme) {
    final country = widget.suggestedCountry!;
    final isSelected = _selectedCountry?.code == country.code;

    return GestureDetector(
      onTap: () => _selectCountry(country),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? appTheme.primary.withOpacity(0.2)
                  : appTheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? appTheme.primary
                    : Colors.white.withOpacity(0.15),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? appTheme.primary.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  country.flag,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Location',
                        style: TextStyle(
                          color: appTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        country.name,
                        style: TextStyle(
                          color: appTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppTheme appTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: appTheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: appTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle: TextStyle(color: appTheme.textTertiary),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: appTheme.textTertiary),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _filterCountries,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryList(AppTheme appTheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _filteredCountries.length,
      itemBuilder: (context, index) {
        final country = _filteredCountries[index];
        final isSelected = _selectedCountry?.code == country.code;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _selectCountry(country),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? appTheme.primary.withOpacity(0.15)
                    : appTheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? appTheme.primary
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    country.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      country.name,
                      style: TextStyle(
                        color: appTheme.textPrimary,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: appTheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton(AppTheme appTheme) {
    final isEnabled = _selectedCountry != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.mediumImpact();
                widget.onCountrySelected(_selectedCountry!);
              }
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isEnabled ? appTheme.primary : appTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: appTheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            'Continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEnabled ? Colors.white : appTheme.textTertiary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
