using System.Text;
using FinancialApp.BLL.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace FinancialApp.API.Auth;

public class ConfigureJwtBearer(IOptions<JwtOptions> jwt) : IConfigureNamedOptions<JwtBearerOptions>
{
    public void Configure(string? name, JwtBearerOptions o)
    {
        if (name != JwtBearerDefaults.AuthenticationScheme) return;

        var j = jwt.Value;
        o.MapInboundClaims = false; // claims keep their raw names: "sub", "jti"
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = j.Issuer,
            ValidateAudience = true,
            ValidAudience = j.Audience,
            ValidateLifetime = true,
            RequireExpirationTime = true,
            ClockSkew = TimeSpan.Zero, // an expired token is rejected right away
            ValidateIssuerSigningKey = true,
            ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
            // Without a proper key every token fails, so the app still starts.
            IssuerSigningKey = j.Key.Length >= 32
                ? new SymmetricSecurityKey(Encoding.UTF8.GetBytes(j.Key))
                : null,
        };

        o.Events = new JwtBearerEvents
        {
            // A valid signature is not enough: the token must still be in the database.
            OnTokenValidated = async ctx =>
            {
                var jti = (ctx.SecurityToken as JsonWebToken)?.Id;
                var auth = ctx.HttpContext.RequestServices.GetRequiredService<IAuthService>();

                if (!Guid.TryParse(jti, out var id)
                    || !await auth.IsTokenActiveAsync(id, ctx.HttpContext.RequestAborted))
                    ctx.Fail("Token is not active.");
            }
        };
    }

    public void Configure(JwtBearerOptions options) => Configure(Options.DefaultName, options);
}