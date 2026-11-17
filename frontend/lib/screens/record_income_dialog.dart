import 'package:flutter/material.dart';

import '../data/category_repository.dart';
import '../data/operation_repository.dart';
import '../data/wallet_repository.dart';
import '../models/operation.dart';
import '../models/wallet.dart';
import 'record_operation_dialog.dart';

/// The Add Income form. It belongs to one wallet, so there is no wallet field.
/// Completes with the new operation, or null if cancelled.
Future<Operation?> showRecordIncomeDialog(
  BuildContext context, {
  required WalletRepository wallets,
  required CategoryRepository categories,
  required OperationRepository operations,
  Wallet? initialWallet,
  bool chooseWallet = true,
  VoidCallback? onAddWallet,
}) {
  return showRecordOperationDialog(
    context,
    kind: OperationKind.income,
    wallets: wallets,
    categories: categories,
    operations: operations,
    initialWallet: initialWallet,
    chooseWallet: chooseWallet,
    onAddWallet: onAddWallet,
  );
}