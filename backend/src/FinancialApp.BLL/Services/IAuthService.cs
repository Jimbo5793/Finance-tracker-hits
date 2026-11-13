using FinancialApp.BLL.Models;

namespace FinancialApp.BLL.Services;

public interface IAuthService
{
    Task<LoginResult> LoginAsync(LoginRequest request, CancellationToken ct = default);
    Task<bool> IsTokenActiveAsync(Guid jti, CancellationToken ct = default);

    Task LogoutAsync(Guid jti, CancellationToken ct = default);
}