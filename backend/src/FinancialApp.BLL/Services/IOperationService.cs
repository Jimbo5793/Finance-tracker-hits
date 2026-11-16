using FinancialApp.BLL.Models;

namespace FinancialApp.BLL.Services;

public interface IOperationService
{
    Task<CreateOperationResult> CreateAsync(int userId, CreateOperationRequest request, CancellationToken ct = default);
    Task<GetOperationsResult> GetAsync(
        int userId, string? walletId, string? type, string? limit, string? offset, CancellationToken ct = default);
}
