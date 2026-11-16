import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../models/wallet.dart';
import '../utils/money.dart';
import 'primary_button.dart';
import 'secondary_button.dart';
import 'wallet_card.dart';

/// Top card of the wallet details: name, balance, action buttons and this month's totals.
class WalletSummaryCard extends StatelessWidget {
  final Wallet wallet;
  final double monthIncome;
  final double monthExpenses; // a positive number
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onAddCategory;

  const WalletSummaryCard({
    super.key,
    required this.wallet,
    required this.monthIncome,
    required this.monthExpenses,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onAddCategory,
  });

  /// "Cash" -> "Cash wallet", "E-wallet" stays "E-wallet".
  static String _kindLabel(String type) {
    final label = WalletCard.typeLabel(type);
    return label.toLowerCase().endsWith('wallet') ? label : '$label wallet';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final info = _walletInfo();
          final totals = _monthTotals();
          if (box.maxWidth >= 860) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: info),
                const SizedBox(width: 32),
                SizedBox(width: 320, child: totals),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [info, const SizedBox(height: 28), totals],
          );
        },
      ),
    );
  }

  Widget _walletInfo() {
    final negative = wallet.balance < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.iconTile,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                WalletCard.typeIcon(wallet.type),
                size: 26,
                color: AppColors.iconTileIcon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _kindLabel(wallet.type),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          AppStrings.currentBalance,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                formatBalance(wallet.balance),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: negative ? AppColors.expense : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              wallet.currency,
              style: const TextStyle(
                fontSize: 22,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            PrimaryButton(
              label: AppStrings.addIncome,
              icon: Icons.add,
              onPressed: onAddIncome,
            ),
            SecondaryButton(
              label: AppStrings.addExpense,
              icon: Icons.remove,
              iconColor: AppColors.expense,
              onPressed: onAddExpense,
            ),
            SecondaryButton(
              label: AppStrings.addCategory,
              icon: Icons.more_horiz,
              onPressed: onAddCategory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _monthTotals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.thisMonth,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _totalTile(
          icon: Icons.south_west,
          color: AppColors.income,
          tile: AppColors.incomeTile,
          label: AppStrings.income,
          amount: formatSigned(monthIncome),
        ),
        const SizedBox(height: 12),
        _totalTile(
          icon: Icons.north_east,
          color: AppColors.expense,
          tile: AppColors.expenseTile,
          label: AppStrings.expenses,
          amount: formatSigned(-monthExpenses),
        ),
      ],
    );
  }

  Widget _totalTile({
    required IconData icon,
    required Color color,
    required Color tile,
    required String label,
    required String amount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.summaryTile,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: tile, shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                wallet.currency,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
