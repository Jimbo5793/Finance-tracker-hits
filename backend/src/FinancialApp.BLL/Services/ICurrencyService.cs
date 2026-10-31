using FinancialApp.BLL.Models;

namespace FinancialApp.BLL.Services;

public interface ICurrencyService
{
    Task<IReadOnlyList<CurrencyDto>> GetAllAsync(CancellationToken ct = default);
}