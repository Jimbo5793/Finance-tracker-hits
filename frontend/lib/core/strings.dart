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
  static const walletNotFound = 'Wallet not found.';
  static const walletNotFoundMessage =
      'It may have been removed, or it is not yours.';
  static const backToWallets = 'Back to wallets';

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
  static const footerIdle = '';
  static const footerSaving = 'Please wait. Saving your wallet.';

  static String walletCreated(String name) => '$name was created successfully.';

  // Record expense
  static const recordExpense = 'Record expense';
  static const recordExpenseSubtitle =
      'Money you spent from one of your wallets.';
  static const fieldWallet = 'Wallet';
  static const fieldAmount = 'Amount';
  static const fieldDate = 'Date';
  static const fieldCategory = 'Category (optional)';
  static const fieldComment = 'Comment (optional)';
  static const hintWallet = 'Select wallet';
  static const hintAmount = 'Enter amount';
  static const hintComment = 'Add a note';
  static const noCategory = 'No category';
  static const helperAmount =
      'How much you spent. More than 0, up to 2 decimal places.';
  static const helperDate = 'Only days of the current month can be picked.';
  static const categoriesFailed =
      'Could not load categories. You can still save without one.';
  static const errorWalletRequired = 'Choose a wallet.';
  static const errorAmountRequired = 'Enter an amount.';
  static const errorAmountInvalid =
      'Enter a number greater than 0, with up to 2 decimal places.';
  static const noWalletsForExpense =
      'Create a wallet first, then you can record an expense in it.';
  static String expenseRecorded(String amount, String wallet) =>
      'Expense of $amount recorded in $wallet.';

  // Top bar
  static const logOut = 'Log out';

  // Create category form
  static const createCategoryTitle = 'Add Category';
  static const createCategorySubtitle =
      'Group your transactions under a name and an icon.';
  static const fieldCategoryName = 'Name';
  static const hintCategoryName = 'e.g. Food';
  static const fieldCategoryIcon = 'Icon';
  static const fieldCategoryKind = 'Type';
  static const kindExpense = 'Expense';
  static const kindIncome = 'Income';
  static const errorCategoryNameEmpty = 'Enter a category name.';
  static const errorCategoryNameTooLong = 'Use 30 characters or fewer.';
  static const errorCategoryNameTaken = 'This name is already used.';
  static const errorCategoryIconEmpty = 'Pick an icon.';
  static const iconSelect = 'Select icon';
  static const iconSelected = 'Selected icon';
  static const markExpenseMandatory = 'Mark Expense as mandatory';

  // Used by the categories list in the next task
  static const mandatoryLabel = 'Mandatory';
  static const nonMandatoryLabel = 'Non-mandatory';
  static String categoryCreated(String name) => 'Category "$name" added.';

  // Wallet details
  static const currentBalance = 'Current balance';
  static const thisMonth = 'THIS MONTH';
  static const income = 'Income';
  static const expenses = 'Expenses';
  static const operationIncome = 'Income';
  static const operationExpense = 'Expense';
  static const addIncome = 'Add Income';
  static const addExpense = 'Add Expense';
  static const addCategory = 'Add Category';

  // Transactions
  static const transactions = 'Transactions';
  static String transactionsSubtitle(String month, int count) =>
      '$month · $count ${count == 1 ? 'transaction' : 'transactions'}';
  static const searchHint = 'Search';
  static const filterAll = 'All';
  static const colDescription = 'DESCRIPTION';
  static const colCategory = 'CATEGORY';
  static const colDate = 'DATE';
  static const colAmount = 'AMOUNT';
  static const transactionsLoading = 'Loading transactions...';
  static const transactionsEmpty = 'No transactions yet.';
  static const transactionsNoMatch = 'No transactions match your search.';
  static const transactionsError = 'Could not load transactions.';

  // Temporary, until those tasks are built
  static const recordFormComingSoon = 'The record form is the next task.';
  static const logOutComingSoon = 'Log out comes with the login screen.';

    // Login
  static const loginTitle = 'Welcome back';
  static const fieldEmail = 'Email';
  static const fieldPassword = 'Password';
  static const hintEmail = 'you@example.com';
  static const hintPassword = 'Enter your password';
  static const logIn = 'Log in';
  static const loggingIn = 'Logging in...';
  static const noAccount = "Don't have an account?";
  static const register = 'Register';
  static const registerComingSoon = 'Registration is not available yet.';
  static const errorEmailRequired = 'Enter your email.';
  static const errorPasswordRequired = 'Enter your password.';
  static const loginWrongCredentials = 'Incorrect email or password.';
  static const loginUnavailable = 'Could not reach the server. Please try again.';
}
