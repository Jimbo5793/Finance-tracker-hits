using FinancialApp.BLL.Models;
using FinancialApp.DAL.Repositories;

namespace FinancialApp.BLL.Services;

public class WalletService(IWalletRepository repo, IWalletBalanceCalculator balances) : IWalletService
{
    public async Task<IReadOnlyList<WalletDto>> GetForUserAsync(int userId, CancellationToken ct = default)
    {
        var wallets = await repo.GetByUserAsync(userId, ct);
        var balanceById = await balances.GetBalancesAsync(wallets, ct);

        return wallets
            .Select(w => new WalletDto(w.Id, w.Name, w.Type, w.CurrencyCode, balanceById[w.Id]))
            .ToList();
    }
}
