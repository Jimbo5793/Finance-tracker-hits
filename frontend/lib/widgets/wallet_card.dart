import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../models/wallet.dart';

const double walletCardWidth = 372;
const double walletCardHeight = 246;

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  const WalletCard({super.key, required this.wallet});

  static final _money = NumberFormat('#,##0.00', 'en_US');

  static String typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return AppStrings.typeCash;
      case 'bank card':
        return AppStrings.typeBankCard;
      case 'paypal':
        return AppStrings.typePayPal;
      case 'e-wallet':
        return AppStrings.typeEWallet;
      case 'savings':
        return AppStrings.typeSavings;
      default:
        // Unknown type: show the backend value with a capital first letter.
        return type.isEmpty ? type : type[0].toUpperCase() + type.substring(1);
    }
  }

  static IconData typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'bank card':
        return Icons.credit_card_outlined;
      case 'paypal':
        return Icons.payment_outlined;
      case 'e-wallet':
        return Icons.smartphone_outlined;
      case 'savings':
        return Icons.savings_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: walletCardWidth,
      height: walletCardHeight,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.iconTile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeIcon(wallet.type),
                  size: 22,
                  color: AppColors.iconTileIcon,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeLabel(wallet.type),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            AppStrings.balance,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  _money.format(wallet.balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                wallet.currency,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.currencyDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.heldIn(wallet.currency),
                style: const TextStyle(
                  fontSize: 12,
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
