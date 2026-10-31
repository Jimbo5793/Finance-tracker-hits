using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface IWalletRepository
{
    /// <summary>Wallets of one user, oldest first.</summary>
    Task<IReadOnlyList<Wallet>> GetByUserAsync(int userId, CancellationToken ct = default);

    /// <summary>Names of the user's wallets. Case-insensitive, like the database column.</summary>
    Task<IReadOnlySet<string>> GetNamesAsync(int userId, CancellationToken ct = default);

    /// <summary>
    /// Saves the wallet and its audit log entry in one transaction: either both are saved or neither.
    /// Throws <see cref="WalletNameTakenException"/> if the name is already used by this user.
    /// </summary>
    Task CreateWithAuditAsync(Wallet wallet, CancellationToken ct = default);
}
