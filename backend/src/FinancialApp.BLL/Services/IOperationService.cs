using FinancialApp.BLL.Models;

namespace FinancialApp.BLL.Services;

public interface IOperationService
{
    Task<CreateOperationResult> CreateAsync(int userId, CreateOperationRequest request, CancellationToken ct = default);
}
