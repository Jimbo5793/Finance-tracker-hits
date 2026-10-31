using FinancialApp.BLL.Models;
using FinancialApp.DAL.Repositories;

namespace FinancialApp.BLL.Services;

public class CurrencyService(ICurrencyRepository repo) : ICurrencyService
{
    public async Task<IReadOnlyList<CurrencyDto>> GetAllAsync(CancellationToken ct = default)
    {
        var items = await repo.GetAllAsync(ct);
        return items.Select(c => new CurrencyDto(c.Code, c.Name, c.Symbol)).ToList();
    }
}