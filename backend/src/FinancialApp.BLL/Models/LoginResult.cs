namespace FinancialApp.BLL.Models;

public enum LoginOutcome { Success, Invalid, BadCredentials }

public record LoginResult(
    LoginOutcome Outcome,
    LoginResponse? Response = null,
    IReadOnlyDictionary<string, string[]>? Errors = null)
{
    public static LoginResult Succeeded(LoginResponse response) => new(LoginOutcome.Success, response);
    public static LoginResult Invalid(IReadOnlyDictionary<string, string[]> errors) => new(LoginOutcome.Invalid, null, errors);
    public static LoginResult BadCredentials() => new(LoginOutcome.BadCredentials);
}