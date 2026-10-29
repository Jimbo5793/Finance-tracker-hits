using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface ICurrencyRepository
{
    Task<IReadOnlyList<Currency>> GetAllAsync(CancellationToken ct = default);
}