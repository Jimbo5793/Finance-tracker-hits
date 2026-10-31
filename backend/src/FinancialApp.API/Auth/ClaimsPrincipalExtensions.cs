using System.Security.Claims;

namespace FinancialApp.API.Auth;

public static class ClaimsPrincipalExtensions
{
    /// <summary>
    /// Id of the logged-in user, taken from the token's "sub" claim. Null if it's missing or not a number.
    /// This is the one place that decides who the current user is; change it here when the login story lands.
    /// </summary>
    public static int? GetUserId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return int.TryParse(value, out var id) ? id : null;
    }
}
