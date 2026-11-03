import 'package:flutter/material.dart';

import '../core/colors.dart';
import 'wallet_card.dart';

/// Grey placeholder shaped like a [WalletCard], shown while loading.
class WalletCardSkeleton extends StatelessWidget {
  const WalletCardSkeleton({super.key});

  Widget _bar(double width, double height, {double radius = 4}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.skeleton,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

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
              _bar(46, 46, radius: 12),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(126, 12),
                  const SizedBox(height: 8),
                  _bar(76, 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          _bar(56, 10),
          const SizedBox(height: 14),
          _bar(160, 29, radius: 6),
          const SizedBox(height: 26),
          _bar(82, 10),
        ],
      ),
    );
  }
}
