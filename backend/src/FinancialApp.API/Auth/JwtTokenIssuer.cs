using System.Security.Claims;
using System.Text;
using FinancialApp.BLL.Services;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace FinancialApp.API.Auth;

public class JwtTokenIssuer(IOptions<JwtOptions> options) : ITokenIssuer
{
    public IssuedToken Issue(int userId)
    {
        var o = options.Value;
        if (o.Key.Length < 32)
            throw new InvalidOperationException(
                "Jwt:Key must be at least 32 characters. Set JWT_KEY in .env, or Jwt:Key in user-secrets.");

        var jti = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(o.LifetimeMinutes);

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, jti.ToString()),
            }),
            Issuer = o.Issuer,
            Audience = o.Audience,
            IssuedAt = now,
            NotBefore = now,
            Expires = expires,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(o.Key)), SecurityAlgorithms.HmacSha256),
        };

        return new IssuedToken(new JsonWebTokenHandler().CreateToken(descriptor), jti, expires);
    }
}