using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.DAL.Repositories;

public class CurrencyRepository(AppDbContext db) : ICurrencyRepository
{
    public async Task<IReadOnlyList<Currency>> GetAllAsync(CancellationToken ct = default) =>
        await db.Currencies.AsNoTracking().OrderBy(c => c.Code).ToListAsync(ct);
}