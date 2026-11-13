using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface IAuthTokenRepository
{
    Task AddAsync(AuthToken token, CancellationToken ct = default);
    Task<bool> IsActiveAsync(Guid jti, DateTime nowUtc, CancellationToken ct = default);

    Task DeleteAsync(Guid jti, CancellationToken ct = default);
}