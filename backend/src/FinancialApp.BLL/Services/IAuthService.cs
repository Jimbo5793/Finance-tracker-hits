using FinancialApp.BLL.Models;

namespace FinancialApp.BLL.Services;

public interface IAuthService
{
    Task<LoginResult> LoginAsync(LoginRequest request, CancellationToken ct = default);
}