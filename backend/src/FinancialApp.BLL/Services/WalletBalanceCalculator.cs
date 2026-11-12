using FinancialApp.DAL.Repositories;
using FinancialApp.DB.Entities;

namespace FinancialApp.BLL.Services;

public class WalletBalanceCalculator(IOperationRepository operations) : IWalletBalanceCalculator
{
    public async Task<IReadOnlyDictionary<int, decimal>> GetBalancesAsync(
        IReadOnlyCollection<Wallet> wallets, CancellationToken ct = default)
    {
        if (wallets.Count == 0)
            return new Dictionary<int, decimal>();

        var net = await operations.GetNetByWalletAsync(wallets.Select(w => w.Id).ToArray(), ct);

        return wallets.ToDictionary(w => w.Id, w => w.StartingBalance + net.GetValueOrDefault(w.Id));
    }
}