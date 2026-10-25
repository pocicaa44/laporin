import 'package:flutter/material.dart';

/// Controller untuk mengelola tab navigasi aktif pada [MainNavigationScreen] dan AppDrawer
class NavigationController extends ChangeNotifier {
  NavigationController({int initialIndex = 0}) : _currentIndex = initialIndex;

  int _currentIndex;
  int get currentIndex => _currentIndex;

  /// Mengubah index navigasi aktif
  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Mereset navigasi kembali ke Beranda/Feed (index 0)
  void resetToHome() {
    setIndex(0);
  }
}
