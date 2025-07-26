import 'package:flutter/foundation.dart';

class DashboardRefreshProvider extends ChangeNotifier {
  static final DashboardRefreshProvider _instance =
      DashboardRefreshProvider._internal();
  factory DashboardRefreshProvider() => _instance;
  DashboardRefreshProvider._internal();

  void refreshDashboard() {
    notifyListeners();
  }
}
