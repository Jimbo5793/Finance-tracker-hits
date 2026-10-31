using FinancialApp.BLL.Models;

namespace FinancialApp.BLL.Services;

public interface IWalletService
{
    Task<IReadOnlyList<WalletDto>> GetForUserAsync(int userId, CancellationToken ct = default);

    Task<CreateWalletResult> CreateAsync(int userId, CreateWalletRequest request, CancellationToken ct = default);
}
