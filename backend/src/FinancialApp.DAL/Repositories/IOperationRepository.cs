using FinancialApp.DB.Entities;

namespace FinancialApp.DAL.Repositories;

public interface IOperationRepository
{
    Task<IReadOnlyDictionary<int, decimal>> GetNetByWalletAsync(IReadOnlyCollection<int> walletIds, CancellationToken ct = default);

    /// <summary>
    /// Saves the operation and its audit log entry (for <paramref name="userId"/>) in one transaction:
    /// either both are saved or neither.
    /// </summary>
    Task CreateWithAuditAsync(Operation operation, int userId, CancellationToken ct = default);
    Task<IReadOnlyList<Operation>> GetForUserAsync(
        int userId, int? walletId, string? type, int limit, int offset, CancellationToken ct = default);
}