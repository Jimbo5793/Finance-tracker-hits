import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/strings.dart';

/// Sidebar + breadcrumb bar around the page content, as in the design.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: Column(
              children: [
                const _Breadcrumb(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(56, 56, 56, 40),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 36, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.sidebarLogoBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      size: 18, color: AppColors.sidebarLogoIcon),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      color: AppColors.sidebarText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 48, 20, 12),
            child: Text(
              AppStrings.workspace,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.4,
                color: AppColors.sidebarMutedText,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.sidebarActiveItem,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 18, color: AppColors.sidebarText),
                  SizedBox(width: 12),
                  Text(
                    AppStrings.navWallets,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sidebarText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          const Divider(height: 1, color: AppColors.sidebarDivider, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.sidebarAvatar,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    AppStrings.userInitials,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.sidebarMutedText,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.userName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sidebarText,
                        ),
                      ),
                      Text(
                        AppStrings.userSubtitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.sidebarMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 56),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      alignment: Alignment.centerLeft,
      child: const Row(
        children: [
          Text(
            AppStrings.breadcrumbDashboard,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.chevron_right,
                size: 16, color: AppColors.textMuted),
          ),
          Text(
            AppStrings.navWallets,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
