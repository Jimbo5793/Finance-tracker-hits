using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface IUserRepository
{
    Task<User?> FindByLoginAsync(string login, CancellationToken ct = default);
}