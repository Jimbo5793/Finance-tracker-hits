import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/colors.dart';
import '../core/strings.dart';

class Breadcrumb {
  final String label;
  final VoidCallback? onTap;
  const Breadcrumb(this.label, {this.onTap});
}

/// Lets a page tell the top bar something it can't know by itself.
/// For now: the wallet name shown in the breadcrumb of the wallet details.
class ShellController extends ChangeNotifier {
  final Map<int, String> _walletNames = {};

  String? walletName(int id) => _walletNames[id];

  void setWalletName(int id, String name) {
    if (_walletNames[id] == name) return;
    _walletNames[id] = name;
    notifyListeners();
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem(this.label, this.icon, this.path);
}

/// Sidebar entries. Add the Categories screen here later.
const _navItems = [
  _NavItem(AppStrings.navWallets, Icons.account_balance_wallet_outlined, '/wallets'),
];

/// Sidebar + top bar. Built once by the router, every page is shown inside it.
class AppShell extends StatelessWidget {
  final Widget child;
  final String location; // current path, e.g. /wallets/3
  final ShellController controller;
  final VoidCallback onLogOut;

  const AppShell({
    super.key,
    required this.child,
    required this.location,
    required this.controller,
    required this.onLogOut,
  });

  List<Breadcrumb> _breadcrumbs(BuildContext context) {
    final detail = RegExp(r'^/wallets/(\d+)').firstMatch(location);
    if (detail == null) {
      return const [
        Breadcrumb(AppStrings.breadcrumbDashboard),
        Breadcrumb(AppStrings.navWallets),
      ];
    }
    final name = controller.walletName(int.parse(detail.group(1)!)) ?? '';
    return [
      const Breadcrumb(AppStrings.breadcrumbDashboard),
      Breadcrumb(AppStrings.navWallets, onTap: () => context.go('/wallets')),
      Breadcrumb(name),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(location: location),
          Expanded(
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) =>
                      _TopBar(items: _breadcrumbs(context), onLogOut: onLogOut),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every page wraps its content in this: same padding, own scrolling.
class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(56, 40, 56, 40),
      child: child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String location;
  const _Sidebar({required this.location});

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
          for (final item in _navItems)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: _SidebarItem(
                item: item,
                active: location == item.path || location.startsWith('${item.path}/'),
              ),
            ),
          const Spacer(),
          const Divider(
              height: 1, color: AppColors.sidebarDivider, indent: 20, endIndent: 20),
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
                    style: TextStyle(fontSize: 12, color: AppColors.sidebarMutedText),
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
                        style: TextStyle(fontSize: 11, color: AppColors.sidebarMutedText),
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

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  const _SidebarItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.sidebarText : AppColors.sidebarMutedText;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(item.path),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.sidebarActiveItem : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final List<Breadcrumb> items;
  final VoidCallback onLogOut;
  const _TopBar({required this.items, required this.onLogOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 56),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.chevron_right,
                          size: 16, color: AppColors.textMuted),
                    ),
                  Flexible(child: _Crumb(item: items[i], isLast: i == items.length - 1)),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onLogOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.fieldBorder),
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: const Text(AppStrings.logOut),
          ),
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  final Breadcrumb item;
  final bool isLast;
  const _Crumb({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
        color: isLast ? AppColors.textPrimary : AppColors.textSecondary,
      ),
    );
    if (item.onTap == null) return text;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: item.onTap, child: text),
    );
  }
}