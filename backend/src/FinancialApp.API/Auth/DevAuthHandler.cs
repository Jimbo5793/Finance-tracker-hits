using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace FinancialApp.API.Auth;

public class DevAuthHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder,
    IConfiguration config)
    : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string Scheme = "DevAuth";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var id = config["DevAuth:UserId"] ?? "10000001";
        var claims = new[]
        {
            new Claim("sub", id),
            new Claim(ClaimTypes.NameIdentifier, id),
            new Claim(ClaimTypes.Name, "dev-user")
        };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, Scheme));
        return Task.FromResult(AuthenticateResult.Success(new AuthenticationTicket(principal, Scheme)));
    }
}