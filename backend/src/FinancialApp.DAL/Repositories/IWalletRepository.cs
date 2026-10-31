using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface IWalletRepository
{
    /// <summary>Wallets of one user, oldest first.</summary>
    Task<IReadOnlyList<Wallet>> GetByUserAsync(int userId, CancellationToken ct = default);
}
