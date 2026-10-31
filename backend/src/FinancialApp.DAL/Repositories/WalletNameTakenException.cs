namespace FinancialApp.DAL.Repositories;

/// <summary>The user already has a wallet with this name (caught by the database's unique index).</summary>
public class WalletNameTakenException(string name, Exception inner)
    : Exception($"A wallet called \"{name}\" already exists for this user.", inner);
