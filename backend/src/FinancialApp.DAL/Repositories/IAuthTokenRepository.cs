using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface IAuthTokenRepository
{
    Task AddAsync(AuthToken token, CancellationToken ct = default);
}