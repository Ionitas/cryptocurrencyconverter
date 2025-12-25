import 'package:flutter/material.dart';

/// Controller for managing dashboard navigation and state
class DashboardController extends ChangeNotifier {
  int _currentIndex = 0;
  late PageController _pageController;

  DashboardController() {
    _pageController = PageController(initialPage: 0);
  }

  int get currentIndex => _currentIndex;
  PageController get pageController => _pageController;

  void switchTab(int index) {
    if (index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
