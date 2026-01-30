
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navProvider = StateProvider<int>((ref) => 0);

class NavIndex {
  static const int dashboard = 0;
  static const int orderList = 1;
  static const int customers = 2;
  static const int ledger = 3;
  static const int outstanding = 4;
}
