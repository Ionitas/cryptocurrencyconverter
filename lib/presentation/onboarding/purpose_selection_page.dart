import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/onboarding_service.dart';

/// Purpose option data
class PurposeOption {
  final UserPurpose purpose;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const PurposeOption({
    required this.purpose,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// Stage 2: Purpose selection
class PurposeSelectionPage extends StatefulWidget {
  final AppTheme appTheme;
  final Function(UserPurpose) onPurposeSelected;

  const PurposeSelectionPage({
    super.key,
    required this.appTheme,
    required this.onPurposeSelected,
  });

  @override
  State<PurposeSelectionPage> createState() => _PurposeSelectionPageState();
}

class _PurposeSelectionPageState extends State<PurposeSelectionPage>
    with SingleTickerProviderStateMixin {
  UserPurpose? _selectedPurpose;
  late AnimationController _animController;
  late List<Animation<double>> _itemAnimations;

  static const List<PurposeOption> _options = [
    PurposeOption(
      purpose: UserPurpose.financial,
      title: 'Financial',
      subtitle: 'Track expenses, budgeting & money management',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF10B981),
    ),
    PurposeOption(
      purpose: UserPurpose.travel,
      title: 'Travel',
      subtitle: 'Convert currencies while traveling abroad',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF3B82F6),
    ),
    PurposeOption(
      purpose: UserPurpose.investments,
      title: 'Investments',
      subtitle: 'Crypto, stocks & international investments',
      icon: Icons.trending_up_rounded,
      color: Color(0xFFF59E0B),
    ),
    PurposeOption(
      purpose: UserPurpose.other,
      title: 'Other',
      subtitle: 'Just exploring currency conversions',
      icon: Icons.explore_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _itemAnimations = List.generate(
      _options.length,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(
            index * 0.15,
            0.4 + index * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectPurpose(UserPurpose purpose) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPurpose = purpose;
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
          'What brings you here?',
          style: TextStyle(
            color: appTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'We\'ll personalize the app for your needs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Purpose options
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _itemAnimations[index],
                builder: (context, child) {
                  final value = _itemAnimations[index].value;
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildPurposeCard(
                        appTheme,
                        _options[index],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Continue button
        _buildContinueButton(appTheme),
      ],
    );
  }

  Widget _buildPurposeCard(AppTheme appTheme, PurposeOption option) {
    final isSelected = _selectedPurpose == option.purpose;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _selectPurpose(option.purpose),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color.withOpacity(0.15)
                    : appTheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? option.color : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: option.color.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: option.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      option.icon,
                      color: option.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: TextStyle(
                            color: appTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.subtitle,
                          style: TextStyle(
                            color: appTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? option.color : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? option.color
                            : appTheme.textTertiary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(AppTheme appTheme) {
    final isEnabled = _selectedPurpose != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.mediumImpact();
                widget.onPurposeSelected(_selectedPurpose!);
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
