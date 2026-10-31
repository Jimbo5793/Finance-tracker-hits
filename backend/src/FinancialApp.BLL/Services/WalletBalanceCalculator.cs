using FinancialApp.DB.Entities;

namespace FinancialApp.BLL.Services;

/// <summary>
/// The only place wallet balances are calculated. Anything that shows a balance goes through here.
/// For now the balance is the starting balance. Stories that add money, transfers or operations
/// should change this class (e.g. starting balance + sum of operations), not the callers.
/// </summary>
public class WalletBalanceCalculator : IWalletBalanceCalculator
{
    public Task<IReadOnlyDictionary<int, decimal>> GetBalancesAsync(IReadOnlyCollection<Wallet> wallets, CancellationToken ct = default)
    {
        IReadOnlyDictionary<int, decimal> balances = wallets.ToDictionary(w => w.Id, w => w.StartingBalance);
        return Task.FromResult(balances);
    }
}
