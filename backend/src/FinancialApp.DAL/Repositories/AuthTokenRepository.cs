using FinancialApp.DB;
using FinancialApp.DB.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinancialApp.DAL.Repositories;

public class AuthTokenRepository(AppDbContext db) : IAuthTokenRepository
{
    public async Task AddAsync(AuthToken token, CancellationToken ct = default)
    {
        db.AuthTokens.Add(token);
        await db.SaveChangesAsync(ct);
    }
}