using System.Security.Claims;

namespace FinancialApp.API.Auth;

public static class ClaimsPrincipalExtensions
{
    public static int? GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return int.TryParse(value, out var id) ? id : null;
    }
    public static Guid? GetTokenId(this ClaimsPrincipal user) =>
        Guid.TryParse(user.FindFirstValue("jti"), out var id) ? id : null;
}
