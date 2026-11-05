class AppStrings {
  AppStrings._();

  // App shell
  static const appName = 'Finance Tracker';
  static const workspace = 'WORKSPACE';
  static const navWallets = 'Wallets';
  static const breadcrumbDashboard = 'Dashboard';
  static const userName = 'John Doe';
  static const userSubtitle = 'Personal Finance Tracker';
  static const userInitials = 'JD';

  // Wallets screen
  static const walletsTitle = 'Wallets';
  static const walletsSubtitle = 'Your money, kept in its own currency.';
  static const addWallet = 'Add wallet';

  // Card
  static const balance = 'Balance';
  static String heldIn(String currency) => 'Held in $currency';

  // Wallet types
  static const typeCash = 'Cash';
  static const typeBankCard = 'Bank card';
  static const typePayPal = 'PayPal';
  static const typeEWallet = 'E-wallet';
  static const typeSavings = 'Savings';

  // Loading
  static const loadingWallets = 'Loading your wallets...';

  // Empty
  static const emptyTitle = 'No wallets yet.';
  static const emptyMessage =
      'Add your first wallet to keep its balance in one place.';

  // Error
  static const errorTitle = 'Could not load your wallets.';
  static const errorMessage = 'Please check your connection and try again.';
  static const retry = 'Retry';

  // Temporary, until the create form exists
  static const createFormComingSoon = 'Create wallet form is not built yet.';
}
