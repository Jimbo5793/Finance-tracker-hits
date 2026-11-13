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
    public Task<bool> IsActiveAsync(Guid jti, DateTime nowUtc, CancellationToken ct = default) =>
        db.AuthTokens.AsNoTracking().AnyAsync(t => t.Jti == jti && t.ExpiresAt > nowUtc, ct);

    public async Task DeleteAsync(Guid jti, CancellationToken ct = default) =>
        await db.AuthTokens.Where(t => t.Jti == jti).ExecuteDeleteAsync(ct);
}