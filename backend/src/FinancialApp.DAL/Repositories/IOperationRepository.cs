namespace FinancialApp.DAL.Repositories;

public interface IOperationRepository
{
    Task<IReadOnlyDictionary<int, decimal>> GetNetByWalletAsync(IReadOnlyCollection<int> walletIds, CancellationToken ct = default);
}