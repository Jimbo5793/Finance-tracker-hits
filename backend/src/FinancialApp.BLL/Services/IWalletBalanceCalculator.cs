using FinancialApp.DB.Entities;

namespace FinancialApp.BLL.Services;

public interface IWalletBalanceCalculator
{
    /// <summary>Current balance of each wallet, keyed by wallet id, in the wallet's own currency.</summary>
    Task<IReadOnlyDictionary<int, decimal>> GetBalancesAsync(IReadOnlyCollection<Wallet> wallets, CancellationToken ct = default);
}
