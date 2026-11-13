namespace FinancialApp.API.Auth;

public class JwtOptions
{
    public const string Section = "Jwt";

    public string Key { get; set; } = "";
    public string Issuer { get; set; } = "";
    public string Audience { get; set; } = "";
    public int LifetimeMinutes { get; set; } = 60;
}