using FinancialApp.BLL.Models;
using FinancialApp.DAL.Repositories;
using FinancialApp.DB.Entities;
using Microsoft.AspNetCore.Identity;

namespace FinancialApp.BLL.Services;

public class AuthService(
    IUserRepository users,
    IAuthTokenRepository tokens,
    IPasswordHasher<User> hasher,
    ITokenIssuer issuer) : IAuthService
{
    private static readonly string DummyHash =
        new PasswordHasher<User>().HashPassword(new User(), Guid.NewGuid().ToString());

    public async Task<LoginResult> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var errors = new Dictionary<string, string[]>();
        var username = request.Username?.Trim();
        if (string.IsNullOrEmpty(username)) errors["username"] = ["Username is required."];
        if (string.IsNullOrEmpty(request.Password)) errors["password"] = ["Password is required."];
        if (errors.Count > 0) return LoginResult.Invalid(errors);

        var user = await users.FindByLoginAsync(username!, ct);
        var hash = user?.PasswordHash ?? DummyHash;
        var verification = hasher.VerifyHashedPassword(user ?? new User(), hash, request.Password!);

        if (user?.PasswordHash is null || verification == PasswordVerificationResult.Failed)
            return LoginResult.BadCredentials();

        var issued = issuer.Issue(user.Id);
        await tokens.AddAsync(new AuthToken
        {
            UserId = user.Id,
            Jti = issued.Jti,
            ExpiresAt = issued.ExpiresAt,
        }, ct);

        return LoginResult.Succeeded(new LoginResponse(issued.Token, issued.ExpiresAt));
    }
    public Task<bool> IsTokenActiveAsync(Guid jti, CancellationToken ct = default) =>
        tokens.IsActiveAsync(jti, DateTime.UtcNow, ct);

    public Task LogoutAsync(Guid jti, CancellationToken ct = default) =>
        tokens.DeleteAsync(jti, ct);
}