using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.DAL.Repositories;

public class WalletRepository(AppDbContext db) : IWalletRepository
{
    public async Task<IReadOnlyList<Wallet>> GetByUserAsync(int userId, CancellationToken ct = default) =>
        await db.Wallets.AsNoTracking()
            .Where(w => w.UserId == userId)
            .OrderBy(w => w.CreatedAt)
            .ThenBy(w => w.Id) // wallets created in the same transaction share created_at
            .ToListAsync(ct);
}
