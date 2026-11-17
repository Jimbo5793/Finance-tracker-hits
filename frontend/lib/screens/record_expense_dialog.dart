import 'package:flutter/material.dart';

import '../data/category_repository.dart';
import '../data/operation_repository.dart';
import '../data/wallet_repository.dart';
import '../models/operation.dart';
import '../models/wallet.dart';
import 'record_operation_dialog.dart';

/// Opens the record expense form. Completes with the new operation, or null if cancelled.
/// [initialWallet] is preselected. [onAddWallet] runs after the form closes when
/// the user has no wallets and presses "Add wallet".
Future<Operation?> showRecordExpenseDialog(
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
    kind: OperationKind.expense,
    wallets: wallets,
    categories: categories,
    operations: operations,
    initialWallet: initialWallet,
    chooseWallet: chooseWallet,
    onAddWallet: onAddWallet,
  );
}
