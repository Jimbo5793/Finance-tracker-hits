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

  // Create wallet form
  static const createWalletTitle = 'Create wallet';
  static const createWalletSubtitle =
      'A separate place for a balance in one currency.';

  static const fieldType = 'Type';
  static const fieldName = 'Name (optional)';
  static const fieldCurrency = 'Currency';
  static const fieldStartingBalance = 'Starting balance';

  static const hintType = 'Select type';
  static const hintName = 'Leave blank';
  static const hintCurrency = 'Select currency';
  static const hintBalance = 'Enter amount';
  static const hintCurrenciesLoading = 'Loading currencies...';
  static const hintCurrenciesFailed = 'Could not load. Tap to retry.';

  static const helperName =
      'Leave empty for a backend-generated name, e.g. Cash #1.';
  static const helperNameRules =
      'No whitespace-only names. Maximum 50 characters. Duplicate names are not allowed.';
  static const helperBalance =
      'The amount in your wallet right now. 0 is allowed; use up to 2 decimal places.';

  static const errorTypeRequired = 'Choose a wallet type.';
  static const errorCurrencyRequired = 'Choose a currency.';
  static const errorNameSpaces = 'Name cannot be only spaces.';
  static const errorNameTooLong = 'Name can be at most 50 characters.';
  static const errorBalanceRequired = 'Enter a starting balance.';
  static const errorBalanceInvalid =
      'Enter a number ≥ 0, with up to 2 decimal places.';
  static const saveFailed = 'Could not save. Try again.';

  static const cancel = 'Cancel';
  static const save = 'Save';
  static const saving = 'Saving...';
  static const tryAgain = 'Try again';
  static const footerIdle = 'You can review before saving.';
  static const footerSaving = 'Please wait. Saving your wallet.';

  static String walletCreated(String name) => '$name was created successfully.';
}
