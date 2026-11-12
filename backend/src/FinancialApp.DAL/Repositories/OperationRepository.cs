using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.DAL.Repositories;

public class OperationRepository(AppDbContext db) : IOperationRepository
{
    public async Task<IReadOnlyDictionary<int, decimal>> GetNetByWalletAsync(
        IReadOnlyCollection<int> walletIds, CancellationToken ct = default)
    {
        var ids = walletIds.ToArray();

        var rows = await db.Operations.AsNoTracking()
            .Where(o => ids.Contains(o.WalletId))
            .GroupBy(o => o.WalletId)
            .Select(g => new
            {
                WalletId = g.Key,
                Net = g.Sum(o => o.Type == OperationTypes.Income ? o.Amount : -o.Amount)
            })
            .ToListAsync(ct);

        return rows.ToDictionary(r => r.WalletId, r => r.Net);
    }
}